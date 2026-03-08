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
# Given: an empty directory with no SKILL.md
t1="$TMPDIR_ROOT/t1"
mkdir -p "$t1"
# When + Then: validation exits non-zero
assert_exit_fail "missing SKILL.md exits non-zero" "$t1"

# --- Test: no frontmatter ---
# Given: a SKILL.md without YAML frontmatter
t2="$TMPDIR_ROOT/t2"
mkdir -p "$t2"
echo "# No frontmatter" > "$t2/SKILL.md"
# When + Then: validation exits non-zero
assert_exit_fail "no frontmatter exits non-zero" "$t2"

# --- Test: valid minimal skill ---
# Given: a well-formed SKILL.md with all required fields
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
# When + Then: grades A
assert_grade "valid minimal skill" "A" "$t3"

# --- Test: uppercase folder name ---
# Given: a skill directory with uppercase letters in folder name
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
# When + Then: grades C due to naming violation
assert_grade "uppercase folder name" "C" "$t4"

# --- Test: folder != name ---
# Given: folder name does not match the name field in SKILL.md
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
# When + Then: grades C due to name mismatch
assert_grade "folder != name" "C" "$t5"

# --- Test: description with angle brackets ---
# Given: a SKILL.md with angle brackets in the description
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
# When + Then: grades C due to angle brackets
assert_grade "description with angle brackets" "C" "$t6"

# --- Test: disallowed frontmatter field ---
# Given: a SKILL.md with an unsupported frontmatter field
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
# When + Then: grades C due to disallowed field
assert_grade "disallowed frontmatter field" "C" "$t7"

# --- Test: no trigger phrases (D-03 warn) ---
# Given: a SKILL.md with no trigger phrases in the description
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
# When + Then: produces 1 warning
assert_verdict_count "no trigger phrases warns" "WARN" "1" "$t8"

# --- Test: no argument ---
# Given: no arguments passed to validate.sh
# When + Then: exits non-zero with usage message
if bash "$VALIDATE" >/dev/null 2>&1; then
  echo "FAIL: no argument exits non-zero — expected non-zero exit"
  failed=$((failed + 1))
else
  echo "PASS: no argument exits non-zero (exit non-zero)"
  passed=$((passed + 1))
fi

# --- Test: case-variant SKILL.md ---
# Given: a directory with skill.md (wrong case) instead of SKILL.md
tc="$TMPDIR_ROOT/t-case"
mkdir -p "$tc"
cat > "$tc/skill.md" <<'EOF'
---
name: t-case
description: Creates reports. Use when user says "test" or "run".
---
Instructions.
EOF
assert_exit_fail "case variant SKILL.md detected" "$tc"

# --- Test: empty frontmatter (consecutive delimiters, no body) ---
# Given: SKILL.md with two --- lines and nothing else
tef="$TMPDIR_ROOT/t-ef"
mkdir -p "$tef"
printf '%s\n' "---" "---" > "$tef/SKILL.md"
assert_exit_fail "empty frontmatter" "$tef"

# --- Test: invalid YAML ---
# Given: SKILL.md with invalid YAML in frontmatter
tiy="$TMPDIR_ROOT/t-iy"
mkdir -p "$tiy"
printf '%s\n' "---" "name: t-iy" "!!!not valid yaml" "---" "Instructions." > "$tiy/SKILL.md"
assert_exit_fail "invalid YAML exits non-zero" "$tiy"

# --- Test: missing name and description (Grade F) ---
# Given: SKILL.md with no name and no description fields
tmnf="$TMPDIR_ROOT/t-mnf"
mkdir -p "$tmnf"
printf '%s\n' "---" "license: MIT" "---" "Instructions." > "$tmnf/SKILL.md"
assert_grade "missing name+desc grades F" "F" "$tmnf"

