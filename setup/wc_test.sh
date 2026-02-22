#!/usr/bin/env bash
set -euo pipefail

# Test wc.sh — bootstrap script
# Sources the actual wc.sh and calls main() in subshells.
#
# Manual tests (cannot be automated):
# - curl -fsSL <raw-url>/wc.sh | bash (real remote bootstrap)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WC_SH="$SCRIPT_DIR/wc.sh"

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

# Temp directory + cleanup
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- Setup: create a local bare repo to act as the remote ---
staging="$tmp/staging-$$-$RANDOM"
mkdir "$staging"
(
  cd "$staging"
  git init -q
  git checkout -q -b main

  cat > .env.example <<'EOF'
GH_TOKEN=github_pat_xxxxx
EOF

  mkdir -p setup
  cat > setup/up.sh <<'UPEOF'
#!/usr/bin/env bash
echo "up.sh placeholder"
UPEOF
  chmod +x setup/up.sh

  git add -A
  git commit -q -m "initial"
)

fake_remote="$tmp/ciya-dev.git"
git clone -q --bare "$staging" "$fake_remote"

# Helper: run wc.sh main() in a subshell with env var override.
# Stubs ensure_* functions for integration tests.
run_wc() {
  local workdir="$1"
  local repo_url="${2:-$fake_remote}"
  (
    cd "$workdir"
    export CIYA_REPO_URL="$repo_url"
    source "$WC_SH"
    ensure_git() { :; }
    ensure_tmux() { :; }
    ensure_gh() { :; }
    ensure_claude() { :; }
    ensure_kcov() { :; }
    main
  )
}

# ── Happy path ────────────────────────────────────────────────
echo "happy path:"

# Given: an empty working directory
workdir="$tmp/test_happy"
mkdir "$workdir"

# When: running wc.sh
run_wc "$workdir" >/dev/null

# Then: ciya-dev/ directory is created with expected structure
assert_eq "ciya-dev/ directory created" "true" "$([ -d "$workdir/ciya-dev" ] && echo true || echo false)"
assert_eq ".bare/ contains bare clone" "true" "$([ -f "$workdir/ciya-dev/.bare/HEAD" ] && echo true || echo false)"
assert_eq "main/ worktree exists" "true" "$([ -d "$workdir/ciya-dev/main" ] && echo true || echo false)"
assert_eq ".env extracted from .env.example" "true" "$(grep -q GH_TOKEN "$workdir/ciya-dev/.env" && echo true || echo false)"
assert_eq "up.sh is symlink" "main/setup/up.sh" "$(readlink "$workdir/ciya-dev/up.sh")"

# ── Directory already exists ──────────────────────────────────
echo "directory already exists:"

# Given: a directory where ciya-dev/ already exists
workdir="$tmp/test_exists"
mkdir -p "$workdir/ciya-dev"

# When: running wc.sh
# Then: exits with non-zero and error message (exit 1 is explicit, not relying on set -e)
actual_msg="$(run_wc "$workdir" 2>&1 || true)"
assert_eq "exits with error" "true" "$(echo "$actual_msg" | grep -q "already exists" && echo true || echo false)"

# ── Cleanup on failure (trap) ─────────────────────────────────
echo "cleanup on failure:"

# Given: a remote repo without .env.example (will cause git show failure)
bad_staging="$tmp/bad_staging-$$-$RANDOM"
mkdir "$bad_staging"
(
  cd "$bad_staging"
  git init -q
  git checkout -q -b main
  echo "dummy" > README.md
  git add -A
  git commit -q -m "no env"
)
bad_remote="$tmp/ciya-dev-bad.git"
git clone -q --bare "$bad_staging" "$bad_remote"

workdir="$tmp/test_cleanup"
mkdir "$workdir"

# When: wc.sh fails because .env.example doesn't exist
# Note: run as child process (not sourced) so set -e works correctly for trap testing
CIYA_REPO_URL="$bad_remote" bash "$WC_SH" 2>/dev/null || true

