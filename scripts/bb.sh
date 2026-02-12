#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bb.sh <branch-name-or-path>

Remove a worktree and clean up all associated artifacts:
  - Local worktree directory
  - Local branch
  - Remote branch

Before cleanup, verifies whether the associated PR/Issue is completed.
If not, asks for confirmation before proceeding.
USAGE
}

if [ $# -ne 1 ]; then
  usage >&2
  exit 1
fi

branch="$(basename "$1")"

if [ "$branch" = "main" ]; then
  echo "Error: cannot remove the 'main' worktree" >&2
  exit 1
fi

worktree_root="$(cd "$(dirname "$0")/../.." && pwd)"

# --- Completion check ---
# Look for a PR associated with this branch
pr_state=""
pr_number=""
if pr_json="$(gh pr list --head "$branch" --json number,state --jq '.[0] // empty' 2>/dev/null)" && [ -n "$pr_json" ]; then
  pr_number="$(echo "$pr_json" | gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null || true)"
  pr_state="$(gh pr view "$pr_number" --json state --jq '.state' 2>/dev/null || true)"
fi

incomplete=false
if [ -n "$pr_state" ] && [ "$pr_state" != "MERGED" ]; then
  echo "Warning: PR #$pr_number is $pr_state (not merged)." >&2
  incomplete=true
elif [ -z "$pr_state" ]; then
  # No PR found — check if there's a related issue by branch name pattern (e.g., issue-42)
  issue_number=""
  if [[ "$branch" =~ ^issue-([0-9]+)$ ]]; then
    issue_number="${BASH_REMATCH[1]}"
  fi
  if [ -n "$issue_number" ]; then
    issue_state="$(gh issue view "$issue_number" --json state --jq '.state' 2>/dev/null || true)"
    if [ -n "$issue_state" ] && [ "$issue_state" != "CLOSED" ]; then
      echo "Warning: Issue #$issue_number is $issue_state (not closed)." >&2
      incomplete=true
    fi
  fi
fi

if [ "$incomplete" = true ]; then
  read -rp "Proceed with cleanup anyway? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Aborted." >&2
      exit 0
      ;;
  esac
fi

# --- Cleanup ---
cd "$worktree_root"
git -C "$worktree_root/main" pull --ff-only origin main || echo "Warning: could not update main (continuing cleanup)" >&2

# Remove worktree (skip if already removed)
if git worktree list --porcelain | grep -q "worktree $worktree_root/$branch\$"; then
  git worktree remove "$branch"
  echo "Removed worktree: $branch"
else
  echo "Worktree already removed: $branch (skipping)"
fi

# Delete local branch (skip if already deleted)
if git rev-parse --verify "$branch" >/dev/null 2>&1; then
  git branch -D "$branch"
  echo "Deleted local branch: $branch"
else
  echo "Local branch already deleted: $branch (skipping)"
fi

# Delete remote branch (skip if never pushed or already deleted)
if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
  git push origin --delete "$branch"
  echo "Deleted remote branch: $branch"
else
  echo "Remote branch not found: $branch (skipping)"
fi

git remote prune origin

echo "Done! Cleaned up: $branch"
