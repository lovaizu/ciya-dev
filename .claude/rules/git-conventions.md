# Git Conventions

## Branch Strategy

- Create a branch from the latest `main`: `git fetch origin && git switch -c <branch-name> origin/main`
- Branch name must describe the user's goal, not the implementation approach, using only hyphen-separated words
- Good: `parallel-claude-code-tasks`, `faster-test-feedback`
- Bad: `setup-bare-repo-worktree`, `refactor-module-to-class`

## Commit Conventions

- Split commits by purpose (one logical change per commit)
- Commit title must describe the purpose of the change
- Do not include absolute paths (starting with `/`) in commit messages — the sandbox hook will block them
- Include `Co-Authored-By` in the commit body to indicate agent work:
  ```
  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  ```
