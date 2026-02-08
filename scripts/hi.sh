#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: hi.sh <branch-name-or-path>" >&2
  exit 1
fi

arg="$1"
worktree_root="$(cd "$(dirname "$0")/../.." && pwd)"

# Resolve branch name from path (e.g., /path/to/ciya-dev/my-branch -> my-branch)
if [[ "$arg" == */* ]]; then
  branch="$(basename "$arg")"
else
  branch="$arg"
fi

worktree_dir="$worktree_root/$branch"

# Source .env if it exists in the worktree
if [ -f "$worktree_dir/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$worktree_dir/.env"
  set +a
fi

# Default ALLOWED_DOMAINS_FILE to the worktree's allowed-domains.txt
export ALLOWED_DOMAINS_FILE="${ALLOWED_DOMAINS_FILE:-$worktree_dir/.claude/hooks/allowed-domains.txt}"

if [ -d "$worktree_dir" ]; then
  # Resume existing worktree
  cd "$worktree_dir"
  exec claude --dangerously-skip-permissions
fi

# Create new worktree
cd "$worktree_root"
git fetch origin
git worktree add "$branch" -b "$branch" origin/main

cd "$worktree_dir"
exec claude --dangerously-skip-permissions
