# Issue #38: Standardized Unit Test Rules

## Problem Summary

Test rules exist only as three bullet points in CLAUDE.md. Six test scripts share a consistent structure that is undocumented. No rules exist for tool adoption. This causes inconsistent test quality and review overhead.

## Approach

1. **Extract and codify the existing test patterns** from the 6 test scripts into `.claude/rules/testing-shell.md`
   - Given-When-Then structure (already used implicitly by all scripts)
   - Test code format: shebang, set flags, SCRIPT_DIR, counters, helpers, sections, summary, exit
   - Coverage requirements: unit test isolation, integration where needed, manual test documentation

2. **Replace CLAUDE.md Script Testing section** with a reference to the new rule file

3. **Add meta-rules** to `.claude/rules/testing-shell.md`:
   - Require unit tests following the rules whenever code is written
   - Require a test rule proposal when a new code type (not just shell) is added

4. **Create `.claude/rules/tool-adoption.md`** for tool comparison/evaluation, user approval, and setup script updates

5. **Evaluate coverage tools and test frameworks** — compare options, document the decision

6. **Update existing test scripts** to conform to the new rule format (if any gaps)

## Key Decisions

- Codify existing patterns rather than invent new ones — the 6 scripts already converge on a solid structure
- Given-When-Then is implicit in all scripts; make it explicit via comments
- Keep "plain bash, no external frameworks" as the standard (aligns with existing practice)
- Meta-rules go in the same file as test rules (keeps related rules together)

## Open Questions

- ~~Coverage tool evaluation~~ → Resolved (see below)
- ~~Given-When-Then enforcement~~ → Resolved: via comments for multi-step tests; implicit for one-liner assertions

## Tool Evaluation

### Coverage Tools

| Tool | How it works | Pros | Cons |
|------|-------------|------|------|
| kcov | Traces bash via `PS4`/`BASH_XTRACEFD`; outputs Cobertura XML | Mature, CI-friendly | Requires C++ build/install, heavyweight for 6 small scripts |
| bashcov | Ruby gem wrapping simplecov | Familiar coverage reports | Requires Ruby runtime, not maintained actively |
| (none) | Manual coverage via test review | Zero dependencies, no maintenance | No automated coverage metrics |

### Test Frameworks

| Tool | How it works | Pros | Cons |
|------|-------------|------|------|
| bats-core | TAP-compliant test runner with `@test` blocks | Standard output format, setup/teardown hooks | Changes test file format, adds dependency |
| shunit2 | xUnit-style framework for shell | Familiar xUnit API | Heavyweight for simple tests, adds dependency |
| plain bash | Manual assert helpers, exit code | Zero dependencies, already in use | No built-in test discovery or reporting |

### Decision: Keep plain bash, no external tools

1. The test suite has 6 scripts — too small to justify framework/tool overhead
2. All scripts already converge on a consistent pattern (assert helpers, counters, summary)
3. Adding tools contradicts the existing "plain bash, no external frameworks" rule
4. Coverage tools require installation and build steps that complicate the setup
5. If the project grows to need these tools, the new tool-adoption rule provides a process to revisit
