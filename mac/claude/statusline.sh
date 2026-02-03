#!/bin/bash
#
# Claude Code Statusline Script
#
# Output preview:
#   mynewshq/src on feat/branch | Opus | ctx: 42% | limit: 15%(22m), 39%(1d18h)
#   ~~~~~~~~~~~~ ~~~~~~~~~~~~~   ~~~~   ~~~~~~~~   ~~~~~~~~~~~~~~~~~~~~~~~~~~
#   dir(cyan)    branch(orange)  model  context    usage: 5h%(left), 7d%(left)
#                                (pink) (g/y/r)    (g/y/r)
#
# Colors: green(<50%), yellow(50-79%), red(>=80%)
#
# Usage: Run with --test to see test cases
#

# Test mode: run with --test
if [ "$1" = "--test" ]; then
    run_test() {
        local name="$1"
        local json="$2"
        echo "=== $name ==="
        echo "$json" | /bin/bash "$0"
        echo ""
    }

    run_test "git repo root" "{\"workspace\":{\"current_dir\":\"$HOME/ghq/github.com/user/project\",\"project_dir\":\"$HOME/ghq/github.com/user/project\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":15}}"

    run_test "git repo subdir" "{\"workspace\":{\"current_dir\":\"$HOME/ghq/github.com/user/project/src/lib\",\"project_dir\":\"$HOME/ghq/github.com/user/project\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":45}}"

    run_test "no project (null)" "{\"workspace\":{\"current_dir\":\"$HOME/Downloads/folder\",\"project_dir\":null},\"model\":{\"display_name\":\"Sonnet\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":55}}"

    run_test "no project (empty)" "{\"workspace\":{\"current_dir\":\"$HOME/tmp/deep/path\",\"project_dir\":\"\"},\"model\":{\"display_name\":\"Haiku\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":85}}"

    run_test "ctx 50% (yellow)" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":50}}"

    run_test "ctx 80% (red)" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":80}}"

    exit 0
fi

# Color utilities
RESET=$(printf '\033[0m')
get_usage_color() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        printf '\033[91m'  # Red
    elif [ "$pct" -ge 50 ]; then
        printf '\033[93m'  # Yellow
    else
        printf '\033[92m'  # Green
    fi
}

# Read JSON input
input=$(cat)

# Extract values
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name')
output_style=$(echo "$input" | jq -r '.output_style.name')

# Format directory (show relative to project root)
if [ -n "$project_dir" ] && [ "$project_dir" != "null" ] && [ "$cwd" != "$project_dir" ]; then
    # Get project name (last component of project_dir)
    project_name="${project_dir##*/}"
    # Get relative path from project_dir
    relative_path="${cwd#$project_dir}"
    dir_display="${project_name}${relative_path}"
elif [ -n "$project_dir" ] && [ "$project_dir" != "null" ]; then
    # At project root
    dir_display="${project_dir##*/}"
else
    # Fallback to home-relative path
    dir_display="${cwd/#$HOME/~}"
fi

# Get git info (skip locks for safety)
git_info=""
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
    branch=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false branch --show-current 2>/dev/null || git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_info=" $(printf '\033[38;5;208m')on$(printf '\033[0m') $(printf '\033[38;5;208m')${branch}$(printf '\033[0m')"
    fi
fi

# Add model info
model_info=" | $(printf '\033[95m')${model}$(printf '\033[0m')"

# Calculate context usage if available
context_info=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    ctx_color=$(get_usage_color "$used_int")
    context_info=" | ctx: ${ctx_color}${used_int}%${RESET}"
fi

# Fetch Claude subscription usage (with cache)
usage_info=""
CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_MAX_AGE=300  # 5 minutes
OP_CLAUDE_TOKEN_ITEM_NAME="Claude OAuth token"  # Name of the 1Password item storing the oauth token

