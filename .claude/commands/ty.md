---
disable-model-invocation: true
---

The developer has approved. Detect which approval gate this is and proceed.

## Usage

Show this to the developer:

```
/ty              Approve the current workflow gate (issue, PR description, or PR)
```

## Detect the gate

1. Find the PR for the current branch: `gh pr list --head <branch-name> --json number,title,body,url`
2. Determine the current approval gate:

## Gate: Issue approved (no PR exists yet)

Proceed to step 4 of the workflow: draft the PR title and body, and present it to the developer.

## Gate: PR description approved (PR not yet created)

Proceed to step 6 of the workflow: implement the solution, make commits, push the branch, and create the PR with `gh pr create`. Then continue through consistency check, expert review, and success criteria check.

## Gate: PR approved (PR exists and is approved)

Proceed to step 12 of the workflow:
1. Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
2. Squash merge: `gh pr merge <number> --squash`
3. Tell the developer to clean up by running `bb.sh <branch-name>` from the main worktree
