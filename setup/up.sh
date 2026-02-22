#!/usr/bin/env bash
set -euo pipefail

# up.sh — Start or resume CC development environment.
# Creates/adjusts work worktrees and launches tmux with CC in each pane.
#
# Usage:
#   ./up.sh <n>    Create/adjust to n work worktrees + start tmux
#   ./up.sh        Resume with previous configuration
#
# Prerequisites are installed by wc.sh (bootstrap).

# Allow tests to override these variables before sourcing
if [ -z "${REPO_ROOT:-}" ]; then  # LCOV_EXCL_START — auto-detect for direct execution only
  SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  # Sanity check: verify we're in a bare repo structure
  if [ ! -d "$REPO_ROOT/.bare" ] && [ ! -f "$REPO_ROOT/.git" ]; then
    echo "Error: $REPO_ROOT does not look like a ciya-dev repo root" >&2
    exit 1
  fi
fi  # LCOV_EXCL_STOP

CONFIG_FILE="${CONFIG_FILE:-$REPO_ROOT/.up_config}"
SESSION_NAME="${SESSION_NAME:-ciya}"
CIYA_DEFAULT_BRANCH="${CIYA_DEFAULT_BRANCH:-main}"

usage() {
  cat <<'USAGE'
Usage: up.sh [<n>]

Start or resume the CC development environment.

  up.sh <n>    Create main + n work worktrees, start tmux with CC
  up.sh        Resume previous configuration (default: 1 worktree)

Examples:
  up.sh 4      Start with 4 work worktrees (work-1 through work-4)
  up.sh 6      Add work-5 and work-6
  up.sh 2      Remove work-3 through work-6 (if clean)
  up.sh        Resume previous session
USAGE
}

check_env() {
  local env_file="$REPO_ROOT/.env"
  if [ ! -f "$env_file" ]; then
    echo "Error: .env not found. Copy .env.example and edit it:" >&2
    echo "  vi .env" >&2
    exit 1
  fi
  if grep -q "github_pat_xxxxx" "$env_file"; then
    echo "Error: .env still has placeholder tokens. Edit it first:" >&2
    echo "  vi .env" >&2
    exit 1
  fi
}

