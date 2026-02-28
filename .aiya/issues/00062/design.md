## Problem Summary

AIYA consists of 22 files (17 rules + 5 commands) spread across `.claude/rules/` and `.claude/commands/`. These files are tightly coupled and reference each other. Developers who want to adopt AIYA must manually copy all files, risk conflicts with existing configurations, and cannot easily update.

## Step 1: Current State Analysis

### What AIYA provides

AIYA is a structured development workflow system for Claude Code. It provides:

1. **Phased workflow**: Goal → Approach → Delivery with 3 approval gates
2. **5 commands**: `/hi` (hearing), `/ok` (start/resume), `/bb` (save state), `/ty` (approve), `/fb` (feedback)
3. **Format specifications**: Issue format (Situation→Pain→Benefit→AS), PR format (Approach table, Steps)
4. **Verification procedures**: Expert review, scenario evaluation, consistency check
5. **Convention rules**: Git conventions, testing, step design, work records, tool adoption, agent behavior

### Categorization Criteria

Each file is categorized from the **AIYA user's perspective**: what does a developer adopting AIYA need?

- **Plugin candidate**: Files that define the AIYA workflow system itself — a developer adopting AIYA needs these to use the structured workflow (phases, gates, commands, formats, conventions)
- **Project-specific / Infrastructure**: Files needed only for developing or operating the aiya-dev repository itself — an AIYA user does not need these (e.g., CI pipelines, security hooks specific to this repo, setup scripts for this repo's worktree structure)

Within plugin candidates, files are further split:

- **Core**: Content the agent needs during standard workflow execution — loaded on every invocation or actively referenced during a specific workflow phase (e.g., `workflow.md` on every invocation, `issue-format.md` during Phase 1)
- **Reference**: Detailed guides the agent consults only when a specific topic arises during implementation (e.g., `testing-shell.md` only when writing shell tests, `step-design.md` only when authoring procedural rules)

### File Inventory

#### Rules (17 files, 782 lines) — `.claude/rules/`

| File | Lines | Purpose | Skill Candidate? |
|------|-------|---------|-------------------|
| `workflow.md` | 74 | Core workflow: 3 phases, 3 gates, full progression | Yes — core |
| `requirements-definition.md` | 53 | Phase 1 procedure: define user value | Yes — core |
| `approach-design.md` | 48 | Phase 2 procedure: design means to achieve AS | Yes — core |
| `issue-format.md` | 60 | Issue format specification (Situation, Pain, Benefit, AS) | Yes — core |
| `pr-format.md` | 61 | PR format specification (Approach, Steps, Expert Review) | Yes — core |
| `consistency-check.md` | 41 | Cross-artifact traceability verification | Yes — core |
| `expert-review.md` | 79 | Domain expert review procedure | Yes — core |
| `scenario-evaluation.md` | 65 | Acceptance scenario verification procedure | Yes — core |
| `work-records.md` | 21 | Work records directory structure (`.aiya/issues/nnnnn/`) | Yes — core |
| `git-conventions.md` | 20 | Branch naming, commit format | Yes — core |
| `step-design.md` | 72 | Rules for writing procedural steps (Generate-Verify-Iterate) | Yes — reference |
| `agent-behavior.md` | 8 | Agent behavior expectations | Yes — core |
| `testing.md` | 48 | Common testing rules (Given-When-Then, coverage) | Yes — reference |
| `testing-shell.md` | 102 | Shell-specific test conventions (kcov, assert_eq) | Yes — reference |
| `tool-adoption.md` | 20 | Tool evaluation process | Yes — reference |
| `language.md` | 4 | Documentation language rule (English) | Yes — core |
| `temporary-files.md` | 6 | Temp file location (`.tmp/`) | Yes — core |

#### Commands (5 files, 350 lines) — `.claude/commands/`

| File | Lines | Purpose | Skill Candidate? |
|------|-------|---------|-------------------|
| `hi.md` | 30 | Start hearing → create issue on GitHub | Yes — core |
| `ok.md` | 72 | Start or resume work on an issue | Yes — core |
| `bb.md` | 69 | Save work state and prepare to switch | Yes — core |
| `ty.md` | 84 | Approve current gate and proceed | Yes — core |
| `fb.md` | 95 | Address review feedback on PRs/issues | Yes — core |

#### Infrastructure (NOT skill candidates)

| File | Lines | Purpose | Why not in skill |
|------|-------|---------|------------------|
| `CLAUDE.md` | 9 | Project-specific rules (env var prefix) | Project-specific, varies per adopting repo |
| `.claude/settings.json` | — | Claude Code hook configuration | Infrastructure config, not workflow content |
| `.claude/statusline.sh` | 29 | Status line display | Developer tooling, not workflow |
| `.claude/hooks/sandbox.sh` | ~449 | Security enforcement hook | Infrastructure, repo-specific security policy |
| `.claude/hooks/notify.sh` | — | Notification hook | Infrastructure |
| `.claude/hooks/allowed-domains.txt` | — | Domain whitelist | Project-specific security config |
| `.claude/hooks/*_test.sh` | — | Hook tests | Infrastructure tests |
| `.claude/statusline_test.sh` | — | Status line tests | Infrastructure tests |
| `.claude/skills/skill-smith/` | — | Skill creation/evaluation tool | Separate skill, not AIYA workflow |
| `setup/` (6 files) | — | Bootstrap and worktree management | Infrastructure, specific to aiya-dev repo |
| `.github/workflows/` | — | CI/CD | Infrastructure |
| `.aiya/issues/` | — | Work records data | Generated at runtime, not skill content |
| `.env.example` | — | Environment config template | Infrastructure |
| `README.md` | — | Project README for aiya-dev repository | Repository documentation, not workflow content |

### Categorization Summary

| Category | Files | Lines | Description |
|----------|-------|-------|-------------|
| Skill — core | 15 rules + 5 commands | 837 | Needed on every invocation or during specific workflow phases |
| Skill — reference | 4 rules | 242 | Detailed guides consulted only when relevant |
| Not in skill | ~15 files | ~500+ | Infrastructure, project-specific config, separate tools |

### Implicit Conventions (not in files)

1. **Workflow orchestration**: The user runs commands in sequence (`/hi` → `/ty` → `/ok` → `/ty` → implementation → `/ty`), but no single file describes this end-to-end user journey
2. **Work records lifecycle**: `.aiya/issues/nnnnn/` directories are created by `/ok`, updated by `/bb`, read on resume — the lifecycle spans multiple commands but is documented piecemeal
3. **Gate detection logic**: `/ty` auto-detects which gate based on PR and file state — this logic lives only in `ty.md`

## Key Decisions

_(To be updated in later steps)_

## Open Questions

1. Should testing rules (`testing.md`, `testing-shell.md`) be included in the skill? They define how AIYA enforces code quality but are also reusable conventions. **Preliminary answer**: Include as reference material — they are part of the AIYA workflow (Phase 3: expert review references testing standards).
2. Should `step-design.md` be included? It defines how AIYA's own rules are written. **Preliminary answer**: Include as reference — it's the meta-pattern behind all AIYA procedures.
3. Should `tool-adoption.md` be included? **Preliminary answer**: Include as reference — it's consulted when AIYA encounters a new tool during implementation.
