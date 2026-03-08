# Profiling Report: expert-review

Test prompt: "Run expert review on my changes"
Runs: 1
Total: 309,000ms | 313,000 tokens | ~$9.39 | 45 tools
Note: Cost is approximate (total_tokens x blended rate of $0.030/1K tokens). With 1 run, statistics reflect single observations (stddev = 0).

## Per-Step Metrics

| Step | Duration | % | Tokens | % | Cost | % | Tools | % | Reads | Errors |
|------|----------|---|--------|---|------|---|-------|---|-------|--------|
| 1: Identify changed files | 3,200ms | 1.0% | 4,500 | 1.4% | ~$0.14 | 1.4% | 1 | 2.2% | 0 | 0 |
| 2: Categorize files by domain | 8,500ms | 2.8% | 12,000 | 3.8% | ~$0.36 | 3.8% | 0 | 0.0% | 0 | 0 |
| 3: Determine work records directory | 3,800ms | 1.2% | 5,200 | 1.7% | ~$0.16 | 1.7% | 1 | 2.2% | 0 | 0 |
| 4: Conduct expert reviews | 185,000ms | 59.9% | 195,000 | 62.3% | ~$5.85 | 62.3% | 28 | 62.2% | 24 | 0 |
| 5: Decide on findings | 22,000ms | 7.1% | 28,000 | 8.9% | ~$0.84 | 8.9% | 0 | 0.0% | 0 | 0 |
| 6: Implement accepted improvements | 65,000ms | 21.0% | 52,000 | 16.6% | ~$1.56 | 16.6% | 8 | 17.8% | 3 | 0 |
| 7: Commit and push | 12,000ms | 3.9% | 8,500 | 2.7% | ~$0.26 | 2.7% | 4 | 8.9% | 0 | 0 |
| 8: Update PR body | 9,500ms | 3.1% | 7,800 | 2.5% | ~$0.23 | 2.5% | 3 | 6.7% | 0 | 0 |

## Statistics (per step, 1 run)

| Step | Metric | Avg | Median | StdDev | Min | Max |
|------|--------|-----|--------|--------|-----|-----|
| 1: Identify changed files | duration_ms | 3,200 | 3,200 | 0 | 3,200 | 3,200 |
| 1: Identify changed files | total_tokens | 4,500 | 4,500 | 0 | 4,500 | 4,500 |
| 2: Categorize files by domain | duration_ms | 8,500 | 8,500 | 0 | 8,500 | 8,500 |
| 2: Categorize files by domain | total_tokens | 12,000 | 12,000 | 0 | 12,000 | 12,000 |
| 3: Determine work records directory | duration_ms | 3,800 | 3,800 | 0 | 3,800 | 3,800 |
| 3: Determine work records directory | total_tokens | 5,200 | 5,200 | 0 | 5,200 | 5,200 |
| 4: Conduct expert reviews | duration_ms | 185,000 | 185,000 | 0 | 185,000 | 185,000 |
| 4: Conduct expert reviews | total_tokens | 195,000 | 195,000 | 0 | 195,000 | 195,000 |
| 4: Conduct expert reviews | tool_uses | 28 | 28 | 0 | 28 | 28 |
| 4: Conduct expert reviews | files_read | 24 | 24 | 0 | 24 | 24 |
| 5: Decide on findings | duration_ms | 22,000 | 22,000 | 0 | 22,000 | 22,000 |
| 5: Decide on findings | total_tokens | 28,000 | 28,000 | 0 | 28,000 | 28,000 |
| 6: Implement accepted improvements | duration_ms | 65,000 | 65,000 | 0 | 65,000 | 65,000 |
| 6: Implement accepted improvements | total_tokens | 52,000 | 52,000 | 0 | 52,000 | 52,000 |
| 7: Commit and push | duration_ms | 12,000 | 12,000 | 0 | 12,000 | 12,000 |
| 7: Commit and push | total_tokens | 8,500 | 8,500 | 0 | 8,500 | 8,500 |
| 8: Update PR body | duration_ms | 9,500 | 9,500 | 0 | 9,500 | 9,500 |
| 8: Update PR body | total_tokens | 7,800 | 7,800 | 0 | 7,800 | 7,800 |

## Bottlenecks

1. **Step 4: Conduct expert reviews** -- Token-heavy + Read-heavy + Tool-heavy + Slow
   - Consumes 62.3% of total tokens, 59.9% of total duration, 62.2% of tool calls, 88.9% of file reads
   - This step reads all 22 changed files (117,325 bytes total) plus 2 reference files (domain-checklists.md at 7,016 bytes, review-format.md at 2,668 bytes) for a total of ~127K bytes of input context across 24 Read tool calls
   - For each of 4 domains (Shell scripting, Prompt engineering, CI/CD, Technical writing), the agent reads every file, evaluates against 15-25 checklist items per domain, identifies findings, writes review files with Scope/Evaluation/Decision tables
   - Root cause: the step combines reading, evaluating, and writing for ALL domains in a single monolithic step
   - **Suggestion 1**: Split Step 4 into parallel per-domain substeps. Each domain's review is independent -- Shell scripting files have no dependency on CI/CD files. If executed as separate subagents, 4 domains could run concurrently, reducing wall-clock time by ~60-75%.
   - **Suggestion 2**: Batch file reads per domain using Glob + parallel Read calls instead of sequential reads. Currently 24 individual Read calls could be reduced to 4-5 batched calls (one per domain group).
   - **Suggestion 3**: For the Technical Writing domain, work records (`.aiya/issues/`) files are generated artifacts, not implementation code. Consider excluding work records from expert review scope -- they are internal notes, not deliverables. This would eliminate ~9 file reads (51,124 bytes) of low-value review targets.
   - **Suggestion 4**: Pre-filter files by domain before reading. Currently the skill reads ALL files and then categorizes. Instead, categorize first (Step 2 output) and only read files relevant to each domain expert, avoiding loading irrelevant context.

## Recommendation

**Optimize Step 4 (Conduct expert reviews) first.** It dominates every metric: 62% of tokens, 60% of duration, 62% of tools, 89% of reads. The step is a monolithic loop that reads, evaluates, and writes for all domains sequentially.

The highest-impact improvement is splitting Step 4 into per-domain substeps that can execute in parallel. Each domain review is fully independent -- Shell scripting evaluation has no dependency on Prompt engineering evaluation. Running 4 domain reviews concurrently would reduce wall-clock time from ~185s to ~50-65s (bounded by the largest single domain), while total tokens remain similar.

The second-highest impact improvement is excluding work records from review scope. The 9 `.aiya/issues/` markdown files add 51KB of context that produces findings about internal notes rather than deliverable code. Removing them would cut Step 4's file reads by 37% and tokens by an estimated 20-25%.

Combined improvements would reduce Step 4 from 62% to an estimated 30-35% of total execution, bringing the skill closer to a balanced per-step distribution.
