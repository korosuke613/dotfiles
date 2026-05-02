#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/dismiss-alerts-batch.sh <alert_numbers> <reason> <comment>
# alert_numbers: space-separated list of alert numbers (e.g., "89 90 96 97")
#
# Valid reasons: fix_started, inaccurate, no_bandwidth, not_used, tolerable_risk
# NOTE: "not_impacted" is NOT a valid value (returns HTTP 422)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

alert_numbers="${1:?Usage: $0 <alert_numbers> <reason> <comment>}"
reason="${2:?Usage: $0 <alert_numbers> <reason> <comment>}"
comment="${3:?Usage: $0 <alert_numbers> <reason> <comment>}"

succeeded=0
failed=0
failed_alerts=""

for alert_num in $alert_numbers; do
    if "$SCRIPT_DIR/dismiss-alert.sh" "$alert_num" "$reason" "$comment"; then
        ((succeeded++))
    else
        ((failed++))
        failed_alerts="${failed_alerts} #${alert_num}"
    fi
done

echo ""
echo "=== Batch dismiss summary ==="
echo "Succeeded: $succeeded"
echo "Failed: $failed"
if [[ $failed -gt 0 ]]; then
    echo "Failed alerts:${failed_alerts}"
    exit 1
fi
