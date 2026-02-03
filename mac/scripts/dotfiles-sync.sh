#!/usr/bin/env zsh

set -euo pipefail

# Repo + sync branch
REPO="$HOME/dotfiles"
SYNC_BRANCH="sync"

# State/log files
LOG_DIR="$HOME/Library/Logs"
STATE_DIR="$HOME/.local/state/dotfiles-sync"
STATE_FILE="$STATE_DIR/last_pr_month"
LAST_RUN_FILE="$STATE_DIR/last_run"
LOCK_DIR="$STATE_DIR/lock"

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_TERMINAL_PROMPT=0

mkdir -p "$LOG_DIR" "$STATE_DIR"

LOG_FILE="$LOG_DIR/dotfiles-sync.log"
NOTICE_PRINTED=0
DEBUG="${DOTFILES_SYNC_DEBUG:-}"

# Color output only when stderr is a TTY
if [[ -t 2 ]]; then
  C_CYAN=$'\033[36m'
  C_YELLOW=$'\033[33m'
  C_GREEN=$'\033[32m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_CYAN=""
  C_YELLOW=""
  C_GREEN=""
  C_DIM=""
  C_RESET=""
fi

# Log helpers (log file + stderr for human-visible errors)
log() {
  local msg="$1"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
}

err() {
  local msg="$1"
  printf '%s[%s] %s%s\n' "$C_YELLOW" "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" "$C_RESET" >&2
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
}

info() {
  local msg="$1"
  printf '%s%s%s\n' "$C_CYAN" "$msg" "$C_RESET" >&2
}

success() {
  local msg="$1"
  printf '%s%s%s\n' "$C_GREEN" "$msg" "$C_RESET" >&2
}

dbg() {
  if [[ -n "$DEBUG" ]]; then
    printf '%s[debug]%s %s\n' "$C_DIM" "$C_RESET" "$1" >&2
  fi
}

# Run a command and capture all output to log
run() {
  "$@" >> "$LOG_FILE" 2>&1
}

# Human-only guard: skip non-TTY, CI, or SSH non-interactive runs
if [[ ! -t 0 ]] || [[ ! -t 2 ]] || [[ -n "${CI:-}" ]] || [[ -n "${SSH_ORIGINAL_COMMAND:-}" ]]; then
  dbg "human-guard: skipped (stdin_tty=$(test -t 0 && echo yes || echo no), stderr_tty=$(test -t 2 && echo yes || echo no), CI=${CI:-}, SSH_ORIGINAL_COMMAND=${SSH_ORIGINAL_COMMAND:-})"
  exit 0
fi

# Bail out if repo is missing
if [[ ! -d "$REPO/.git" ]]; then
  log "Repo not found: $REPO"
  exit 0
fi

# Ensure required commands
if ! command -v git >/dev/null 2>&1; then
  log "git not found in PATH"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  log "gh not found in PATH (monthly PR creation will be skipped)"
fi

# Throttle: run at most once per hour
now_epoch=$(date '+%s')
last_epoch=0
if [[ -f "$LAST_RUN_FILE" ]]; then
  last_epoch=$(cat "$LAST_RUN_FILE" | tr -d '\n')
fi

# Lock to prevent concurrent runs (cleanup stale locks older than 10 min)
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  dbg "lock: exists"
  lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
  seconds_ago=0
  if [[ "$lock_mtime" -gt 0 ]]; then
    seconds_ago=$(( now_epoch - lock_mtime ))
  fi
  dbg "lock: mtime=$lock_mtime seconds_ago=$seconds_ago"

  if [[ "$lock_mtime" -gt 0 ]] && [[ "$seconds_ago" -gt 600 ]]; then
    dbg "lock: stale, removing"
    printf '%s=== DOTFILES CHANGES DETECTED ===%s\n' "$C_CYAN" "$C_RESET" >&2
    printf '%sStale lock detected%s (started ~%ds ago). Removing and continuing.\n' "$C_YELLOW" "$C_RESET" "$seconds_ago" >&2
    printf 'Log: %s%s%s\n' "$C_DIM" "$LOG_FILE" "$C_RESET" >&2
    printf '%s=================================%s\n' "$C_CYAN" "$C_RESET" >&2
    rmdir "$LOCK_DIR" >/dev/null 2>&1 || true
  fi

  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    dbg "lock: still held, skipping"
    printf '%s=== DOTFILES CHANGES DETECTED ===%s\n' "$C_CYAN" "$C_RESET" >&2
    printf '%sSync already running%s (started ~%ds ago). Skipping this run.\n' "$C_YELLOW" "$C_RESET" "$seconds_ago" >&2
    printf 'Log: %s%s%s\n' "$C_DIM" "$LOG_FILE" "$C_RESET" >&2
    printf '%s=================================%s\n' "$C_CYAN" "$C_RESET" >&2
    exit 0
  fi
  dbg "lock: acquired after cleanup"
fi
cleanup() {
  if [[ "$NOTICE_PRINTED" == "1" ]]; then
    printf '%s=================================%s\n' "$C_CYAN" "$C_RESET" >&2
  fi
  rmdir "$LOCK_DIR" >/dev/null 2>&1 || true
}
trap 'cleanup' EXIT

if [[ $((now_epoch - last_epoch)) -lt 3600 ]]; then
  exit 0
fi

# Human-friendly notice (only when actually running)
printf '%s=== DOTFILES CHANGES DETECTED ===%s\n' "$C_CYAN" "$C_RESET" >&2
printf '%sSyncing now%s (runs at most once per hour)...\n' "$C_YELLOW" "$C_RESET" >&2
printf 'Log: %s%s%s\n' "$C_DIM" "$LOG_FILE" "$C_RESET" >&2
NOTICE_PRINTED=1

echo "$now_epoch" > "$LAST_RUN_FILE"
log "Starting dotfiles sync"

# Fetch remote refs
if ! run git -C "$REPO" fetch origin main "$SYNC_BRANCH"; then
  err "git fetch failed"
  exit 1
fi

# Ensure local sync branch exists and tracks origin
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

# Rebase on top of remote sync
if ! run git -C "$REPO" pull --rebase --autostash origin "$SYNC_BRANCH"; then
  err "git pull --rebase failed; attempting rebase --abort"
  run git -C "$REPO" rebase --abort || true
  exit 1
fi

# Commit & push if there are changes (ask human first)
if git -C "$REPO" status --porcelain | grep -q .; then
  printf 'Commit and push dotfiles changes now? [y/N]: ' >&2
  if ! read -r reply; then
    err "Failed to read user input"
    exit 1
  fi
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log "User declined commit/push"
    exit 0
  fi

  info "Staging changes..."
  run git -C "$REPO" add -A
  if ! git -C "$REPO" diff --cached --quiet; then
    local_ts=$(date '+%Y-%m-%d %H:%M')
    info "Creating commit: sync: $local_ts"
    if run git -C "$REPO" commit -m "sync: $local_ts"; then
      info "Pushing to origin/$SYNC_BRANCH..."
      if run git -C "$REPO" push origin "$SYNC_BRANCH"; then
        log "Pushed sync changes"
        success "Sync complete."
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

# Monthly PR creation (first run after month change)
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
