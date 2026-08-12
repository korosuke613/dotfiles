#!/usr/bin/env bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
export MISE_CEILING_PATHS="$(dirname "$repo_root")"
mode="${1:-apply}"
mise_version="2026.8.5"
mise_sha256="0268084c853545dc4a81acc0a494965a784a8935f3aa53728f0703398dc0cdbd"
mise_bin="${MISE_BIN:-$HOME/.local/bin/mise}"

usage() {
  printf 'Usage: %s [check|dry-run|apply]\n' "$0" >&2
  exit 2
}

find_mise() {
  local candidate=""
  if [[ -n "${MISE_BIN:-}" && -x "$mise_bin" ]]; then
    candidate="$mise_bin"
  elif command -v mise >/dev/null 2>&1; then
    candidate=$(command -v mise)
  elif [[ -x "$mise_bin" ]]; then
    candidate="$mise_bin"
  fi
  [[ -n "$candidate" ]] || return 1
  [[ "$("$candidate" --version 2>/dev/null)" == "$mise_version "* ]] || return 1
  printf '%s\n' "$candidate"
}

download_mise() {
  local destination="$1"
  [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || {
    printf 'setup: only Apple Silicon macOS is supported\n' >&2
    return 1
  }

  local actual
  curl -fL "https://github.com/jdx/mise/releases/download/v${mise_version}/mise-v${mise_version}-macos-arm64" \
    -o "$destination"
  actual=$(shasum -a 256 "$destination" | awk '{print $1}')
  [[ "$actual" == "$mise_sha256" ]] || {
    printf 'setup: mise checksum mismatch (expected %s, got %s)\n' "$mise_sha256" "$actual" >&2
    return 1
  }
  chmod 0755 "$destination"
}

install_mise() {
  local tmp
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' RETURN
  download_mise "$tmp"
  mkdir -p "$(dirname "$mise_bin")"
  install -m 0755 "$tmp" "$mise_bin"
}

case "$mode" in
  check)
    exec "$repo_root/mac/scripts/dot-doctor"
    ;;
  dry-run)
    dry_run_mise=""
    dry_run_dir=""
    mise_cmd=$(find_mise) || {
      dry_run_dir=$(mktemp -d)
      dry_run_mise="$dry_run_dir/mise"
      trap 'rm -f "$dry_run_mise"; rmdir "$dry_run_dir"' EXIT
      download_mise "$dry_run_mise" || exit 1
      mise_cmd="$dry_run_mise"
    }
    "$repo_root/mac/scripts/bootstrap-preflight"
    "$mise_cmd" trust "$repo_root/mise.toml" >/dev/null
    "$mise_cmd" -C "$repo_root" bootstrap --dry-run --locked
    if [[ -n "$dry_run_mise" ]]; then
      rm -f "$dry_run_mise"
      rmdir "$dry_run_dir"
      trap - EXIT
    fi
    ;;
  apply)
    mise_cmd=$(find_mise) || {
      install_mise
      mise_cmd="$mise_bin"
    }
    "$repo_root/mac/scripts/bootstrap-preflight"
    "$mise_cmd" trust "$repo_root/mise.toml" >/dev/null
    "$mise_cmd" -C "$repo_root" install jq --locked
    jq_bin=$("$mise_cmd" -C "$repo_root" which jq)
    "$repo_root/mac/scripts/bootstrap-migrate"
    JQ_BIN="$jq_bin" "$repo_root/mac/scripts/bootstrap-overlays"
    "$mise_cmd" -C "$repo_root" bootstrap --yes --locked
    "$repo_root/mac/scripts/bootstrap-assets"
    export MISE_BIN="$mise_cmd"
    exec "$repo_root/mac/scripts/dot-doctor"
    ;;
  *)
    usage
    ;;
esac
