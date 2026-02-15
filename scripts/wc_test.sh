#!/usr/bin/env bash
set -euo pipefail

# Test wc.sh — bootstrap script
# Tests run the actual wc.sh with repo_url overridden via sed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WC_SH="$SCRIPT_DIR/wc.sh"

passed=0
failed=0

run_test() {
  local name="$1"
  shift
  if "$@"; then
    echo "PASS: $name"
    passed=$((passed + 1))
  else
    echo "FAIL: $name"
    failed=$((failed + 1))
  fi
}

# --- Setup: create a local bare repo to act as the remote ---
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Create a fake remote repo with the files wc.sh expects
fake_remote="$tmpdir/ciya-dev.git"
staging="$tmpdir/staging"
mkdir "$staging"
(
  cd "$staging"
  git init -q
  git checkout -q -b main

  cat > .env.example <<'EOF'
GH_TOKEN=github_pat_xxxxx
EOF

  mkdir -p scripts
  cat > scripts/up.sh <<'UPEOF'
#!/usr/bin/env bash
echo "up.sh placeholder"
UPEOF
  chmod +x scripts/up.sh

  git add -A
  git commit -q -m "initial"
)

git clone -q --bare "$staging" "$fake_remote"

# Create a patched copy of wc.sh that uses our fake remote
patched_wc="$tmpdir/wc.sh"
sed "s|CIYA_REPO_URL=\"\${CIYA_REPO_URL:-.*}\"|CIYA_REPO_URL=\"$fake_remote\"|" "$WC_SH" > "$patched_wc"
chmod +x "$patched_wc"

# --- Helper: run the patched wc.sh in a given directory ---
run_wc() {
  local workdir="$1"
  (cd "$workdir" && bash "$patched_wc")
}

# --- Test 1: Creates ciya-dev/ directory ---
test_creates_directory() {
  local workdir="$tmpdir/test1"
  mkdir "$workdir"
  run_wc "$workdir"
  [ -d "$workdir/ciya-dev" ]
}
run_test "Creates ciya-dev/ directory" test_creates_directory

# --- Test 2: .bare/ contains bare clone ---
test_bare_clone() {
  [ -f "$tmpdir/test1/ciya-dev/.bare/HEAD" ]
}
run_test ".bare/ contains bare clone" test_bare_clone

# --- Test 3: main/ worktree exists ---
test_main_worktree() {
  [ -d "$tmpdir/test1/ciya-dev/main" ] &&
  [ -f "$tmpdir/test1/ciya-dev/main/.env.example" ]
}
run_test "main/ worktree exists" test_main_worktree

# --- Test 4: .env is extracted ---
test_env_extracted() {
  [ -f "$tmpdir/test1/ciya-dev/.env" ] &&
  grep -q "GH_TOKEN" "$tmpdir/test1/ciya-dev/.env"
}
run_test ".env is extracted from .env.example" test_env_extracted

# --- Test 5: up.sh is a symlink to main/scripts/up.sh ---
test_upsh_symlink() {
  [ -L "$tmpdir/test1/ciya-dev/up.sh" ] &&
  [ "$(readlink "$tmpdir/test1/ciya-dev/up.sh")" = "main/scripts/up.sh" ]
}
run_test "up.sh is symlink to main/scripts/up.sh" test_upsh_symlink

# --- Test 6: Errors if ciya-dev/ already exists ---
test_error_if_exists() {
  local workdir="$tmpdir/test6"
  mkdir -p "$workdir/ciya-dev"
  ! run_wc "$workdir" 2>/dev/null
}
run_test "Errors if ciya-dev/ already exists" test_error_if_exists

# --- Test 7: Cleanup on failure (trap) ---
test_cleanup_on_failure() {
  # Create a patched wc.sh that fails after mkdir (remove .env.example from remote)
  local bad_remote="$tmpdir/bad_remote.git"
  local bad_staging="$tmpdir/bad_staging"
  mkdir "$bad_staging"
  (
    cd "$bad_staging"
    git init -q
    git checkout -q -b main
    # No .env.example → git show will fail
    echo "dummy" > README.md
    git add -A
    git commit -q -m "no env"
  )
  git clone -q --bare "$bad_staging" "$bad_remote"

  local bad_wc="$tmpdir/bad_wc.sh"
  sed "s|CIYA_REPO_URL=\"\${CIYA_REPO_URL:-.*}\"|CIYA_REPO_URL=\"$bad_remote\"|" "$WC_SH" > "$bad_wc"
  chmod +x "$bad_wc"

  local workdir="$tmpdir/test7"
  mkdir "$workdir"
  # Should fail because .env.example doesn't exist
  ! (cd "$workdir" && bash "$bad_wc") 2>/dev/null
  # ciya-dev/ should be cleaned up by trap
  [ ! -d "$workdir/ciya-dev" ]
}
run_test "Cleanup on failure (trap removes ciya-dev/)" test_cleanup_on_failure

# --- Results ---
echo ""
echo "Results: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