fetch_usage() {
    TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
	# TOKEN=$(op item get "$OP_CLAUDE_TOKEN_ITEM_NAME" --fields label=credential --reveal)
	if [ -n "$TOKEN" ]; then
        # Use --config with process substitution to avoid exposing token in process list
        curl --max-time 3 \
            -K <(printf '%s\n' \
                "-H \"Authorization: Bearer $TOKEN\"" \
                "-H \"anthropic-beta: oauth-2025-04-20\"" \
                "-H \"Content-Type: application/json\"") \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null
    fi
	# Example response:
    # {
    #   "five_hour": {
    #     "utilization": 7.0,
    #     "resets_at": "2026-01-20T08:00:00.425335+00:00"
    #   },
    #   "seven_day": {
    #     "utilization": 38.0,
    #     "resets_at": "2026-01-22T02:00:00.425356+00:00"
    #   },
    #   "seven_day_oauth_apps": null,
    #   "seven_day_opus": null,
    #   "seven_day_sonnet": {
    #     "utilization": 36.0,
    #     "resets_at": "2026-01-25T07:00:00.425364+00:00"
    #   },
    #   "iguana_necktie": null,
    #   "extra_usage": {
    #     "is_enabled": false,
    #     "monthly_limit": null,
    #     "used_credits": null,
    #     "utilization": null
    #   }
    # }
}

get_usage() {
    local now=$(date +%s)
    local cache_time=0

    # Check cache
    if [ -f "$CACHE_FILE" ]; then
        cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
        local age=$((now - cache_time))
        if [ $age -lt $CACHE_MAX_AGE ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi

    # Fetch fresh data
    local usage=$(fetch_usage)
    if [ -n "$usage" ] && echo "$usage" | jq -e '.five_hour' >/dev/null 2>&1; then
        echo "$usage" > "$CACHE_FILE"
        echo "$usage"
    elif [ -f "$CACHE_FILE" ]; then
        # Use stale cache on error
        cat "$CACHE_FILE"
    fi
}

usage_data=$(get_usage)
if [ -n "$usage_data" ]; then
    five_hour=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty')
    five_hour_reset=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
    seven_day=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty')
    seven_day_reset=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')

    if [ -n "$five_hour" ] && [ -n "$seven_day" ]; then
        five_int=$(printf "%.0f" "$five_hour")
        seven_int=$(printf "%.0f" "$seven_day")
        now_epoch=$(date +%s)

        # Calculate remaining time until 5h reset
        five_reset_time=""
        if [ -n "$five_hour_reset" ]; then
            utc_time="${five_hour_reset%%.*}+0000"
            reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$utc_time" "+%s" 2>/dev/null)
            if [ -n "$reset_epoch" ]; then
                remaining=$((reset_epoch - now_epoch))
                if [ $remaining -gt 0 ]; then
                    hours=$((remaining / 3600))
                    minutes=$(((remaining % 3600) / 60))
                    if [ $hours -gt 0 ]; then
                        five_reset_time="${hours}h${minutes}m"
                    else
                        five_reset_time="${minutes}m"
                    fi
                fi
            fi
        fi

        # Calculate remaining time until 7d reset
        seven_reset_time=""
        if [ -n "$seven_day_reset" ]; then
            utc_time="${seven_day_reset%%.*}+0000"
            reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$utc_time" "+%s" 2>/dev/null)
            if [ -n "$reset_epoch" ]; then
                remaining=$((reset_epoch - now_epoch))
                if [ $remaining -gt 0 ]; then
                    days=$((remaining / 86400))
                    hours=$(((remaining % 86400) / 3600))
                    if [ $days -gt 0 ]; then
                        seven_reset_time="${days}d${hours}h"
                    else
                        seven_reset_time="${hours}h"
                    fi
                fi
            fi
        fi

        five_color=$(get_usage_color "$five_int")
        seven_color=$(get_usage_color "$seven_int")
        usage_info=" | limit: ${five_color}${five_int}%${RESET}(${five_reset_time}), ${seven_color}${seven_int}%${RESET}(${seven_reset_time})"
    fi
fi

# Build status line (Starship-style: dir + git + model + context + usage)
printf "$(printf '\033[36m')%s$(printf '\033[0m')%s%s%s%s" "$dir_display" "$git_info" "$model_info" "$context_info" "$usage_info"

