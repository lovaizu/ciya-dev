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
6. **Implementation** - Write code, make commits, push the branch
7. **Expert review** - Identify the technical domain of the deliverable and simulate a review from a domain expert perspective. Evaluate correctness, best practices, and potential issues. Fix any problems found, then append the review results to the PR body
8. **Success Criteria check** - Check the Issue's Success Criteria and update them, address any unmet criteria. Append the check results to the PR body
9. **PR review** - Request review, address feedback
10. **Approval** - Wait for developer approval of the PR
11. **Merge** - Merge to main (using squash merge), delete the work branch, and run `git fetch --prune` to clean up stale remote tracking branches
12. **Done**

## Issue Format

**Title:** Use user story format: "As a [role], I want [goal] so that [benefit]"

**Body:**

```
## Situation
{Concrete facts and observed circumstances}

## Pain
{Who is affected and what problem they face}

## Benefit
{Who benefits and how, once resolved}

## Success Criteria
- [ ] {Specific, measurable success condition}
- [ ] {Condition}
- [ ] {Condition}
```

## Branch Strategy

- Always branch from the latest `main`
- Branch name must describe the purpose of the work using only hyphen-separated words
- Examples: `create-claude-md`, `add-user-authentication`, `fix-login-error`

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
{Review results appended after expert review step}

## Success Criteria Check
{Check results appended after success criteria check step}
```

## PR Review Process

- Continue addressing reviews until the PR is approved
- Search for unresolved review comments and work through them one by one
- If something is unclear, reply to the review comment asking for clarification
- When making a fix: commit, push, then reply to the review comment
- Include a link to the commit in the reply when a fix is made
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in review replies
- Do NOT resolve review comments — the author of the comment will resolve them
- Do NOT create new comments on the PR — only reply to existing review comments
