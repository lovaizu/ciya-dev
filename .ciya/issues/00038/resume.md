# Resume: Issue #38

## Branch
standardized-test-rules

## Associated
- Issue: https://github.com/lovaizu/ciya-dev/issues/38
- PR: https://github.com/lovaizu/ciya-dev/pull/40

## Current Workflow Step
Step 10: Gate 3 — Goal Verification (review feedback addressed, waiting for re-review)

## In Progress
- All implementation tasks completed and pushed
- All review feedback addressed (5 rounds of review comments resolved)
- Expert Review and Success Criteria Check tables appended to PR
- Added kcov to scripts/up.sh prerequisites (reviewer request)
- Added check_prerequisites tests and fixed environment-dependent test failure

## Completed
- Created `.claude/rules/testing.md` (common test rules: GWT, C1 coverage, meta-rules)
- Created `.claude/rules/testing-shell.md` (shell-specific conventions, kcov integration)
- Created `.claude/rules/tool-adoption.md` (tool evaluation process)
- Updated CLAUDE.md with references to new rule files
- Updated all 6 existing test scripts with GWT comments
- Evaluated kcov and adopted it for coverage measurement
- Added domain request convention to agent-behavior.md
- Added kcov to up.sh prerequisites
- Added check_prerequisites tests (3 tests) and CIYA_WORK_COUNT test
- Fixed pre-existing Test 7 failure (CIYA_WORK_COUNT environment isolation)

## Next Steps
- Developer installs kcov (`sudo apt install kcov`)
- Developer re-reviews PR on GitHub
- If approved: proceed to step 11 (Merge)
- If feedback: address with `/fb`

## Blockers / Open Questions
- None — waiting for developer re-review and approval
