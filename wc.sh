#!/usr/bin/env bash
set -euo pipefail

# wc.sh — Welcome! One-time bootstrap for ciya-dev.
# Creates: ciya-dev/ with bare clone + .env + up.sh symlink
#
# Usage: curl -fsSL <raw-url>/wc.sh -o wc.sh && bash wc.sh

repo_url="https://github.com/lovaizu/ciya-dev.git"
dir="ciya-dev"

if [ -d "$dir" ]; then
  echo "Error: directory '$dir' already exists" >&2
  exit 1
fi

parent_dir="$(pwd)"
mkdir "$dir" && cd "$dir"
abs_dir="$parent_dir/$dir"
trap 'rm -rf "$abs_dir"' EXIT

# Bare clone
git clone -q --bare "$repo_url" .bare
echo "gitdir: ./.bare" > .git
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin

# Extract .env from repo
git show origin/main:.env.example > .env

# Symlink up.sh (will work once main/ worktree is created by up.sh)
# Create main worktree first so the symlink target exists
git worktree add main main
ln -s main/.ciya/scripts/up.sh up.sh

trap - EXIT

cat <<'MSG'

Welcome to ciya-dev!

Next steps:
  1. cd ciya-dev
  2. Edit .env with your tokens (GH_TOKEN is required)
  3. Run: ./up.sh <n>   (e.g., ./up.sh 4 for 4 work worktrees)

MSG
