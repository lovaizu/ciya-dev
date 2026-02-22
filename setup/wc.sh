#!/usr/bin/env bash
set -euo pipefail

# wc.sh — Welcome! One-time bootstrap for ciya-dev.
# Creates: ciya-dev/ with bare clone + .env + up.sh symlink
# Installs: git, tmux, gh, claude, kcov (if not present)
#
# Usage: curl -fsSL <raw-url>/wc.sh | bash

CIYA_REPO_URL="${CIYA_REPO_URL:-https://github.com/lovaizu/ciya-dev.git}"
CIYA_DEFAULT_BRANCH="${CIYA_DEFAULT_BRANCH:-main}"

ensure_git() {
  command -v git >/dev/null 2>&1 && return 0
  echo "git not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y git
}

ensure_tmux() {
  command -v tmux >/dev/null 2>&1 && return 0
  echo "tmux not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y tmux
}

ensure_gh() {
  command -v gh >/dev/null 2>&1 && return 0
  echo "gh not found. Installing..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  local keyring
  keyring="$(mktemp)"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$keyring"
  sudo mv "$keyring" /etc/apt/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y gh
}

ensure_claude() {
  command -v claude >/dev/null 2>&1 && return 0
  echo "claude not found. Installing..."
  curl -fsSL https://claude.ai/install.sh | sh
}

ensure_kcov() {
  command -v kcov >/dev/null 2>&1 && return 0
  echo "kcov not found. Installing from source..."
  sudo apt-get update
  sudo apt-get install -y binutils-dev build-essential cmake libssl-dev \
    libcurl4-openssl-dev libelf-dev libstdc++-14-dev zlib1g-dev \
    libdw-dev libiberty-dev
  local build_dir
  build_dir="$(mktemp -d)"
  git clone https://github.com/SimonKagstrom/kcov.git "$build_dir/kcov"
  cmake -S "$build_dir/kcov" -B "$build_dir/kcov/build"
  make -C "$build_dir/kcov/build"
  sudo make -C "$build_dir/kcov/build" install
  rm -rf "$build_dir"
  if ! command -v kcov >/dev/null 2>&1; then
    echo "Error: kcov installation failed" >&2
    exit 1
  fi
  echo "kcov installed successfully."
}

main() {
  ensure_git

  # Derive directory name from repo URL (strip trailing .git and take basename)
  local dir
  dir="$(basename "${CIYA_REPO_URL%.git}")"

  if [ -d "$dir" ]; then
    echo "Error: directory '$dir' already exists" >&2
    exit 1
  fi

  local parent_dir abs_dir
  parent_dir="$(pwd)"
  mkdir "$dir" && cd "$dir"
  abs_dir="$parent_dir/$dir"
  trap 'rm -rf "$abs_dir"' EXIT

  # Bare clone
  git clone -q --bare "$CIYA_REPO_URL" .bare
  echo "gitdir: ./.bare" > .git
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch -q origin

  # Extract .env from repo
  git show "origin/$CIYA_DEFAULT_BRANCH:.env.example" > .env

  # Create main worktree first so the symlink target exists
  git worktree add main "$CIYA_DEFAULT_BRANCH"
  ln -s main/setup/up.sh up.sh

  # Install remaining tools
  ensure_tmux
  ensure_gh
  ensure_claude
  ensure_kcov

  trap - EXIT

  cat <<MSG

Welcome to $dir!

Next steps:
  1. cd $dir
  2. Edit .env with your tokens (GH_TOKEN is required)
  3. Run: ./up.sh <n>   (e.g., ./up.sh 4 for 4 work worktrees)

MSG
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
