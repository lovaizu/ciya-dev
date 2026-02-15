# Shell Script Testing

Shell-specific test conventions. See `testing.md` for common rules (Given-When-Then, coverage, meta-rules).

## Test File Convention

- Every shell script `<name>.sh` must have a corresponding `<name>_test.sh` in the same directory
- Test scripts must be plain bash — no external test frameworks
- Test scripts must exit 0 on success, non-zero on failure

## Test Code Format

```bash
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

# Temp directory + cleanup (when tests need filesystem isolation)
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# ── Section name ──────────────────────────────────────────────
echo "section name:"

# Given: preconditions
# When: action
# Then: assertion
assert_eq "description" "expected" "$actual"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "Results: $passed passed, $failed failed"
[[ $failed -gt 0 ]] && exit 1
```

### Required elements

- **Shebang**: `#!/usr/bin/env bash`
- **Set flags**: `set -euo pipefail` (omit `-e` only when tests must capture non-zero exit codes)
- **SCRIPT_DIR**: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`
- **Counters**: `passed=0` and `failed=0`
- **Assertion helpers**: At minimum `assert_eq`; add custom helpers as needed (e.g., `assert_contains`, `assert_decision`)
- **Sections**: Group related tests under `# ── Name ──` comment headers with an `echo` for the section name
- **Summary**: Print `"Results: $passed passed, $failed failed"` and exit non-zero if any test failed

### Temp directory

- Tests that create files or directories must use `mktemp -d` and clean up with `trap 'rm -rf "$tmp"' EXIT`
- Tests that only exercise pure functions (no filesystem side effects) may skip the temp directory
