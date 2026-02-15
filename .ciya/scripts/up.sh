#!/usr/bin/env bash
set -euo pipefail

# up.sh — Start or resume CC development environment.
# Creates/adjusts work worktrees and launches tmux with CC in each pane.
#
# Usage:
#   ./up.sh <n>    Create/adjust to n work worktrees + start tmux
#   ./up.sh        Resume with previous configuration
#
# Prerequisites: claude, git, tmux, gh

# Allow tests to override these variables before sourcing
if [ -z "${REPO_ROOT:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

  # Sanity check: verify we're in a bare repo structure
  if [ ! -d "$REPO_ROOT/.bare" ] && [ ! -f "$REPO_ROOT/.git" ]; then
    echo "Error: $REPO_ROOT does not look like a ciya-dev repo root" >&2
    exit 1
  fi
fi

CONFIG_FILE="${CONFIG_FILE:-$REPO_ROOT/.up_config}"
SESSION_NAME="${SESSION_NAME:-ciya}"

usage() {
  cat <<'USAGE'
Usage: up.sh [<n>]

Start or resume the CC development environment.

  up.sh <n>    Create main + n work worktrees, start tmux with CC
  up.sh        Resume with the previous configuration

Examples:
  up.sh 4      Start with 4 work worktrees (work-1 through work-4)
  up.sh 6      Add work-5 and work-6
  up.sh 2      Remove work-3 through work-6 (if clean)
  up.sh        Resume previous session
USAGE
}

check_prerequisites() {
  local missing=()
  for cmd in claude git tmux gh; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: missing required commands: ${missing[*]}" >&2
    echo "Install them before running up.sh." >&2
    exit 1
  fi
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
    echo "Error: no previous configuration found. Run: up.sh <n>" >&2
    exit 1
  fi
}

ensure_main_worktree() {
  if [ ! -d "$REPO_ROOT/main" ]; then
    echo "Creating main worktree..."
    git -C "$REPO_ROOT" worktree add main main
  fi
  # Update main
  git -C "$REPO_ROOT/main" pull --ff-only origin main 2>/dev/null \
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
      git -C "$REPO_ROOT" worktree add "$name" -b "$name" origin/main
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

launch_tmux() {
  local count="$1"

  # If session already exists, kill it to apply new configuration
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Terminating existing tmux session to apply new configuration..."
    tmux kill-session -t "$SESSION_NAME"
  fi

  load_env

  echo "Starting tmux session: $SESSION_NAME"

  local env_cmd="set -a && source '$REPO_ROOT/.env' && set +a"

  # Create session with main window
  tmux new-session -d -s "$SESSION_NAME" -n "main" -c "$REPO_ROOT/main"
  tmux send-keys -t "$SESSION_NAME:main" "$env_cmd && claude --dangerously-skip-permissions" Enter

  # Create work windows
  for i in $(seq 1 "$count"); do
    local name="work-$i"
    tmux new-window -t "$SESSION_NAME" -n "$name" -c "$REPO_ROOT/$name"
    tmux send-keys -t "$SESSION_NAME:$name" "$env_cmd && claude --dangerously-skip-permissions" Enter
  done

  # Select the main window
  tmux select-window -t "$SESSION_NAME:main"

  exec tmux attach -t "$SESSION_NAME"
}

# --- Main (only when executed directly, not sourced) ---

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  check_prerequisites
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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
