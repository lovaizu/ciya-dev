#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
  local test_name="$1" expected="$2" actual="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  PASS: $test_name"
    ((++passed))
  else
    echo "  FAIL: $test_name"
    echo "    expected to contain: $expected"
    echo "    actual:              $actual"
    ((++failed))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# ── Empty input ───────────────────────────────────────────────
echo "empty input:"

# Given: no input data
# When: running profile_stats.sh with empty stdin
# Then: exits with error
result=$(echo "" | bash "$SCRIPT_DIR/profile_stats.sh" 2>"$tmp/stderr" && echo "OK" || echo "FAIL")
assert_eq "exits with error on empty input" "FAIL" "$result"
assert_contains "error message for empty input" "no input data" "$(cat "$tmp/stderr")"

# ── Invalid field count ───────────────────────────────────────
echo "invalid field count:"

# Given: input with wrong number of fields
# When: running profile_stats.sh
# Then: exits with error
result=$(printf '1\tduration_ms\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>"$tmp/stderr" && echo "OK" || echo "FAIL")
assert_eq "exits with error on 2 fields" "FAIL" "$result"
assert_contains "error message mentions field count" "2 fields" "$(cat "$tmp/stderr")"

# Given: input with 4 fields
# When: running profile_stats.sh
# Then: exits with error
result=$(printf '1\tduration_ms\t100\textra\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>"$tmp/stderr" && echo "OK" || echo "FAIL")
assert_eq "exits with error on 4 fields" "FAIL" "$result"
assert_contains "error message mentions 4 fields" "4 fields" "$(cat "$tmp/stderr")"

# ── Single observation ────────────────────────────────────────
echo "single observation:"

# Given: one data point
# When: running profile_stats.sh
# Then: avg=value, median=value, stddev=0, min=max=value, proportion=1.0
result=$(printf '1\tduration_ms\t1000\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
assert_eq "single value stats" "1	duration_ms	1000.00	1000.00	0.00	1000.00	1000.00	1.0000" "$result"

# ── Two observations (even count median) ──────────────────────
echo "even count median:"

# Given: two data points for one step
# When: running profile_stats.sh
# Then: median is average of the two middle values
result=$(printf '1\tduration_ms\t1000\n1\tduration_ms\t2000\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
assert_eq "even count median" "1	duration_ms	1500.00	1500.00	500.00	1000.00	2000.00	1.0000" "$result"

# ── Three observations (odd count median) ─────────────────────
echo "odd count median:"

# Given: three data points for one step
# When: running profile_stats.sh
# Then: median is the middle value
result=$(printf '1\tduration_ms\t1000\n1\tduration_ms\t3000\n1\tduration_ms\t2000\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
assert_eq "odd count median" "1	duration_ms	2000.00	2000.00	816.50	1000.00	3000.00	1.0000" "$result"

# ── Multiple steps, single metric ─────────────────────────────
echo "multiple steps:"

# Given: two steps with duration_ms data
# When: running profile_stats.sh
# Then: proportions sum to 1.0 and reflect each step's share
result=$(printf '1\tduration_ms\t1500\n1\tduration_ms\t1200\n1\tduration_ms\t1800\n2\tduration_ms\t800\n2\tduration_ms\t900\n2\tduration_ms\t700\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
line1=$(echo "$result" | head -1)
line2=$(echo "$result" | tail -1)
assert_eq "step 1 avg" "1500.00" "$(echo "$line1" | cut -f3)"
assert_eq "step 2 avg" "800.00" "$(echo "$line2" | cut -f3)"
assert_eq "step 1 proportion" "0.6522" "$(echo "$line1" | cut -f8)"
assert_eq "step 2 proportion" "0.3478" "$(echo "$line2" | cut -f8)"

# ── Multiple metrics ──────────────────────────────────────────
echo "multiple metrics:"

# Given: two steps with two different metrics
# When: running profile_stats.sh
# Then: proportions are computed independently per metric
result=$(printf '1\tduration_ms\t1000\n2\tduration_ms\t3000\n1\ttotal_tokens\t5000\n2\ttotal_tokens\t5000\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
assert_eq "output has 4 lines" "4" "$(echo "$result" | wc -l | tr -d ' ')"
# step 1 duration proportion: 1000 / (1000+3000) = 0.25
s1_dur=$(echo "$result" | grep '^1	duration_ms' | cut -f8)
assert_eq "step 1 duration proportion" "0.2500" "$s1_dur"
# step 1 tokens proportion: 5000 / (5000+5000) = 0.5
s1_tok=$(echo "$result" | grep '^1	total_tokens' | cut -f8)
assert_eq "step 1 tokens proportion" "0.5000" "$s1_tok"

# ── Sorted output ─────────────────────────────────────────────
echo "sorted output:"

# Given: input with steps in reverse order
# When: running profile_stats.sh
# Then: output is sorted by step_number then metric_name
result=$(printf '2\ttotal_tokens\t100\n1\tduration_ms\t200\n2\tduration_ms\t300\n1\ttotal_tokens\t400\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
first_step=$(echo "$result" | head -1 | cut -f1)
last_step=$(echo "$result" | tail -1 | cut -f1)
assert_eq "first line is step 1" "1" "$first_step"
assert_eq "last line is step 2" "2" "$last_step"

# ── Zero values ───────────────────────────────────────────────
echo "zero values:"

# Given: all zero values
# When: running profile_stats.sh
# Then: proportion is 0 (avoids division by zero)
result=$(printf '1\tduration_ms\t0\n2\tduration_ms\t0\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
s1_prop=$(echo "$result" | head -1 | cut -f8)
assert_eq "zero value proportion" "0.0000" "$s1_prop"

# ── Decimal values ────────────────────────────────────────────
echo "decimal values:"

# Given: decimal input values
# When: running profile_stats.sh
# Then: computation handles decimals correctly
result=$(printf '1\tcost\t0.05\n1\tcost\t0.15\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
avg=$(echo "$result" | cut -f3)
assert_eq "decimal avg" "0.10" "$avg"

# ── Identical values (zero stddev) ────────────────────────────
echo "identical values:"

# Given: all values are the same
# When: running profile_stats.sh
# Then: stddev is 0
result=$(printf '1\tduration_ms\t500\n1\tduration_ms\t500\n1\tduration_ms\t500\n' | bash "$SCRIPT_DIR/profile_stats.sh" 2>/dev/null)
sd=$(echo "$result" | cut -f5)
assert_eq "identical values stddev" "0.00" "$sd"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "Results: $passed passed, $failed failed"
if [[ $failed -gt 0 ]]; then exit 1; fi
