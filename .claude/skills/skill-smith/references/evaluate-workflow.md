# Evaluate

Assess a skill's quality against the Guide's standards. Produces a structured report with findings and a grade.

## Step 1: Structural Validation

Run the automated checks:

```bash
bash scripts/validate.sh <skill-folder-path>
```

This covers: file structure, frontmatter validity, description presence, naming conventions, security basics, and size limits. Report results.

## Step 2: Description Quality

Go beyond what the script can check. Read the description and assess:

**Completeness**: Does it have both WHAT (concrete function) and WHEN (trigger conditions)?

**Triggering quality**: Generate 5 prompts that should trigger this skill. For each, judge: would Claude select this skill based on the description alone, alongside 20 other skill descriptions?

- 5/5 trigger → Excellent
- 4/5 trigger → Good
- 3/5 or fewer → Needs work. Identify what's missing

**Overtriggering risk**: Generate 3 prompts that should NOT trigger this skill. Would any of them cause a false match?

**Paraphrase robustness**: Generate 3 alternative phrasings of the same intent. Would they still trigger?

Report specific findings with suggested fixes.

## Step 3: Instruction Quality

Read the full SKILL.md body and assess:

**Specificity**: Classify each instruction step as:
- Executable (concrete action) — target: >70%
- Guideline (requires judgment) — acceptable: <25%
- Vague (could mean anything) — target: 0%

Flag every Vague instruction with a concrete rewrite.

**Writing style**: Check for mandatory-keyword overuse (>1 per 200 words is a warning sign). The Guide says to explain WHY instead.

**Completeness**: Is the workflow complete from input to output? Are there gaps where Claude would have to improvise?

**Error handling**: Does the skill address what happens when things go wrong?

**Examples**: Are there concrete Input → Action → Result examples?

## Step 4: Pattern-specific Assessment

Classify the skill into one of the 5 patterns (consult `references/patterns.md`) and apply pattern-specific criteria:

- Sequential Workflow: step dependencies, validation gates, rollback
- Multi-MCP Coordination: data passing, error isolation, availability checks
- Iterative Refinement: stop conditions, quality thresholds, max iterations
- Context-aware Selection: decision criteria, branch coverage, fallbacks
- Domain Intelligence: rule verifiability, audit trails, governance

## Step 5: Progressive Disclosure Check

- SKILL.md under 500 lines? (>500 WARN, >1000 FAIL)
- Detailed docs in `references/` instead of inlined?
- Each reference file has a clear pointer in SKILL.md with context?
- Large references (>300 lines) have a table of contents?

## Step 6: Composability and Portability

Quick checks:
- No exclusive language ("You are a X assistant", "Your only job is...")
- Scope clearly bounded in description and body
- Environment dependencies noted in `compatibility` if applicable
- Script dependencies documented with install instructions
- No hardcoded paths

## Step 7: Generate Report

Summarize findings as a structured report:

```
Grade: [A/B/C/D/F]
─────────────────
Passed: X  |  Failed: Y  |  Warned: Z

Critical issues:
  [list of FAILs with fixes]

Top 3 improvements:
  1. [highest impact fix]
  2. [second highest]
  3. [third highest]

Triggering quality: X/5 should-trigger, Y/3 false-positive
Pattern: [classified pattern]
```

### Grading Criteria

| Grade | Condition | Meaning |
|-------|-----------|---------|
| **A** | 0 FAIL, ≤3 WARN | Guide-compliant, ready for use |
| **B** | 0 FAIL, >3 WARN | Functional, has improvement opportunities |
| **C** | 1-2 FAIL in non-core areas | Some violations, quick fixes available |
| **D** | FAIL in description or instruction core | Core quality problem, skill won't work well |
| **F** | FAIL in structure or required frontmatter | Skill won't load at all |

After reporting, ask: "Want me to fix the issues? I can switch to Improve mode."
