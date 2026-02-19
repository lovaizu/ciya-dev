# Work Records

Work records are stored in `.ciya/issues/nnnnn/` where `nnnnn` is the zero-padded 5-digit issue number (e.g., `.ciya/issues/00029/`).

## Required Files

- `design.md` — Design decisions, approach rationale, key trade-offs. Created when starting work on an issue.
- `resume.md` — Current state and next steps. Created by `/bb` when interrupting work.

## Optional Files

- Any `*.md` files for free-form notes: research, debugging logs, investigation results, etc.

## Rules

- Each work branch writes to its own issue's directory
- `/hi <number>` reads work records via git to resume work
- `/bb` commits and pushes work records before interrupting
- Work records are part of the repository and version-controlled
