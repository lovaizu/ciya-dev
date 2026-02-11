#!/usr/bin/env bash

input=$(cat)

eval "$(echo "$input" | jq -r '
  @sh "dir=\(.workspace.current_dir // "")",
  @sh "display_name=\(.model.display_name // "Unknown")",
  @sh "token_in=\(.context_window.total_input_tokens // 0)",
  @sh "token_out=\(.context_window.total_output_tokens // 0)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "ctx=\(.context_window.used_percentage // 0)"
')"

full_dir="$dir"
dir=$(basename "$dir")
ctx=${ctx%%.*}

if [[ -n "$full_dir" ]]; then
  branch=$(git -C "$full_dir" branch --show-current 2>/dev/null || echo "")
else
  branch=""
fi

in_k=$(( (token_in + 500) / 1000 ))
out_k=$(( (token_out + 500) / 1000 ))

cost_fmt=$(printf '$%.1f' "$cost")

echo "${dir} (${branch}) [${display_name}] [in:${in_k}k out:${out_k}k] [${cost_fmt}] [ctx:${ctx}%]"
