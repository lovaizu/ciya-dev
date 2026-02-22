#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
passed=0
failed=0

pass() { echo "PASS: $1"; passed=$((passed + 1)); }
fail() { echo "FAIL: $1 (expected: $2, actual: $3)"; failed=$((failed + 1)); }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass "$desc"; else fail "$desc" "$expected" "$actual"; fi
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

# Setup: git repo with known branch for consistent output
git init "$tmp/feature-branch" >/dev/null 2>&1
git -C "$tmp/feature-branch" checkout -b test-main >/dev/null 2>&1
git -C "$tmp/feature-branch" -c user.name=test -c user.email=test@test.com commit --allow-empty -m "init" >/dev/null 2>&1

# --- Test: normal input with all fields ---
echo "--- statusline.sh: normal input ---"
# Given: JSON input with all fields populated
input="{\"workspace\":{\"current_dir\":\"$tmp/feature-branch\"},\"model\":{\"display_name\":\"Opus\"},\"context_window\":{\"total_input_tokens\":12500,\"total_output_tokens\":3500,\"used_percentage\":45.7},\"cost\":{\"total_cost_usd\":1.23}}"
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: all fields are formatted correctly
expected="feature-branch (test-main) [Opus] [in:13k out:4k] [\$1.2] [ctx:45%]"
assert_eq "formats all fields correctly" "$expected" "$actual"

# --- Test: zero tokens ---
echo "--- statusline.sh: zero tokens ---"
# Given: JSON input with all values at zero
input="{\"workspace\":{\"current_dir\":\"$tmp/feature-branch\"},\"model\":{\"display_name\":\"Sonnet\"},\"context_window\":{\"total_input_tokens\":0,\"total_output_tokens\":0,\"used_percentage\":0},\"cost\":{\"total_cost_usd\":0}}"
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: zero values are displayed correctly
expected="feature-branch (test-main) [Sonnet] [in:0k out:0k] [\$0.0] [ctx:0%]"
assert_eq "handles zero values" "$expected" "$actual"

# --- Test: large token counts round correctly ---
echo "--- statusline.sh: rounding ---"
# Given: JSON input with large token counts near rounding boundaries
input="{\"workspace\":{\"current_dir\":\"$tmp/feature-branch\"},\"model\":{\"display_name\":\"Haiku\"},\"context_window\":{\"total_input_tokens\":999499,\"total_output_tokens\":500,\"used_percentage\":99.9},\"cost\":{\"total_cost_usd\":0.05}}"
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: values are rounded correctly
expected="feature-branch (test-main) [Haiku] [in:999k out:1k] [\$0.1] [ctx:99%]"
assert_eq "rounds token counts and truncates ctx percentage" "$expected" "$actual"

# --- Test: missing optional fields use defaults ---
echo "--- statusline.sh: missing fields ---"
# Given: JSON input with empty objects (no fields)
input='{"workspace":{},"model":{},"context_window":{},"cost":{}}'
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: defaults are used for missing fields
expected=" () [Unknown] [in:0k out:0k] [\$0.0] [ctx:0%]"
assert_eq "uses defaults for missing fields" "$expected" "$actual"

# --- Test: not in a git repo (branch is empty) ---
echo "--- statusline.sh: not in git repo ---"
# Given: workspace pointing to a directory that is not a git repo
mkdir -p "$tmp/not-a-repo"
input="{\"workspace\":{\"current_dir\":\"$tmp/not-a-repo\"},\"model\":{\"display_name\":\"Opus\"},\"context_window\":{\"total_input_tokens\":1000,\"total_output_tokens\":500,\"used_percentage\":10},\"cost\":{\"total_cost_usd\":0.5}}"
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: branch is empty
expected="not-a-repo () [Opus] [in:1k out:1k] [\$0.5] [ctx:10%]"
assert_eq "branch is empty outside git repo" "$expected" "$actual"

# --- Test: integer ctx percentage (no decimal point) ---
echo "--- statusline.sh: integer ctx percentage ---"
# Given: JSON input with integer percentage (no decimal)
input="{\"workspace\":{\"current_dir\":\"$tmp/feature-branch\"},\"model\":{\"display_name\":\"Opus\"},\"context_window\":{\"total_input_tokens\":5000,\"total_output_tokens\":2000,\"used_percentage\":100},\"cost\":{\"total_cost_usd\":3}}"
# When: running statusline.sh
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: integer percentage is handled correctly
expected="feature-branch (test-main) [Opus] [in:5k out:2k] [\$3.0] [ctx:100%]"
assert_eq "handles integer ctx percentage" "$expected" "$actual"

# --- Test: git branch uses workspace dir, not CWD ---
echo "--- statusline.sh: uses workspace dir for git branch ---"
# Given: CWD is a different repo than the workspace dir
git init "$tmp/other-repo" >/dev/null 2>&1
git -C "$tmp/other-repo" checkout -b other-branch >/dev/null 2>&1
git -C "$tmp/other-repo" -c user.name=test -c user.email=test@test.com commit --allow-empty -m "init" >/dev/null 2>&1
input="{\"workspace\":{\"current_dir\":\"$tmp/feature-branch\"},\"model\":{\"display_name\":\"Opus\"},\"context_window\":{\"total_input_tokens\":1000,\"total_output_tokens\":500,\"used_percentage\":10},\"cost\":{\"total_cost_usd\":0.5}}"
# When: running statusline.sh from the other repo's CWD
actual=$(cd "$tmp/other-repo" && echo "$input" | bash "$SCRIPT_DIR/statusline.sh")
# Then: branch comes from workspace dir, not CWD
expected="feature-branch (test-main) [Opus] [in:1k out:1k] [\$0.5] [ctx:10%]"
assert_eq "branch from workspace dir, not CWD" "$expected" "$actual"