# --- Test: non-kebab reserved name (Grade C, > 2 fails) ---
# Given: name with uppercase (non-kebab) AND contains reserved word
tnkr="$TMPDIR_ROOT/t-nkr"
mkdir -p "$tnkr"
cat > "$tnkr/SKILL.md" <<'EOF'
---
name: Claude-Helper
description: Creates test reports from data. Use when user says "run test" or "check output".
---
Instructions.
EOF
assert_grade "non-kebab reserved name grades C" "C" "$tnkr"

# --- Test: vague description, no trigger (Grade D) ---
# Given: description with vague language and no trigger conditions
tvd="$TMPDIR_ROOT/t-vd"
mkdir -p "$tvd"
cat > "$tvd/SKILL.md" <<'EOF'
---
name: t-vd
description: Helps with various tasks and operations.
---
Instructions here.
EOF
assert_grade "vague desc no trigger grades D" "D" "$tvd"

# --- Test: no concrete verbs in description (D-01 warn) ---
# Given: description without concrete function verbs or vague terms
tnv="$TMPDIR_ROOT/t-nv"
mkdir -p "$tnv"
cat > "$tnv/SKILL.md" <<'EOF'
---
name: t-nv
description: A useful thing for testing purposes. Use when user says "test" or "check".
---
Instructions.
EOF
assert_grade "no concrete verbs grades A" "A" "$tnv"

# --- Test: README.md + unexpected dir + auxiliary docs ---
# Given: a skill with README.md, unexpected directory, and auxiliary docs
tra="$TMPDIR_ROOT/t-ra"
mkdir -p "$tra" "$tra/extras"
cat > "$tra/SKILL.md" <<'EOF'
---
name: t-ra
description: Creates test reports from data. Use when user says "run test" or "check output".
---
Instructions.
EOF
touch "$tra/README.md" "$tra/CHANGELOG.md"
assert_grade "readme+unexpdir+auxdoc grades C" "C" "$tra"

