## Outline

| # | Section | Step | Status |
|---|---------|------|--------|
| 1 | Design Background | — | ✓ |
| 2 | Current State Analysis | Step 1 | ✓ |
| 3 | Plugin Requirements | Step 2 | ✓ |
| 4 | Plugin UX | Step 3 | TODO |
| 5 | Plugin Structure Design | Step 4 | TODO |
| 6 | Plugin Test Strategy | Step 5–6 | TODO |

## 1. Design Background

AIYA is a development workflow system for Claude Code that realizes the "Agents in your area" concept — AI agents working alongside developers in their environment. Currently, AIYA consists of 47 files spread across `.claude/rules/`, `.claude/commands/`, `.claude/hooks/`, `setup/`, and other directories. Developers who want to adopt AIYA must manually copy and integrate many interdependent files, risk conflicts with existing configurations, and cannot easily update.

### Key Decisions

1. **Plugin over single skill**: CC plugins can contain commands, hooks, skills, and settings as a single distributable unit. A single skill cannot include slash commands or hooks. Plugin is the correct distribution mechanism.
2. **Rules as workflow instructions**: Plugins have no `rules/` directory. Rule content will be embedded as agent instructions in plugin workflows or templates, not as separate rule files. Verification steps enable self-correction. Skill changes follow step-design.md.
3. **Setup script split**: Setup scripts will be split into plugin parts (reusable) and aiya-dev-only parts (separate script files). Plugin users add project-specific processing in the extracted parts, which serve as extension points.
4. **allowed-domains.txt as default + extension point**: Current domains distributed as default. Setup displays a message prompting the user to customize. README documents this as an extension point (same pattern as setup scripts).
5. **Testing rules and test code are aiya-dev only**: Testing conventions (testing.md, testing-shell.md) and test files (*_test.sh) are for AIYA development, not for plugin users.

## 2. Current State Analysis

Each file categorized by README concept. Files serving no concept are aiya-dev only. Plugin Target shows the plugin component each file maps to.

| Path | Concept | Reason | Plugin Target |
|------|---------|--------|---------------|
| `.claude/rules/workflow.md` | No babysitting | Defines 3 phases and gates that guard quality | Embedded in ok, ty |
| `.claude/rules/requirements-definition.md` | No babysitting | Phase 1 procedure agents follow independently | Embedded in hi |
| `.claude/rules/approach-design.md` | No babysitting | Phase 2 procedure agents follow independently | Embedded in ok |
| `.claude/rules/issue-format.md` | No babysitting | Structured format ensures consistent quality | Embedded in hi |
| `.claude/rules/pr-format.md` | No babysitting | Structured format ensures consistent quality | Embedded in ok |
| `.claude/rules/consistency-check.md` | No babysitting | Verification agents run without supervision | Embedded in ty |
| `.claude/rules/expert-review.md` | No babysitting | Verification agents run without supervision | Embedded in ty |
| `.claude/rules/scenario-evaluation.md` | No babysitting | Verification agents run without supervision | Embedded in ty |
| `.claude/rules/work-records.md` | Walk away anytime | State persistence convention for save/resume | Embedded in ok, bb |
| `.claude/rules/git-conventions.md` | No babysitting | Convention agents follow without supervision | Embedded in ok, bb |
| `.claude/rules/step-design.md` | No babysitting | Convention agents follow without supervision | Skill development reference |
| `.claude/rules/agent-behavior.md` | No babysitting | Convention agents follow without supervision | Embedded in all skills |
| `.claude/rules/testing.md` | aiya-dev | Testing convention for AIYA development | — |
| `.claude/rules/testing-shell.md` | aiya-dev | Shell testing convention for AIYA development | — |
| `.claude/rules/tool-adoption.md` | No babysitting | Convention agents follow without supervision | Embedded in ok |
| `.claude/rules/language.md` | No babysitting | Convention agents follow without supervision | Embedded in all skills |
| `.claude/rules/temporary-files.md` | No babysitting | Convention agents follow without supervision | Embedded in ok |
| `.claude/commands/hi.md` | No babysitting | Structured issue creation via gate process | Skill: hi |
| `.claude/commands/ok.md` | Walk away anytime | Resumes saved work state from any worktree | Skill: ok |
| `.claude/commands/bb.md` | Walk away anytime | Saves work state for later resumption | Skill: bb |
| `.claude/commands/ty.md` | No babysitting | Approves gates in the quality process | Skill: ty |
| `.claude/commands/fb.md` | No babysitting | Addresses feedback in the review process | Skill: fb |
| `.claude/hooks/sandbox.sh` | No babysitting | Auto-approves safe actions without developer | Hook: sandbox |
| `.claude/hooks/sandbox_test.sh` | aiya-dev | Tests for sandbox (AIYA development) | — |
| `.claude/hooks/notify.sh` | Scale as one | Alerts developer across parallel instances | Hook: notify |
| `.claude/hooks/notify_test.sh` | aiya-dev | Tests for notify (AIYA development) | — |
| `.claude/hooks/allowed-domains.txt` | No babysitting | Domain whitelist for sandbox auto-approval | Hook support: allowed-domains.txt |
| `.claude/statusline.sh` | Walk away anytime | Monitors context to decide when to save/resume | Script: statusline |
| `.claude/statusline_test.sh` | aiya-dev | Tests for statusline (AIYA development) | — |
| `.claude/settings.json` | No babysitting | Hook and statusline configuration | hooks.json |
| `setup/up.sh` | Scale as one | Creates parallel worker instances | Script: up (plugin part) |
| `setup/up_test.sh` | aiya-dev | Tests for up.sh (AIYA development) | — |
| `setup/dn.sh` | Scale as one | Removes parallel worker instances | Script: dn (plugin part) |
| `setup/dn_test.sh` | aiya-dev | Tests for dn.sh (AIYA development) | — |
| `setup/wc.sh` | Scale as one | Initializes worktrees for parallel work | Script: wc (plugin part) |
| `setup/wc_test.sh` | aiya-dev | Tests for wc.sh (AIYA development) | — |
| `README.md` | No babysitting, Scale as one, Walk away anytime | Documents all 3 concepts for AIYA users; plugin needs equivalent | Plugin README (Step 3) |
| `.claude/skills/skill-smith/SKILL.md` | aiya-dev | Skill development tool for AIYA contributors | — |
| `.claude/skills/skill-smith/references/checklist.md` | aiya-dev | Skill quality checklist | — |
| `.claude/skills/skill-smith/references/patterns.md` | aiya-dev | Skill writing patterns | — |
| `.claude/skills/skill-smith/references/writing-guide.md` | aiya-dev | Skill writing guide | — |
| `.claude/skills/skill-smith/scripts/validate.sh` | aiya-dev | Skill validation script | — |
| `.claude/skills/skill-smith/scripts/validate_test.sh` | aiya-dev | Tests for validation script | — |
| `.github/workflows/test-shell.yml` | aiya-dev | CI pipeline for AIYA development | — |
| `CLAUDE.md` | aiya-dev | Project rules for aiya-dev repository | — |
| `.env.example` | aiya-dev | Environment configuration template | — |
| `.aiya/issues/` | aiya-dev | Work records data generated at runtime | — |
| `plugin.json` (new) | — | Plugin manifest | Manifest: plugin.json |

