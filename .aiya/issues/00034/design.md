## Problem Summary

Skill developers using skill-smith have no way to measure per-step execution performance (time, tokens, cost, tool calls) during skill execution. Without measured data, optimization is guesswork. LLM non-determinism means single measurements are unreliable.

## Approach

Add a Profile mode to skill-smith that executes each skill step via Claude Code's Task tool, captures returned metrics (duration_ms, total_tokens, tool_uses), and presents per-step results with proportions. Support repeated runs with summary statistics for statistical stability. Analyze results to identify bottlenecks and suggest improvements.

Two implementation areas:
1. **SKILL.md Profile mode** — Instructions for the profiling workflow (capture target, parse steps, execute via Task tool, repeat, analyze, present)
2. **Statistics computation script** — `scripts/profile_stats.sh` for reliable summary statistics (avg, median, stddev, min, max) from raw metrics, since statistics are a deterministic task suited to scripts rather than LLM math

## Key Decisions

- **Task tool for execution**: Each skill step is executed as a separate Task tool subagent invocation, which returns aggregate metrics (total_tokens, tool_uses, duration_ms). This is the only available per-step measurement mechanism.
- **Proxy metrics for tokens**: Task tool doesn't expose per-API-call token breakdown. Use total_tokens from aggregate metrics as the primary token measure.
- **Script for statistics**: Summary statistics (avg, median, stddev, min, max) are computed by a bash script rather than relying on LLM math — deterministic tasks belong in scripts per skill-smith conventions.
- **Default 3 runs**: Balance between statistical stability and cost/time. User can configure.
- **Description update**: Current description says "Do NOT use for running execution-based evals or benchmarks". Profile mode is execution-based but distinct from full eval/benchmark — update the exclusion to clarify scope.

## Open Questions

- None at this time — the approach is constrained by Task tool's available metrics.
