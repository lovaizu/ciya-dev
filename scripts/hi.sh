#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: hi.sh <branch-name>" >&2
  exit 1
fi

branch="$1"
worktree_root="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$worktree_root"
git fetch origin
git worktree add "$branch" -b "$branch" origin/main

cd "$worktree_root/$branch"
exec claude
