#!/usr/bin/env bash
# Tests for validate.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
TMPDIR_ROOT=$(mktemp -d)

cleanup() { rm -rf "$TMPDIR_ROOT"; }
trap cleanup EXIT

passed=0
failed=0

assert_grade() {
  local test_name=$1 expected_grade=$2 skill_dir=$3
  local output grade
  output=$(bash "$VALIDATE" "$skill_dir" 2>/dev/null) || true
  grade=$(echo "$output" | grep -o '"grade": *"[^"]*"' | sed 's/.*"grade": *"//;s/"//')
  if [[ "$grade" == "$expected_grade" ]]; then
    echo "PASS: $test_name (got $grade)"
    passed=$((passed + 1))
  else
    echo "FAIL: $test_name — expected $expected_grade, got $grade"
    failed=$((failed + 1))
  fi
}

assert_exit_fail() {
  local test_name=$1 skill_dir=$2
  if bash "$VALIDATE" "$skill_dir" >/dev/null 2>&1; then
    echo "FAIL: $test_name — expected non-zero exit"
    failed=$((failed + 1))
  else
    echo "PASS: $test_name (exit non-zero)"
    passed=$((passed + 1))
  fi
}

assert_verdict_count() {
  local test_name=$1 verdict=$2 expected=$3 skill_dir=$4
  local output count
  output=$(bash "$VALIDATE" "$skill_dir" 2>/dev/null) || true
  count=$(echo "$output" | grep -o "\"${verdict,,}ed\": *[0-9]*" | grep -o '[0-9]*' || echo 0)
  # Handle FAIL/WARN/SKIP naming in JSON
  case "$verdict" in
    FAIL) count=$(echo "$output" | grep -o '"failed": *[0-9]*' | grep -o '[0-9]*') ;;
    WARN) count=$(echo "$output" | grep -o '"warned": *[0-9]*' | grep -o '[0-9]*') ;;
    PASS) count=$(echo "$output" | grep -o '"passed": *[0-9]*' | grep -o '[0-9]*') ;;
  esac
  if [[ "$count" == "$expected" ]]; then
    echo "PASS: $test_name ($verdict=$count)"
    passed=$((passed + 1))
  else
    echo "FAIL: $test_name — expected $verdict=$expected, got $verdict=$count"
    failed=$((failed + 1))
  fi
}

# --- Test: missing SKILL.md ---
t1="$TMPDIR_ROOT/t1"
mkdir -p "$t1"
assert_exit_fail "missing SKILL.md exits non-zero" "$t1"

# --- Test: no frontmatter ---
t2="$TMPDIR_ROOT/t2"
mkdir -p "$t2"
echo "# No frontmatter" > "$t2/SKILL.md"
assert_exit_fail "no frontmatter exits non-zero" "$t2"

# --- Test: valid minimal skill ---
t3="$TMPDIR_ROOT/t3"
mkdir -p "$t3"
cat > "$t3/SKILL.md" <<'EOF'
---
name: t3
description: Creates test reports from data. Use when user says "run tests" or "generate report".
---

# Test Skill

Step-by-step workflow for testing.

## Step 1: Gather input

Collect data from the user.

## Step 2: Process

Run the analysis script.

## Step 3: Output

Present results to the user.
EOF
assert_grade "valid minimal skill" "A" "$t3"

# --- Test: uppercase folder name ---
t4="$TMPDIR_ROOT/BadName"
mkdir -p "$t4"
cat > "$t4/SKILL.md" <<'EOF'
---
name: bad-name
description: Creates test output. Use when user says "test" or "run checks".
---

# Bad Name

Instructions here with enough content.

## Step 1: Do thing

Concrete step.

## Step 2: Another

More steps.
EOF
assert_grade "uppercase folder name" "C" "$t4"

# --- Test: folder != name ---
t5="$TMPDIR_ROOT/wrong-folder"
mkdir -p "$t5"
cat > "$t5/SKILL.md" <<'EOF'
---
name: correct-name
description: Creates reports from data. Use when user says "make report" or "generate output".
---

# Wrong Folder

Instructions.

## Step 1: Do

Concrete.

## Step 2: More

Details.
EOF
assert_grade "folder != name" "C" "$t5"

# --- Test: description with angle brackets ---
t6="$TMPDIR_ROOT/t6"
mkdir -p "$t6"
cat > "$t6/SKILL.md" <<'EOF'
---
name: t6
description: Creates <html> output. Use when user says "make page".
---

# T6

Instructions.

## Step 1: Do

Concrete.

## Step 2: More

Details.
EOF
assert_grade "description with angle brackets" "C" "$t6"

# --- Test: disallowed frontmatter field ---
t7="$TMPDIR_ROOT/t7"
mkdir -p "$t7"
cat > "$t7/SKILL.md" <<'EOF'
---
name: t7
description: Generates output from data. Use when user says "create" or "build output".
version: 1.0.0
---

# T7

Instructions.

## Step 1: Do

Concrete.

## Step 2: More

Details.
EOF
assert_grade "disallowed frontmatter field" "C" "$t7"

# --- Test: no trigger phrases (D-03 warn) ---
t8="$TMPDIR_ROOT/t8"
mkdir -p "$t8"
cat > "$t8/SKILL.md" <<'EOF'
---
name: t8
description: Generates data reports. Use when the user needs reporting capabilities.
---

# T8

Instructions.

## Step 1: Do

Concrete.

## Step 2: More

Details.
EOF
assert_verdict_count "no trigger phrases warns" "WARN" "1" "$t8"

# --- Test: skill-smith validates itself ---
assert_grade "skill-smith self-validation" "A" "$SCRIPT_DIR/.."
assert_verdict_count "skill-smith 0 FAIL" "FAIL" "0" "$SCRIPT_DIR/.."
assert_verdict_count "skill-smith 0 WARN" "WARN" "0" "$SCRIPT_DIR/.."

# --- Results ---
echo ""
echo "Results: $passed passed, $failed failed"
[[ $failed -eq 0 ]]
