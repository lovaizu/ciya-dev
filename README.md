# ciya-dev
Claude Code in your area

## Getting Started

### 1. Clone (first time)

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/up.sh | bash
```

### 2. Set up environment

```bash
cd ciya-dev/main
cp .env.example .env
vi .env
```

`hi.sh` automatically sources `.env` from the worktree directory on startup.

### 3. Start or resume a task

```bash
cd ciya-dev
./main/scripts/hi.sh <branch-name or path>
```

For a new branch, this creates a worktree. For an existing branch, it enters the worktree. Then starts Claude Code — type `/go` to begin or resume the workflow.

### 4. Work

| Command | Description |
|---------|-------------|
| `/go`   | Start a new task or resume an in-progress task |
| `/fb`   | Address PR review feedback |
| `/ty`   | Approve and proceed to the next workflow step |

### 5. Clean up

After merging, remove the worktree:

```bash
cd ciya-dev
./main/scripts/bb.sh <branch-name-or-path>
```

## Skills

| Skill | Description |
|-------|-------------|
| skill-smith | Create, improve, and evaluate Claude skills following Anthropic's Guide. Includes structural validation with PASS/FAIL/WARN grading. |
