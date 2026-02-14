Start new work or resume existing work on an issue.

## Usage

Show this to the developer:

```
/hi                 In main/: start hearing → create issue
                    In work-N/: show status and available issues
/hi <issue-number>  In work-N/: start or resume work on the specified issue
```

## Detect context

1. Detect the current branch: `git branch --show-current`
2. Detect the worktree directory name from the current working directory

## In main/ worktree (no arguments)

Start the workflow from step 1 (Hearing):

1. Ask the developer to describe their goal — what they want to achieve and why
2. Ask clarifying questions until the goal and scope are clear
3. Draft the issue title in user story format (see `issue-format.md`)
4. Draft the issue body with Situation, Pain, Benefit, and Success Criteria
5. Create the issue on GitHub: `gh issue create`
6. Tell the developer the issue URL and say: "Review on GitHub. Use comments for feedback, then `/ty` to approve."
7. Wait for `/ty` (Gate 1: Goal) or `/fb` (address feedback comments)

## In work-N/ worktree with `$ARGUMENTS` (issue number)

Start or resume work on the specified issue:

1. Fetch the issue: `gh issue view $ARGUMENTS --json number,title,url,body,state`
2. If the issue does not exist, tell the developer
3. Check for work records: look for `.ciya/issues/` + zero-padded 5-digit issue number (e.g., `.ciya/issues/00029/`)
4. Check if a PR already exists: `gh pr list --head <branch-pattern> --json number,title,url,headRefName`

### If resuming (work records or PR exist)

1. Read `resume.md` from the work records directory if it exists
2. Read `design.md` if it exists
3. If a PR exists, read its details
4. Report the current status to the developer and resume from where work was left off

### If starting fresh

1. Create a branch from origin/main: `git fetch origin && git switch -c <branch-name> origin/main`
   - Branch name: derive from the issue goal per `git-conventions.md`
2. Create the work records directory: `.ciya/issues/<5-digit-number>/`
3. Create `design.md` with initial design notes
4. Proceed to PR description drafting (workflow step 4)

## In work-N/ worktree with no arguments

1. Show the current branch and any associated issue/PR
2. List recent open issues: `gh issue list --limit 5`
3. Tell the developer: "Run `/hi <issue-number>` to start or resume work on an issue"

## In main/ worktree with `$ARGUMENTS`

Tell the developer: "Switch to a work-N/ worktree to start implementation. Run `/hi <issue-number>` there."
