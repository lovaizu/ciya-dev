# Testing

Common rules for all test code regardless of language. See `testing-shell.md` for shell-specific conventions.

## Given-When-Then Pattern

Every test follows the Given-When-Then structure.

Multi-step tests must mark each phase with a comment:

```
# Given: a git repo with a known branch
git init "$tmp/repo" >/dev/null 2>&1

# When: running the script
actual=$(echo "$input" | bash "$SCRIPT_DIR/statusline.sh")

# Then: output includes branch name
assert_eq "includes branch" "$expected" "$actual"
```

One-line assertions where Given-When-Then is a single expression do not require comments:

```bash
assert_eq "ampersand" '&amp;' "$(escape_for_xml '&')"
```

## Coverage

- **Target**: C1 (branch) coverage at 100%
- Every conditional branch (`if/else`, `case`, `&&/||`, loop boundaries) must have at least one test exercising each path
- **Measurement**: Use kcov to produce quantitative coverage reports — do not rely solely on code review
- **Unit tests**: Cover what can be tested in isolation — argument parsing, output formatting, error handling, file operations, function behavior
- **Integration tests**: Verify interactions between components (e.g., main function dispatching to helpers)
- **Manual tests**: What cannot be unit tested (tmux sessions, CC startup, interactive prompts) must be documented as manual test tasks in a comment at the top of the test file
- **Coverage exclusions are prohibited by default** — every line and branch must be covered
- Exclusion is allowed only when unit testing is truly impossible (e.g., interactive terminal sessions, OS-specific code paths that cannot be simulated). To exclude a line: document the reason in a comment, get developer approval, then mark with the language-specific exclusion marker

## CI Enforcement

- Each code type with a test rule must have a GitHub Actions workflow that runs all tests and verifies 100% coverage
- Workflow files are separated by code type (e.g., `.github/workflows/test-shell.yml`)
- When a new `testing-<type>.md` rule is added, a corresponding workflow must be created

## Meta-Rules

- **Require tests for code**: Whenever code is written or modified, its tests must be created or updated to cover the changes
- **Require test rules for new code types**: When a code type without a corresponding test rule file is added (e.g., Python, TypeScript), propose a new `.claude/rules/testing-<type>.md` and a corresponding CI workflow
