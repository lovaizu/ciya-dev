You are a development workflow assistant helping the developer safely interrupt and save work in progress.

## Usage

Show this to the developer:

```
/bb              Save current work state and prepare to switch to another issue
```

## Steps

1. Detect the current branch: `git branch --show-current`
2. Detect the worktree type: `basename "$(git rev-parse --show-toplevel)"`
   - `main` → main/ worktree
   - Otherwise → work-N/ worktree (includes `work-*`, `issue-*`, or any non-main name)
3. If in main/, tell the developer: "/bb is for interrupting work in work-N/ worktrees."

4. Check for uncommitted changes: `git status --porcelain`
   - If changes exist, ask the developer: "You have uncommitted changes. Commit them, stash them, or leave as-is?"
   - Follow their instruction before proceeding

5. Identify the associated issue number:
   - Check the PR for this branch: `gh pr list --head <branch-name> --json number,body`
   - Extract the issue number from the PR body ("Closes #NNN")
   - If no PR, try patterns from the branch name: `issue-N`, `N-description`, or trailing digits
   - If no number can be extracted, ask the developer

6. Determine the work records directory: `.ciya/issues/<zero-padded-5-digit-number>/`
   - Create the directory if it doesn't exist

7. Write `resume.md` with the following structure:

<example>
# Resume: Issue #42

## Branch
dark-mode-support

## Associated
- Issue: https://github.com/.../issues/42
- PR: https://github.com/.../pull/43

## Current Workflow Step
Step 6: Implementation (Gate 2 passed, implementing tasks)

## In Progress
- Implementing CSS variable system for theme switching
- Completed: task 1 (theme context), task 2 (toggle component)

## Next Steps
- Complete task 3: apply theme variables to all components
- Run tests after implementation

## Blockers / Open Questions
- None currently
</example>

8. Update `design.md` if design decisions were made during this session

9. Commit and push the work records (follow commit conventions in `git-conventions.md`):
   ```
   git add .ciya/issues/<5-digit-number>/
   git commit -m "Save work records for issue #NNN

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   git push
   ```
   If `git push` fails, report the error and suggest remediation (e.g., set upstream with `-u`)

10. Tell the developer:
    - "Work state saved to `.ciya/issues/<5-digit-number>/resume.md`"
    - "Resume anytime with `/hi <number>` in any work-N/ worktree"