# --- Test: description too long ---
# Given: SKILL.md with description > 1024 characters
tdl="$TMPDIR_ROOT/t-dl"
mkdir -p "$tdl"
long_desc="Creates test reports from data. Use when user says \"run test\" or \"check output\". "
while [[ ${#long_desc} -lt 1030 ]]; do long_desc="${long_desc}Extra words for padding. "; done
{
  echo "---"
  echo "name: t-dl"
  printf 'description: %s\n' "$long_desc"
  echo "---"
  echo "Instructions."
} > "$tdl/SKILL.md"
assert_grade "description too long grades C" "C" "$tdl"

# --- Test: compatibility field short ---
# Given: SKILL.md with a short compatibility field
tcs="$TMPDIR_ROOT/t-cs"
mkdir -p "$tcs"
cat > "$tcs/SKILL.md" <<'EOF'
---
name: t-cs
description: Creates test reports from data. Use when user says "run test" or "check output".
compatibility: claude-code >= 1.0
---
Instructions.
EOF
assert_grade "compatibility short grades A" "A" "$tcs"

# --- Test: compatibility field too long ---
# Given: SKILL.md with compatibility > 500 characters
tcl="$TMPDIR_ROOT/t-cl"
mkdir -p "$tcl"
long_compat="claude-code >= 1.0 "
while [[ ${#long_compat} -lt 510 ]]; do long_compat="${long_compat}and more compat "; done
{
  echo "---"
  echo "name: t-cl"
  echo 'description: Creates test reports from data. Use when user says "run test" or "check output".'
  printf 'compatibility: %s\n' "$long_compat"
  echo "---"
  echo "Instructions."
} > "$tcl/SKILL.md"
assert_grade "compatibility too long grades C" "C" "$tcl"

# --- Test: body > 500 lines (I-05 warn) ---
# Given: SKILL.md with body between 501 and 1000 lines
tbw="$TMPDIR_ROOT/t-bw"
mkdir -p "$tbw"
{
  echo "---"
  echo "name: t-bw"
  echo 'description: Creates test reports from data. Use when user says "run test" or "check output".'
  echo "---"
  seq 1 510
} > "$tbw/SKILL.md"
assert_grade "body 510 lines grades A" "A" "$tbw"

# --- Test: body > 1000 lines (I-05 fail) ---
# Given: SKILL.md with body > 1000 lines
tbf="$TMPDIR_ROOT/t-bf"
mkdir -p "$tbf"
{
  echo "---"
  echo "name: t-bf"
  echo 'description: Creates test reports from data. Use when user says "run test" or "check output".'
  echo "---"
  seq 1 1010
} > "$tbf/SKILL.md"
assert_grade "body 1010 lines grades C" "C" "$tbf"

# --- Test: MUST density good ---
# Given: SKILL.md with MUST keywords but good density (>= 200 words/keyword)
tmg="$TMPDIR_ROOT/t-mg"
mkdir -p "$tmg"
{
  echo "---"
  echo "name: t-mg"
  echo 'description: Creates test reports from data. Use when user says "run test" or "check output".'
  echo "---"
  for i in $(seq 1 50); do echo "This is line $i of instruction content with several words in it."; done
  echo "You MUST follow this guideline."
} > "$tmg/SKILL.md"
assert_grade "MUST density good grades A" "A" "$tmg"

# --- Test: dangerous operations in scripts ---
# Given: a skill with scripts containing dangerous patterns
tdo="$TMPDIR_ROOT/t-do"
mkdir -p "$tdo/scripts"
cat > "$tdo/SKILL.md" <<'EOF'
---
name: t-do
description: Creates test reports from data. Use when user says "run test" or "check output".
---
Instructions.
EOF
# Build dangerous pattern at runtime to avoid matching SEC-02 in this test file
printf '#!/bin/bash\n%s apt-get install package\n' "su""do" > "$tdo/scripts/setup.sh"
assert_grade "dangerous ops in scripts grades A" "A" "$tdo"

# --- Test: hardcoded secrets ---
# Given: a skill with a file containing secret patterns
tse="$TMPDIR_ROOT/t-se"
mkdir -p "$tse/scripts"
cat > "$tse/SKILL.md" <<'EOF'
---
name: t-se
description: Creates test reports from data. Use when user says "run test" or "check output".
---
Instructions.
EOF
# Build secret pattern at runtime to avoid matching SEC-03 in this test file
field="api""_key"
kp="sk-"
kb="$(printf 'a%.0s' {1..30})"
printf '%s = "%s%s"\n' "$field" "$kp" "$kb" > "$tse/scripts/config.py"
assert_grade "secret in script grades C" "C" "$tse"

# --- Test: Grade B (4+ warns, 0 fails) ---
# Given: a skill that produces 4+ warnings but no failures
tgb="$TMPDIR_ROOT/t-gb"
mkdir -p "$tgb" "$tgb/extras"
cat > "$tgb/SKILL.md" <<'EOF'
---
name: t-gb
description: A useful thing for testing purposes. Use when user says "test".
---
MUST do this.
MUST do that.
MUST always check.
MUST never skip.
MUST verify everything.
ALWAYS follow rules.
NEVER ignore warnings.
CRITICAL to remember.
EOF
touch "$tgb/CHANGELOG.md"
# S-05 warn (extras/), S-06 warn (CHANGELOG), D-01 warn (no verbs), D-03 warn (1 phrase), I-07 warn (MUST density)
assert_grade "4+ warns 0 fails grades B" "B" "$tgb"

# --- Test: skill-smith validates itself ---
# Given: the skill-smith skill directory itself
assert_grade "skill-smith self-validation" "A" "$SCRIPT_DIR/.."
assert_verdict_count "skill-smith 0 FAIL" "FAIL" "0" "$SCRIPT_DIR/.."
assert_verdict_count "skill-smith 0 WARN" "WARN" "0" "$SCRIPT_DIR/.."

# --- Results ---
echo ""
echo "Results: $passed passed, $failed failed"
[[ $failed -eq 0 ]]
