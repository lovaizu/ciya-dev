# Workflow

Follow this workflow for every task. Three phases, each with a purpose and a gate.

## Phase 1: Goal (main/ worktree)

**Purpose:** Define user value — what Benefit to deliver and how to verify it.

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
   - `/ty` to approve
   - **The developer asks:** Do Benefit and SC capture the right user value?
   - **Relevant:** Situation, Pain, Benefit, SC — are the facts accurate, the problem real, and the measure of success right?
   - **Irrelevant:** Implementation details, current architecture, technical feasibility

## Phase 2: Approach (work-N/ worktree)

**Purpose:** Design the means to achieve the Success Criteria.

4. **PR description**
   - Draft the PR title (concise, describes purpose)
   - Draft the PR body with Approach table and Steps (see `pr-format.md`)
   - Ensure every SC appears in the Approach table
   - Ensure Steps are grouped by Approach and implement it
   - Create the PR on GitHub with `gh pr create`

5. **Gate 2 — Approach**
   - Developer reviews the PR on GitHub
   - `/fb` to address feedback comments on the PR
   - `/ty` to approve
   - **The developer asks:** Can Approach and Steps achieve all SC?
   - **Relevant:** Does Approach cover all SC? Do Steps implement the Approach? Is this the optimal strategy?
   - **Irrelevant:** Whether the goal itself is right (already approved at Gate 1)

## Phase 3: Delivery (work-N/ worktree)

**Purpose:** Implement and verify that the goal is achieved.

6. **Implementation**
   - Write code and make commits (split by purpose, one logical change per commit)
   - Push commits to the remote branch

7. **Consistency check**
   - Verify the issue title's [benefit] summarizes the primary Benefit from the body
   - Verify each Pain arises from the Situation
   - Verify each Benefit traces from a Pain
   - Verify each Success Criteria maps to a Benefit
   - Verify every SC appears in the PR Approach table
   - Verify Steps are grouped by Approach and implement it
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

10. **Gate 3 — Verification**
    - Developer reviews the implementation on GitHub
    - `/fb` to address feedback comments on the PR
    - `/ty` to approve
    - **The developer asks:** Are SC met and Benefits realized?
    - **Relevant:** Are SC met? Are Benefits realized? Does the implementation match the approved Approach?
    - **Irrelevant:** Whether the approach was optimal (already approved at Gate 2)

11. **Merge**
    - Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
    - If not `APPROVED`, ask the developer to approve the PR on GitHub first
    - Squash-merge: `gh pr merge <number> --squash`
    - Detach HEAD and delete branches: `git checkout --detach && git push origin --delete <branch-name> && git branch -D <branch-name>`

12. **Done**
    - The work-N/ worktree is ready for the next `/hi <number>`

## Gate Rejection

If the developer provides feedback instead of approving a gate, use `/fb` to address their comments and iterate until they approve with `/ty`.

## Interruption

At any point during the workflow, the developer can run `/bb` to:
- Save current state to `.ciya/issues/nnnnn/resume.md`
- Resume later with `/hi <number>` in any work-N/ worktree
