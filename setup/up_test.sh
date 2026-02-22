#!/usr/bin/env bash
set -euo pipefail

# Test up.sh — worktree management (excluding tmux/CC launch)
# Sources the actual up.sh with REPO_ROOT pre-set and launch_tmux stubbed.
#
# Manual tests (cannot be automated):
# - launch_tmux: tmux session creation, pane layout, CC startup
# - Init block (REPO_ROOT auto-detect): run ./up.sh directly in bare repo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UP_SH="$SCRIPT_DIR/up.sh"

passed=0
failed=0

assert_eq() {
  local test_name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $test_name"
    ((++passed))
  else
    echo "  FAIL: $test_name"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((++failed))
  fi
}

assert_contains() {
  local test_name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $test_name"
    ((++passed))
  else
    echo "  FAIL: $test_name"
    echo "    expected to contain: $needle"
    echo "    actual:              $haystack"
    ((++failed))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

setup_repo() {
  local testdir="$1"
  mkdir -p "$testdir"

  local staging="$tmp/staging-$$-$RANDOM"
  (
    mkdir "$staging" && cd "$staging"
    git init -q
    git checkout -q -b main

    mkdir -p setup
    cat > setup/up.sh <<'EOF'
#!/usr/bin/env bash
echo "placeholder"
EOF
    chmod +x setup/up.sh

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

    # Point remote to local .bare so fetches always work after staging is deleted
    git config remote.origin.url "$testdir/.bare"

    git worktree add main main 2>/dev/null

    cat > .env <<'EOF'
GH_TOKEN=ghp_realtoken123
EOF
  )

  rm -rf "$staging"
}

# Source up.sh functions and run worktree management in a subshell.
# Stubs launch_tmux, check_env.
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

# ── Worktree management ──────────────────────────────────────
echo "worktree management:"

# Given: a fresh bare repo
testdir_wt="$tmp/test_wt"
setup_repo "$testdir_wt"

# When: running up.sh with count 4
run_up "$testdir_wt" 4

# Then: work-1 through work-4 exist
assert_eq "up 4 creates work-1..4" "true" "$([ -d "$testdir_wt/work-1" ] && [ -d "$testdir_wt/work-4" ] && [ ! -d "$testdir_wt/work-5" ] && echo true || echo false)"
assert_eq "config stores 4" "4" "$(cat "$testdir_wt/.up_config")"

# When: scaling up to 6
run_up "$testdir_wt" 6
assert_eq "up 6 adds work-5..6" "true" "$([ -d "$testdir_wt/work-5" ] && [ -d "$testdir_wt/work-6" ] && echo true || echo false)"

# When: scaling down to 2
run_up "$testdir_wt" 2
assert_eq "up 2 removes work-3..6" "true" "$([ -d "$testdir_wt/work-1" ] && [ -d "$testdir_wt/work-2" ] && [ ! -d "$testdir_wt/work-3" ] && echo true || echo false)"

# ── Dirty worktree prevents removal ──────────────────────────
echo "dirty worktree:"

# Given: a repo with 3 worktrees and an uncommitted file in work-2
testdir_dirty="$tmp/test_dirty"
setup_repo "$testdir_dirty"
run_up "$testdir_dirty" 3
echo "uncommitted" > "$testdir_dirty/work-2/dirty.txt"

# When: trying to reduce to 1 worktree
# Then: fails because work-2 is dirty
actual_exit=0
run_up "$testdir_dirty" 1 2>/dev/null || actual_exit=$?
assert_eq "dirty worktree prevents removal" "1" "$actual_exit"

# ── get_worker_count ──────────────────────────────────────────
echo "get_worker_count:"

# Given: invalid arguments
for bad_arg in "abc" "0" "-1"; do
  actual_exit=0
  (
    export REPO_ROOT="$testdir_wt"
    export CONFIG_FILE="$testdir_wt/.up_config"
    source "$UP_SH"
    get_worker_count "$bad_arg"
  ) 2>/dev/null || actual_exit=$?
  assert_eq "rejects '$bad_arg'" "1" "$actual_exit"
done

# Given: no config file and CIYA_WORK_COUNT unset
testdir_noconf="$tmp/test_noconf"
setup_repo "$testdir_noconf"
result="$(
  export REPO_ROOT="$testdir_noconf"
  export CONFIG_FILE="$testdir_noconf/.up_config"
  unset CIYA_WORK_COUNT
  source "$UP_SH"
  get_worker_count ""
)"
assert_eq "no config, no env → defaults to 1" "1" "$result"

