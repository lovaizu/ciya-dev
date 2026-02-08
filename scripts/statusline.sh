#!/usr/bin/env bash

input=$(cat)

eval "$(echo "$input" | jq -r '
  @sh "dir=\(.workspace.current_dir // "")",
  @sh "model_id=\(.model.id // "")",
  @sh "display_name=\(.model.display_name // "Unknown")",
  @sh "token_in=\(.context_window.total_input_tokens // 0)",
  @sh "token_out=\(.context_window.total_output_tokens // 0)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "ctx=\(.context_window.used_percentage // 0)"
')"

dir=$(basename "$dir")
ctx=${ctx%%.*}

branch=$(git branch --show-current 2>/dev/null || echo "")

version=$(echo "$model_id" | sed -n 's/^claude-[a-z]*-\([0-9]\)-\([0-9]\).*/\1.\2/p')
if [ -n "$version" ]; then
  model="${display_name} ${version}"
else
  model="$display_name"
fi

cost_fmt=$(printf '$%.1f' "$cost")

echo "${dir} (${branch}) [${model}] [IN:${token_in} OUT:${token_out}] [${cost_fmt}] [ctx: ${ctx}%]"
