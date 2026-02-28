## Problem Summary

AIYA is a development workflow system for Claude Code that realizes the "Agents in your area" concept — AI agents working alongside developers in their environment. Currently, AIYA consists of 45 files spread across `.claude/rules/`, `.claude/commands/`, `.claude/hooks/`, `setup/`, and other directories. Developers who want to adopt AIYA must manually copy and integrate many interdependent files, risk conflicts with existing configurations, and cannot easily update.

## Step 1: Current State Analysis

### What AIYA provides

AIYA realizes "Agents in your area" through:

1. **Structured workflow**: Goal → Approach → Delivery with 3 approval gates
2. **5 commands**: `/hi` (create issue), `/ok` (start/resume work), `/bb` (save state), `/ty` (approve gate), `/fb` (address feedback)
3. **Format specifications**: Issue format (Situation→Pain→Benefit→AS), PR format (Approach table, Steps)
4. **Verification procedures**: Expert review, scenario evaluation, consistency check
5. **Convention rules**: Git, testing, step design, work records, tool adoption, agent behavior
6. **Autonomous operation**: Sandbox hook for unattended agent work, notify hook for alerting the developer
7. **Parallel work**: Worktree management (setup scripts) for multiple agents working simultaneously
8. **Monitoring**: Status line for tracking agent context usage

### Concepts

"Agents in your area" is realized through 3 concepts:

1. **Workflow** — Structured development process (Goal → Approach → Delivery) with gates, commands, format specifications, verification procedures, and conventions
2. **Autonomous operation** — Agents work unattended with safety (sandbox), alerting (notify), and monitoring (statusline)
3. **Parallel work** — Multiple agents work simultaneously via worktree management

### Categorization Criteria

Each file is categorized by **which concept it serves**. Files that don't belong to any concept are for AIYA development only (aiya-dev).

### File Inventory

