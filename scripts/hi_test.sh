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

# Dummy claude command that optionally dumps its env for inspection
mkdir -p "$tmp/bin"
cat > "$tmp/bin/claude" <<'CLAUDE'
#!/bin/bash
if [ -n "${CLAUDE_TEST_ENV:-}" ]; then
  env > "$CLAUDE_TEST_ENV"
fi
exit 0
CLAUDE
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"

# --- Test: no arguments ---
echo "--- hi.sh: no arguments ---"
exit_code=0
bash "$tmp/ciya-dev/main/scripts/hi.sh" 2>/dev/null || exit_code=$?
check "exits non-zero without arguments" test "$exit_code" -ne 0

# --- Test: too many arguments ---
echo "--- hi.sh: too many arguments ---"
exit_code=0
bash "$tmp/ciya-dev/main/scripts/hi.sh" arg1 arg2 2>/dev/null || exit_code=$?
check "exits non-zero with two arguments" test "$exit_code" -ne 0

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

# --- Test: ALLOWED_DOMAINS_FILE default ---
echo "--- hi.sh: ALLOWED_DOMAINS_FILE default ---"
(cd "$tmp/ciya-dev" && git worktree add env-test -b env-test origin/main >/dev/null 2>&1)
CLAUDE_TEST_ENV="$tmp/claude_env_default" bash "$tmp/ciya-dev/main/scripts/hi.sh" env-test >/dev/null 2>&1
expected_adf="$tmp/ciya-dev/env-test/.claude/hooks/allowed-domains.txt"
if grep -q "^ALLOWED_DOMAINS_FILE=$expected_adf$" "$tmp/claude_env_default" 2>/dev/null; then
  pass "ALLOWED_DOMAINS_FILE set to default"
else
  fail "ALLOWED_DOMAINS_FILE set to default"
fi

# --- Test: ALLOWED_DOMAINS_FILE preserves existing value ---
echo "--- hi.sh: ALLOWED_DOMAINS_FILE override preserved ---"
ALLOWED_DOMAINS_FILE="/custom/path.txt" CLAUDE_TEST_ENV="$tmp/claude_env_override" \
  bash "$tmp/ciya-dev/main/scripts/hi.sh" env-test >/dev/null 2>&1
if grep -q "^ALLOWED_DOMAINS_FILE=/custom/path.txt$" "$tmp/claude_env_override" 2>/dev/null; then
  pass "ALLOWED_DOMAINS_FILE preserves existing value"
else
  fail "ALLOWED_DOMAINS_FILE preserves existing value"
fi

# --- Test: .env sourcing exports variables ---
echo "--- hi.sh: .env sourcing ---"
(cd "$tmp/ciya-dev" && git worktree add dotenv-test -b dotenv-test origin/main >/dev/null 2>&1)
echo "HI_TEST_CUSTOM_VAR=hello_from_dotenv" > "$tmp/ciya-dev/dotenv-test/.env"
CLAUDE_TEST_ENV="$tmp/claude_env_dotenv" bash "$tmp/ciya-dev/main/scripts/hi.sh" dotenv-test >/dev/null 2>&1
if grep -q "^HI_TEST_CUSTOM_VAR=hello_from_dotenv$" "$tmp/claude_env_dotenv" 2>/dev/null; then
  pass ".env variables exported to claude"
else
  fail ".env variables exported to claude"
fi
