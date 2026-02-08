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
vi .env          # Set ANTHROPIC_API_KEY and GH_TOKEN
source .env
```

`hi.sh` automatically sources `.env` from the worktree directory and sets `ALLOWED_DOMAINS_FILE` to the default path if not specified.

### 3. Start a task

```bash
cd ciya-dev/main
scripts/hi.sh <branch-name>
```

This creates a worktree, enters it, and starts Claude Code. Then type `/go` to begin the workflow.

### 4. Work

| Command | Description |
|---------|-------------|
| `/go`   | Start a new task or resume an in-progress task |
| `/fb`   | Address PR review feedback |
| `/ty`   | Approve and proceed to the next workflow step |

### 5. Clean up

After merging, remove the worktree from the `main` worktree:

```bash
cd ciya-dev/main
scripts/bb.sh <branch-name-or-path>
```
