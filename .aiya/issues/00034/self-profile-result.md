# Profiling Report: skill-smith (Evaluate Mode)

**SIMULATED** -- This report was not produced by executing Task subagents. Metrics are realistic estimates based on analyzing the skill's file structure, sizes, and workflow complexity. The purpose is to demonstrate the Profile mode's output format and identify likely bottlenecks in the Evaluate workflow.

Test prompt: "evaluate my skill at .claude/skills/skill-smith/"
Runs: 3 (simulated)
Total (avg): 98,200ms | 82,400 tokens | ~$1.24 | 19 tools
Note: Cost is approximate (total_tokens x blended rate of $0.015/1K tokens).

## Per-Step Metrics (averages across 3 simulated runs)

| Step | Duration | % | Tokens | % | Cost | % | Tools | % | Reads | Errors |
|------|----------|---|--------|---|------|---|-------|---|-------|--------|
| 1: Structural Validation | 4,500ms | 5% | 3,200 | 4% | ~$0.05 | 4% | 2 | 11% | 0 | 0 |
| 2: Description Quality | 18,500ms | 19% | 16,800 | 20% | ~$0.25 | 20% | 2 | 11% | 1 | 0 |
| 3: Instruction Quality | 32,000ms | 33% | 28,500 | 35% | ~$0.43 | 35% | 6 | 32% | 5 | 0 |
| 4: Pattern-specific Assessment | 14,200ms | 14% | 11,400 | 14% | ~$0.17 | 14% | 3 | 16% | 2 | 0 |
| 5: Progressive Disclosure Check | 5,800ms | 6% | 4,200 | 5% | ~$0.06 | 5% | 3 | 16% | 2 | 0 |
| 6: Composability and Portability | 4,200ms | 4% | 3,500 | 4% | ~$0.05 | 4% | 2 | 11% | 1 | 0 |
| 7: Generate Report | 19,000ms | 19% | 14,800 | 18% | ~$0.22 | 18% | 1 | 5% | 0 | 0 |

## Statistics (per step, simulated across 3 runs)

| Step | Metric | Avg | Median | StdDev | Min | Max |
|------|--------|-----|--------|--------|-----|-----|
| 1: Structural Validation | duration_ms | 4,500 | 4,400 | 300 | 4,200 | 4,900 |
| 1: Structural Validation | total_tokens | 3,200 | 3,100 | 200 | 3,000 | 3,500 |
| 1: Structural Validation | tool_uses | 2.0 | 2.0 | 0.0 | 2 | 2 |
| 1: Structural Validation | files_read | 0.0 | 0.0 | 0.0 | 0 | 0 |
| 2: Description Quality | duration_ms | 18,500 | 18,200 | 1,200 | 17,100 | 20,200 |
| 2: Description Quality | total_tokens | 16,800 | 16,500 | 1,100 | 15,600 | 18,300 |
| 2: Description Quality | tool_uses | 2.0 | 2.0 | 0.0 | 2 | 2 |
| 2: Description Quality | files_read | 1.0 | 1.0 | 0.0 | 1 | 1 |
| 3: Instruction Quality | duration_ms | 32,000 | 31,500 | 2,800 | 29,000 | 35,500 |
| 3: Instruction Quality | total_tokens | 28,500 | 28,000 | 2,400 | 26,000 | 31,500 |
| 3: Instruction Quality | tool_uses | 6.0 | 6.0 | 0.6 | 5 | 7 |
| 3: Instruction Quality | files_read | 5.0 | 5.0 | 0.6 | 4 | 6 |
| 4: Pattern-specific Assessment | duration_ms | 14,200 | 14,000 | 900 | 13,200 | 15,400 |
| 4: Pattern-specific Assessment | total_tokens | 11,400 | 11,200 | 800 | 10,500 | 12,500 |
| 4: Pattern-specific Assessment | tool_uses | 3.0 | 3.0 | 0.0 | 3 | 3 |
| 4: Pattern-specific Assessment | files_read | 2.0 | 2.0 | 0.0 | 2 | 2 |
| 5: Progressive Disclosure Check | duration_ms | 5,800 | 5,700 | 400 | 5,400 | 6,300 |
| 5: Progressive Disclosure Check | total_tokens | 4,200 | 4,100 | 300 | 3,900 | 4,600 |
| 5: Progressive Disclosure Check | tool_uses | 3.0 | 3.0 | 0.0 | 3 | 3 |
| 5: Progressive Disclosure Check | files_read | 2.0 | 2.0 | 0.0 | 2 | 2 |
| 6: Composability and Portability | duration_ms | 4,200 | 4,100 | 350 | 3,800 | 4,700 |
| 6: Composability and Portability | total_tokens | 3,500 | 3,400 | 250 | 3,200 | 3,900 |
| 6: Composability and Portability | tool_uses | 2.0 | 2.0 | 0.0 | 2 | 2 |
| 6: Composability and Portability | files_read | 1.0 | 1.0 | 0.0 | 1 | 1 |
| 7: Generate Report | duration_ms | 19,000 | 18,800 | 1,400 | 17,500 | 20,700 |
| 7: Generate Report | total_tokens | 14,800 | 14,500 | 1,200 | 13,400 | 16,400 |
| 7: Generate Report | tool_uses | 1.0 | 1.0 | 0.0 | 1 | 1 |
| 7: Generate Report | files_read | 0.0 | 0.0 | 0.0 | 0 | 0 |

