Interrupt current work and save state for later resumption.

## Usage

Show this to the developer:

```
/bb              Save current work state and prepare to switch to another issue
```

## Steps

1. Detect the current branch: `git branch --show-current`
2. If on main, tell the developer: "/bb is for interrupting work in work-N/ worktrees"

3. Identify the associated issue number:
   - Check the PR for this branch: `gh pr list --head <branch-name> --json number,body`
   - Extract the issue number from the PR body ("Closes #NNN")
   - If no PR, try to extract from the branch name (e.g., `issue-29` → 29)
   - If no issue number found, ask the developer

4. Determine the work records directory: `.ciya/issues/<5-digit-number>/`
   - Create the directory if it doesn't exist

5. Write `resume.md` with:
   - Current branch name
   - Associated issue and PR numbers/URLs
   - Current workflow step (which gate was last passed)
   - What was in progress (what you were working on)
   - What needs to be done next
   - Any blockers or open questions

6. Update `design.md` if design decisions were made during this session

7. Commit the work records:
   ```
   git add .ciya/issues/<5-digit-number>/
   git commit -m "Save work records for issue #NNN"
   git push
   ```

8. Tell the developer:
   - "Work state saved to .ciya/issues/<5-digit-number>/resume.md"
   - "Resume anytime with `/hi <issue-number>` in any work-N/ worktree"
