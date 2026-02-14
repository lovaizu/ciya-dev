# Project Rules

- **CLAUDE.md** — Repository-specific rules: domain knowledge, deliverables, project-specific conventions
- **`.claude/rules/`** — Reusable rules that are not repository-specific, split into one file per topic

## Design Principle

- Always aim for the ideal state (To-Be), not incremental patches on the current state
- If a gap cannot be closed, explain why before falling back to alternatives
- Always propose — do not wait for instructions when you see an improvement opportunity

## Script Testing

- Every shell script must have a corresponding test script in the same directory, named `<script name>_test.sh` (e.g., `foo.sh` → `foo_test.sh`)
- Test scripts must use `mktemp -d` to create temporary environments and clean up (remove the temp directory) after completion
- Test scripts must be plain bash (no external test frameworks) and exit 0 on success, non-zero on failure
- Unit tests cover what can be tested in isolation (file creation, argument parsing, error handling, etc.)
- What cannot be unit tested (e.g., tmux sessions, CC startup) must be listed as manual test tasks for the developer
