## Problem Summary

AIYA is a development workflow system for Claude Code that realizes the "Agents in your area" concept — AI agents working alongside developers in their environment. Currently, AIYA consists of 47 files spread across `.claude/rules/`, `.claude/commands/`, `.claude/hooks/`, `setup/`, and other directories. Developers who want to adopt AIYA must manually copy and integrate many interdependent files, risk conflicts with existing configurations, and cannot easily update.

## Step 1: Current State Analysis

Each file is categorized by which README concept it primarily serves. Files that don't serve any concept are for AIYA development only (aiya-dev).

### File Inventory

| Path | Concept | Reason |
|------|---------|--------|
| `.claude/rules/workflow.md` | No babysitting | Defines 3 phases and gates that guard quality |
| `.claude/rules/requirements-definition.md` | No babysitting | Phase 1 procedure agents follow independently |
| `.claude/rules/approach-design.md` | No babysitting | Phase 2 procedure agents follow independently |
| `.claude/rules/issue-format.md` | No babysitting | Structured format ensures consistent quality |
| `.claude/rules/pr-format.md` | No babysitting | Structured format ensures consistent quality |
| `.claude/rules/consistency-check.md` | No babysitting | Verification agents run without supervision |
| `.claude/rules/expert-review.md` | No babysitting | Verification agents run without supervision |
| `.claude/rules/scenario-evaluation.md` | No babysitting | Verification agents run without supervision |
| `.claude/rules/work-records.md` | Walk away anytime | State persistence convention for save/resume |
| `.claude/rules/git-conventions.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/step-design.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/agent-behavior.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/testing.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/testing-shell.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/tool-adoption.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/language.md` | No babysitting | Convention agents follow without supervision |
| `.claude/rules/temporary-files.md` | No babysitting | Convention agents follow without supervision |
| `.claude/commands/hi.md` | No babysitting | Structured issue creation via gate process |
| `.claude/commands/ok.md` | Walk away anytime | Resumes saved work state from any worktree |
| `.claude/commands/bb.md` | Walk away anytime | Saves work state for later resumption |
| `.claude/commands/ty.md` | No babysitting | Approves gates in the quality process |
| `.claude/commands/fb.md` | No babysitting | Addresses feedback in the review process |
| `.claude/hooks/sandbox.sh` | No babysitting | Auto-approves safe actions without developer |
| `.claude/hooks/sandbox_test.sh` | No babysitting | Tests for sandbox |
| `.claude/hooks/notify.sh` | Scale as one | Alerts developer across parallel instances |
| `.claude/hooks/notify_test.sh` | Scale as one | Tests for notify |
| `.claude/hooks/allowed-domains.txt` | No babysitting | Domain whitelist for sandbox auto-approval |
| `.claude/statusline.sh` | Walk away anytime | Monitors context to decide when to save/resume |
| `.claude/statusline_test.sh` | Walk away anytime | Tests for statusline |
| `.claude/settings.json` | No babysitting | Hook and statusline configuration |
| `setup/up.sh` | Scale as one | Creates parallel worker instances |
| `setup/up_test.sh` | Scale as one | Tests for up.sh |
| `setup/dn.sh` | Scale as one | Removes parallel worker instances |
| `setup/dn_test.sh` | Scale as one | Tests for dn.sh |
| `setup/wc.sh` | Scale as one | Initializes worktrees for parallel work |
| `setup/wc_test.sh` | Scale as one | Tests for wc.sh |
| `README.md` | No babysitting, Scale as one, Walk away anytime | Documents all 3 concepts for AIYA users; plugin needs equivalent |
| `.claude/skills/skill-smith/SKILL.md` | aiya-dev | Skill development tool for AIYA contributors |
| `.claude/skills/skill-smith/references/checklist.md` | aiya-dev | Skill quality checklist |
| `.claude/skills/skill-smith/references/patterns.md` | aiya-dev | Skill writing patterns |
| `.claude/skills/skill-smith/references/writing-guide.md` | aiya-dev | Skill writing guide |
| `.claude/skills/skill-smith/scripts/validate.sh` | aiya-dev | Skill validation script |
| `.claude/skills/skill-smith/scripts/validate_test.sh` | aiya-dev | Tests for validation script |
| `.github/workflows/test-shell.yml` | aiya-dev | CI pipeline for AIYA development |
| `CLAUDE.md` | aiya-dev | Project rules for aiya-dev repository |
| `.env.example` | aiya-dev | Environment configuration template |
| `.aiya/issues/` | aiya-dev | Work records data generated at runtime |

## Key Decisions

1. **Plugin over single skill**: CC plugins can contain commands, hooks, skills, and settings as a single distributable unit. A single skill cannot include slash commands or hooks. Plugin is the correct distribution mechanism.

## Open Questions

1. Plugins do not have a `rules/` directory. How should the 17 rule files be incorporated into the plugin structure? Options: embed in commands/skills, use an agent with system prompt, or reference files within skills.
2. Setup scripts (`up.sh`, `dn.sh`, `wc.sh`) are currently designed for the aiya-dev repo's worktree structure. How should they be generalized for any adopting repository?
3. `allowed-domains.txt` contains domains specific to AIYA development. Should the plugin include a default set, or should this be user-configurable?
