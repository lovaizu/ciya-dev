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
   - **cost**: approximate, derived from total_tokens using the current model's per-token rate. Cost is approximate because the Task tool does not expose input/output token split — report the caveat once in the output header.
   - **result_summary**: first 200 characters of the result text

3. Store all metrics in a structured format (one row per step per run)

4. Handle subagent failures — profiling involves external execution, which is the most failure-prone operation:
   - If a subagent fails or returns no `PROFILE_METRICS` line, retry the step once
   - If it fails again, record the step as errored (duration=0, tokens=0, errors=1) and continue with remaining steps
   - Report incomplete runs in the final output so the user knows which data points are missing

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
Total (avg): {duration}ms | {tokens} tokens | ~${cost} | {tool_calls} tools
Note: Cost is approximate (total_tokens × blended rate).

## Per-Step Metrics (averages across {N} runs)

| Step | Duration | % | Tokens | % | Cost | % | Tools | % | Reads | Errors |
|------|----------|---|--------|---|------|---|-------|---|-------|--------|
| 1: {title} | {ms} | {%} | {n} | {%} | ~${n} | {%} | {n} | {%} | {n} | {n} |

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
