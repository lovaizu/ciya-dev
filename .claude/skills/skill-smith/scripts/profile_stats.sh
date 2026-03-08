#!/usr/bin/env bash
#
# Compute summary statistics from profiling metrics.
#
# Usage: bash scripts/profile_stats.sh < input.tsv
#        echo -e "1\tduration_ms\t1500\n..." | bash scripts/profile_stats.sh
#
# Input:  Tab-separated lines: step_number<TAB>metric_name<TAB>value
#         One line per observation (step × metric × run).
#         Values must be non-negative numbers (integers or decimals).
#
# Output: Tab-separated lines: step_number<TAB>metric_name<TAB>avg<TAB>median<TAB>stddev<TAB>min<TAB>max<TAB>proportion
#         proportion = step's avg / sum of all steps' avg for that metric (0–1 scale).
#         Sorted by step_number then metric_name.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input=$(cat)

if [[ -z "$input" ]]; then
  echo "error: no input data" >&2
  exit 1
fi

printf '%s\n' "$input" | awk -f "$SCRIPT_DIR/profile_stats.awk" | sort -t$'\t' -k1,1n -k2,2
