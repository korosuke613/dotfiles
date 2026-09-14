#!/usr/bin/env bash

set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
state_dir="${HERDR_PLUGIN_STATE_DIR:?HERDR_PLUGIN_STATE_DIR is required}"
event_json="${HERDR_PLUGIN_EVENT_JSON:-}"

mkdir -p "$state_dir"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$state_dir/lock"
  flock 9
else
  lock_dir="$state_dir/lockdir"
  while ! mkdir "$lock_dir" 2>/dev/null; do
    sleep 0.1
  done
  trap 'rmdir "$lock_dir"' EXIT
fi

log() {
  printf 'title-sync: %s\n' "$*" >&2
}

run_herdr() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 "$herdr_bin" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 10 "$herdr_bin" "$@"
  else
    "$herdr_bin" "$@"
  fi
}

normalize_title() {
  local title="$1"
  title=${title//$'\r'/ }
  title=${title//$'\n'/ }
  title=$(printf '%s' "$title" | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//')
  printf '%s' "${title:0:120}"
}

meaningful_title() {
  local title="$1"
  local agent="$2"
  [[ -n "$title" ]] || return 1
  [[ "$title" != "$agent" ]] || return 1
  [[ "$title" != "Claude Code" ]] || return 1
  [[ "$title" != "GitHub Copilot" ]] || return 1
  [[ "$title" != "Copilot" ]] || return 1
  [[ "$title" != "Codex" ]] || return 1
  [[ "$title" != "OpenCode" ]] || return 1
}

agent_name() {
  local title="$1"
  local agent="$2"
  case "$agent" in
    claude|copilot|codex|opencode)
      printf '%s' "$agent"
      return
      ;;
  esac
  local slug
  slug=$(printf '%s' "$title" |
    LC_ALL=C tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9_-]+/-/g; s/^-+//; s/-+$//' |
    cut -c1-32)
  [[ "$slug" =~ ^[a-z] ]] || slug="task-${slug}"
  printf '%s' "${slug:0:32}"
}

rename_agent() {
  local pane_id="$1"
  local title="$2"
  local agent="$3"
  run_herdr agent rename "$pane_id" "$(agent_name "$title" "$agent")" >/dev/null
}

rename_tab_if_owned() {
  local tab_id="$1"
  local title="$2"
  local current="$3"
  local state_file="$state_dir/tab-${tab_id//:/_}.label"

  if [[ -f "$state_file" ]]; then
    local expected
    expected=$(<"$state_file")
    if [[ "$current" != "$expected" && "$current" != "$title" ]]; then
      log "tab $tab_id appears manually renamed; leaving it unchanged"
      return 0
    fi
  elif [[ "$current" != "1" && "$current" != "2" && "$current" != "3" &&
          "$current" != "4" && "$current" != "5" ]]; then
    log "tab $tab_id has a non-default label; leaving it unchanged"
    return 0
  fi

  [[ "$current" == "$title" ]] || run_herdr tab rename "$tab_id" "$title" >/dev/null
  printf '%s\n' "$title" >"$state_file"
}

rename_workspace_if_owned() {
  local workspace_id="$1"
  local project="$2"
  local title="$3"
  local current="$4"
  local workspace_label="${project} - ${title}"
  local state_file="$state_dir/workspace-${workspace_id}.label"

  workspace_label=$(normalize_title "$workspace_label")
  if [[ -f "$state_file" ]]; then
    local expected
    expected=$(<"$state_file")
    if [[ "$current" != "$expected" && "$current" != "$workspace_label" ]]; then
      log "workspace $workspace_id appears manually renamed; leaving it unchanged"
      return 0
    fi
  elif [[ "$current" != "home" && "$current" != "$project" ]]; then
    log "workspace $workspace_id has a non-default label; leaving it unchanged"
    return 0
  fi

  [[ "$current" == "$workspace_label" ]] ||
    run_herdr workspace rename "$workspace_id" "$workspace_label" >/dev/null
  printf '%s\n' "$workspace_label" >"$state_file"
}

sync_workspace() {
  local workspace_id="$1"
  local snapshot workspace_json project current representative

  workspace_json=$(run_herdr workspace get "$workspace_id" | jq -e '.result.workspace')
  project=$(jq -r '.tokens.project // empty' <<<"$workspace_json")
  [[ -n "$project" ]] || return 0
  current=$(jq -r '.label // empty' <<<"$workspace_json")
  snapshot=$(run_herdr api snapshot | jq -e '.result.snapshot')
  representative=$(jq -r --arg workspace "$workspace_id" '
    [.panes[] | select(.workspace_id == $workspace and .agent != null)] |
    (map(select(.focused)) + map(select(.agent_status == "working")) + .) |
    .[0].terminal_title_stripped // empty
  ' <<<"$snapshot")
  representative=$(normalize_title "$representative")
  [[ -n "$representative" ]] || return 0
  rename_workspace_if_owned "$workspace_id" "$project" "$representative" "$current"
}

sync_pane() {
  local pane_id="$1" workspace_id
  local agent_json tab_id agent title snapshot tab_json agent_count current_tab

  agent_json=$(run_herdr agent get "$pane_id" | jq -e '.result.agent')
  tab_id=$(jq -r '.tab_id // empty' <<<"$agent_json")
  workspace_id=$(jq -r '.workspace_id // empty' <<<"$agent_json")
  agent=$(jq -r '.agent // empty' <<<"$agent_json")
  title=$(normalize_title "$(jq -r '.terminal_title_stripped // empty' <<<"$agent_json")")
  [[ -n "$tab_id" && -n "$agent" ]] || return 0
  meaningful_title "$title" "$agent" || return 0

  rename_agent "$pane_id" "$title" "$agent"

  snapshot=$(run_herdr api snapshot | jq -e '.result.snapshot')
  tab_json=$(jq -c --arg tab "$tab_id" '.tabs[] | select(.tab_id == $tab)' <<<"$snapshot")
  agent_count=$(jq --arg tab "$tab_id" '[.panes[] | select(.tab_id == $tab and .agent != null)] | length' <<<"$snapshot")
  current_tab=$(jq -r '.label // empty' <<<"$tab_json")
  if [[ "$agent_count" -eq 1 && -n "$current_tab" ]]; then
    rename_tab_if_owned "$tab_id" "$title" "$current_tab"
  fi
  [[ -n "$workspace_id" ]] && sync_workspace "$workspace_id"
}

sync_all() {
  run_herdr agent list |
    jq -r '.result.agents[]?.pane_id // empty' |
    while IFS= read -r pane_id; do
      [[ -n "$pane_id" ]] && sync_pane "$pane_id"
    done
}

if [[ "${1:-}" == "--all" ]]; then
  sync_all
  exit 0
fi

pane_id="${HERDR_PANE_ID:-}"
if [[ -z "$pane_id" && -n "$event_json" ]]; then
  pane_id=$(jq -r '.data.pane_id // .pane_id // empty' <<<"$event_json")
fi
[[ -n "$pane_id" ]] || exit 0
sync_pane "$pane_id"
