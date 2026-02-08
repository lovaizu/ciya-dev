#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
passed=0
failed=0

pass() { echo "PASS: $1"; passed=$((passed + 1)); }
fail() { echo "FAIL: $1"; failed=$((failed + 1)); }

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

tmp="$(mktemp -d)"
cleanup() {
  local rc=$?
  rm -rf "$tmp"
  echo ""
  echo "Results: $passed passed, $failed failed"
  if [ "$rc" -ne 0 ] || [ "$failed" -gt 0 ]; then
    exit 1
  fi
}
trap cleanup EXIT

# --- Setup: local remote repo with a main branch ---
git init --bare "$tmp/remote.git" >/dev/null 2>&1
git -C "$tmp/remote.git" symbolic-ref HEAD refs/heads/main
git clone "$tmp/remote.git" "$tmp/seed" >/dev/null 2>&1
(
  cd "$tmp/seed"
  git checkout -b main >/dev/null 2>&1
  mkdir -p scripts
  cp "$SCRIPT_DIR/hi.sh" scripts/hi.sh
  cp "$SCRIPT_DIR/bb.sh" scripts/bb.sh
  git add . >/dev/null 2>&1
  git commit -m "init" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
)
rm -rf "$tmp/seed"

# Set up ciya-dev bare repo + worktree structure
git clone --bare "$tmp/remote.git" "$tmp/ciya-dev/.bare" >/dev/null 2>&1
echo "gitdir: ./.bare" > "$tmp/ciya-dev/.git"
(
  cd "$tmp/ciya-dev"
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch origin >/dev/null 2>&1
  git worktree add main main >/dev/null 2>&1
)

# Dummy claude command to satisfy exec claude
mkdir -p "$tmp/bin"
printf '#!/bin/bash\nexit 0\n' > "$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"

# --- Test: no arguments ---
echo "--- hi.sh: no arguments ---"
exit_code=0
bash "$tmp/ciya-dev/main/scripts/hi.sh" 2>/dev/null || exit_code=$?
check "exits non-zero without arguments" test "$exit_code" -ne 0

# --- Test: creates new worktree ---
echo "--- hi.sh: creates new worktree ---"
bash "$tmp/ciya-dev/main/scripts/hi.sh" test-branch >/dev/null 2>&1
check "worktree directory created" test -d "$tmp/ciya-dev/test-branch"
check "branch is test-branch" test "$(git -C "$tmp/ciya-dev/test-branch" branch --show-current)" = "test-branch"

# --- Test: reuses existing worktree ---
echo "--- hi.sh: reuses existing worktree ---"
bash "$tmp/ciya-dev/main/scripts/hi.sh" test-branch >/dev/null 2>&1
check "worktree still exists after reuse" test -d "$tmp/ciya-dev/test-branch"

# --- Test: extracts basename from path ---
echo "--- hi.sh: extracts basename from path ---"
bash "$tmp/ciya-dev/main/scripts/hi.sh" /some/path/feature-x >/dev/null 2>&1
check "worktree created with basename" test -d "$tmp/ciya-dev/feature-x"