# Then: ciya-dev-bad/ is cleaned up by trap
assert_eq "directory removed by trap" "false" "$([ -d "$workdir/ciya-dev-bad" ] && echo true || echo false)"

# ── ensure_git ────────────────────────────────────────────────
echo "ensure_git:"

# Given: git is already installed
fake_bin_git="$tmp/fake_bin_git"
mkdir -p "$fake_bin_git"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_git/git"
chmod +x "$fake_bin_git/git"
(
  source "$WC_SH"
  PATH="$fake_bin_git"
  ensure_git
)
assert_eq "skips when git installed" "0" "$?"

# Given: git is NOT installed
fake_bin_no_git="$tmp/fake_bin_no_git"
mkdir -p "$fake_bin_no_git"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_git/sudo"
chmod +x "$fake_bin_no_git/sudo"
output="$(
  source "$WC_SH"
  PATH="$fake_bin_no_git"
  ensure_git 2>&1
)"
assert_contains "installs git when missing" "git not found" "$output"

# ── ensure_tmux ───────────────────────────────────────────────
echo "ensure_tmux:"

# Given: tmux is already installed
fake_bin_tmux="$tmp/fake_bin_tmux"
mkdir -p "$fake_bin_tmux"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_tmux/tmux"
chmod +x "$fake_bin_tmux/tmux"
(
  source "$WC_SH"
  PATH="$fake_bin_tmux"
  ensure_tmux
)
assert_eq "skips when tmux installed" "0" "$?"

# Given: tmux is NOT installed
fake_bin_no_tmux="$tmp/fake_bin_no_tmux"
mkdir -p "$fake_bin_no_tmux"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_tmux/sudo"
chmod +x "$fake_bin_no_tmux/sudo"
output="$(
  source "$WC_SH"
  PATH="$fake_bin_no_tmux"
  ensure_tmux 2>&1
)"
assert_contains "installs tmux when missing" "tmux not found" "$output"

# ── ensure_gh ─────────────────────────────────────────────────
echo "ensure_gh:"

# Given: gh is already installed
fake_bin_gh="$tmp/fake_bin_gh"
mkdir -p "$fake_bin_gh"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_gh/gh"
chmod +x "$fake_bin_gh/gh"
(
  source "$WC_SH"
  PATH="$fake_bin_gh"
  ensure_gh
)
assert_eq "skips when gh installed" "0" "$?"

# Given: gh is NOT installed
fake_bin_no_gh="$tmp/fake_bin_no_gh_ensure"
mkdir -p "$fake_bin_no_gh"
# Mock sudo: consume stdin when called with tee to avoid SIGPIPE
cat > "$fake_bin_no_gh/sudo" << 'MOCKEOF'
#!/bin/bash
if [[ "$1" == "tee" ]]; then
  while IFS= read -r _; do :; done
fi
exit 0
MOCKEOF
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_gh/curl"
printf '#!/bin/sh\necho "amd64"\n' > "$fake_bin_no_gh/dpkg"
gh_keyring_tmp="$tmp/gh_keyring_tmp"
touch "$gh_keyring_tmp"
cat > "$fake_bin_no_gh/mktemp" << MOCKEOF
#!/bin/sh
echo "$gh_keyring_tmp"
MOCKEOF
chmod +x "$fake_bin_no_gh/sudo" "$fake_bin_no_gh/curl" "$fake_bin_no_gh/dpkg" "$fake_bin_no_gh/mktemp"
output="$(
  source "$WC_SH"
  PATH="$fake_bin_no_gh"
  ensure_gh 2>&1
)"
assert_contains "installs gh when missing" "gh not found" "$output"

# ── ensure_claude ─────────────────────────────────────────────
echo "ensure_claude:"

# Given: claude is already installed
fake_bin_claude="$tmp/fake_bin_claude"
mkdir -p "$fake_bin_claude"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_claude/claude"
chmod +x "$fake_bin_claude/claude"
(
  source "$WC_SH"
  PATH="$fake_bin_claude"
  ensure_claude
)
assert_eq "skips when claude installed" "0" "$?"

