#!/usr/bin/env bash
set -euo pipefail

# wc.sh — Welcome! One-time bootstrap for ciya-dev.
# Creates: ciya-dev/ with bare clone + .env + up.sh symlink
# Installs: kcov (from source, if not present)
#
# Usage: curl -fsSL <raw-url>/wc.sh | bash

CIYA_REPO_URL="${CIYA_REPO_URL:-https://github.com/lovaizu/ciya-dev.git}"
CIYA_DEFAULT_BRANCH="${CIYA_DEFAULT_BRANCH:-main}"

check_prerequisites() {
  local missing=()
  for cmd in git tmux gh claude; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: missing required commands: ${missing[*]}" >&2
    echo "Install them before running wc.sh." >&2
    exit 1
  fi
}

ensure_kcov() {
  if command -v kcov >/dev/null 2>&1; then
    return 0
  fi

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
  check_prerequisites

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

  # Symlink up.sh (will work once main/ worktree is created by up.sh)
  # Create main worktree first so the symlink target exists
  git worktree add main "$CIYA_DEFAULT_BRANCH"
  ln -s main/setup/up.sh up.sh

  # Install tools
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
