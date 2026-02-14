# ciya-dev

Claude Code in your area

## Getting Started

### 1. Bootstrap (first time)

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/.ciya/scripts/wc.sh -o wc.sh
bash wc.sh
```

This creates `ciya-dev/` with a bare clone, `.env`, and `up.sh`.

### 2. Set up environment

```bash
cd ciya-dev
vi .env    # Set GH_TOKEN (required) and other tokens
```

### 3. Start

```bash
./up.sh 4    # Create main + 4 work worktrees, launch tmux with CC
```

### 4. Resume

```bash
./up.sh      # Resume with previous configuration
./up.sh 6    # Change to 6 work worktrees
```

## Workflow

```
CC (main/)                                  CC (work-N/)
──────────                                  ────────────

  /hi                                       /hi <issue#>
   │                                             │
   ▼                                             ▼
  Hearing                                   .ciya/issues/nnnnn/ read
  (brainstorm)                                   │
   │                                         ┌───┴───┐
   ▼                                        new   resume
  Issue → GitHub                             │       │
   │                                         ▼       ▼
   ▼                                        Branch   Restore
  Developer reviews on GitHub                │       │
   │                                         └───┬───┘
  /fb ← Issue comments                          ▼
   │                                        PR → GitHub
   ▼                                             │
  /ty ── Gate 1: Goal                            ▼
   │     Right problem and goal?            Developer reviews on GitHub
   ▼                                             │
  Next /hi                                  /fb ← PR comments
                                                 │
                                                 ▼
                                            /ty ── Gate 2: Approach
                                                 │  Can this achieve the goal?
                                                 ▼
                                            Implementation
                                                 │
                                                 ▼
                                            Checks & Review
                                                 │
                                            /fb ← PR comments
                                                 │
                                                 ▼
                                            /ty ── Gate 3: Goal Verification
                                                 │  Has the goal been achieved?
                                                 ▼
                                            Merge (--delete-branch)
                                                 │
                                                 ▼
                                            Next /hi

  * /bb at any point to interrupt and save state for later
```

## Commands

| Command | Where | What it does |
|---------|-------|-------------|
| `/hi` | main/ | Start hearing → create issue |
| `/hi <issue#>` | work-N/ | Start or resume work on an issue |
| `/bb` | work-N/ | Interrupt work, save state for resumption |
| `/fb` | any | Address feedback comments on Issues or PRs |
| `/ty` | any | Approve the current gate |

## Three Gates

| Gate | Question | Where |
|------|----------|-------|
| Goal | Is the issue capturing the right problem and goal? | GitHub Issue page |
| Approach | Can the PR's approach achieve the goal? | GitHub PR page |
| Goal Verification | Has the goal been achieved? | GitHub PR page |

At each gate: review on GitHub, leave comments if needed (`/fb` to address them), then `/ty` to approve.

## Directory Structure

```
ciya-dev/
├── .bare/              Bare clone
├── .env                Environment variables
├── up.sh               Symlink → main/.ciya/scripts/up.sh
├── main/               Issue management worktree
│   ├── .ciya/
│   │   ├── scripts/    wc.sh, up.sh
│   │   └── issues/     Work records per issue
│   ├── .claude/        Commands, rules, hooks
│   └── ...
├── work-1/             Implementation worktree
├── work-2/
├── work-3/
└── work-4/
```
