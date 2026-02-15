# Evaluation Checklist

All check items used by the Evaluate mode. Each item has an ID, criterion, and anchor examples for consistent judgment.

Verdicts: **PASS** (meets criterion), **FAIL** (violates, blocks deployment), **WARN** (works but should improve), **SKIP** (not applicable).

---

## Structure (S)

| ID | Check | Criterion |
|----|-------|-----------|
| S-01 | SKILL.md exists | Exact case match. `skill.md` → FAIL |
| S-02 | Folder is kebab-case | `^[a-z0-9]+(-[a-z0-9]+)*$` |
| S-03 | Folder matches `name` | frontmatter name = folder name |
| S-04 | No README.md | README.md in skill root → FAIL |
| S-05 | Standard directories only | Only scripts/, references/, assets/, evals/. Others → WARN |

## Frontmatter (F)

| ID | Check | Criterion |
|----|-------|-----------|
| F-01 | Valid delimiters | Opens and closes with `---` |
| F-02 | Valid YAML | yaml.safe_load() succeeds |
| F-03 | name exists | Required, string |
| F-04 | name is kebab-case | Pattern match, ≤64 chars |
| F-05 | name not reserved | No "claude"/"anthropic" |
| F-06 | description exists | Required, string |
| F-07 | description ≤ 1024 chars | Length check |
| F-08 | No XML in description | No `<` or `>` |
| F-09 | Allowed properties only | name, description, license, allowed-tools, metadata, compatibility |
| F-10 | compatibility ≤ 500 chars | If present |

## Description Quality (D)

| ID | Check | PASS Anchor | FAIL Anchor |
|----|-------|------------|------------|
| D-01 | WHAT stated | "Generates PDF reports from tabular data" | "Helps with data" |
| D-02 | WHEN stated | "Use when user says 'create a report'" | No trigger conditions |
| D-03 | Natural phrases (≥2) | "'make a PDF', 'turn spreadsheet into report'" | Only technical terms |
| D-04 | File types (if applicable) | ".csv, .xlsx, .tsv" | Handles files but no types listed |
| D-05 | Not too broad | "PDF reports from tabular data" | "Processes documents" |
| D-06 | Not too narrow | Includes paraphrases and related intents | Only exact-match phrases |
| D-07 | Negative triggers (if applicable) | "Do NOT use for data exploration" | Overlapping scope, no boundary |
| D-08 | Actionable language | "Creates sprint tasks in Linear" | "Implements entity model" |

## Instruction Quality (I)

| ID | Check | PASS Anchor | FAIL Anchor |
|----|-------|------------|------------|
| I-01 | Step-ordered | "Step 1: Fetch → Step 2: Validate → Step 3: Generate" | Unordered prose |
| I-02 | Executable steps (>70%) | "Run `python scripts/validate.py`" | "Validate properly" |
| I-03 | Critical first | Core workflow in first section | Critical steps after background |
| I-04 | Success conditions | "Expected: PDF with formatted tables" | No output description |
| I-05 | Size ≤ 500 lines | 300-line focused SKILL.md | 1200-line monolith (>1000 → FAIL) |
| I-06 | Imperative voice | "Validate the input" | "Should probably be validated" |
| I-07 | MUST density ≤ 1/200 words | Rationale-based constraints | MUST/ALWAYS every sentence |

## Error Handling (E)

| ID | Check | Criterion |
|----|-------|-----------|
| E-01 | ≥1 error scenario | At least one "If ... fails" |
| E-02 | MCP error handling (MCP skills) | Connection failure recovery |
| E-03 | Fallback procedures | Alternative when primary fails → WARN if missing |

## Examples (X)

| ID | Check | Criterion |
|----|-------|-----------|
| X-01 | ≥1 example | Concrete usage example |
| X-02 | Input → Action → Result | Full flow shown |

## Progressive Disclosure (P)

| ID | Check | Criterion |
|----|-------|-----------|
| P-01 | References separated | Detailed docs in references/, not inlined |
| P-02 | Pointers explicit | Each ref file has a pointer in SKILL.md with context |
| P-03 | Core focus | SKILL.md body is actionable instructions |
| P-04 | Large ref TOC | References > 300 lines have table of contents |

## Composability (C)

| ID | Check | Criterion |
|----|-------|-----------|
| C-01 | Not exclusive | No "You are a X assistant" / "Your only job" |
| C-02 | Scope bounded | Clear domain + task boundaries |
| C-03 | No tool lockout | Doesn't restrict tools beyond own scope |

## Portability (T)

| ID | Check | Criterion |
|----|-------|-----------|
| T-01 | Environment noted | If env-specific, declared in compatibility |
| T-02 | Dependencies documented | Script deps have install instructions |
| T-03 | No hardcoded paths | No absolute or user-specific paths |

## Security (SEC)

| ID | Check | Criterion |
|----|-------|-----------|
| SEC-01 | No XML in frontmatter | Same as F-08 |
| SEC-02 | No dangerous ops in scripts | No rm -rf /, sudo, data exfil |
| SEC-03 | No hardcoded secrets | No API keys, tokens, passwords |
| SEC-04 | Principle of least surprise | Behavior matches description |
