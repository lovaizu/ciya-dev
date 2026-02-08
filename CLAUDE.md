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
6. **Implementation** - Create an empty commit (`git commit --allow-empty`) and push the branch to create the PR (`gh pr create`) first, then write code and make commits
7. **Consistency check** - Verify all issue and PR sections are consistent with each other: issue title goal matches Benefit, each SC maps to a Benefit, PR Approach addresses each Pain, PR Tasks are traceable to Approach. If any section was updated during earlier steps, re-check all
8. **Expert review** - Identify the technical domain of the deliverable and simulate a review from a domain expert perspective. Evaluate correctness, best practices, and potential issues. Fix any problems found, then append the review results to the PR body
9. **Success Criteria check** - Check the Issue's Success Criteria and update them, address any unmet criteria. Prefer execution over inspection; use inspection only when execution is not feasible. Append the check results to the PR body
10. **PR review** - Request review, address feedback
11. **Approval** - Wait for developer approval of the PR
12. **Merge** - Verify the PR is approved (`gh pr view <number> --json reviewDecision` must return `APPROVED`). If not `APPROVED`, confirm with the developer before proceeding. Squash-merge to main (`gh pr merge <number> --squash`). The developer will clean up the worktree and branch using `bb.sh`
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

Execute the criterion as written first. If direct execution is truly not possible, explain why before falling back to alternatives.

| Criterion | Status | Method | Judgment |
|-----------|--------|--------|----------|
| {SC from the issue} | {OK/NG} | {Executed/Inspected} | {See format below} |

Judgment format by method:
- Executed: "Ran {what}. Got {result}. {Why this means OK or NG}"
- Inspected: "Cannot execute because {reason}. Inspected {what instead}. {Why this means OK or NG}"
```

## Worktree

This repository uses a bare repo + worktree structure to enable parallel Claude Code instances.

### Directory Layout

```
ciya-dev/
├── .bare/             # bare repository (metadata only)
├── .git               # pointer file to .bare
├── main/              # main branch worktree (always present)
├── feature-branch/    # work branch worktree
└── another-branch/    # work branch worktree
```

### Setup (first time)

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/up.sh | bash
```

### Creating a Work Worktree

```bash
cd /path/to/ciya-dev
./main/scripts/hi.sh <branch-name>
```

### Removing a Work Worktree

```bash
cd /path/to/ciya-dev
./main/scripts/bb.sh <branch-name-or-path>
```

### Rules

- Worktree directory name must match the branch name
- The `main` worktree must always be present — it is the base for running scripts
- Always run `hi.sh` / `bb.sh` from the `ciya-dev` root directory
- Do not modify the `main` worktree directly — always work in a branch worktree

## PR Review Process

- Continue addressing reviews until the PR is approved
- Search for unresolved review comments and work through them one by one
- If something is unclear, reply to the review comment asking for clarification
- When making a fix: commit, push, then reply to the review comment
- Include a link to the commit in the reply when a fix is made
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in review replies
- Do NOT resolve review comments — the author of the comment will resolve them
- Do NOT create new comments on the PR — only reply to existing review comments