## 3. Plugin Requirements

### What the User Gets

| Concept | What the user gets |
|---------|-------------------|
| No babysitting | • Describe a goal; agent creates a structured issue • Agent designs approach, implements, and verifies independently • Approve each phase; agent proceeds to next • Agent addresses review feedback • Safe actions auto-approved without prompts |
| Scale as one | • Start and stop parallel worker instances • Get alerted when any agent needs attention |
| Walk away anytime | • Save work state and step away at any time • Resume from where you left off in any worktree • Monitor context usage at a glance |

### Rule Embedding

Plugins have no `rules/` directory. Rule content is embedded as instructions within skills, with verification steps for self-correction.

| Rule file | Embedded in | How |
|-----------|-------------|-----|
| workflow.md | ty (gate logic), ok (workflow steps) | Phase/gate definitions as skill instructions |
| requirements-definition.md | hi | Hearing procedure as skill instructions |
| approach-design.md | ok | PR drafting procedure as skill instructions |
| issue-format.md | hi | Issue format specification inline |
| pr-format.md | ok | PR format specification inline |
| consistency-check.md | ty (Gate 2→3 transition) | Verification procedure as skill instructions |
| expert-review.md | ty (Gate 2→3 transition) | Review procedure as skill instructions |
| scenario-evaluation.md | ty (Gate 2→3 transition) | Evaluation procedure as skill instructions |
| work-records.md | ok, bb | Work records convention inline |
| git-conventions.md | ok, bb | Branch/commit convention inline |
| step-design.md | Skill development only | Referenced when modifying AIYA skills |
| agent-behavior.md | All skills (shared preamble) | Agent behavior guidelines in each skill |
| tool-adoption.md | ok (implementation phase) | Tool adoption process inline |
| language.md | All skills (shared preamble) | Language convention in each skill |
| temporary-files.md | ok (implementation phase) | Temp file convention inline |

### Exclusions

| Excluded | Reason |
|----------|--------|
| testing.md, testing-shell.md | Testing conventions for AIYA development, not for plugin users |
| *_test.sh (8 files) | Test code for AIYA development |
| .github/workflows/test-shell.yml | CI pipeline for AIYA development |
| skill-smith (6 files) | Skill development tool for AIYA contributors |
| CLAUDE.md | Project-specific rules for the aiya-dev repository |
| .env.example | Project configuration template for aiya-dev |
| .aiya/issues/ | Runtime data generated during work; created by ok and bb |

## 4. Plugin UX

TODO: Step 3

## 5. Plugin Structure Design

### Gaps and Constraints

| Gap | Impact | Mitigation |
|-----|--------|------------|
| Plugin settings.json only supports `agent` key | Cannot configure statusLine via plugin settings | Document manual statusLine setup in plugin README; investigate if CC supports plugin-provided statusLine |
| `${CLAUDE_PLUGIN_ROOT}` required for paths | Hook scripts must use `${CLAUDE_PLUGIN_ROOT}` instead of `$CLAUDE_PROJECT_DIR` | Update all path references in hook scripts |
| Skill description budget (2% of context) | Skills with embedded rules may exceed budget | Split large skills into skill + reference files; use `${CLAUDE_SKILL_DIR}` for dynamic reads |
| Setup scripts need project-specific parts | up.sh/dn.sh/wc.sh contain aiya-dev-specific logic | Split into plugin part (reusable) + extension point (project-specific) |

TODO: Step 4 — Design plugin directory structure, map files to exact plugin paths, solve rules integration details.

## 6. Plugin Test Strategy

TODO: Step 5–6

## Open Questions

None — all questions resolved.