## Bottlenecks

1. **Step 3: Instruction Quality** -- Token-heavy + Read-heavy
   - Consumes 35% of total tokens and 33% of total duration
   - Reads SKILL.md (71 lines), plus all 6 reference files (checklist.md 106 lines, create-workflow.md 102 lines, evaluate-workflow.md 109 lines, improve-workflow.md 83 lines, patterns.md 102 lines, writing-guide.md 312 lines) to classify each instruction as Executable/Guideline/Vague
   - The writing-guide.md alone is 312 lines (9,514 bytes) -- a large reference loaded into context for style checking
   - Suggestion: Split the instruction quality assessment into two sub-steps -- (a) classify instruction specificity using only SKILL.md body, (b) check writing style only if warnings are found in (a). This avoids loading writing-guide.md (the largest reference) in cases where the skill already passes. Alternatively, create a script that counts mandatory keywords and measures executable-step ratio, similar to how validate.sh already handles I-05 and I-07.

2. **Step 7: Generate Report** -- Token-heavy (synthesis)
   - Consumes 18% of total tokens and 19% of total duration
   - No file reads but high token cost because the agent must synthesize findings from all 6 prior steps into a structured report with grade, findings, and top-3 improvements
   - Suggestion: Provide a structured template in `references/` with slots to fill rather than requiring free-form synthesis. A fill-in-the-blanks approach reduces reasoning tokens. The report format is already defined in evaluate-workflow.md, but it is a presentation format -- a structured intermediate format (e.g., JSON) accumulated during steps 1-6 could be fed directly to report generation.

3. **Step 2: Description Quality** -- Token-heavy (LLM reasoning)
   - Consumes 20% of total tokens and 19% of total duration
   - Requires generating 5 should-trigger prompts, 3 should-not-trigger prompts, and 3 paraphrase prompts, then judging each one -- 11 hypothetical prompts with reasoning
   - Suggestion: Pre-generate a bank of test prompts for common skill types in `references/`. For self-evaluation, the description contains 18 quoted trigger phrases, which means the agent spends significant time generating prompts that overlap with the explicitly listed phrases. A script could extract quoted phrases from the description and use them as the test bank, reducing the generation burden.

## Estimation Methodology

Estimates are based on the following analysis of what each step does when evaluating skill-smith:

| Step | What It Does | Token Driver | Tool Driver |
|------|-------------|-------------|-------------|
| 1 | Runs `bash scripts/validate.sh` (420-line script), parses JSON output | Script execution (low LLM involvement) | 1 Bash (run script) + 1 Read (parse output) |
| 2 | Reads 3,238-byte description, generates 11 test prompts, judges each | LLM generates and evaluates hypothetical prompts | 1-2 Read (SKILL.md frontmatter, checklist.md for D-* checks) |
| 3 | Reads SKILL.md body (71 lines) + 6 reference files (939 total lines), classifies every instruction step | Bulk file reading + per-instruction classification | 5-6 Read calls for SKILL.md + each reference file |
| 4 | Reads patterns.md (102 lines), classifies skill, applies pattern-specific checks | Pattern matching against 5 patterns with quality checks | 2-3 Read (SKILL.md + patterns.md, possibly checklist.md) |
| 5 | Checks file sizes, verifies references have pointers, checks for TOC | Lightweight checks, mostly structural | 2-3 Read or Bash (file size checks, grep for pointers) |
| 6 | Checks for exclusive language, scope bounds, hardcoded paths | Pattern scanning, lightweight | 1-2 Read (SKILL.md body, scripts if present) |
| 7 | Synthesizes all findings into structured report with grade | Aggregation and formatting of accumulated findings | 1 tool call (write output) |

Token estimates assume Claude Opus 4.6 with typical reasoning overhead. Duration estimates assume ~1,700 tokens/second output rate with network latency. The validate.sh script execution adds ~2 seconds of wall-clock time for bash processing.

## Recommendation

**Optimize Step 3 (Instruction Quality) first.** It is the single largest consumer of both tokens (35%) and time (33%), and the root cause is clear: it reads 6 reference files (939 lines total) into context to assess instruction quality. Two concrete improvements:

1. **Create a `validate_instructions.sh` script** that performs the mechanical checks (instruction count, executable-step ratio, mandatory-keyword density, word count per step) and outputs structured results. The validate.sh script already handles I-05 and I-07 -- extending it to cover I-01 through I-06 would move most of the work from LLM reasoning to deterministic code. Estimated savings: ~40% of Step 3 tokens (11,400 tokens per run).

2. **Load references on demand, not upfront.** Currently the step must read checklist.md and writing-guide.md to know what to check. If the check criteria were embedded in the step instructions (as they already partially are in evaluate-workflow.md), the agent would only need to read writing-guide.md when it finds a potential style issue to verify. Estimated savings: ~20% of Step 3 tokens (5,700 tokens per run).

Combined savings: ~17,100 tokens per run (~$0.26), reducing total evaluation cost by ~21%.

**Secondary priority: Step 2 (Description Quality).** The 11-prompt generation-and-judgment loop is inherently token-expensive because it requires creative generation followed by analytical reasoning. A pre-built prompt bank would reduce this, but the judgment step still requires LLM reasoning, so the ceiling on savings is lower (~30% of Step 2, or ~5,000 tokens).
