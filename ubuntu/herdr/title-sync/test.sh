#!/usr/bin/env bash

set -euo pipefail

root="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/herdr" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  "agent get")
    jq -n --arg pane "${3}" '{result:{agent:{pane_id:$pane,tab_id:"w1:t1",agent:"copilot",terminal_title_stripped:"Fix OAuth callback"}}}'
    ;;
  "api snapshot")
    jq -n '{result:{snapshot:{tabs:[{tab_id:"w1:t1",label:"1"}],panes:[{pane_id:"w1:p1",tab_id:"w1:t1",agent:"copilot"}]}}}'
    ;;
  "agent rename"|"tab rename")
    printf '%s\n' "$*" >>"$HERDR_TEST_LOG"
    ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$tmp/herdr"

export HERDR_BIN_PATH="$tmp/herdr"
export HERDR_PLUGIN_STATE_DIR="$tmp/state"
export HERDR_PANE_ID="w1:p1"
export HERDR_TEST_LOG="$tmp/log"

bash "$root/sync.sh"
grep -Fx 'agent rename w1:p1 Fix OAuth callback' "$tmp/log"
grep -Fx 'tab rename w1:t1 Fix OAuth callback' "$tmp/log"

printf 'title-sync tests passed\n'
