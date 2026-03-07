---
name: expert-review
description: Evaluates implementation quality from domain expert perspectives
  (shell scripting, prompt engineering, CI/CD, technical writing) by reviewing
  changed files against best practices. Use when the user says "expert review",
  "review my code", "check quality before delivery", "run domain review",
  "review changes from expert perspective", "evaluate best practices",
  "review implementation quality", or asks for a quality check before merging.
  Also use when user wants to "find issues in my changes", "check for
  best practice violations", or "review before PR". Do NOT use for general
  code review comments on a PR (use GitHub PR review) or for running linters
  and formatters. Produces structured review files with findings, severity
  ratings, and improvement decisions.
---

# Expert Review

Evaluate implementation quality from domain expert perspectives before delivery. Domain experts catch issues that generalists miss — a shell scripting expert spots portability problems, a prompt engineer spots instruction ambiguity.

## Workflow

### Step 1: Identify changed files

List all changed files compared to the main branch:

```bash
git diff origin/main --name-only
```

If no files are changed, inform the user and stop — there is nothing to review.

### Step 2: Categorize files by domain

Assign each changed file to one or more domain experts based on file type and location. Each domain has distinct best practices that require specialized evaluation:

| File Pattern | Domain Expert |
|-------------|---------------|
| `*.sh` | Shell scripting |
| `.claude/**/*.md` (rules, prompts, skills) | Prompt engineering |
| `.github/**` (workflows, actions) | CI/CD |
| `*.md` outside `.claude/` | Technical writing |

If a file does not match any pattern, assign it to the most relevant domain or create a new domain category.

Before proceeding, verify that every changed file from Step 1 appears in at least one domain — an uncovered file means potential issues go undetected. If any file is missing, assign it before continuing.

### Step 3: Determine work records directory

Identify the issue number from the current branch name (the leading digits before the underscore). Construct the work records path:

```
.aiya/issues/<5-digit-zero-padded-number>/
```

Create the directory if it does not exist. If the branch name has no issue number, ask the user for the issue number before proceeding.

### Step 4: Conduct expert reviews

For each domain expert, follow this procedure:

1. **Read** each changed file assigned to this domain
2. **Evaluate** against domain best practices — consult `references/domain-checklists.md` for the evaluation criteria per domain. Search official documentation when uncertain about a best practice.
3. **Record findings** — each finding must be specific enough to act on without ambiguity. Vague advice like "consider improving" is not actionable. Include:
   - What was found (the specific issue)
   - Severity: High (correctness/security), Medium (reliability/maintainability), Low (style/convention)
   - A concrete proposed improvement
4. **Write** the review file to `{domain}-expert-review.md` in the work records directory — consult `references/review-format.md` for the exact template, field definitions, and examples of good vs bad findings

A domain review is complete when every file in the domain's scope has been evaluated against each applicable checklist item, and all findings are recorded with severity and improvement.

### Step 5: Decide on findings

Fill in the Decision table for each finding:

- **Accepted** — the finding is valid and the improvement should be implemented
- **Rejected** — record the reason (e.g., false positive, acceptable trade-off, out of scope)

Accept findings that fix real issues. Reject findings that are subjective preferences or low-value nitpicks — the goal is quality improvement, not perfection at the cost of progress.

### Step 6: Implement accepted improvements

Apply each accepted improvement to the codebase. After implementation:

1. Run existing tests to verify the fix does not introduce regressions — a fix that breaks passing tests is worse than the original finding
2. If a fix causes regressions, revert it, update the finding's Decision to "Rejected" with reason "Fix causes regression", and move on
3. If implementation reveals new issues, add them as findings in the review file and decide on them
4. Continue until all accepted improvements are implemented and verified

### Step 7: Commit and push

Commit the review files and implemented improvements. Split commits by purpose so each commit tells a clear story:

```bash
git add .aiya/issues/nnnnn/*-expert-review.md
git commit -m "Add expert review records for issue #N"

git add <changed-source-files>
git commit -m "Apply expert review improvements

Implement accepted findings from domain expert reviews."

git push
```

### Step 8: Update PR body

Add links to the review files in the PR body under an "Expert Review" section:

```
## Expert Review

- [{Domain} Expert Review]({url})
```

Construct each URL:
```bash
# Get repository info
gh repo view --json owner,name
# Get current branch
git branch --show-current
```

URL format: `https://github.com/{owner}/{repo}/blob/{branch}/.aiya/issues/nnnnn/{domain}-expert-review.md`

## Example

User says: "Run expert review"

Actions:
1. Run `git diff origin/main --name-only` and find 3 files changed: `lib/statusline.sh`, `.claude/rules/workflow.md`, `.github/workflows/test-shell.yml`
2. Categorize: `statusline.sh` to Shell scripting, `workflow.md` to Prompt engineering, `test-shell.yml` to CI/CD
3. Determine work records directory from branch `42_faster-test-feedback` as `.aiya/issues/00042/`
4. Review each file from the domain expert perspective, record findings
5. Decide: accept 3 findings, reject 1 (subjective preference)
6. Implement the 3 accepted improvements
7. Commit review files and improvements separately, push
8. Add Expert Review links to the PR body

Result: Three review files created (`shell-scripting-expert-review.md`, `prompt-engineering-expert-review.md`, `cicd-expert-review.md`), accepted improvements implemented, PR body updated with links.

## Common Issues

### No changed files

If `git diff origin/main --name-only` returns nothing, the branch has no changes to review. Inform the user and suggest checking they are on the correct branch.

### Branch has no issue number

If the branch name does not start with a number (e.g., `feature-branch` instead of `42_feature-branch`), ask the user for the issue number so the work records directory can be determined.

### Domain not in checklist

If a file type has no matching domain in the checklist, create a review using general software engineering best practices. Note in the review file that no domain-specific checklist was available — this signals that a new checklist should be added for future reviews.

### Finding is ambiguous

If you cannot determine whether a finding is valid, search official documentation for the tool or language in question. If still uncertain, mark the finding as "Needs clarification" in the Decision table and ask the user to decide.

### Improvement causes regression

If implementing an accepted finding breaks existing tests, revert the change, update the Decision to "Rejected" with reason "Fix causes regression: {test that failed}", and continue with the next finding. Report the regression to the user after the review is complete so they can decide whether to pursue the fix differently.
