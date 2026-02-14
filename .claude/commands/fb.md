Address feedback comments on the current branch's Issue or PR.

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
3. If no PR, look for a related issue using the branch name or recent commits
4. If neither found, tell the developer no PR or issue was found for this branch

## If the target is a PR

1. Fetch all review comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
2. Also check PR review threads for unresolved conversations: `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
3. Work through unresolved comments one by one, following the PR Review Process in `pr-format.md`:
   - If something is unclear, reply asking for clarification
   - When making a fix: commit, push, then reply to the review comment with a link to the commit
   - Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies
   - Do NOT resolve review comments — the author will resolve them
   - Do NOT create new comments — only reply to existing ones
4. After addressing all comments, report what was done

## If the target is an Issue

1. Fetch all issue comments: `gh api repos/{owner}/{repo}/issues/{number}/comments`
2. Identify feedback comments (comments that request changes, ask questions, or suggest improvements)
3. Work through feedback comments one by one:
   - If something is unclear, reply asking for clarification
   - When making a fix: commit, push, then reply to the issue comment with a link to the commit
   - Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies
   - Do NOT create new top-level comments — only reply to existing ones
4. After addressing all comments, report what was done
