---
disable-model-invocation: true
---

The developer has approved. Detect which approval gate this is and proceed.

1. Find the PR for the current branch: `gh pr list --head <branch-name> --json number,title,body,url`
2. Determine the current approval gate:

## Gate: Goal approved (issue exists, no PR yet)

Proceed to step 4 of the workflow: draft the PR title and body, create an empty commit, push the branch, create the PR with `gh pr create`, and present the GitHub PR link to the developer.

## Gate: Approach approved (PR exists, only empty commit)

Proceed to step 6 of the workflow: implement the solution, make commits, and push to the remote branch. Then continue through consistency check, expert review, and success criteria check.

## Gate: Goal verified (PR exists and is approved)

Proceed to step 11 of the workflow:
1. Verify approval: `gh pr view <number> --json reviewDecision` must return `APPROVED`
2. Squash merge: `gh pr merge <number> --squash`
3. Tell the developer to clean up by running `bb.sh <branch-name>` from the main worktree
