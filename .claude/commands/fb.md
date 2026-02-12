Address feedback on the current branch.

1. Find the PR for the current branch: `gh pr list --head <branch-name> --json number,url,body`
2. Extract the associated issue number from the PR body (look for "Closes #N")

## Issue feedback

3. If an issue number was found, fetch issue comments: `gh api repos/{owner}/{repo}/issues/{number}/comments`
4. Identify developer comments that have not been responded to (no subsequent comment from the agent)
5. Work through unanswered issue comments one by one:
   - If something is unclear, reply on the issue asking for clarification
   - When making a fix: update the relevant content (e.g., issue body via `gh issue edit`), commit if needed, push, then reply on the issue with what was changed
   - Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies

## PR feedback

6. Fetch PR review comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
7. Also check PR review threads for unresolved conversations: `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
8. Work through unresolved PR comments one by one, following the PR Review Process in CLAUDE.md:
   - If something is unclear, reply asking for clarification
   - When making a fix: commit, push, then reply to the review comment with a link to the commit
   - Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies
   - Do NOT resolve review comments — the author will resolve them
   - Do NOT create new comments — only reply to existing ones

9. After addressing all feedback, report what was done
