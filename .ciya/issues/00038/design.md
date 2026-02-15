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

| Tool | Install | Dependencies | How it works | Output | Maintenance |
|------|---------|-------------|-------------|--------|-------------|
| kcov | `apt install kcov` (v38) or build from source (latest v43) | C++ build chain if from source; none at runtime | Traces bash via `BASH_XTRACEFD`; no script changes needed | HTML, Cobertura XML, JSON | Active (last commit Jan 2026) |
| bashcov | `gem install bashcov` | Ruby >= 3.2.0 + simplecov | Uses `set -x` with custom `PS4`; no script changes needed | HTML via simplecov | Active (last commit Jan 2026) |
| (none) | — | — | Manual review | — | — |

**kcov usage** — wraps existing test scripts without modification:
```
kcov --include-path=. /tmp/coverage ./foo_test.sh
# Produces /tmp/coverage/foo_test.sh/index.html + cobertura.xml
```

**Recommendation: Adopt kcov**
- Provides quantitative C1 coverage data — detects missed branches that code review might overlook
- Zero changes to existing test scripts (just wraps the invocation)
- Industry standard for bash coverage (kcov is the de facto tool; coverage measurement is rare but kcov is what's used when it is done)
- `apt install kcov` is sufficient for a working setup
- Overhead: one package install in setup script + `kcov` prefix when running tests

### Test Frameworks

| Tool | Install | How it works | Stars | Maintenance |
|------|---------|-------------|-------|-------------|
| bats-core | `apt install bats` or `npm install -g bats` | TAP-compliant `@test` blocks with auto-isolation | 5,832 | Very active (last commit Feb 2026) |
| shunit2 | Manual download | xUnit-style functions | ~500 | Low activity |
| ShellSpec | Manual install | BDD-style DSL, POSIX-compatible | 1,346 | Active |
| plain bash | — | Manual assert helpers, exit code | — | — |

**Industry practice**: bats-core is the dominant framework (used by Docker, rbenv, nvm, Homebrew). Plain bash tests are common in smaller projects.

**Recommendation: Keep plain bash**
- bats-core would require rewriting all 6 existing test scripts to `@test` format
- Our plain bash tests already provide GWT structure, assert helpers, and consistent formatting
- The benefit (auto-isolation, TAP output, parallel execution) is not justified for 6 scripts

### Decision Summary

| Category | Decision | Rationale |
|----------|----------|-----------|
| Coverage | **Adopt kcov** | Quantitative coverage with zero test changes; `apt install kcov` |
| Framework | **Keep plain bash** | Rewriting 6 scripts to bats-core is not justified |
