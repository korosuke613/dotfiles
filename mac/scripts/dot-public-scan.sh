#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s [--staged|--all]\\n' "$0" >&2
  exit 2
}

mode="${1:---staged}"
case "$mode" in
  --staged|--all) ;;
  *) usage ;;
esac

repo_root=$(git rev-parse --show-toplevel)
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

if [[ "$mode" == "--staged" ]]; then
  git -C "$repo_root" diff --cached --no-ext-diff --unified=0 --binary >"$tmp_file"
fi

patterns=(
  'op://'
  'BEGIN (OPENSSH|RSA|EC) PRIVATE KEY'
  'ntfy\.sh/'
  '/Users/[^/$[:space:]]+/'
  '[[:alnum:]._%+-]+@(private-role|client-role)\.[[:alnum:].-]+'
  'github\.dev\.private-role\.co\.jp'
)

failed=0
for pattern in "${patterns[@]}"; do
  if [[ "$mode" == "--staged" ]]; then
    matches=$(grep -E -n -- "$pattern" "$tmp_file" || true)
  else
    matches=$(git -C "$repo_root" grep -n -I -E -- "$pattern" HEAD -- || true)
  fi
  if [[ -n "$matches" ]]; then
    printf '%s\n' "$matches"
    printf 'public scan failed: matched %s\n' "$pattern" >&2
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  printf 'Remove or explicitly review the matched content before publishing.\n' >&2
  exit 1
fi

printf 'public scan passed (%s)\\n' "$mode"
