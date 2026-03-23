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

    # Dynamic timestamps for test cases
    now=$(date +%s)
    five_reset_ts=$((now + 1320))    # 22 minutes from now
    seven_reset_ts=$((now + 151200)) # 1 day 18 hours from now

    run_test "git repo root" "{\"workspace\":{\"current_dir\":\"$HOME/ghq/github.com/user/project\",\"project_dir\":\"$HOME/ghq/github.com/user/project\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":15},\"rate_limits\":{\"five_hour\":{\"used_percentage\":15.2,\"resets_at\":$five_reset_ts},\"seven_day\":{\"used_percentage\":39.1,\"resets_at\":$seven_reset_ts}}}"

    run_test "git repo subdir" "{\"workspace\":{\"current_dir\":\"$HOME/ghq/github.com/user/project/src/lib\",\"project_dir\":\"$HOME/ghq/github.com/user/project\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":45},\"rate_limits\":{\"five_hour\":{\"used_percentage\":42.3,\"resets_at\":$five_reset_ts},\"seven_day\":{\"used_percentage\":55.0,\"resets_at\":$seven_reset_ts}}}"

    run_test "no project (null)" "{\"workspace\":{\"current_dir\":\"$HOME/Downloads/folder\",\"project_dir\":null},\"model\":{\"display_name\":\"Sonnet\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":55}}"

    run_test "no project (empty)" "{\"workspace\":{\"current_dir\":\"$HOME/tmp/deep/path\",\"project_dir\":\"\"},\"model\":{\"display_name\":\"Haiku\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":85}}"

    run_test "ctx 50% (yellow)" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":50}}"

    run_test "ctx 80% (red)" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":80}}"

    run_test "rate limit green" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"five_hour\":{\"used_percentage\":15.0,\"resets_at\":$five_reset_ts},\"seven_day\":{\"used_percentage\":25.0,\"resets_at\":$seven_reset_ts}}}"

    run_test "rate limit yellow" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"five_hour\":{\"used_percentage\":55.0,\"resets_at\":$five_reset_ts},\"seven_day\":{\"used_percentage\":65.0,\"resets_at\":$seven_reset_ts}}}"

    run_test "rate limit red" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"five_hour\":{\"used_percentage\":85.0,\"resets_at\":$five_reset_ts},\"seven_day\":{\"used_percentage\":92.0,\"resets_at\":$seven_reset_ts}}}"

    run_test "no rate limits" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":30}}"

    past_ts=$((now - 600))  # 10 minutes ago
    run_test "reset already passed" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"five_hour\":{\"used_percentage\":85.0,\"resets_at\":$past_ts},\"seven_day\":{\"used_percentage\":42.0,\"resets_at\":$seven_reset_ts}}}"

    run_test "only five_hour" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"five_hour\":{\"used_percentage\":50.0,\"resets_at\":$five_reset_ts}}}"

    run_test "only seven_day" "{\"workspace\":{\"current_dir\":\"$HOME/test\",\"project_dir\":\"$HOME/test\"},\"model\":{\"display_name\":\"Opus\"},\"output_style\":{\"name\":\"default\"},\"context_window\":{\"used_percentage\":20},\"rate_limits\":{\"seven_day\":{\"used_percentage\":70.0,\"resets_at\":$seven_reset_ts}}}"

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

# Read JSON input and extract all values in a single jq call
input=$(cat)
eval "$(echo "$input" | jq -r '
  @sh "cwd=\(.workspace.current_dir)",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "model=\(.model.display_name)",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "five_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_reset=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "seven_reset=\(.rate_limits.seven_day.resets_at // "")"
')"

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
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    ctx_color=$(get_usage_color "$used_int")
    context_info=" | ctx: ${ctx_color}${used_int}%${RESET}"
fi

# Rate limit info from JSON input (Claude Code v2.1.80+)
# Note: Claude Code provides both five_hour and seven_day together, but we handle partial data gracefully.
usage_info=""
if [ -n "$five_pct" ] || [ -n "$seven_pct" ]; then
    now_epoch=$(date +%s)
    parts=()

    # 5-hour window
    if [ -n "$five_pct" ]; then
        five_int=$(printf "%.0f" "$five_pct")
        five_reset_time=""
        if [ -n "$five_reset" ]; then
            remaining=$((five_reset - now_epoch))
            if [ $remaining -gt 0 ]; then
                hours=$((remaining / 3600))
                minutes=$(((remaining % 3600) / 60))
                if [ $hours -gt 0 ]; then
                    five_reset_time="${hours}h"
                    [ $minutes -gt 0 ] && five_reset_time="${five_reset_time}${minutes}m"
                else
                    five_reset_time="${minutes}m"
                fi
            fi
        fi
        five_color=$(get_usage_color "$five_int")
        five_display="${five_int}%"
        [ -n "$five_reset_time" ] && five_display="${five_display}(${five_reset_time})"
        parts+=("${five_color}${five_display}${RESET}")
    fi

    # 7-day window
    if [ -n "$seven_pct" ]; then
        seven_int=$(printf "%.0f" "$seven_pct")
        seven_reset_time=""
        if [ -n "$seven_reset" ]; then
            remaining=$((seven_reset - now_epoch))
            if [ $remaining -gt 0 ]; then
                days=$((remaining / 86400))
                hours=$(((remaining % 86400) / 3600))
                if [ $days -gt 0 ]; then
                    seven_reset_time="${days}d"
                    [ $hours -gt 0 ] && seven_reset_time="${seven_reset_time}${hours}h"
                else
                    seven_reset_time="${hours}h"
                fi
            fi
        fi
        seven_color=$(get_usage_color "$seven_int")
        seven_display="${seven_int}%"
        [ -n "$seven_reset_time" ] && seven_display="${seven_display}(${seven_reset_time})"
        parts+=("${seven_color}${seven_display}${RESET}")
    fi

    # Join parts with ", "
    usage_info=" | limit: $(printf '%s' "${parts[0]}")$([ ${#parts[@]} -gt 1 ] && printf ', %s' "${parts[1]}")"
fi

# Build status line (Starship-style: dir + git + model + context + usage)
printf "$(printf '\033[36m')%s$(printf '\033[0m')%s%s%s%s" "$dir_display" "$git_info" "$model_info" "$context_info" "$usage_info"

