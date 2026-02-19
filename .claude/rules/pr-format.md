# PR Format

The PR defines the means to achieve the Success Criteria. It is reviewed at Gate 2 (Approach): can Approach and Steps achieve all SC?

**Title:** A concise title describing the purpose of the work

**Body:**

```
Closes #{issue number}

## Approach

| SC | Approach |
|----|----------|
| SC1: {condition from issue} | {Why this method — the means to achieve this SC} |
| SC2: {condition from issue} | {Why this method} |

- Every SC from the issue must appear in the table — an uncovered SC will not be achieved
- Explain why this approach was chosen over alternatives when the choice is non-obvious

## Steps

### {Approach for SC1}
- [ ] {Step}
- [ ] {Step}

### {Approach for SC2}
- [ ] {Step}
- [ ] {Step}

- Steps are grouped by the Approach they implement
- Each step must be a concrete, actionable work item
- Use checkboxes to track progress

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
