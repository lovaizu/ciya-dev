# Project Rules

## Language

All communication, documentation, commit messages, PR descriptions, issue descriptions, and review comments must be written in English.

## Workflow

Follow this workflow for every task:

1. **Hearing** - Gather requirements from the developer, ask clarifying questions
2. **Issue creation** - Propose and create a GitHub issue
3. **Approval** - Wait for developer approval of the issue. If denied, revise based on feedback and re-propose
4. **PR description** - Draft the PR title and body
5. **Approval** - Wait for developer approval of the PR description. If denied, revise based on feedback and re-propose
6. **Implementation** - Create a worktree (`git fetch origin && git worktree add <branch-name> -b <branch-name> origin/main`), write code, make commits, push the branch, and create the PR (`gh pr create`)
7. **Consistency check** - Verify all issue and PR sections are consistent with each other: issue title goal matches Benefit, each SC maps to a Benefit, PR Approach addresses each Pain, PR Tasks are traceable to Approach. If any section was updated during earlier steps, re-check all
8. **Expert review** - Identify the technical domain of the deliverable and simulate a review from a domain expert perspective. Evaluate correctness, best practices, and potential issues. Fix any problems found, then append the review results to the PR body
9. **Success Criteria check** - Check the Issue's Success Criteria and update them, address any unmet criteria. Append the check results to the PR body
10. **PR review** - Request review, address feedback
11. **Approval** - Wait for developer approval of the PR
12. **Merge** - Verify the PR is approved (`gh pr view <number> --json reviewDecision` must return `APPROVED`). If not `APPROVED`, confirm with the developer before proceeding. Merge to main (using squash merge), remove the worktree (`git worktree remove <branch-name>`), delete the work branch, and run `git fetch --prune` to clean up stale remote tracking branches
13. **Done**

## Issue Format

**Title:** Use user story format: "As a [role], I want [goal] so that [benefit]"

- [goal] must be the user's desired outcome, not a technical means or implementation detail
- Good: "I want to run multiple tasks in parallel"
- Bad: "I want a bare repo + worktree structure"

**Body:**

```
## Situation
{Concrete facts and observed circumstances}

## Pain
{Who is affected and what problem they face}

## Benefit
{Who benefits and how, once resolved}

- Use "[who] can [what]" form
- Good: "Developers can run multiple tasks in parallel"
- Bad: "Development throughput is improved"

## Success Criteria
- [ ] {Condition that verifies the Benefit is achieved}
- [ ] {Condition}

- Must verify Benefit achievement, not describe tasks to complete
- Good: "A developer can create a worktree and start parallel work by following the documented steps"
- Bad: "CLAUDE.md has a Worktree section with setup instructions"
```

## Branch Strategy

- Create a worktree from the latest `main`: `git fetch origin && git worktree add <branch-name> -b <branch-name> origin/main`
- Branch name must describe the user's goal, not the implementation approach, using only hyphen-separated words
- Good: `parallel-claude-code-tasks`, `faster-test-feedback`
- Bad: `setup-bare-repo-worktree`, `refactor-module-to-class`

## Commit Conventions

- Split commits by purpose (one logical change per commit)
- Commit title must describe the purpose of the change
- Include `Co-Authored-By` in the commit body to indicate agent work:
  ```
  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  ```

## PR Format

**Title:** A concise title describing the purpose of the work

**Body:**

```
Closes #{issue number}

## Approach
{Solution strategy and design decisions}

## Tasks
- [ ] {Task}
- [ ] {Task}
- [ ] {Task}

## Expert Review

| Feedback | Improvement | Decision |
|----------|-------------|----------|
| {What the expert found} | {Proposed fix or change} | {Accepted/Rejected + reason} |

## Success Criteria Check

| Criterion | Status | Method | Evidence |
|-----------|--------|--------|----------|
| {SC from the issue} | {OK/NG} | {Executed/Inspected} | {What was done and what was observed} |
```

## Worktree

This repository uses a bare repo + worktree structure to enable parallel Claude Code instances.

### Directory Layout

```
ciya-dev/
├── .bare/             # bare repository (metadata only)
├── .git               # pointer file to .bare
├── feature-branch/    # work branch worktree
└── another-branch/    # work branch worktree
```

### Setup (first time)

```bash
mkdir ciya-dev && cd ciya-dev
git clone --bare https://github.com/lovaizu/ciya-dev.git .bare
echo "gitdir: ./.bare" > .git
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
```

### Creating a Work Worktree

```bash
cd /path/to/ciya-dev
git fetch origin && git worktree add <branch-name> -b <branch-name> origin/main
```

### Removing a Work Worktree

```bash
cd /path/to/ciya-dev
git worktree remove <branch-name>
git branch -d <branch-name>
```

### Rules

- Worktree directory name must match the branch name
- Do not create a worktree for `main` — main is managed as a bare ref only
- Always branch from `origin/main` after `git fetch origin` to ensure the latest remote state
- Run `git worktree list` to check active worktrees before creating a new one

## PR Review Process

- Continue addressing reviews until the PR is approved
- Search for unresolved review comments and work through them one by one
- If something is unclear, reply to the review comment asking for clarification
- When making a fix: commit, push, then reply to the review comment
- Include a link to the commit in the reply when a fix is made
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in review replies
- Do NOT resolve review comments — the author of the comment will resolve them
- Do NOT create new comments on the PR — only reply to existing review comments
