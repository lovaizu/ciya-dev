# Shell Expert Review

## Scope

| File | Description |
|------|-------------|
| `.claude/skills/skill-smith/scripts/profile_stats.sh` | Bash wrapper that reads TSV from stdin, validates non-empty, pipes to awk, and sorts output |
| `.claude/skills/skill-smith/scripts/profile_stats.awk` | Awk script computing avg, median, stddev, min, max, and proportion per step/metric group |
| `.claude/skills/skill-smith/scripts/profile_stats_test.sh` | Test suite covering empty input, invalid fields, single/multiple observations, sorting, zero/decimal values |

## Evaluation

| # | Finding | Severity | Improvement |
|---|---------|----------|-------------|
| 1 | `echo "$input"` in `profile_stats.sh` line 27 is a portability hazard — if the stored input starts with `-n`, `-e`, or `-E`, bash's `echo` interprets them as flags instead of data. While current usage (TSV with numeric step as first field) avoids this, the fix is trivial. | Medium | Replace `echo "$input"` with `printf '%s\n' "$input"` on line 27 |
| 2 | `input=$(cat)` followed by `echo "$input"` buffers all stdin in a shell variable. For very large inputs this could exceed memory or ARG_MAX. | Low | Pipe stdin directly to awk and check exit status. However, the empty-input check on line 22 requires pre-reading stdin, making this a design trade-off for a tool that processes small profiling data. |
| 3 | The awk script silently coerces non-numeric values to 0 via `$3 + 0` (line 22), which could mask data corruption. The script header documents "Values must be non-negative numbers" but does not enforce it at runtime. | Low | Add a numeric validation check in the awk main block (e.g., `if ($3 !~ /^[0-9]*\.?[0-9]+$/)`). |
| 4 | `assert_contains` in the test file uses `[[ "$actual" == *"$expected"* ]]` glob matching. If `$expected` contained glob metacharacters (`*`, `?`, `[`), the match could give false results. | Low | Use `[[ "$actual" == *"${expected}"* ]]` or a `case` statement. In practice, all test strings are controlled literals with no glob characters. |
| 5 | The test file ends with `if [[ $failed -gt 0 ]]; then exit 1; fi` but has no explicit `exit 0`, relying on bash's implicit exit code of the last command. | Low | Add `exit 0` at the end for clarity. |

## Decision

| # | Decision | Reason |
|---|----------|--------|
| 1 | Accepted | `printf '%s\n'` is the universally safe replacement for `echo` with variable content. The fix is one line and eliminates an entire class of potential bugs. |
| 2 | Rejected | The empty-input check requires buffering stdin. The tool processes small profiling data (dozens to hundreds of lines), so memory is not a practical concern. Restructuring the flow adds complexity without benefit. |
| 3 | Rejected | The precondition is documented in the script header. Awk's `+0` coercion to zero for non-numeric strings is standard, well-understood behavior. The tool receives machine-generated TSV from the profiling pipeline, not user-typed input. Adding validation adds complexity for a scenario that does not arise in practice. |
| 4 | Rejected | All test expected strings are controlled string literals with no glob metacharacters. The theoretical risk does not apply to the actual test data, and adding quoting complexity provides zero practical benefit. |
| 5 | Rejected | Subjective style preference. Bash exits with the status of the last executed command, which is the `if` statement (exit code 0 when `$failed` is 0). The behavior is correct and explicit to anyone familiar with bash. |
