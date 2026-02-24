## Problem Summary

AIYA consists of 22 files (17 rules + 5 commands) spread across `.claude/rules/` and `.claude/commands/`. These files are tightly coupled and reference each other. Developers who want to adopt AIYA must manually copy all files, risk conflicts with existing configurations, and cannot easily update.

## Approach

Consolidate all AIYA content into a single skill directory at `.claude/skills/aiya/`:

- **SKILL.md**: Core workflow (phases, gates), all 5 commands (/hi, /ok, /bb, /ty, /fb), and essential rules (issue format, PR format, git conventions, work records, etc.)
- **references/**: Detailed reference material that supports the core workflow but is not needed on every invocation (testing conventions, step design patterns, tool adoption process)

The skill system provides natural isolation — skills in `.claude/skills/` don't modify or conflict with `.claude/rules/` or `CLAUDE.md`. Updating means replacing the single skill directory.

## Key Decisions

1. **Skill vs. single file**: A skill directory (SKILL.md + references/) rather than a literal single file, because progressive disclosure keeps SKILL.md manageable while preserving all content. The issue's intent is "easy adoption" — one directory to copy is as easy as one file.

2. **What goes in SKILL.md vs. references/**: Core workflow, commands, and formats that are needed on every invocation go in SKILL.md. Detailed conventions (testing, step design) that are consulted only during specific phases go in references/.

3. **Current files remain**: This is additive — the skill is created alongside existing files. Removing the original files is a separate concern (migration for the AIYA repo itself).

## Open Questions

1. Should the skill include project-specific rules currently in CLAUDE.md (e.g., `AIYA_` env var prefix), or should those remain project-specific?
2. Should testing rules (testing.md, testing-shell.md) be included in the skill, or are they project-specific conventions?
