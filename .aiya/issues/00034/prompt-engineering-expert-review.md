# Prompt Engineering Expert Review

## Scope

| File | Description |
|------|-------------|
| `.claude/rules/approach-design.md` | Strengthened traceability between Approach table text and Step headings in Generate steps 3-4 and Verify check 3 |
| `.claude/skills/skill-smith/SKILL.md` | Added Profile mode: description triggers, mode list, routing table, and full Profile workflow (Steps 1-6) |

## Evaluation

| # | Finding | Severity | Improvement |
|---|---------|----------|-------------|
| 1 | `approach-design.md` step 3 packs two distinct instructions into one sentence: (a) draft the Approach table and (b) write each approach as a concise action phrase. The step-design rule says "one action per instruction" — combining them makes the second instruction easy to overlook. | Medium | Split into two numbered steps: step 3 drafts the table, new step 4 instructs to write each approach as a concise action phrase that serves as both table cell and Step heading. Renumber subsequent steps. |
| 2 | `SKILL.md` Profile Step 3 instructs the agent to extract `duration_ms`, `total_tokens`, and `tool_uses` from a `<usage>` block, but does not explain what this block is or where it comes from. The Task tool's response structure is not documented, so the agent may not find these fields. | Medium | Add a rationale clause explaining that the `<usage>` block is returned in Task subagent results and contains execution statistics. If the field names differ from the actual Task tool output, correct them. |
| 3 | `SKILL.md` Profile Step 3 instructs the agent to derive cost as `total_tokens x rate` with "(use current model pricing)" but provides no concrete rate or source. The agent has no way to look up pricing at runtime, leading to guesswork. | Medium | Provide a concrete default rate (e.g., a formula or a reference to a pricing source), or instruct the agent to report tokens only and let the user calculate cost — removing ambiguity about an unknowable runtime value. |
| 4 | `SKILL.md` Profile mode has no error handling for subagent failures. If a Task subagent fails mid-run (timeout, tool error, malformed output), there is no guidance on whether to retry, skip, or abort. The Create, Improve, and Evaluate modes each address failure scenarios, but Profile does not. | Medium | Add error handling guidance after Step 3: if a subagent fails or returns no PROFILE_METRICS line, retry once; if it fails again, record the step as errored and continue with remaining steps. Report incomplete runs in the final output. |
| 5 | `SKILL.md` Profile Step 4 says "If the script is unavailable, compute statistics directly" — this is a vague fallback. The agent has no concrete instructions for computing statistics inline (what formulas, what output format). | Low | Replace the vague fallback with an explicit instruction: "Compute mean, median, standard deviation, min, and max for each metric per step. Output in the same tab-separated format the script produces." Or remove the fallback since the script is part of the skill folder and should always be available. |
| 6 | `SKILL.md` description removed the negative trigger "Do NOT use for running execution-based evals or benchmarks (use skill-creator Eval/Benchmark modes instead)" that was present in the original. Removing scope boundaries increases overtriggering risk — the writing-guide and checklist (D-07) both recommend negative triggers when there is overlapping scope with other skills. | Medium | Restore the negative trigger clause or add an updated version that accounts for the new Profile mode, e.g., "Do NOT use for running execution-based evals or benchmarks (use skill-creator instead)." |
| 7 | `SKILL.md` Profile Step 1 says "Ask for a test prompt" and "Ask how many runs" as two separate questions. The Improve and Create modes batch their questions into a single interview step. Asking questions one at a time across multiple turns increases latency and token cost. | Low | Combine the two questions into a single ask: "Ask for a test prompt and how many runs to perform (default: 3)." This matches the interview pattern used in Create Step 2. |
| 8 | `approach-design.md` step 4 changed to "Use each unique Approach from the table as the exact Step heading" — this is clear and well-written. However, the rationale is only in the Verify section ("different text breaks traceability"). Moving the rationale to the Generate step would follow the step-design rule of explaining WHY at the point of action. | Low | Add rationale inline: "Use each unique Approach from the table as the exact Step heading — different text between the table and headings breaks traceability and confuses reviewers." |

## Decision

| # | Decision | Reason |
|---|----------|--------|
| 1 | Accepted | Violates the one-action-per-instruction rule from step-design.md. The second instruction (write as concise action phrase) is critical for the Approach-to-Step-heading traceability and risks being overlooked when packed into step 3. |
| 2 | Rejected | The `<usage>` block reference describes an internal mechanism of the Task tool that the executing agent would encounter at runtime. Documenting Task tool internals in the skill would couple the skill to implementation details that may change. The current instruction is sufficient as a hint. |
| 3 | Accepted | An unknowable runtime value produces unreliable output. Reporting tokens directly and letting the user derive cost is more honest and avoids hallucinated pricing. |
| 4 | Accepted | Every other mode handles failure scenarios. Profile mode involves external subagent execution, which is the most failure-prone operation in the skill. Missing error handling is a real gap. |
| 5 | Rejected | The script is packaged in the skill's `scripts/` directory and should always be available. The fallback is a defensive measure for edge cases. Making it more concrete adds bulk for a scenario that should not occur in normal use. |
| 6 | Accepted | Removing the negative trigger is a regression. The checklist (D-07) specifically flags missing negative triggers when there is scope overlap. The original boundary helped prevent overtriggering against skill-creator. |
| 7 | Rejected | Profile mode's two questions have different complexity levels. The test prompt requires the user to think about representative usage while the run count is a simple default-accept. Batching them may cause the user to overlook the more important question. The current approach is acceptable. |
| 8 | Accepted | The step-design rule says to explain WHY at the point of action so the agent generalizes correctly. Currently the rationale only appears in Verify, not where the action happens. |
