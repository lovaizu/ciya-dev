# skill-smith vs skill-creator Comparison

## Context

- skill-creator was published to [anthropics/skills](https://github.com/anthropics/skills) on GitHub (Apache 2.0 license)
- This is the same skill previously only available via Claude.ai, now including Eval, Benchmark, Description Optimization, and Blind Comparison capabilities
- skill-smith (this repository) has Create, Improve, Evaluate, and Profile modes
- This comparison evaluates both tools after #34 (Profile mode) was implemented in skill-smith

## Structural Comparison

| Aspect | skill-smith | skill-creator |
|--------|------------|---------------|
| Language | Bash/AWK | Python |
| Modes | Create, Improve, Evaluate, Profile | Create, Improve, Eval, Benchmark, Description Optimization |
| Validation | Comprehensive (30+ checks, A-F grading via validate.sh) | Minimal (quick_validate.py: frontmatter only) |
| Eval approach | Static analysis (structural + checklist grading) | Execution-based (run skill on test prompts, grade outputs) |
| Benchmark | None | Full pipeline (with/without skill comparison, statistics, viewer) |
| Profiling | Per-step execution metrics via Task tool | None |
| Description optimization | Manual checking in Evaluate mode | Automated loop (generate eval queries, run `claude -p`, improve with extended thinking) |
| Blind comparison | None | A/B comparison via specialized comparator agent |
| Specialized agents | None | grader.md, comparator.md, analyzer.md |
| Output viewer | Markdown reports | Rich HTML eval viewer (qualitative outputs + quantitative benchmark) |
| Packaging | None | .skill file (ZIP format) |
| Reference architecture | patterns.md, writing-guide.md, checklist.md, 4 workflow files | schemas.md (JSON schemas only) |
| Writing guidance | Comprehensive (5 workflow patterns, anti-patterns, progressive disclosure) | Inline in SKILL.md (less structured but practical) |
| Test infrastructure | Bash test suites (validate_test.sh, profile_stats_test.sh) | None |
| External dependencies | None (pure bash/awk) | Python 3, `claude` CLI (for description optimization) |

## Capability Analysis

### Where skill-creator is stronger

1. **Execution-based evaluation** — Runs the skill on real test prompts and grades output quality. This is fundamentally more rigorous than skill-smith's static analysis, which can only check structure and patterns but cannot verify that the skill actually produces good results when used.

2. **Benchmark pipeline** — Compares with-skill vs without-skill (or old vs new skill) quantitatively. Mean, stddev, min, max for pass_rate, time, tokens across multiple runs. skill-smith has no equivalent.

3. **Description optimization** — Automated triggering accuracy loop using `claude -p` with train/test split to avoid overfitting. Generates eval queries, runs multiple iterations with extended thinking, produces HTML report. skill-smith only has manual description quality checks in Evaluate mode.

4. **Eval viewer** — Rich HTML UI for reviewing test case outputs side-by-side with feedback, previous iterations, formal grades, and benchmark data. skill-smith outputs markdown only.

5. **Blind comparison** — Independent A/B comparison by an agent that doesn't know which version produced which output. Reduces bias in quality assessment.

6. **Specialized agents** — Grader (assertion evaluation), Comparator (blind A/B), Analyzer (post-hoc analysis) are well-defined agent roles with clear inputs/outputs/schemas.

7. **Packaging** — .skill file format for distribution.

### Where skill-smith is stronger

1. **Structural validation** — 30+ automated checks (frontmatter, naming, description quality, instruction quality, error handling, examples, progressive disclosure, composability, portability, security) with A-F grading. quick_validate.py only checks basic frontmatter.

2. **Per-step profiling** — Measures time, tokens, cost, tool calls per skill step. Identifies bottlenecks with concrete improvement suggestions. skill-creator has no equivalent — it measures aggregate per-run metrics only.

3. **Writing guidance** — Structured reference files (patterns.md with 5 workflow patterns, writing-guide.md with anti-patterns, checklist.md with evaluation criteria) provide reusable knowledge. skill-creator's guidance is inline in SKILL.md.

4. **Test coverage** — validate.sh and profile_stats.sh have comprehensive test suites. skill-creator has no tests for its Python scripts.

5. **Zero dependencies** — Pure bash/awk, no Python required.

### Complementary capabilities (no overlap)

| Capability | Source | Value |
|-----------|--------|-------|
| Execution-based eval + grading | skill-creator | Verifies skill actually works |
| Benchmark (with/without comparison) | skill-creator | Quantifies skill impact |
| Description optimization loop | skill-creator | Improves triggering accuracy |
| Blind A/B comparison | skill-creator | Unbiased quality comparison |
| Eval viewer HTML UI | skill-creator | Human review workflow |
| Structural validation (30+ checks) | skill-smith | Catches structural problems early |
| Per-step profiling | skill-smith | Identifies execution bottlenecks |
| Workflow pattern classification | skill-smith | Pattern-specific quality criteria |
| .skill packaging | skill-creator | Distribution format |

## Evaluation

### Core question: Which tool produces better skills?

skill-creator's execution-based eval loop is the decisive advantage. The fundamental limitation of skill-smith's Evaluate mode is that static analysis can tell you whether a skill is well-structured, but it cannot tell you whether the skill actually produces good results. skill-creator closes this gap by running the skill on real prompts, grading outputs against assertions, and iterating based on measured results.

skill-smith's strengths (structural validation, profiling, writing guidance) are complementary — they address different quality dimensions that skill-creator does not cover.

### Assessment

| Dimension | Winner | Rationale |
|-----------|--------|-----------|
| Creating a skill from scratch | Tie | Both have similar interview→draft→test flows. skill-creator has richer eval loop; skill-smith has better writing guidance. |
| Improving an existing skill | skill-creator | Execution-based eval with before/after comparison is far more rigorous than skill-smith's static diagnosis. |
| Evaluating skill quality | skill-creator | Execution-based grading + benchmark > static structural analysis. But skill-smith catches structural issues skill-creator misses. |
| Profiling execution performance | skill-smith | skill-creator has no equivalent. |
| Optimizing description/triggering | skill-creator | Automated loop with train/test split vs manual checking. |
| Structural correctness | skill-smith | 30+ checks vs 5 basic checks. |

## Decision: Use both tools with distinct roles

### Role separation

| Purpose | Tool | Rationale |
|---------|------|-----------|
| Skill creation | skill-smith Create | Structured interview, writing guidance, workflow patterns |
| Structural validation | skill-smith Evaluate | 30+ automated checks, A-F grading |
| Execution efficiency optimization | skill-smith Profile (#34) | Per-step metrics, bottleneck identification |
| Output quality evaluation and improvement | skill-creator Eval/Improve | Execution-based eval with assertions, human review via Viewer |
| Triggering accuracy optimization | skill-creator Description Optimization | Automated loop with train/test split |

### Why not consolidate into one tool?

- skill-smith is optimized for **multi-step, interactive skills** (our primary use case) — structural validation and per-step profiling work regardless of skill complexity
- skill-creator is optimized for **one-shot skills with clear IN/OUT** — its eval loop runs the entire skill in a subagent, which doesn't work well for interactive, multi-phase workflows
- The tools address different quality dimensions: structure and efficiency (skill-smith) vs output quality and triggering (skill-creator)

### Applicability to our skills

skill-creator's Eval/Improve loop is most effective for skills where:
- A single subagent execution produces a complete output
- Output quality can be checked with objective assertions
- With/without skill comparison is meaningful

Our multi-step, interactive skills (/ok, /bb, /fb, skill-smith) don't fit this pattern well. For these, output quality is verified through human gate reviews in our workflow.

skill-creator's value for our project is primarily:
- Description Optimization for any skill (automated triggering accuracy)
- Eval/Improve loop if we create one-shot skills in the future

### Action items

1. **#34**: Continue as-is — Profile mode for skill-smith (this PR)
2. **New issue**: Adopt skill-creator for output quality evaluation and description optimization (separate scope)
