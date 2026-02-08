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
  echo '#!/bin/bash' > scripts/hi.sh
  echo '#!/bin/bash' > scripts/bb.sh
  git add . >/dev/null 2>&1
  git commit -m "init" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1
)
rm -rf "$tmp/seed"

# Patch up.sh to use local remote instead of GitHub URL
sed "s|https://github.com/lovaizu/ciya-dev.git|$tmp/remote.git|" \
  "$SCRIPT_DIR/up.sh" > "$tmp/up_local.sh"

# --- Test: success path ---
echo "--- up.sh: creates bare repo structure ---"
(cd "$tmp" && bash "$tmp/up_local.sh" >/dev/null 2>&1)

check "ciya-dev directory created" test -d "$tmp/ciya-dev"
check ".bare directory created" test -d "$tmp/ciya-dev/.bare"
check ".git pointer file created" test -f "$tmp/ciya-dev/.git"
check "main worktree created" test -d "$tmp/ciya-dev/main"
check ".git contains gitdir pointer" grep -q "gitdir: ./.bare" "$tmp/ciya-dev/.git"

# --- Test: error path (directory already exists) ---
echo "--- up.sh: fails when directory already exists ---"
mkdir -p "$tmp/error_test"
mkdir "$tmp/error_test/ciya-dev"
exit_code=0
(cd "$tmp/error_test" && bash "$tmp/up_local.sh") 2>/dev/null || exit_code=$?
check "exits non-zero when ciya-dev exists" test "$exit_code" -ne 0