| Path | Lines | Purpose | Concept |
|------|-------|---------|---------|
| `.claude/rules/workflow.md` | 74 | Core workflow: 3 phases, 3 gates, full progression | Workflow |
| `.claude/rules/requirements-definition.md` | 53 | Phase 1 procedure: define user value | Workflow |
| `.claude/rules/approach-design.md` | 48 | Phase 2 procedure: design means to achieve AS | Workflow |
| `.claude/rules/issue-format.md` | 60 | Issue format specification (Situation, Pain, Benefit, AS) | Workflow |
| `.claude/rules/pr-format.md` | 61 | PR format specification (Approach, Steps) | Workflow |
| `.claude/rules/consistency-check.md` | 41 | Cross-artifact traceability verification | Workflow |
| `.claude/rules/expert-review.md` | 79 | Domain expert review procedure | Workflow |
| `.claude/rules/scenario-evaluation.md` | 65 | Acceptance scenario verification procedure | Workflow |
| `.claude/rules/work-records.md` | 21 | Work records directory structure | Workflow |
| `.claude/rules/git-conventions.md` | 20 | Branch naming, commit format | Workflow |
| `.claude/rules/step-design.md` | 72 | Rules for writing procedural steps | Workflow |
| `.claude/rules/agent-behavior.md` | 8 | Agent behavior expectations | Workflow |
| `.claude/rules/testing.md` | 48 | Common testing rules (Given-When-Then, coverage) | Workflow |
| `.claude/rules/testing-shell.md` | 102 | Shell-specific test conventions (kcov) | Workflow |
| `.claude/rules/tool-adoption.md` | 20 | Tool evaluation process | Workflow |
| `.claude/rules/language.md` | 4 | Documentation language rule | Workflow |
| `.claude/rules/temporary-files.md` | 6 | Temp file location (`.tmp/`) | Workflow |
| `.claude/commands/hi.md` | 30 | Create issue on GitHub | Workflow |
| `.claude/commands/ok.md` | 72 | Start or resume work on an issue | Workflow |
| `.claude/commands/bb.md` | 69 | Save work state and prepare to switch | Workflow |
| `.claude/commands/ty.md` | 84 | Approve current gate and proceed | Workflow |
| `.claude/commands/fb.md` | 95 | Address review feedback | Workflow |
| `.claude/hooks/sandbox.sh` | 448 | Safety hook: auto-approve safe actions | Autonomous operation |
| `.claude/hooks/sandbox_test.sh` | 616 | Sandbox hook tests | Autonomous operation |
| `.claude/hooks/notify.sh` | 125 | Alert hook: notify when agent completes or needs attention | Autonomous operation |
| `.claude/hooks/notify_test.sh` | 166 | Notify hook tests | Autonomous operation |
| `.claude/hooks/allowed-domains.txt` | 13 | Domain whitelist for sandbox web access | Autonomous operation |
| `.claude/statusline.sh` | 29 | Monitor agent context usage | Autonomous operation |
| `.claude/statusline_test.sh` | 105 | Status line tests | Autonomous operation |
| `.claude/settings.json` | 44 | Hook and statusline configuration | Autonomous operation |
| `setup/up.sh` | 245 | Create worktree for parallel agent work | Parallel work |
| `setup/up_test.sh` | 334 | up.sh tests | Parallel work |
| `setup/dn.sh` | 46 | Remove worktree | Parallel work |
| `setup/dn_test.sh` | 140 | dn.sh tests | Parallel work |
| `setup/wc.sh` | 123 | Initialize worktree with configuration | Parallel work |
| `setup/wc_test.sh` | 397 | wc.sh tests | Parallel work |
| `.claude/skills/skill-smith/SKILL.md` | 347 | Skill creation/evaluation tool | aiya-dev |
| `.claude/skills/skill-smith/references/checklist.md` | 106 | Skill quality checklist | aiya-dev |
| `.claude/skills/skill-smith/references/patterns.md` | 102 | Skill writing patterns | aiya-dev |
| `.claude/skills/skill-smith/references/writing-guide.md` | 312 | Skill writing guide | aiya-dev |
| `.claude/skills/skill-smith/scripts/validate.sh` | 420 | Skill validation script | aiya-dev |
| `.claude/skills/skill-smith/scripts/validate_test.sh` | 239 | Validation script tests | aiya-dev |
| `.github/workflows/test-shell.yml` | 57 | CI pipeline for shell tests | aiya-dev |
| `CLAUDE.md` | 9 | Project-specific rules (env var prefix) | aiya-dev |
| `README.md` | 242 | aiya-dev repository documentation | aiya-dev |
| `.env.example` | 34 | Environment config template | aiya-dev |
| `.aiya/issues/` | — | Work records data (generated at runtime) | aiya-dev |

### Categorization Summary

| Concept | Files | Lines | What it provides |
|---------|-------|-------|------------------|
| Workflow | 22 | 1,957 | Structured development process: phases, gates, commands, formats, verification, conventions |
| Autonomous operation | 8 | 1,371 | Unattended agent work: safety (sandbox), alerting (notify), monitoring (statusline) |
| Parallel work | 6 | 1,289 | Multiple agents simultaneously: worktree creation, removal, initialization |
| aiya-dev | 11 | 1,868 | AIYA project development only: CI, skill-smith, project docs, config |

### Implicit Conventions (not in files)

1. **Workflow orchestration**: The user runs commands in sequence (`/hi` → `/ty` → `/ok` → `/ty` → implementation → `/ty`), but no single file describes this end-to-end user journey
2. **Work records lifecycle**: `.aiya/issues/nnnnn/` directories are created by `/ok`, updated by `/bb`, read on resume — the lifecycle spans multiple commands but is documented piecemeal
3. **Gate detection logic**: `/ty` auto-detects which gate based on PR and file state — this logic lives only in `ty.md`

## Key Decisions

1. **Plugin over single skill**: CC plugins can contain commands, hooks, skills, and settings as a single distributable unit. A single skill cannot include slash commands or hooks. Plugin is the correct distribution mechanism.

## Open Questions

1. Plugins do not have a `rules/` directory. How should the 17 rule files be incorporated into the plugin structure? Options: embed in commands/skills, use an agent with system prompt, or reference files within skills.
2. Setup scripts (`up.sh`, `dn.sh`, `wc.sh`) are currently designed for the aiya-dev repo's worktree structure. How should they be generalized for any adopting repository?
3. `allowed-domains.txt` contains domains specific to AIYA development. Should the plugin include a default set, or should this be user-configurable?
