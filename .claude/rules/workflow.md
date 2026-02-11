# Workflow

Follow this workflow for every task:

1. **Hearing**
   - Gather requirements from the developer
   - Ask clarifying questions until the goal and scope are clear

2. **Issue creation**
   - Draft the issue title in user story format (see `issue-format.md`)
   - Draft the issue body with Situation, Pain, Benefit, and Success Criteria
   - Present the draft to the developer

3. **Approval (Issue)**
   - Wait for developer approval of the issue
   - If denied, revise based on feedback and re-propose
   - Once approved, create the issue on GitHub with `gh issue create`

4. **PR description**
   - Draft the PR title (concise, describes purpose)
   - Draft the PR body with Approach and Tasks (see `pr-format.md`)
   - Ensure Approach addresses each Pain from the issue
   - Ensure Tasks are traceable to the Approach
   - Present the draft to the developer

5. **Approval (PR description)**
   - Wait for developer approval of the PR description
   - If denied, revise based on feedback and re-propose

6. **Implementation**
   - Create an empty commit: `git commit --allow-empty`
   - Push the branch and create the PR: `gh pr create`
   - Name the branch per the rules in `git-conventions.md`
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
   - Update the issue body to check off completed Success Criteria checkboxes (fetch with `gh issue view`, modify, update with `gh issue edit --body`)
   - Append the Success Criteria Check table to the PR body (see `pr-format.md`)
   - If any criterion is NG, address it and re-check

10. **PR review**
    - Request review from the developer
    - Address feedback (see PR Review Process in `pr-format.md`)

11. **Approval (PR)**
    - Wait for developer approval of the PR

12. **Merge**
    - Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
    - If not `APPROVED`, confirm with the developer before proceeding
    - Squash-merge: `gh pr merge <number> --squash`
    - The developer will clean up the worktree and branch using `bb.sh`

13. **Done**
