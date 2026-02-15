# PR Format

The PR defines the means to achieve the goal. It is reviewed at Gate 2 (Approach): can Approach and Tasks achieve Benefit through SC?

**Title:** A concise title describing the purpose of the work

**Body:**

```
Closes #{issue number}

## Approach
{Solution strategy and design decisions}

- Must address each Pain from the issue — an unaddressed Pain is an unresolved problem

## Tasks
- [ ] {Task} → SC: {which Success Criteria this achieves}
- [ ] {Task} → SC: {which Success Criteria this achieves}
- [ ] {Task} → SC: {which Success Criteria this achieves}

- Each Task must trace to one or more SC — a Task with no SC link is unnecessary
- Each SC must be covered by at least one Task — an uncovered SC will not be achieved
- Reference SC by quoting its key phrase (e.g., → SC: "README exists with diagram")

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

# PR Review Process

- Continue addressing reviews until the PR is approved
- Search for unresolved review comments and work through them one by one
- If something is unclear, reply to the review comment asking for clarification
- When making a fix: commit, push, then reply to the review comment
- Include a link to the commit in the reply when a fix is made
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in review replies
- Do NOT resolve review comments — the author of the comment will resolve them
- Do NOT create new comments on the PR — only reply to existing review comments
