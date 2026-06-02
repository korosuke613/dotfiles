#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/get-alert-detail.sh <alert_number>
# Output: JSON object with alert detail including first_patched_version

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-repo.sh"

alert_number="${1:?Usage: $0 <alert_number>}"

command -v gh >/dev/null 2>&1 || { echo "Error: gh is not installed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is not installed" >&2; exit 1; }

[[ "$alert_number" =~ ^[0-9]+$ ]] || {
    echo "Error: alert_number must be an integer, got: $alert_number" >&2
    exit 1
}

response=$(gh api "repos/${OWNER}/${REPO}/dependabot/alerts/${alert_number}" 2>&1) || {
    echo "Error: Failed to fetch alert #${alert_number}" >&2
    echo "$response" >&2
    exit 1
}

echo "$response" | jq '{
  number,
  package: .security_vulnerability.package.name,
  ecosystem: .security_vulnerability.package.ecosystem,
  vulnerable_range: .security_vulnerability.vulnerable_version_range,
  first_patched_version: .security_vulnerability.first_patched_version.identifier,
  manifest: .dependency.manifest_path,
  scope: .dependency.scope,
  severity: .security_advisory.severity,
  summary: .security_advisory.summary,
  advisory_url: .security_advisory.references[0].url
}'
