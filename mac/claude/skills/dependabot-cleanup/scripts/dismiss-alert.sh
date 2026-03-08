#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/dismiss-alert.sh <alert_number> <reason> <comment>
#
# Valid reasons: fix_started, inaccurate, no_bandwidth, not_used, tolerable_risk
# NOTE: "not_impacted" is NOT a valid value (returns HTTP 422)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-repo.sh"

alert_number="${1:?Usage: $0 <alert_number> <reason> <comment>}"
reason="${2:?Usage: $0 <alert_number> <reason> <comment>}"
comment="${3:?Usage: $0 <alert_number> <reason> <comment>}"

command -v gh >/dev/null 2>&1 || { echo "Error: gh is not installed" >&2; exit 1; }

[[ "$alert_number" =~ ^[0-9]+$ ]] || {
    echo "Error: alert_number must be an integer, got: $alert_number" >&2
    exit 1
}

valid_reasons=("fix_started" "inaccurate" "no_bandwidth" "not_used" "tolerable_risk")
valid=false
for r in "${valid_reasons[@]}"; do
    [[ "$reason" == "$r" ]] && valid=true && break
done
$valid || {
    echo "Error: Invalid dismissed_reason: $reason" >&2
    echo "Valid values: ${valid_reasons[*]}" >&2
    exit 1
}

response=$(gh api --method PATCH "repos/${OWNER}/${REPO}/dependabot/alerts/${alert_number}" \
  -f state=dismissed \
  -f dismissed_reason="$reason" \
  -f dismissed_comment="$comment" 2>&1) || {
    echo "Error: Failed to dismiss alert #${alert_number}" >&2
    echo "$response" >&2
    exit 1
}

echo "Dismissed #${alert_number} (${OWNER}/${REPO})"
