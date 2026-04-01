#!/usr/bin/env bash
set -euo pipefail

# Detect owner/repo from git remote origin.
# Usage: source this script to set OWNER and REPO variables.
#
# Supports:
#   - HTTPS: https://github.com/owner/repo.git
#   - SSH:   git@github.com:owner/repo.git

remote_url=$(git remote get-url origin 2>/dev/null) || {
    echo "Error: Not a git repository or no 'origin' remote found" >&2
    exit 1
}

# Strip trailing .git
remote_url="${remote_url%.git}"

if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    echo "Error: Could not parse owner/repo from remote URL: $remote_url" >&2
    exit 1
fi

export OWNER REPO
