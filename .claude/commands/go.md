Detect the current branch and resume or start the workflow.

## Usage

Show this to the developer:

```
/go              Resume the workflow on the current branch (or start hearing if on main)
/go <number>     Open a specific issue or PR by number and resume its workflow
```

## If `$ARGUMENTS` is provided (a number)

The argument is an issue or PR number. Determine what it refers to:

1. Try `gh pr view $ARGUMENTS --json number,title,url,headRefName,body,state` first
2. If that fails, try `gh issue view $ARGUMENTS --json number,title,url,body,state`
3. If neither exists, tell the developer the number was not found

### If the number is a PR

- Read the PR details (title, body, branch, state)
- Detect the current branch with `git branch --show-current`
- If on the PR's branch: determine workflow status (same logic as "If on a feature branch" below) and resume
- If on main or a different branch: tell the developer to switch to the PR's branch, suggesting `hi.sh <branch-name>` if the worktree doesn't exist yet

### If the number is an issue

- Read the issue details (title, body, state)
- Detect the current branch with `git branch --show-current`
- If on main: suggest creating a worktree with `hi.sh <branch-name>` (derive branch name from the issue's goal)
- If on a feature branch:
  - First check if a PR already exists for this branch: `gh pr list --head <branch-name> --json number,title,url`
  - If a PR exists: determine workflow status (same logic as "If on a feature branch" below) and resume
  - If no PR exists: treat the issue as approved (step 3 done) and resume from step 4 (PR description drafting). Read the issue body to use as context for drafting the PR

## If no `$ARGUMENTS` (no number provided)

### If on main (or bare repo root)

Ask the developer what they want to work on, then follow the workflow from step 1 (Hearing).

### If on a feature branch

1. Identify the branch name and find the associated issue and PR using `gh`:
   - `gh pr list --head <branch-name> --json number,title,url`
   - If no PR exists, check `gh issue list` for a related issue
2. Read the full commit history on this branch: `git log origin/main..<branch-name> --oneline`
3. Determine which workflow step was last completed by checking:
   - Does an issue exist? (step 2 done)
   - Does a PR exist on GitHub? (step 6 done — PR is created during Implementation)
   - Does the PR body contain Expert Review / SC Check sections? (step 8-9 done)
   - Are there pending review comments? (step 10 in progress)
   - If the issue exists but no PR is on GitHub, the workflow is between steps 3-5 — ask the developer which step to resume from
4. Report the current status to the developer and resume the workflow from the next step
