# ciya-dev
Claude Code in your area

## Getting Started

### 1. Clone (first time)

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/up.sh | bash
```

### 2. Start or resume a task

```bash
cd ciya-dev
./main/scripts/hi.sh <branch-name or path>
```

For a new branch, this creates a worktree. For an existing branch, it enters the worktree. Then starts Claude Code — type `/go` to begin or resume the workflow.

### 3. Work

| Command | Description |
|---------|-------------|
| `/go`   | Start a new task or resume an in-progress task |
| `/fb`   | Address PR review feedback |
| `/ty`   | Approve and proceed to the next workflow step |

### 4. Clean up

After merging, remove the worktree:

```bash
cd ciya-dev
./main/scripts/bb.sh <branch-name-or-path>
```
