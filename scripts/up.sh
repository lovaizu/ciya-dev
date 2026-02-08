#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/lovaizu/ciya-dev.git"
dir="ciya-dev"

if [ -d "$dir" ]; then
  echo "Error: directory '$dir' already exists" >&2
  exit 1
fi

mkdir "$dir" && cd "$dir"
git clone --bare "$repo_url" .bare
echo "gitdir: ./.bare" > .git
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
git worktree add main main

echo "Done! Run: cd $dir && ./main/scripts/hi.sh <branch-name or path>"
