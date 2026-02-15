#!/usr/bin/env bash
set -euo pipefail

# Test up.sh — worktree management (excluding tmux/CC launch)
# Sources the actual up.sh with REPO_ROOT pre-set and launch_tmux stubbed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UP_SH="$SCRIPT_DIR/up.sh"

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

setup_repo() {
  local testdir="$1"
  mkdir -p "$testdir"

  local staging="$tmpdir/staging-$$-$RANDOM"
  (
    mkdir "$staging" && cd "$staging"
    git init -q
    git checkout -q -b main

    mkdir -p scripts
    cat > scripts/up.sh <<'EOF'
#!/usr/bin/env bash
echo "placeholder"
EOF
    chmod +x scripts/up.sh

    cat > .env.example <<'EOF'
GH_TOKEN=github_pat_real_token
EOF

    git add -A
    git commit -q -m "initial"
  )

  (
    cd "$testdir"
    git clone -q --bare "$staging" .bare
    echo "gitdir: ./.bare" > .git
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch -q origin

    git worktree add main main 2>/dev/null

    cat > .env <<'EOF'
GH_TOKEN=ghp_realtoken123
EOF
  )

  rm -rf "$staging"
}

# Source up.sh functions and run worktree management in a subshell.
# Stubs launch_tmux, check_prerequisites, check_env.
run_up() {
  local repo_root="$1"
  local count="$2"

  (
    # Pre-set variables before sourcing up.sh
    export REPO_ROOT="$repo_root"
    export CONFIG_FILE="$repo_root/.up_config"
    export SESSION_NAME="ciya-test-$$"

    # Source the actual up.sh (BASH_SOURCE guard prevents main from running)
    source "$UP_SH"

    # Stub functions we can't run in tests
    launch_tmux() { :; }
    check_prerequisites() { :; }
    check_env() { :; }
    load_env() { :; }

    cd "$REPO_ROOT"
    local c
    c="$(get_worker_count "$count")"
    ensure_main_worktree
    ensure_work_worktrees "$c"
    remove_excess_worktrees "$c"
    echo "$c" > "$CONFIG_FILE"
  )
}

# --- Test 1: up.sh 4 creates work-1 through work-4 ---
test_creates_4_worktrees() {
  local testdir="$tmpdir/test1"
  setup_repo "$testdir"
  run_up "$testdir" 4
  [ -d "$testdir/work-1" ] &&
  [ -d "$testdir/work-2" ] &&
  [ -d "$testdir/work-3" ] &&
  [ -d "$testdir/work-4" ] &&
  [ ! -d "$testdir/work-5" ]
}
run_test "up.sh 4 creates work-1 through work-4" test_creates_4_worktrees

# --- Test 2: Config file stores worker count ---
test_stores_config() {
  [ -f "$tmpdir/test1/.up_config" ] &&
  [ "$(cat "$tmpdir/test1/.up_config")" = "4" ]
}
run_test "Config file stores worker count" test_stores_config

# --- Test 3: up.sh 6 adds work-5 and work-6 ---
test_adds_worktrees() {
  run_up "$tmpdir/test1" 6
  [ -d "$tmpdir/test1/work-5" ] &&
  [ -d "$tmpdir/test1/work-6" ] &&
  [ ! -d "$tmpdir/test1/work-7" ]
}
run_test "up.sh 6 adds work-5 and work-6" test_adds_worktrees

# --- Test 4: up.sh 2 removes work-3 through work-6 ---
test_removes_worktrees() {
  run_up "$tmpdir/test1" 2
  [ -d "$tmpdir/test1/work-1" ] &&
  [ -d "$tmpdir/test1/work-2" ] &&
  [ ! -d "$tmpdir/test1/work-3" ] &&
  [ ! -d "$tmpdir/test1/work-4" ] &&
  [ ! -d "$tmpdir/test1/work-5" ] &&
  [ ! -d "$tmpdir/test1/work-6" ]
}
run_test "up.sh 2 removes work-3 through work-6" test_removes_worktrees

# --- Test 5: Dirty worktree prevents removal ---
test_dirty_prevents_removal() {
  local testdir="$tmpdir/test5"
  setup_repo "$testdir"
  run_up "$testdir" 3

  echo "uncommitted" > "$testdir/work-2/dirty.txt"

  ! run_up "$testdir" 1 2>/dev/null
}
run_test "Dirty worktree prevents removal" test_dirty_prevents_removal

# --- Test 6: Invalid argument rejected ---
test_invalid_arg() {
  ! (
    export REPO_ROOT="$tmpdir/test1"
    export CONFIG_FILE="$tmpdir/test1/.up_config"
    source "$UP_SH"
    get_worker_count "abc"
  ) 2>/dev/null &&
  ! (
    export REPO_ROOT="$tmpdir/test1"
    export CONFIG_FILE="$tmpdir/test1/.up_config"
    source "$UP_SH"
    get_worker_count "0"
  ) 2>/dev/null &&
  ! (
    export REPO_ROOT="$tmpdir/test1"
    export CONFIG_FILE="$tmpdir/test1/.up_config"
    source "$UP_SH"
    get_worker_count "-1"
  ) 2>/dev/null
}
run_test "Invalid argument rejected" test_invalid_arg

# --- Test 7: No config and no argument defaults to 1 ---
test_no_config_no_arg_defaults() {
  local testdir="$tmpdir/test7"
  setup_repo "$testdir"
  [ ! -f "$testdir/.up_config" ] &&
  local result
  result="$(
    export REPO_ROOT="$testdir"
    export CONFIG_FILE="$testdir/.up_config"
    source "$UP_SH"
    get_worker_count ""
  )" &&
  [ "$result" = "1" ]
}
run_test "No config and no argument defaults to 1" test_no_config_no_arg_defaults

# --- Test 8: Config created after successful run ---
test_config_after_run() {
  local testdir="$tmpdir/test7"
  run_up "$testdir" 2
  [ -f "$testdir/.up_config" ] &&
  [ "$(cat "$testdir/.up_config")" = "2" ]
}
run_test "Config created after successful run" test_config_after_run

# --- Results ---
echo ""
echo "Results: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
