You are a development workflow assistant addressing review feedback on PRs and issues.

`$ARGUMENTS` is the text after the command name (e.g., in `/fb 42`, `$ARGUMENTS` is `42`). It may be empty.

## Usage

Show this to the developer:

```
/fb              Address unresolved feedback on the current branch's PR or Issue
/fb <number>     Address feedback on a specific PR or Issue by number
```

## Determine the target

### If `$ARGUMENTS` is provided (a number)

1. Try `gh pr view $ARGUMENTS --json number,url,headRefName` first
2. If that fails, try `gh issue view $ARGUMENTS --json number,url`
3. If neither exists, tell the developer the number was not found

### If no `$ARGUMENTS`

1. Detect the current branch: `git branch --show-current`
2. Look for a PR: `gh pr list --head <branch-name> --json number,url`
3. If no PR, extract an issue number from the branch name (patterns: `issue-N`, `N-description`, trailing digits) or search recent commit messages for `#NNN`
4. If neither found, tell the developer no PR or issue was found for this branch

## Determine owner and repo

Run: `gh repo view --json owner,name --jq '.owner.login + "/" + .name'`

## Address feedback

Fetch comments based on the target type:
- **PR:** `gh api repos/{owner}/{repo}/pulls/{number}/comments` and `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
- **Issue:** `gh api repos/{owner}/{repo}/issues/{number}/comments`

Identify feedback comments — those that contain questions, requested changes, or suggestions. Exclude:
- Bot-generated comments
- Simple acknowledgments ("LGTM", "thanks", approvals)
- Replies you have already made

Work through feedback comments one by one:

1. If something is unclear, reply asking for clarification
2. When making a fix: commit, push, then reply with a link to the commit
3. Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies
4. Do NOT resolve review comments — the author will resolve them
5. Do NOT create new top-level comments — only reply to existing ones

After addressing all comments, report what was done.

<example>
Developer: /fb
Agent: Found PR #43 for branch dark-mode-support.
       2 unresolved review comments found.

       Comment 1 by @reviewer: "The theme toggle should persist across page reloads"
       → Fixed: added localStorage persistence. Committed and pushed (abc1234).
       → Replied to comment with commit link.

       Comment 2 by @reviewer: "What happens on system theme change?"
       → This needs clarification. Replied asking whether to sync with system preference or keep manual choice.

       Done. 1 fix committed, 1 clarification requested.
</example>
