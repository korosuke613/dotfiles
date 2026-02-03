#!/usr/bin/env zsh

set -euo pipefail

REPO="$HOME/dotfiles"
SYNC_BRANCH="sync"
LOG_DIR="$HOME/Library/Logs"
STATE_DIR="$HOME/.local/state/dotfiles-sync"
STATE_FILE="$STATE_DIR/last_pr_month"
LAST_RUN_FILE="$STATE_DIR/last_run"
LOCK_DIR="$STATE_DIR/lock"

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_TERMINAL_PROMPT=0

mkdir -p "$LOG_DIR" "$STATE_DIR"

LOG_FILE="$LOG_DIR/dotfiles-sync.log"

log() {
  local msg="$1"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
}

err() {
  local msg="$1"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >&2
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
}

run() {
  "$@" >> "$LOG_FILE" 2>&1
}

if [[ ! -d "$REPO/.git" ]]; then
  log "Repo not found: $REPO"
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  log "git not found in PATH"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  log "gh not found in PATH (monthly PR creation will be skipped)"
fi

now_epoch=$(date '+%s')
last_epoch=0
if [[ -f "$LAST_RUN_FILE" ]]; then
  last_epoch=$(cat "$LAST_RUN_FILE" | tr -d '\n')
fi

if [[ $((now_epoch - last_epoch)) -lt 3600 ]]; then
  exit 0
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Another sync is running
  exit 0
fi
trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1 || true' EXIT

printf '=== DOTFILES CHANGES DETECTED ===\n' >&2
printf 'Syncing now (runs at most once per hour)...\n' >&2
printf 'Log: %s\n' "$LOG_FILE" >&2
printf '=================================\n' >&2

echo "$now_epoch" > "$LAST_RUN_FILE"
log "Starting dotfiles sync"

if ! run git -C "$REPO" fetch origin main "$SYNC_BRANCH"; then
  err "git fetch failed"
  exit 1
fi

if ! git -C "$REPO" show-ref --verify --quiet "refs/heads/$SYNC_BRANCH"; then
  if git -C "$REPO" show-ref --verify --quiet "refs/remotes/origin/$SYNC_BRANCH"; then
    log "Creating local $SYNC_BRANCH tracking origin/$SYNC_BRANCH"
    run git -C "$REPO" switch -c "$SYNC_BRANCH" --track "origin/$SYNC_BRANCH"
  else
    log "Creating local $SYNC_BRANCH from origin/main"
    run git -C "$REPO" switch -c "$SYNC_BRANCH" "origin/main"
    if ! run git -C "$REPO" push -u origin "$SYNC_BRANCH"; then
      err "git push failed"
      exit 1
    fi
  fi
else
  run git -C "$REPO" switch "$SYNC_BRANCH"
fi

if ! run git -C "$REPO" pull --rebase --autostash origin "$SYNC_BRANCH"; then
  err "git pull --rebase failed; attempting rebase --abort"
  run git -C "$REPO" rebase --abort || true
  exit 1
fi

# Commit and push if staged changes exist
if git -C "$REPO" status --porcelain | grep -q .; then
  run git -C "$REPO" add -A
  if ! git -C "$REPO" diff --cached --quiet; then
    local_ts=$(date '+%Y-%m-%d %H:%M')
    if run git -C "$REPO" commit -m "sync: $local_ts"; then
      if run git -C "$REPO" push origin "$SYNC_BRANCH"; then
        log "Pushed sync changes"
      else
        err "git push failed"
        exit 1
      fi
    else
      err "git commit failed"
      exit 1
    fi
  fi
fi

# Monthly PR creation
current_month=$(date '+%Y-%m')
last_month=""
if [[ -f "$STATE_FILE" ]]; then
  last_month=$(cat "$STATE_FILE" | tr -d '\n')
fi

if [[ "$current_month" != "$last_month" ]]; then
  if command -v gh >/dev/null 2>&1; then
    ahead_count=$(git -C "$REPO" rev-list --count origin/main.."$SYNC_BRANCH")
    if [[ "$ahead_count" -gt 0 ]]; then
      if ! run gh pr list --base main --head "$SYNC_BRANCH" --state open | grep -q .; then
        if run gh pr create --base main --head "$SYNC_BRANCH" --title "dotfiles: sync $current_month" --body "Monthly squash merge for $current_month."; then
          echo "$current_month" > "$STATE_FILE"
          log "Created monthly PR for $current_month"
        else
          err "gh pr create failed"
          exit 1
        fi
      else
        echo "$current_month" > "$STATE_FILE"
        log "Monthly PR already exists; recorded month"
      fi
    else
      log "No changes to main..sync; skipping PR"
    fi
  else
    log "gh not available; skipping PR creation"
  fi
fi

log "Finished dotfiles sync"
