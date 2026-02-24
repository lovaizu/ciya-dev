---
name: skill-smith
description: Create, improve, evaluate, and profile Claude skills following Anthropic's official Guide. Use when the user wants to "make a skill", "create a skill", "build a skill from scratch", "turn this into a skill", "improve this skill", "make this skill better", "fix my skill", "evaluate my skill", "review this skill", "audit this skill", "check skill quality", "profile this skill", "how fast is this skill", "optimize skill performance", "measure skill cost", "benchmark this skill", or references any skill development workflow. Also use when user uploads a SKILL.md and wants feedback or changes.
---

# Skill Smith

Create, improve, evaluate, and profile Claude skills following the standards in Anthropic's "The Complete Guide to Building Skills for Claude."

Four capabilities, equal weight:

- **Create**: Build a new skill from a user's intent through interview, drafting, and validation
- **Improve**: Make an existing skill better through diagnosis and targeted fixes
- **Evaluate**: Assess a skill's quality against the Guide's standards
- **Profile**: Measure per-step execution metrics and identify bottlenecks

## Deciding What To Do

Read the user's request and jump in at the right point:

- "I want to make a skill for X" → **Create**
- "Turn this conversation/workflow into a skill" → **Create** (extract from context)
- "Make this skill better" / "Fix my skill" → **Improve**
- "Is this skill any good?" / "Review this skill" → **Evaluate**
- "Improve based on evaluation results" → **Evaluate** first, then **Improve**
- "Profile this skill" / "How fast is this skill?" / "Optimize performance" → **Profile**
- "Why is this skill slow?" / "Measure skill cost" → **Profile**

When unclear, ask the user which they need. When the user gives you a skill and a vague request, default to **Evaluate** first — it reveals what needs work.

---

# Create

Build a new skill from intent to a working, Guide-compliant skill folder.

## Step 1: Capture Intent

Understand what the user wants. The conversation might already contain the workflow to capture (e.g., "turn this into a skill"). If so, extract from context first: tools used, step sequence, corrections made, input/output formats observed.

Gather these answers (from context or by asking):

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What is the expected output format?
4. What category does this skill fall into?

Consult `references/patterns.md` to classify into one of the 5 workflow patterns. This shapes the skill's structure.

## Step 2: Interview and Research

Proactively ask about:
- Edge cases and failure scenarios
- Input/output formats and example files
- Success criteria — what makes the output "good"?
- Dependencies (MCP servers, packages, external tools)

Don't make the user think of everything. Propose reasonable defaults and let them adjust.

## Step 3: Draft the Skill

### 3a. Create the folder structure

```
skill-name/
├── SKILL.md
├── scripts/      (if the skill needs executable code)
├── references/   (if detailed docs are needed beyond SKILL.md)
└── assets/       (if templates/fonts/icons are needed)
```

Only create directories the skill actually needs. Empty directories add noise.

### 3b. Write the frontmatter

The description is the most important part of the entire skill. It determines whether Claude ever loads it. Follow these rules:

**Structure**: `[WHAT it does] + [WHEN to use it with trigger phrases] + [optional: NOT for]`

**Be appropriately pushy**: Claude undertriggers skills. Include natural-language phrases users would actually say, paraphrases, and related intents. Better to trigger on a borderline case than miss a valid one.

Example of a well-crafted description:
```
description: Generates professional PDF reports from tabular data files
  (.csv, .xlsx, .tsv). Use when the user wants to "create a report",
  "make a PDF from data", "turn this spreadsheet into a document",
  or asks for formatted output from any tabular source. Also triggers
  for "summarize this data as a PDF" or "export as report".
```

**Constraints**: ≤1024 chars, no XML angle brackets, name in kebab-case.

### 3c. Write the instructions

Consult `references/writing-guide.md` for detailed patterns. Key principles:

- **Imperative voice**: "Validate the input" not "The input should be validated"
- **Explain why, not just what**: Instead of barking orders, explain rationale — "Validate input before processing — invalid data causes silent corruption in downstream steps"
- **Step-ordered structure**: Numbered steps or clear phases. Claude follows step-by-step most faithfully
- **Concrete over abstract**: "Run `bash scripts/validate.sh --input {file}`" not "validate properly"
- **Include examples**: At least one Input → Action → Result example
- **Error handling**: At least one failure scenario with recovery steps
- **Success conditions**: Describe what good output looks like

**Progressive Disclosure**: Keep SKILL.md under 500 lines. Move detailed reference material to `references/` with clear pointers: "Before writing queries, consult `references/api-patterns.md` for rate limits and pagination patterns."

### 3d. Write supporting files

