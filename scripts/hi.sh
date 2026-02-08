#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: hi.sh <branch-name or path>" >&2
  exit 1
fi

branch="$(basename "$1")"
worktree_root="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$worktree_root"
git -C "$worktree_root/main" pull --ff-only origin main

if [ -d "$worktree_root/$branch" ]; then
  cd "$worktree_root/$branch"
else
  git worktree add "$branch" -b "$branch" origin/main
  cd "$worktree_root/$branch"
fi
exec claude
