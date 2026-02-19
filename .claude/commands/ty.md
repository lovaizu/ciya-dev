---
disable-model-invocation: true
---

You are a development workflow assistant managing approval gates and workflow progression.

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

Use this decision tree:

1. Detect the worktree type: `basename "$(git rev-parse --show-toplevel)"`
2. If `main` → **Gate 1**
3. Otherwise (any non-main worktree):
   a. Find PR: `gh pr list --head $(git branch --show-current) --json number,title,body,url,reviewDecision`
   b. If no PR exists → tell the developer: "No PR found. Run `/hi <number>` first."
   c. Check implementation status: `git log origin/main..HEAD --oneline`
      - If no commits or only an empty initial commit → **Gate 2**
      - If implementation commits exist → **Gate 3**

If the gate cannot be determined, tell the developer which gate could not be identified and ask them to clarify.

## Gate 1: Goal (in main/ worktree)

The developer approved the issue.

1. Tell the developer: "Issue approved. Run `/hi <number>` in a work-N/ worktree to start implementation."

<example>
Developer: /ty
Agent: Gate 1 — Goal approved.
       Run `/hi 42` in a work-N/ worktree to start implementation.
</example>

## Gate 2: Approach (in work-N/, PR exists, no implementation yet)

The developer approved the PR approach. Proceed to implementation:

1. Follow the workflow steps in `workflow.md` starting from step 6 (Implementation):
   - Implement the solution following the PR tasks
   - Make commits (split by purpose, one logical change per commit)
   - Push commits to the remote branch
2. After implementation, continue through steps 7-9:
   - Consistency check, expert review, success criteria check
3. Tell the developer: "Implementation complete. Review on GitHub, then `/ty` to approve."

<example>
Developer: /ty
Agent: Gate 2 — Approach approved. Starting implementation.
       [implements, commits, pushes, runs checks]
       Implementation complete. Review on GitHub, then `/ty` to approve.
</example>

## Gate 3: Goal Verification (in work-N/, PR with implementation)

The developer confirmed the goal is achieved. Proceed to merge:

1. Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
2. If not `APPROVED`, tell the developer: "Please approve the PR on GitHub first, then run `/ty` again."
3. Squash merge: `gh pr merge <number> --squash`
4. Detach HEAD and delete branches: `git checkout --detach && git push origin --delete <branch-name> && git branch -D <branch-name>`
5. Clean up work records: delete `resume.md` from the work records directory (`.ciya/issues/nnnnn/`) if it exists, since the issue is now complete and the saved state is no longer needed
6. Tell the developer: "Merged! This worktree is ready for the next `/hi <number>`."

<example>
Developer: /ty
Agent: Gate 3 — Goal verification approved.
       PR #43 is approved. Merging...
       Merged! This worktree is ready for the next `/hi <number>`.
</example>
