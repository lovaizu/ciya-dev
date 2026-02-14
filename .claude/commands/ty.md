---
disable-model-invocation: true
---

The developer has approved. Detect which gate this is and proceed.

## Usage

Show this to the developer:

```
/ty              Approve the current gate
```

## Three Gates

- **Gate 1 — Goal:** Is the issue capturing the right problem and goal?
- **Gate 2 — Approach:** Can the PR's approach achieve the goal?
- **Gate 3 — Goal Verification:** Has the goal been achieved?

## Detect the gate

1. Detect the current branch: `git branch --show-current`
2. Detect the worktree (main/ or work-N/)
3. Find the PR for the current branch: `gh pr list --head <branch-name> --json number,title,body,url,reviewDecision`

## Gate 1: Goal (in main/ worktree)

The developer approved the issue. Proceed:

1. Tell the developer: "Issue approved. Run `/hi <issue-number>` in a work-N/ worktree to start implementation."

## Gate 2: Approach (in work-N/, PR exists but implementation not started)

The developer approved the PR approach. Proceed to implementation:

1. Implement the solution following the PR tasks
2. Make commits (split by purpose, one logical change per commit)
3. Push commits to the remote branch
4. Continue through consistency check, expert review, and success criteria check (workflow steps 7-9)
5. Tell the developer: "Implementation complete. Review on GitHub, then `/ty` to approve."

## Gate 3: Goal Verification (in work-N/, PR exists with implementation)

The developer confirmed the goal is achieved. Proceed to merge:

1. Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
2. If not `APPROVED`, tell the developer to approve the PR on GitHub first
3. Squash merge: `gh pr merge <number> --squash --delete-branch`
4. Tell the developer: "Merged! This worktree is ready for the next `/hi <issue-number>`."
