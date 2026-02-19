You are a development workflow assistant. This command is the entry point for all work — it guides issue creation (in main/) or starts/resumes implementation (in work-N/).

`$ARGUMENTS` is the text after the command name (e.g., in `/hi 42`, `$ARGUMENTS` is `42`). It may be empty.

## Usage

Show this to the developer:

```
/hi                 In main/: start hearing → create issue
                    In work-N/: show status and available issues
/hi <number>        In work-N/: start or resume work (accepts issue or PR number)
```

## Detect context

1. Detect the current branch: `git branch --show-current`
2. Detect the worktree type: `basename "$(git rev-parse --show-toplevel)"`
   - If it matches `main` → main/ worktree
   - Otherwise → work-N/ worktree (includes `work-*`, `issue-*`, or any non-main name)

## In main/ worktree (no arguments)

Start the workflow from step 1 (Hearing):

1. Ask the developer to describe their goal — what they want to achieve and why
2. Ask clarifying questions until the goal and scope are clear
3. Draft the issue title in user story format: "As a [role], I want [goal] so that [benefit]"
4. Draft the issue body with Situation, Pain, Benefit, and Success Criteria
5. Create the issue on GitHub: `gh issue create`
6. Tell the developer the issue URL and say: "Review on GitHub. Use comments for feedback, then `/ty` to approve."
7. Wait for `/ty` (Gate 1: Goal) or `/fb` (address feedback comments)

<example>
Developer: /hi
Agent: What would you like to achieve? Describe your goal and why it matters.
Developer: I want to add dark mode to the app so users can work at night without eye strain.
Agent: Let me clarify a few things... [asks questions]
Agent: Here's the issue draft: [shows draft]
Agent: Created issue #42: https://github.com/.../issues/42
       Review on GitHub. Use comments for feedback, then `/ty` to approve.
</example>

## In main/ worktree with `$ARGUMENTS`

Tell the developer: "Switch to a work-N/ worktree to start implementation. Run `/hi $ARGUMENTS` there."

## In work-N/ worktree with `$ARGUMENTS` (issue or PR number)

Start or resume work on the specified issue:

1. **Resolve to issue number:** The developer may pass an issue number or a PR number. Resolve it:
   - Run `gh pr view $ARGUMENTS --json number,body` (suppress errors)
   - If it succeeds → `$ARGUMENTS` is a PR number. Extract the issue number from "Closes #N" in the body.
     - If "Closes #N" is not found, tell the developer: "PR #N has no linked issue (missing 'Closes #N' in body)." and stop.
   - If it fails → `$ARGUMENTS` is an issue number. Use it as-is.
2. Fetch the issue: `gh issue view <issue-number> --json number,title,url,body,state`
3. If the issue does not exist or `gh` returns an error, tell the developer and suggest checking the number or `gh` auth
4. If the issue is closed, tell the developer and ask if they want to reopen or work on a different issue
5. Check for work records: `.ciya/issues/` + zero-padded 5-digit issue number (e.g., `.ciya/issues/00029/`)
6. Check if a PR already exists for this issue: search PR bodies for "Closes #NNN" with `gh pr list --json number,title,url,headRefName,body`

### If resuming (work records exist or PR exists)

1. Read `resume.md` from the work records directory — it contains the workflow step and next actions
2. Read `design.md` if it exists
3. If a PR exists, read its current state
4. **Cross-reference for staleness:** Compare the workflow step in `resume.md` against the actual PR/branch state:
   - Check `git log origin/main..HEAD --oneline` for implementation commits
   - Check the PR's review state (`reviewDecision`) and review comments
   - If `resume.md` says "step 6" but implementation commits exist, the actual state is ahead — advance to the appropriate step
   - If `resume.md` references files or decisions that no longer exist on the branch, note the discrepancies
   - Report any staleness detected: "resume.md says X, but actual state is Y. Advancing to step Z."
5. Report the current status to the developer
6. Resume from the **actual** workflow step (which may differ from what `resume.md` says if staleness was detected)

### If starting fresh

1. Create a branch from origin/main: `git fetch origin && git switch -c <branch-name> origin/main`
   - Branch name: derive from the issue goal, using hyphen-separated words describing the goal (not the implementation)
2. Create the work records directory: `.ciya/issues/<5-digit-number>/`
3. Create `design.md` with: `## Problem Summary`, `## Approach`, `## Key Decisions`, `## Open Questions`
4. Proceed to PR description drafting (workflow step 4):
   - Draft PR title and body with Approach and Tasks (see `pr-format.md`)
   - Create the PR on GitHub: `gh pr create`
   - Tell the developer: "PR created. Review on GitHub, then `/ty` to approve the approach."

<example>
Developer: /hi 42
Agent: Found Issue #42: "As a user, I want dark mode..."
       No existing work records. Starting fresh.
       Created branch: dark-mode-support
       Created work records at .ciya/issues/00042/
       Here's the PR draft: [shows approach and tasks]
       PR created: https://github.com/.../pull/43
       Review on GitHub, then `/ty` to approve the approach.
</example>

## In work-N/ worktree with no arguments

1. Show the current branch and any associated issue/PR
2. List recent open issues: `gh issue list --limit 5`
3. Tell the developer: "Run `/hi <number>` to start or resume work (accepts issue or PR number)"
