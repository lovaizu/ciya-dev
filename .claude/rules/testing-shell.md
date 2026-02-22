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

- Omit `set -e` only when tests must capture non-zero exit codes
- Tests with no filesystem side effects may skip the temp directory

## Coverage with kcov

Run tests through kcov to measure C1 branch coverage. Test scripts require no modification — kcov wraps the execution.

### Running coverage

```bash
# Single test
kcov --include-path="$SCRIPT_DIR" --exclude-pattern=_test.sh \
     --bash-parse-files-in-dirs="$SCRIPT_DIR" \
     --bash-dont-parse-binary-dir \
     ./coverage ./foo_test.sh

# All tests in a directory (accumulates into one report)
for f in *_test.sh; do
    kcov --include-path="$PWD" --exclude-pattern=_test.sh \
         --bash-parse-files-in-dirs="$PWD" \
         --bash-dont-parse-binary-dir \
         ./coverage "./$f"
done
```

### Key flags

| Flag | Purpose |
|------|---------|
| `--include-path=DIR` | Only report on source scripts in these directories |
| `--exclude-pattern=_test.sh` | Exclude test scripts from coverage report |
| `--bash-parse-files-in-dirs=DIR` | Include untested scripts in report (showing 0%) |
| `--bash-dont-parse-binary-dir` | Don't auto-scan for sibling scripts |

### Coverage exclusions

Coverage exclusions are prohibited by default (see `testing.md`). When exclusion is approved by the developer, use `# LCOV_EXCL_LINE` for single lines or `# LCOV_EXCL_START` / `# LCOV_EXCL_STOP` for blocks:

```bash
# Requires interactive tmux session; see manual tests in up_test.sh
launch_tmux() {  # LCOV_EXCL_START
  ...
}  # LCOV_EXCL_STOP
```

### Known limitations

- `set -x` in source scripts conflicts with kcov's default PS4 method — use `--bash-method=DEBUG` as a workaround
- `eval` and complex heredocs may not be tracked accurately
- Use absolute paths in `--include-path` when tests change the working directory
