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
  cp "$SCRIPT_DIR/bb.sh" scripts/bb.sh
  cp "$SCRIPT_DIR/hi.sh" scripts/hi.sh
  git add . >/dev/null 2>&1
  git -c user.name=test -c user.email=test@test.com commit -m "init" >/dev/null 2>&1
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

# --- Test: no arguments ---
echo "--- bb.sh: no arguments ---"
exit_code=0
bash "$tmp/ciya-dev/main/scripts/bb.sh" 2>/dev/null || exit_code=$?
check "exits non-zero without arguments" test "$exit_code" -ne 0

# --- Test: too many arguments ---
echo "--- bb.sh: too many arguments ---"
exit_code=0
bash "$tmp/ciya-dev/main/scripts/bb.sh" arg1 arg2 2>/dev/null || exit_code=$?
check "exits non-zero with two arguments" test "$exit_code" -ne 0

# --- Test: removes worktree and branch ---
echo "--- bb.sh: removes worktree and branch ---"
(cd "$tmp/ciya-dev" && git worktree add test-branch -b test-branch origin/main >/dev/null 2>&1)
check "setup: worktree created" test -d "$tmp/ciya-dev/test-branch"

bash "$tmp/ciya-dev/main/scripts/bb.sh" test-branch >/dev/null 2>&1
check "worktree directory removed" test ! -d "$tmp/ciya-dev/test-branch"
if git -C "$tmp/ciya-dev/main" branch --list test-branch | grep -q test-branch 2>/dev/null; then
  fail "branch deleted"
else
  pass "branch deleted"
fi

# --- Test: extracts basename from path ---
echo "--- bb.sh: extracts basename from path ---"
(cd "$tmp/ciya-dev" && git worktree add path-branch -b path-branch origin/main >/dev/null 2>&1)
bash "$tmp/ciya-dev/main/scripts/bb.sh" /some/path/path-branch >/dev/null 2>&1
check "worktree removed using basename" test ! -d "$tmp/ciya-dev/path-branch"
