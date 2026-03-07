# Domain Expert Checklists

Evaluation criteria organized by domain. Each checklist contains the best practices the domain expert checks against. When reviewing, work through each applicable item and record violations as findings.

These checklists are starting points. Search official documentation when uncertain about a best practice — documentation reflects current standards while these lists may become outdated.

---

## Shell Scripting

### Safety and Correctness

- `set -euo pipefail` at the top of every script — prevents silent failures from unhandled errors, unset variables, and broken pipes
- All variables double-quoted unless word splitting is intentionally needed — unquoted variables break on filenames with spaces
- `[[ ]]` instead of `[ ]` for conditionals — `[[ ]]` handles empty strings and pattern matching correctly
- No `eval` with user-controlled input — command injection vulnerability
- Temporary files created with `mktemp` and cleaned up with `trap` — leftover temp files waste disk and leak data
- Exit codes used consistently: 0 for success, non-zero for failure with distinct codes for different error types

### Portability

- `#!/usr/bin/env bash` shebang — finds bash regardless of installation path
- No bashisms in scripts declared as `#!/bin/sh` — dash and other POSIX shells do not support arrays, `[[ ]]`, or process substitution
- `command -v` instead of `which` for checking command availability — `which` behavior varies across systems
- `$(...)` instead of backticks for command substitution — backticks cannot nest and are harder to read

### Style and Maintainability

- Functions used for repeated logic — copy-pasted code diverges over time
- Meaningful variable names — `$f` is unclear; `$config_file` communicates intent
- Comments explain why, not what — `# Retry 3 times because the API rate-limits` is useful; `# Set x to 5` is noise
- Local variables declared with `local` inside functions — prevents accidental global state

### Error Handling

- Commands that can fail have explicit error handling — `|| { echo "error"; exit 1; }`
- `set -e` interactions understood — commands in `if` conditions, `||` chains, and subshells do not trigger `set -e`
- User-facing error messages written to stderr — stdout is for program output

---

## Prompt Engineering

### Clarity and Precision

- Instructions use imperative voice — "Validate the input" not "The input should be validated"
- Each instruction has one action — compound instructions get partially executed
- Abstract terms are grounded with examples — "format properly" is vague; "format as a markdown table with columns: Name, Date, Amount" is concrete
- Ambiguous pronouns are replaced with specific nouns — "it" and "this" often have unclear referents

### Structure

- Steps are numbered and ordered — Claude follows numbered steps most faithfully
- Sections have clear headings — allows Claude to locate relevant instructions quickly
- Related instructions are grouped — scattered instructions on the same topic lead to inconsistent behavior
- Preconditions stated at the start — "Requires: issue approved at Gate 1" prevents executing steps out of order

### Reasoning Support

- Instructions explain why, not just what — rationale helps Claude generalize to situations not explicitly covered
- Examples show aligned behavior — the distinction between good and bad output is demonstrated
- Positive instructions describe desired behavior — "Write the title as the user's desired outcome" is more effective than "Do not write implementation details in the title"
- Edge cases are addressed — instructions that only cover the happy path produce unpredictable behavior on edge cases

### Anti-patterns

- No excessive mandatory language (MUST/ALWAYS/NEVER) — when everything is critical, nothing is; explain why instead
- No identity claims ("You are a X assistant") — blocks other skills from functioning
- No vague quality requirements ("ensure quality") — replace with specific, checkable criteria

---

## CI/CD

### Workflow Structure

- Jobs use `needs` to declare dependencies — implicit ordering through file position is fragile
- Matrix builds cover all target platforms — missing a platform means untested combinations ship
- Timeouts set on jobs — runaway jobs waste CI minutes and block other runs
- Concurrency groups prevent redundant runs — pushing twice in quick succession should cancel the first run

### Security

- Secrets accessed through `${{ secrets.NAME }}` — never hardcoded in workflow files
- Third-party actions pinned to commit SHA, not tags — tags can be moved to point at malicious code
- `permissions` scoped to minimum needed — default permissions are too broad
- User-controlled input not passed to `run:` unsanitized — injection through PR titles, branch names, or commit messages

### Reliability

- Steps have `if: failure()` or `continue-on-error` where appropriate — one flaky step should not block the entire pipeline
- Caching configured for package managers — downloading dependencies on every run wastes time and bandwidth
- Artifacts uploaded for debugging failed runs — without artifacts, reproducing CI failures requires re-running
- Retry logic for network-dependent steps — transient failures should not require manual re-runs

### Maintainability

- Reusable workflows or composite actions for repeated logic — copy-pasted workflow steps diverge
- Environment variables used for values referenced in multiple places — magic strings scattered across steps cause inconsistency
- Comments explain non-obvious steps — workflow YAML is often opaque without context

---

## Technical Writing

### Accuracy

- Technical claims are verifiable — assertions match the actual code behavior
- Code examples are syntactically correct — broken examples confuse readers and erode trust
- Links point to valid targets — broken links frustrate readers

### Clarity

- One idea per sentence — compound sentences with multiple clauses are hard to parse
- Active voice preferred — "The script validates input" is clearer than "Input is validated by the script"
- Jargon is defined on first use — domain terms that are obvious to the author may be unknown to the reader
- Consistent terminology — using different words for the same concept creates confusion

### Structure

- Headings follow a logical hierarchy — skipping levels (h1 to h3) breaks document structure
- Lists used for parallel items — inline lists of more than 3 items are hard to scan
- Tables used for structured comparisons — prose descriptions of tabular data are hard to compare

### Formatting

- Markdown syntax is valid — broken formatting renders poorly and distracts from content
- Code blocks specify the language — enables syntax highlighting and signals the reader what they are reading
- File paths and commands in code formatting — distinguishes executable text from prose
