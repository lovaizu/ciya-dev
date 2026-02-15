# Project Rules

- **CLAUDE.md** — Repository-specific rules: domain knowledge, deliverables, project-specific conventions
- **`.claude/rules/`** — Reusable rules that are not repository-specific, split into one file per topic

## Environment Variables

- All environment variables defined by this project must use the `CIYA_` prefix (e.g., `CIYA_WORK_COUNT`, `CIYA_DEFAULT_BRANCH`)
- Third-party variables (e.g., `GH_TOKEN`, `ANTHROPIC_API_KEY`) keep their original names

## Script Testing

See `.claude/rules/testing-shell.md` for test conventions, code format, and coverage requirements.
