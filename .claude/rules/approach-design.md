# Approach Design

Procedure for Phase 2 of the workflow: designing means to achieve Acceptance Scenarios.

## Purpose

Design an approach for every AS so the developer can evaluate the strategy before implementation work begins. An uncovered AS will not be achieved; a vague step cannot be tracked.

## Deliverable

A GitHub PR following `pr-format.md`:
- "Closes #N" linking to the issue
- Approach table with every AS mapped to a means
- Steps grouped by Approach with concrete, actionable items

Work records in `.aiya/issues/nnnnn/`:
- `design.md` — Problem Summary, Approach, Key Decisions, Open Questions

## Generate

Requires: issue approved at Gate 1.

1. Read the issue's Acceptance Scenarios
2. For each AS, determine the means to achieve it — consider the simplest approach that satisfies the scenario
3. Draft the Approach table with every AS mapped to an approach — every AS must appear so all scenarios are covered. Write each approach as a concise action phrase — the same text serves as both a table cell and a Step heading in the PR.
4. Use each unique Approach from the table as the exact Step heading — if multiple ASs share the same approach, use a single heading to avoid duplication
5. Break each approach into concrete steps with checkboxes so progress can be tracked during implementation
6. Create a branch: `git fetch origin && git switch -c <branch-name> origin/main`
7. Create work records directory: `.aiya/issues/<5-digit-number>/`
8. Write `design.md` with Problem Summary, Approach, Key Decisions, Open Questions — this captures rationale that would otherwise be lost
9. Create the PR: `gh pr create`
10. Report the PR URL to the developer

## Verify

1. Every AS from the issue appears in the Approach table
2. Each Approach describes means (what), not rationale (why) — rationale goes in `design.md`
3. Each Step heading matches an Approach from the table exactly — different text breaks traceability
4. Each step is concrete and actionable
5. Steps collectively implement the Approach they belong to
6. Branch name describes the goal, not the implementation
7. `design.md` captures key decisions and rationale

## Iterate

- If any check fails, revise and re-verify all checks
- If the approach is non-obvious, explain why it was chosen over alternatives
- Present the verified PR to the developer for Gate 2 review
