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

# Mock gh to prevent real GitHub calls (return failure so completion check is skipped)
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$tmp/bin/gh"

# --- Test: refuses to remove main ---
echo "--- bb.sh: refuses to remove main ---"
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" main 2>/dev/null || exit_code=$?
check "exits non-zero for main" test "$exit_code" -ne 0
check "main worktree still exists" test -d "$tmp/ciya-dev/main"

# --- Test: no arguments ---
echo "--- bb.sh: no arguments ---"
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" 2>/dev/null || exit_code=$?
check "exits non-zero without arguments" test "$exit_code" -ne 0

# --- Test: too many arguments ---
echo "--- bb.sh: too many arguments ---"
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" arg1 arg2 2>/dev/null || exit_code=$?
check "exits non-zero with two arguments" test "$exit_code" -ne 0

# --- Test: removes worktree and branch ---
echo "--- bb.sh: removes worktree and branch ---"
(cd "$tmp/ciya-dev" && git worktree add test-branch -b test-branch origin/main >/dev/null 2>&1)
check "setup: worktree created" test -d "$tmp/ciya-dev/test-branch"

PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" test-branch >/dev/null 2>&1
check "worktree directory removed" test ! -d "$tmp/ciya-dev/test-branch"
if git -C "$tmp/ciya-dev/main" branch --list test-branch | grep -q test-branch 2>/dev/null; then
  fail "branch deleted"
else
  pass "branch deleted"
fi

# --- Test: extracts basename from path ---
echo "--- bb.sh: extracts basename from path ---"
(cd "$tmp/ciya-dev" && git worktree add path-branch -b path-branch origin/main >/dev/null 2>&1)
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" /some/path/path-branch >/dev/null 2>&1
check "worktree removed using basename" test ! -d "$tmp/ciya-dev/path-branch"

# --- Test: worktree already removed (should succeed) ---
echo "--- bb.sh: worktree already removed ---"
(cd "$tmp/ciya-dev" && git worktree add already-gone -b already-gone origin/main >/dev/null 2>&1)
# Manually remove the worktree directory to simulate "already removed"
rm -rf "$tmp/ciya-dev/already-gone"
git -C "$tmp/ciya-dev/main" worktree prune >/dev/null 2>&1
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" already-gone >/dev/null 2>&1 || exit_code=$?
check "succeeds when worktree already removed" test "$exit_code" -eq 0
# Branch should still be cleaned up
if git -C "$tmp/ciya-dev/main" branch --list already-gone | grep -q already-gone 2>/dev/null; then
  fail "branch deleted even when worktree was pre-removed"
else
  pass "branch deleted even when worktree was pre-removed"
fi

# --- Test: branch never pushed to remote ---
echo "--- bb.sh: branch never pushed to remote ---"
(cd "$tmp/ciya-dev" && git worktree add unpushed -b unpushed origin/main >/dev/null 2>&1)
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" unpushed >/dev/null 2>&1 || exit_code=$?
check "succeeds when branch was never pushed" test "$exit_code" -eq 0
check "worktree removed for unpushed branch" test ! -d "$tmp/ciya-dev/unpushed"

# --- Test: deletes remote branch when it exists ---
echo "--- bb.sh: deletes remote branch ---"
(
  cd "$tmp/ciya-dev"
  git worktree add remote-test -b remote-test origin/main >/dev/null 2>&1
  cd "$tmp/ciya-dev/remote-test"
  git -c user.name=test -c user.email=test@test.com commit --allow-empty -m "test" >/dev/null 2>&1
  git push origin remote-test >/dev/null 2>&1
)
# Verify remote branch exists before cleanup
check "setup: remote branch exists" git -C "$tmp/ciya-dev/main" ls-remote --heads origin remote-test
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" remote-test >/dev/null 2>&1
# Verify remote branch is gone
if git -C "$tmp/ciya-dev/main" ls-remote --heads origin remote-test 2>/dev/null | grep -q remote-test; then
  fail "remote branch deleted"
else
  pass "remote branch deleted"
fi

# --- Test: incomplete work — abort on "n" ---
echo "--- bb.sh: incomplete work abort ---"
(cd "$tmp/ciya-dev" && git worktree add abort-test -b abort-test origin/main >/dev/null 2>&1)
# Mock gh to report an open (not merged) PR
cat > "$tmp/bin/gh" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  *"pr list"*) echo '{"number":99,"state":"OPEN"}' ;;
  *"pr view"*"--json state"*) echo "OPEN" ;;
  *"pr view"*"--json number"*) echo "99" ;;
  *) exit 1 ;;
esac
MOCK
exit_code=0
echo "n" | PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" abort-test 2>/dev/null || exit_code=$?
check "exits zero on abort (user chose not to proceed)" test "$exit_code" -eq 0
check "worktree preserved on abort" test -d "$tmp/ciya-dev/abort-test"

# --- Test: incomplete work — proceed on "y" ---
echo "--- bb.sh: incomplete work proceed ---"
# Worktree still exists from abort test above
check "setup: worktree still exists" test -d "$tmp/ciya-dev/abort-test"
exit_code=0
echo "y" | PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" abort-test >/dev/null 2>&1 || exit_code=$?
check "succeeds when user confirms proceed" test "$exit_code" -eq 0
check "worktree removed after user confirms" test ! -d "$tmp/ciya-dev/abort-test"

# Reset mock gh to failure (skip completion checks)
cat > "$tmp/bin/gh" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK

# --- Test: nonexistent branch (never created) ---
echo "--- bb.sh: nonexistent branch ---"
exit_code=0
PATH="$tmp/bin:$PATH" bash "$tmp/ciya-dev/main/scripts/bb.sh" never-existed >/dev/null 2>&1 || exit_code=$?
check "succeeds for nonexistent branch (all steps skip)" test "$exit_code" -eq 0
