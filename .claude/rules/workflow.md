# Workflow

Follow this workflow for every task. The workflow spans two worktrees:
- **main/** — Issue creation and goal approval (steps 1-3)
- **work-N/** — Implementation and delivery (steps 4-12)

## Phase 1: Issue (main/ worktree)

1. **Hearing**
   - Gather requirements from the developer
   - Ask clarifying questions until the goal and scope are clear

2. **Issue creation**
   - Draft the issue title in user story format (see `issue-format.md`)
   - Draft the issue body with Situation, Pain, Benefit, and Success Criteria
   - Create the issue on GitHub with `gh issue create`

3. **Gate 1 — Goal**
   - Developer reviews the issue on GitHub
   - `/fb` to address feedback comments on the issue
   - `/ty` to approve: is the issue capturing the right problem and goal?

## Phase 2: Implementation (work-N/ worktree)

4. **PR description**
   - Draft the PR title (concise, describes purpose)
   - Draft the PR body with Approach and Tasks (see `pr-format.md`)
   - Ensure Approach addresses each Pain from the issue
   - Ensure Tasks are traceable to the Approach
   - Create the PR on GitHub with `gh pr create`

5. **Gate 2 — Approach**
   - Developer reviews the PR on GitHub
   - `/fb` to address feedback comments on the PR
   - `/ty` to approve: can the PR's approach achieve the goal?

6. **Implementation**
   - Write code and make commits (split by purpose, one logical change per commit)
   - Push commits to the remote branch

7. **Consistency check**
   - Verify issue title [goal] matches one of the Benefits
   - Verify each Success Criteria maps to a Benefit
   - Verify PR Approach addresses each Pain
   - Verify PR Tasks are traceable to the Approach
   - If any section was updated during earlier steps, re-check all sections
   - Fix any inconsistencies found

8. **Expert review**
   - Identify the technical domain of the deliverable
   - Simulate a review from a domain expert perspective
   - Evaluate correctness, best practices, and potential issues
   - Fix any problems found
   - Append the Expert Review table to the PR body (see `pr-format.md`)

9. **Success Criteria check**
   - Read the issue's Success Criteria
   - For each criterion: execute it as written (prefer execution over inspection)
   - If execution is truly not possible, explain why before falling back to inspection
   - Update the issue body to check off completed Success Criteria checkboxes
   - Append the Success Criteria Check table to the PR body (see `pr-format.md`)
   - If any criterion is NG, address it and re-check

10. **Gate 3 — Goal Verification**
    - Developer reviews the implementation on GitHub
    - `/fb` to address feedback comments on the PR
    - `/ty` to approve: has the goal been achieved?

11. **Merge**
    - Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
    - If not `APPROVED`, ask the developer to approve the PR on GitHub first
    - Squash-merge: `gh pr merge <number> --squash --delete-branch`

12. **Done**
    - The work-N/ worktree is ready for the next `/hi <issue-number>`

## Interruption

At any point during the workflow, the developer can run `/bb` to:
- Save current state to `.ciya/issues/nnnnn/resume.md`
- Resume later with `/hi <issue-number>` in any work-N/ worktree