# Given: claude is NOT installed
fake_bin_no_claude="$tmp/fake_bin_no_claude"
mkdir -p "$fake_bin_no_claude"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_claude/curl"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_claude/sh"
chmod +x "$fake_bin_no_claude/curl" "$fake_bin_no_claude/sh"
output="$(
  source "$WC_SH"
  PATH="$fake_bin_no_claude"
  ensure_claude 2>&1
)"
assert_contains "installs claude when missing" "claude not found" "$output"

# ── ensure_kcov ───────────────────────────────────────────────
echo "ensure_kcov:"

# Given: kcov is already installed
fake_bin_kcov="$tmp/fake_bin_kcov"
mkdir -p "$fake_bin_kcov"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_kcov/kcov"
chmod +x "$fake_bin_kcov/kcov"
(
  source "$WC_SH"
  PATH="$fake_bin_kcov"
  ensure_kcov
)
assert_eq "skips when kcov installed" "0" "$?"

# Given: kcov is NOT installed, mock installation succeeds
fake_bin_no_kcov="$tmp/fake_bin_no_kcov"
mkdir -p "$fake_bin_no_kcov"
# Mock sudo: creates kcov stub on "make install"
cat > "$fake_bin_no_kcov/sudo" << MOCKEOF
#!/bin/bash
if [[ "\$*" == *"make"*"install"* ]]; then
  printf '#!/bin/sh\\ntrue\\n' > "$fake_bin_no_kcov/kcov"
  chmod +x "$fake_bin_no_kcov/kcov"
fi
MOCKEOF
chmod +x "$fake_bin_no_kcov/sudo"
# Mock git clone: create target directory
cat > "$fake_bin_no_kcov/git" << 'MOCKEOF'
#!/bin/bash
[[ "$1" == "clone" ]] && mkdir -p "$3"
exit 0
MOCKEOF
chmod +x "$fake_bin_no_kcov/git"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_kcov/cmake"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_kcov/make"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_no_kcov/rm"
chmod +x "$fake_bin_no_kcov/cmake" "$fake_bin_no_kcov/make" "$fake_bin_no_kcov/rm"
build_tmp="$tmp/kcov_build"
mkdir -p "$build_tmp"
cat > "$fake_bin_no_kcov/mktemp" << MOCKEOF
#!/bin/bash
echo "$build_tmp"
MOCKEOF
chmod +x "$fake_bin_no_kcov/mktemp"

output="$(
  source "$WC_SH"
  PATH="$fake_bin_no_kcov:/usr/bin:/bin"
  ensure_kcov 2>&1
)"
assert_contains "installs when missing" "Installing from source" "$output"
assert_contains "reports success" "installed successfully" "$output"

# Given: kcov NOT installed and installation fails (no kcov stub created)
fake_bin_fail="$tmp/fake_bin_fail_kcov"
mkdir -p "$fake_bin_fail"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_fail/sudo"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_fail/cmake"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_fail/make"
printf '#!/bin/sh\ntrue\n' > "$fake_bin_fail/rm"
chmod +x "$fake_bin_fail/sudo" "$fake_bin_fail/cmake" "$fake_bin_fail/make" "$fake_bin_fail/rm"
cat > "$fake_bin_fail/git" << 'MOCKEOF'
#!/bin/bash
[[ "$1" == "clone" ]] && mkdir -p "$3"
exit 0
MOCKEOF
chmod +x "$fake_bin_fail/git"
build_tmp2="$tmp/kcov_build2"
mkdir -p "$build_tmp2"
cat > "$fake_bin_fail/mktemp" << MOCKEOF
#!/bin/bash
echo "$build_tmp2"
MOCKEOF
chmod +x "$fake_bin_fail/mktemp"
actual_exit=0
(
  source "$WC_SH"
  PATH="$fake_bin_fail:/usr/bin:/bin"
  ensure_kcov
) 2>/dev/null || actual_exit=$?
assert_eq "exits 1 when install fails" "1" "$actual_exit"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "Results: $passed passed, $failed failed"
[[ $failed -gt 0 ]] && exit 1
exit 0