# Given: CIYA_WORK_COUNT=5 and no config
result="$(
  export REPO_ROOT="$testdir_noconf"
  export CONFIG_FILE="$testdir_noconf/.up_config"
  export CIYA_WORK_COUNT=5
  source "$UP_SH"
  get_worker_count ""
)"
assert_eq "CIYA_WORK_COUNT overrides default" "5" "$result"

# Given: a config file exists
run_up "$testdir_noconf" 3
result="$(
  export REPO_ROOT="$testdir_noconf"
  export CONFIG_FILE="$testdir_noconf/.up_config"
  source "$UP_SH"
  get_worker_count ""
)"
assert_eq "reads count from config file" "3" "$result"

# ── check_env ─────────────────────────────────────────────────
echo "check_env:"

# Given: no .env file
testdir_noenv="$tmp/test_noenv"
setup_repo "$testdir_noenv"
rm -f "$testdir_noenv/.env"
actual_exit=0
(
  export REPO_ROOT="$testdir_noenv"
  source "$UP_SH"
  check_env
) 2>/dev/null || actual_exit=$?
assert_eq "missing .env exits 1" "1" "$actual_exit"

# Given: .env with placeholder tokens
echo "GH_TOKEN=github_pat_xxxxx" > "$testdir_noenv/.env"
actual_exit=0
(
  export REPO_ROOT="$testdir_noenv"
  source "$UP_SH"
  check_env
) 2>/dev/null || actual_exit=$?
assert_eq "placeholder .env exits 1" "1" "$actual_exit"

# Given: .env with real tokens
echo "GH_TOKEN=ghp_realtoken123" > "$testdir_noenv/.env"
(
  export REPO_ROOT="$testdir_noenv"
  source "$UP_SH"
  check_env
)
assert_eq "valid .env passes" "0" "$?"

# ── load_env ──────────────────────────────────────────────────
echo "load_env:"

# Given: .env with a custom variable
cat > "$testdir_noenv/.env" << 'EOF'
MY_TEST_VAR=hello_from_env
EOF
result="$(
  export REPO_ROOT="$testdir_noenv"
  source "$UP_SH"
  load_env
  echo "$MY_TEST_VAR"
)"
assert_eq "load_env sources .env" "hello_from_env" "$result"

# Given: no .env file
rm -f "$testdir_noenv/.env"
(
  export REPO_ROOT="$testdir_noenv"
  source "$UP_SH"
  load_env
)
assert_eq "load_env without .env succeeds" "0" "$?"

# ── usage ─────────────────────────────────────────────────────
echo "usage:"

output="$(
  export REPO_ROOT="$testdir_wt"
  source "$UP_SH"
  usage
)"
assert_contains "usage shows help" "Usage: up.sh" "$output"

# ── ensure_main_worktree ─────────────────────────────────────
echo "ensure_main_worktree:"

# Given: a repo WITHOUT main worktree
testdir_nomain="$tmp/test_nomain"
setup_repo "$testdir_nomain"
# Remove the main worktree that setup_repo created
git -C "$testdir_nomain" worktree remove main 2>/dev/null || true

# When: ensure_main_worktree runs
output="$(
  export REPO_ROOT="$testdir_nomain"
  source "$UP_SH"
  ensure_main_worktree 2>&1
)"

# Then: main worktree is created
assert_eq "creates main worktree" "true" "$([ -d "$testdir_nomain/main" ] && echo true || echo false)"
assert_contains "logs creation" "Creating main worktree" "$output"

# ── main() with stubs ────────────────────────────────────────
echo "main():"

# Given: a valid repo
testdir_main="$tmp/test_main"
setup_repo "$testdir_main"

# When: calling main() with stubs
(
  export REPO_ROOT="$testdir_main"
  export CONFIG_FILE="$testdir_main/.up_config"
  export SESSION_NAME="ciya-test-$$"
  source "$UP_SH"
  launch_tmux() { :; }
  check_env() { :; }
  load_env() { :; }
  main 2
)
assert_eq "main creates worktrees" "true" "$([ -d "$testdir_main/work-1" ] && [ -d "$testdir_main/work-2" ] && echo true || echo false)"
assert_eq "main saves config" "2" "$(cat "$testdir_main/.up_config")"

# When: calling main with -h
output="$(
  export REPO_ROOT="$testdir_main"
  source "$UP_SH"
  main -h
)" || true
assert_contains "main -h shows usage" "Usage: up.sh" "$output"

# When: calling main with --help
output="$(
  export REPO_ROOT="$testdir_main"
  source "$UP_SH"
  main --help
)" || true
assert_contains "main --help shows usage" "Usage: up.sh" "$output"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "Results: $passed passed, $failed failed"
[[ $failed -gt 0 ]] && exit 1
exit 0
