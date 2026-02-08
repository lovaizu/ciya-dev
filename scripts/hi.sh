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
