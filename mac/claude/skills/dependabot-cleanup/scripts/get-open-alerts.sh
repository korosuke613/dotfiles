#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/get-open-alerts.sh
# Output: JSON array of open Dependabot alerts with structured fields
# owner/repo is auto-detected from git remote origin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-repo.sh"

command -v gh >/dev/null 2>&1 || { echo "Error: gh is not installed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is not installed" >&2; exit 1; }

echo "Fetching Dependabot alerts for ${OWNER}/${REPO}..." >&2

response=$(gh api "repos/${OWNER}/${REPO}/dependabot/alerts" \
  --paginate \
  -q '[.[] | select(.state == "open")]' 2>&1) || {
    echo "Error: Failed to fetch Dependabot alerts" >&2
    echo "$response" >&2
    exit 1
}

echo "$response" | jq '[.[] | {
  number,
  package: .security_vulnerability.package.name,
  ecosystem: .security_vulnerability.package.ecosystem,
  vulnerable_range: .security_vulnerability.vulnerable_version_range,
  first_patched_version: .security_vulnerability.first_patched_version.identifier,
  manifest: .dependency.manifest_path,
  scope: .dependency.scope,
  severity: .security_advisory.severity,
  summary: .security_advisory.summary
}]'
