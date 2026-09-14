#!/usr/bin/env bash

set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
state_dir="${HERDR_PLUGIN_STATE_DIR:?HERDR_PLUGIN_STATE_DIR is required}"
event_json="${HERDR_PLUGIN_EVENT_JSON:-}"

mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock 9

log() {
  printf 'title-sync: %s\n' "$*" >&2
}

run_herdr() {
  timeout 10 "$herdr_bin" "$@"
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

rename_agent() {
  local pane_id="$1"
  local title="$2"
  run_herdr agent rename "$pane_id" "$title" >/dev/null
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

sync_pane() {
  local pane_id="$1"
  local agent_json tab_id agent title snapshot tab_json agent_count current_tab

  agent_json=$(run_herdr agent get "$pane_id" | jq -e '.result.agent')
  tab_id=$(jq -r '.tab_id // empty' <<<"$agent_json")
  agent=$(jq -r '.agent // empty' <<<"$agent_json")
  title=$(normalize_title "$(jq -r '.terminal_title_stripped // empty' <<<"$agent_json")")
  [[ -n "$tab_id" && -n "$agent" ]] || return 0
  meaningful_title "$title" "$agent" || return 0

  rename_agent "$pane_id" "$title"

  snapshot=$(run_herdr api snapshot | jq -e '.result.snapshot')
  tab_json=$(jq -c --arg tab "$tab_id" '.tabs[] | select(.tab_id == $tab)' <<<"$snapshot")
  agent_count=$(jq --arg tab "$tab_id" '[.panes[] | select(.tab_id == $tab and .agent != null)] | length' <<<"$snapshot")
  current_tab=$(jq -r '.label // empty' <<<"$tab_json")
  if [[ "$agent_count" -eq 1 && -n "$current_tab" ]]; then
    rename_tab_if_owned "$tab_id" "$title" "$current_tab"
  fi
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
