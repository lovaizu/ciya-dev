Address PR review feedback on the current branch.

1. Find the PR for the current branch: `gh pr list --head <branch-name> --json number,url`
2. Fetch all review comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
3. Also check PR review threads for unresolved conversations: `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
4. Work through unresolved comments one by one, following the PR Review Process in CLAUDE.md:
   - If something is unclear, reply asking for clarification
   - When making a fix: commit, push, then reply to the review comment with a link to the commit
   - Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in replies
   - Do NOT resolve review comments — the author will resolve them
   - Do NOT create new comments — only reply to existing ones
5. After addressing all comments, report what was done