load_env() {
  local env_file="$REPO_ROOT/.env"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

# Determine the number of work worktrees
get_worker_count() {
  local arg="${1:-}"
  if [ -n "$arg" ]; then
    if ! [[ "$arg" =~ ^[1-9][0-9]*$ ]]; then
      echo "Error: argument must be a positive integer, got '$arg'" >&2
      exit 1
    fi
    echo "$arg"
  elif [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
  else
    echo "${CIYA_WORK_COUNT:-1}"
  fi
}

ensure_main_worktree() {
  if [ ! -d "$REPO_ROOT/main" ]; then
    echo "Creating main worktree..."
    git -C "$REPO_ROOT" worktree add main "$CIYA_DEFAULT_BRANCH"
  fi
  # Update main
  git -C "$REPO_ROOT/main" pull --ff-only origin "$CIYA_DEFAULT_BRANCH" 2>/dev/null \
    || echo "Warning: could not update main worktree" >&2
}

ensure_work_worktrees() {
  local count="$1"
  local needs_fetch=true
  for i in $(seq 1 "$count"); do
    local name="work-$i"
    local wt_dir="$REPO_ROOT/$name"
    if [ ! -d "$wt_dir" ]; then
      # Fetch once before creating any new worktrees
      if [ "$needs_fetch" = true ]; then
        git -C "$REPO_ROOT" fetch origin
        needs_fetch=false
      fi
      echo "Creating worktree: $name"
      git -C "$REPO_ROOT" worktree add "$name" -b "$name" "origin/$CIYA_DEFAULT_BRANCH"
    fi
  done
}

remove_excess_worktrees() {
  local count="$1"
  local i=$((count + 1))
  while true; do
    local name="work-$i"
    local wt_dir="$REPO_ROOT/$name"
    [ -d "$wt_dir" ] || break

    # Check if worktree is dirty
    if [ -n "$(git -C "$wt_dir" status --porcelain 2>/dev/null)" ]; then
      echo "Error: $name has uncommitted changes. Commit or stash first, then retry." >&2
      exit 1
    fi

    # Check for unpushed commits (use -d to refuse deleting unmerged branches)
    echo "Removing worktree: $name"
    git -C "$REPO_ROOT" worktree remove "$name"
    if git -C "$REPO_ROOT" rev-parse --verify "$name" >/dev/null 2>&1; then
      git -C "$REPO_ROOT" branch -d "$name" 2>/dev/null \
        || echo "Warning: branch '$name' has unmerged commits, kept for safety" >&2
    fi
    i=$((i + 1))
  done
}

# LCOV_EXCL_START — requires interactive tmux session; see manual tests in up_test.sh
launch_tmux() {
  local count="$1"
  local total=$((count + 1))
  local max_cols=4

  # If session already exists, kill it to apply new configuration
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Terminating existing tmux session to apply new configuration..."
    tmux kill-session -t "$SESSION_NAME"
  fi

  load_env

  echo "Starting tmux session: $SESSION_NAME"

  local env_cmd="set -a && source '$REPO_ROOT/.env' && set +a"

  # Build directory list: main first, then work-1..N
  local -a dirs=("$REPO_ROOT/main")
  for i in $(seq 1 "$count"); do
    dirs+=("$REPO_ROOT/work-$i")
  done

  # Collect pane IDs in dirs[] order for reliable targeting
  local -a pids=()

  # Create session with first pane (main)
  tmux new-session -d -s "$SESSION_NAME" -c "${dirs[0]}"
  pids+=("$(tmux display-message -t "$SESSION_NAME" -p '#{pane_id}')")

  if [ "$total" -le "$max_cols" ]; then
    # Single row: chain horizontal splits (each split divides the active pane)
    for (( i = 1; i < total; i++ )); do
      local pct=$(( 100 * (total - i) / (total - i + 1) ))
      pids+=("$(tmux split-window -h -P -F '#{pane_id}' -t "$SESSION_NAME" -c "${dirs[$i]}" -l "${pct}%")")
    done
  else
    # Two rows: top row has max_cols panes, bottom row has the rest
    local top_n=$max_cols
    local bot_n=$(( total - top_n ))

    # Create bottom row with full-width vertical split
    local bot_first
    bot_first=$(tmux split-window -v -f -P -F '#{pane_id}' -t "${pids[0]}" -c "${dirs[$top_n]}" -l 50%)

    # Fill top row: select first pane, then chain horizontal splits
    tmux select-pane -t "${pids[0]}"
    for (( i = 1; i < top_n; i++ )); do
      local pct=$(( 100 * (top_n - i) / (top_n - i + 1) ))
      pids+=("$(tmux split-window -h -P -F '#{pane_id}' -t "$SESSION_NAME" -c "${dirs[$i]}" -l "${pct}%")")
    done

    # Add bottom row first pane
    pids+=("$bot_first")

    # Fill bottom row if more than 1 pane
    if [ "$bot_n" -gt 1 ]; then
      tmux select-pane -t "$bot_first"
      for (( i = 1; i < bot_n; i++ )); do
        local dir_idx=$(( top_n + i ))
        local pct=$(( 100 * (bot_n - i) / (bot_n - i + 1) ))
        pids+=("$(tmux split-window -h -P -F '#{pane_id}' -t "$SESSION_NAME" -c "${dirs[$dir_idx]}" -l "${pct}%")")
      done
    fi
  fi

  # Launch CC in each pane
  for pid in "${pids[@]}"; do
    tmux send-keys -t "$pid" "$env_cmd && claude --dangerously-skip-permissions" Enter
  done

  # Select first pane (main)
  tmux select-pane -t "${pids[0]}"

  exec tmux attach -t "$SESSION_NAME"
}  # LCOV_EXCL_STOP

# --- Main (only when executed directly, not sourced) ---

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  check_env
  load_env

  cd "$REPO_ROOT"

  local count
  count="$(get_worker_count "${1:-}")"

  ensure_main_worktree
  ensure_work_worktrees "$count"
  remove_excess_worktrees "$count"

  # Save config after worktrees are successfully set up
  echo "$count" > "$CONFIG_FILE"

  launch_tmux "$count"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then  # LCOV_EXCL_START
  main "$@"
fi  # LCOV_EXCL_STOP
