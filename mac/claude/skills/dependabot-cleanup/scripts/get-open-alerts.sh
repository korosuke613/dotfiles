#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/get-open-alerts.sh
# Output: JSON array of open Dependabot alerts with structured fields
# owner/repo is auto-detected from git remote origin
#
# Note: Uses GraphQL API instead of REST API.
# The REST API's Dependabot alerts list endpoint has a known issue where
# cursor-based pagination (introduced Oct 2025) causes --paginate to
# return incomplete results. GraphQL reliably returns all alerts.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-repo.sh"

command -v gh >/dev/null 2>&1 || { echo "Error: gh is not installed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is not installed" >&2; exit 1; }

echo "Fetching Dependabot alerts for ${OWNER}/${REPO}..." >&2

# Fetch all open alerts using GraphQL with pagination
all_nodes="[]"
has_next="true"
cursor=""

while [ "$has_next" = "true" ]; do
  if [ -z "$cursor" ]; then
    after_clause="null"
  else
    after_clause="\"$cursor\""
  fi

  response=$(gh api graphql -f query="
    {
      repository(owner: \"${OWNER}\", name: \"${REPO}\") {
        vulnerabilityAlerts(first: 100, states: OPEN, after: ${after_clause}) {
          totalCount
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            number
            securityVulnerability {
              package { name ecosystem }
              firstPatchedVersion { identifier }
              vulnerableVersionRange
            }
            securityAdvisory {
              severity
              summary
            }
            vulnerableManifestPath
            state
          }
        }
      }
    }
  " 2>&1) || {
    echo "Error: Failed to fetch Dependabot alerts" >&2
    echo "$response" >&2
    exit 1
  }

  # Extract nodes and pagination info
  page_nodes=$(echo "$response" | jq '.data.repository.vulnerabilityAlerts.nodes')
  has_next=$(echo "$response" | jq -r '.data.repository.vulnerabilityAlerts.pageInfo.hasNextPage')
  cursor=$(echo "$response" | jq -r '.data.repository.vulnerabilityAlerts.pageInfo.endCursor')

  # Merge nodes
  all_nodes=$(echo "$all_nodes" "$page_nodes" | jq -s '.[0] + .[1]')
done

# Transform to match the expected output format
echo "$all_nodes" | jq '[.[] | {
  number,
  package: .securityVulnerability.package.name,
  ecosystem: .securityVulnerability.package.ecosystem,
  vulnerable_range: .securityVulnerability.vulnerableVersionRange,
  first_patched_version: .securityVulnerability.firstPatchedVersion.identifier,
  manifest: .vulnerableManifestPath,
  scope: (if .vulnerableManifestPath then null else null end),
  severity: (.securityAdvisory.severity | ascii_downcase),
  summary: .securityAdvisory.summary
}]'
