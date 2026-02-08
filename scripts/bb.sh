#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: bb.sh <branch-name-or-path>" >&2
  exit 1
fi

branch="$(basename "$1")"
worktree_root="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$worktree_root"
git worktree remove "$branch"
git branch -D "$branch"
git remote prune origin

echo "Done! Removed worktree and branch: $branch"
