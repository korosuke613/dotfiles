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
    jq -n --arg pane "${3}" '{result:{agent:{pane_id:$pane,tab_id:"w1:t1",workspace_id:"w1",tab_id:"w1:t1",agent:"copilot",terminal_title_stripped:"Fix OAuth callback"}}}'
    ;;
  "api snapshot")
    jq -n '{result:{snapshot:{tabs:[{tab_id:"w1:t1",label:"1"}],panes:[{pane_id:"w1:p1",tab_id:"w1:t1",workspace_id:"w1",agent:"copilot",focused:true,agent_status:"working",terminal_title_stripped:"Fix OAuth callback"}]}}}'
    ;;
  "workspace get")
    jq -n '{result:{workspace:{workspace_id:"w1",label:"home",tokens:{project:"home-server"}}}}'
    ;;
  "agent rename"|"tab rename"|"workspace rename")
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
grep -Fx 'agent rename w1:p1 copilot' "$tmp/log"
grep -Fx 'tab rename w1:t1 Fix OAuth callback' "$tmp/log"
grep -Fx 'workspace rename w1 home-server - Fix OAuth callback' "$tmp/log"

# 回帰: ID再利用で前セッションの状態ファイルが残っていても、初期名なら更新される
: >"$tmp/log"
printf 'Old session tab\n' >"$HERDR_PLUGIN_STATE_DIR/tab-w1_t1.label"
printf 'home-server - Old session\n' >"$HERDR_PLUGIN_STATE_DIR/workspace-w1.label"
bash "$root/sync.sh"
grep -Fx 'tab rename w1:t1 Fix OAuth callback' "$tmp/log"
grep -Fx 'workspace rename w1 home-server - Fix OAuth callback' "$tmp/log"
[[ "$(<"$HERDR_PLUGIN_STATE_DIR/tab-w1_t1.label")" == "Fix OAuth callback" ]]

# 手動変更(初期名でも保存値でも新タイトルでもない)は引き続き尊重される
: >"$tmp/log"
cat >"$tmp/herdr-manual" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  "api snapshot") "$HERDR_REAL_STUB" "$@" | jq '.result.snapshot.tabs[0].label="My name"' ;;
  "workspace get") "$HERDR_REAL_STUB" "$@" | jq '.result.workspace.label="My space"' ;;
  *) "$HERDR_REAL_STUB" "$@" ;;
esac
STUB
chmod +x "$tmp/herdr-manual"
printf 'Old session tab\n' >"$HERDR_PLUGIN_STATE_DIR/tab-w1_t1.label"
printf 'home-server - Old session\n' >"$HERDR_PLUGIN_STATE_DIR/workspace-w1.label"
HERDR_REAL_STUB="$tmp/herdr" HERDR_BIN_PATH="$tmp/herdr-manual" bash "$root/sync.sh" 2>/dev/null
! grep -q '^tab rename' "$tmp/log"
! grep -q '^workspace rename' "$tmp/log"

printf 'title-sync tests passed\n'