- **scripts/**: Deterministic operations. Validation, formatting, data processing. Code is more reliable than prose instructions for repetitive tasks.
- **references/**: Detailed docs Claude reads on demand. API guides, schema docs, compliance rules. Add a table of contents for files over 300 lines.
- **assets/**: Templates, fonts, icons used in output. Not loaded into context.

## Step 4: Validate

Run the validation script to catch structural issues:

```bash
bash scripts/validate.sh <skill-folder-path>
```

Fix any FAIL items. Review WARN items and fix or justify.

## Step 5: Test

Generate 2-3 realistic test prompts — things a real user would actually say. Share with the user: "Here are some test cases. Do these look right?"

If the environment supports it, run the test prompts to see how Claude behaves with the skill. The first run should be in the main loop (not a subagent) so the user can see the transcript and give feedback.

## Step 6: Present

Present the completed skill folder to the user. Summarize what was created and suggest next steps:
- Upload to Claude.ai via Settings > Capabilities > Skills
- Place in Claude Code skills directory
- Iterate further with Improve mode

---

# Improve

Make an existing skill better. Improvement can be driven by:
- Evaluation results (from Evaluate mode)
- User feedback ("this skill doesn't trigger", "output quality is bad")
- Known issues ("MCP calls keep failing")

## Step 1: Diagnose

If no evaluation exists, run a quick assessment:

1. Run `bash scripts/validate.sh <skill-path>` for structural checks
2. Read the SKILL.md and identify the most obvious issues
3. Classify the skill's pattern (consult `references/patterns.md`)

If evaluation results exist, use them directly — skip redundant analysis.

Identify the category of problems:

| Problem Type | Symptoms | Priority |
|-------------|----------|----------|
| **Won't load** | Structural/frontmatter violations | Fix first |
| **Won't trigger** | Description too narrow, missing phrases | Fix second |
| **Triggers wrong** | Description too broad, no negative triggers | Fix second |
| **Bad output** | Vague instructions, no examples, no error handling | Fix third |
| **Inefficient** | Too long, poor progressive disclosure, overfit | Fix fourth |

## Step 2: Plan Fixes

Present the diagnosis and proposed fixes to the user. For each fix:
- What the current state is
- What the fix changes
- Why it matters (tied to Guide principles)

Get user approval before applying, especially for description changes (they affect when the skill triggers) and instruction rewrites (they change behavior).

## Step 3: Apply Fixes

### Description Fixes

When the description needs improvement:

1. Extract current WHAT and WHEN components
2. Identify missing trigger phrases by considering how different users would request this functionality — experts, beginners, people who don't know the exact terminology
3. Draft new description following the structure: `[WHAT] + [WHEN with phrases] + [optional: NOT for]`
4. Verify ≤1024 chars, no angle brackets
5. Show the before/after to the user

### Instruction Fixes

When instructions need improvement:

1. Find all vague instructions — anything that could mean different things to different people
2. Rewrite each as a concrete action with specific commands or clear criteria
3. Replace mandatory-keyword overuse with rationale-based explanations
4. Add error handling for steps that could fail
5. Add examples where behavior is ambiguous
6. Verify step ordering and data flow between steps

### Structural Fixes

When the skill structure needs improvement:

1. If SKILL.md > 500 lines, identify content that belongs in `references/`
2. Move it, add clear pointers from SKILL.md
3. If scripts are missing for deterministic tasks, create them
4. Remove unused directories and placeholder files

### Generalize, Don't Overfit

When improving based on specific failures, look for the pattern behind the failure, not just the specific case. A fix that only helps one test prompt but doesn't generalize is a liability. Ask: "Would this fix help for any similar request, or just this exact one?"

If a stubborn issue resists targeted fixes, try a completely different approach — different metaphors, different workflow structure, different tool usage. It's cheap to experiment.

## Step 4: Re-validate

Run `bash scripts/validate.sh <skill-path>` again. Confirm the grade improved. If new WARNs appeared, review them.

## Step 5: Recommend Testing

After static improvement, recommend runtime testing:
- "Try these 3 prompts with the improved skill and see if it behaves better"
- If the user has skill-creator available, suggest Eval mode for systematic testing

---

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

---

# Profile

Measure per-step execution metrics for a skill and identify performance bottlenecks. Profiling reveals which steps consume the most time, tokens, and cost — turning optimization from guesswork into data-driven decisions.

## Step 1: Capture Target

1. Get the target skill folder path from the user (or detect from context)
2. Read the target skill's SKILL.md
3. Ask for a test prompt — a realistic user request that triggers the skill. The prompt determines what workload each step processes, so it should represent typical usage.
4. Ask how many runs to perform (default: 3) — more runs improve statistical stability but cost more

## Step 2: Parse Steps

1. Extract all numbered steps from the target SKILL.md (e.g., "## Step 1: ...", "## Step 2: ...")
2. For each step, capture:
   - Step number and title
   - Full instruction text (including sub-steps)
3. Present the parsed steps to the user for confirmation — misidentified steps invalidate all measurements

## Step 3: Execute and Record

For each run (1 to N):

1. For each step, launch a Task subagent with this prompt structure:

   ```
   You are executing one step of a skill to measure its performance.

   Target skill: {skill name}
   Test prompt (simulating a user request): "{test_prompt}"

   Execute this step's instructions:
   ---
   {step_instructions}
   ---

   After completing the step, append this summary line:
   PROFILE_METRICS: files_read={count} errors={count}
   ```

   Use `subagent_type: "general-purpose"` so the agent has full tool access.

2. From each Task result, extract:
   - **duration_ms**: from the `<usage>` block
   - **total_tokens**: from the `<usage>` block
   - **tool_uses**: from the `<usage>` block
   - **files_read**: from the `PROFILE_METRICS` line in the result
   - **errors**: from the `PROFILE_METRICS` line in the result
   - **cost**: derived as `total_tokens × rate` (use current model pricing)
   - **result_summary**: first 200 characters of the result text

3. Store all metrics in a structured format (one row per step per run)

## Step 4: Compute Statistics

After all runs complete, compute summary statistics per step per metric.

Run the statistics script:

```bash
bash scripts/profile_stats.sh <<'EOF'
{tab-separated metrics data: step_number, metric_name, value (one per line)}
EOF
```

The script outputs per-step statistics: average, median, standard deviation, min, max for each metric. It also outputs each step's proportion of the total for each metric.

If the script is unavailable, compute statistics directly — the formulas are standard (mean, median, stddev, min, max).

## Step 5: Analyze Bottlenecks

1. Identify bottleneck steps — any step consuming >30% of total for any metric is a bottleneck
2. For each bottleneck, classify the type and suggest improvements:

   | Bottleneck Type | Signal | Typical Improvement |
   |----------------|--------|---------------------|
   | Token-heavy | High total_tokens proportion | Reduce context size, split into sub-steps, use progressive disclosure |
   | Slow | High duration_ms proportion | Parallelize independent operations, reduce tool call chains |
   | Tool-heavy | High tool_uses proportion | Batch file reads, use Glob instead of individual reads, cache results |
   | Error-prone | errors > 0 | Add validation, improve error handling, clarify instructions |
   | Read-heavy | High files_read proportion | Consolidate reads, use targeted Grep instead of full file reads |

3. Generate concrete suggestions tied to the actual step content — "Step 3 reads 12 files individually; batch with a single Glob pattern" is actionable, "reduce file reads" is not

## Step 6: Present Report

Present results in this format:

```
# Profiling Report: {skill name}

Test prompt: "{test_prompt}"
Runs: {N}
Total (avg): {duration}ms | {tokens} tokens | ${cost} | {tool_calls} tools

## Per-Step Metrics (averages across {N} runs)

| Step | Duration | % | Tokens | % | Cost | % | Tools | % | Reads | Errors |
|------|----------|---|--------|---|------|---|-------|---|-------|--------|
| 1: {title} | {ms} | {%} | {n} | {%} | ${n} | {%} | {n} | {%} | {n} | {n} |

## Statistics (per step)

| Step | Metric | Avg | Median | StdDev | Min | Max |
|------|--------|-----|--------|--------|-----|-----|
| 1: {title} | duration_ms | ... | ... | ... | ... | ... |

## Bottlenecks

1. **Step {N}: {title}** — {bottleneck type}
   - Consumes {X}% of total {metric}
   - Suggestion: {concrete improvement}

## Recommendation

{Overall optimization priority: which step to improve first and why}
```

After presenting, ask: "Want me to improve the bottleneck steps? I can switch to Improve mode."

---

# Principles

These guide all four modes. They come from the Guide itself.

1. **Description is king.** It determines whether Claude ever loads the skill. Prioritize it above everything else.

2. **Explain why, not just what.** Skills that explain rationale produce more consistent behavior than skills that bark orders with mandatory keywords.

3. **Appropriately pushy.** Claude undertriggers. Descriptions should lean toward inclusivity. Better to trigger on a borderline case than miss a valid one.

4. **Generalize, don't overfit.** When improving, address patterns, not individual examples. A fix that works for one case but doesn't generalize is a liability.

5. **Progressive disclosure.** SKILL.md is the core. References are for depth. Assets are for output. Respect the three-level loading hierarchy.

6. **Composability.** Skills coexist. Don't claim exclusive roles or restrict tools beyond your scope.
