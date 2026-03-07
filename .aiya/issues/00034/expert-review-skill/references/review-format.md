# Review File Format

Each domain expert produces one file named `{domain}-expert-review.md` in the work records directory.

Use the domain name in kebab-case for the filename prefix:
- Shell scripting -> `shell-scripting-expert-review.md`
- Prompt engineering -> `prompt-engineering-expert-review.md`
- CI/CD -> `cicd-expert-review.md`
- Technical writing -> `technical-writing-expert-review.md`

## Template

```markdown
# {Domain} Expert Review

## Scope

| File | Description |
|------|-------------|
| {relative path from repo root} | {brief description of what changed in this file} |

## Evaluation

| # | Finding | Severity | Improvement |
|---|---------|----------|-------------|
| 1 | {specific issue found} | {High/Medium/Low} | {concrete proposed fix} |

## Decision

| # | Decision | Reason |
|---|----------|--------|
| 1 | {Accepted/Rejected} | {rationale for the decision} |
```

## Field Definitions

### Scope Table

- **File**: Relative path from the repository root (e.g., `lib/statusline.sh`). Use the path as shown by `git diff --name-only`.
- **Description**: What changed in this file in this branch. Focus on the nature of the change (e.g., "Added input validation for branch names"), not a generic file description.

### Evaluation Table

- **#**: Sequential number starting from 1. Use this number to cross-reference with the Decision table.
- **Finding**: The specific issue identified. State what is wrong and where. A finding must be specific enough that a developer can locate and fix the issue without additional investigation.
  - Good: "Line 42: `eval "$user_input"` executes arbitrary input without sanitization"
  - Bad: "Code could be improved"
- **Severity**:
  - **High**: Correctness bugs, security vulnerabilities, data loss risks, broken functionality
  - **Medium**: Reliability issues, maintainability problems, performance concerns, missing error handling
  - **Low**: Style inconsistencies, naming conventions, minor readability improvements
- **Improvement**: A concrete, actionable fix. Describe the change to make, not just the problem.
  - Good: "Replace `eval` with a case statement that matches allowed commands"
  - Bad: "Consider sanitizing input"

### Decision Table

- **#**: Matches the finding number from the Evaluation table.
- **Decision**: Either `Accepted` or `Rejected`.
- **Reason**:
  - For Accepted: Brief confirmation that the finding is valid (e.g., "Fixes real security vulnerability")
  - For Rejected: The specific reason for rejection (e.g., "False positive: variable is always set by the caller", "Acceptable trade-off: readability over minor performance gain", "Out of scope for this change")
