# ciya-dev

Claude Code in your area

## Step-by-step Usage

### First-time setup

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/wc.sh | bash

# You now have:
#   ciya-dev/.bare/    ← bare clone
#   ciya-dev/.env      ← from .env.example (edit this)
#   ciya-dev/main/     ← main branch worktree
#   ciya-dev/up.sh     ← symlink → main/scripts/up.sh

cd ciya-dev
vi .env    # Set GH_TOKEN and other tokens
```

### Starting worktrees and CC

```bash
./up.sh 4
# Creates work-1/ through work-4/ worktrees
# Launches tmux session "ciya" with 5 panes:
#   main/ | work-1/ | work-2/ | work-3/ | work-4/
# Each pane starts Claude Code automatically
```

### Resuming a previous session

```bash
./up.sh
# No arguments → reads saved config and starts with the same number of worktrees
# If last run was "up.sh 4", this is equivalent to "up.sh 4"
```

### Scaling worktrees up and down

```bash
./up.sh 6
# Adds work-5/ and work-6/ to the existing worktrees
# Restarts tmux with 7 panes (main + 6 workers)

./up.sh 4
# Removes work-5/ and work-6/ (only if they have no uncommitted changes)
# Restarts tmux with 5 panes (main + 4 workers)
```

### Keeping up.sh up to date

```bash
# In the main/ worktree:
cd main && git pull && cd ..

# up.sh at repo root is a symlink to main/scripts/up.sh
# After git pull, ./up.sh automatically runs the latest version
```

### Working on issues

In the **main/** pane:
```
/hi                    # Start hearing → brainstorm → create issue on GitHub
                       # Review the issue on GitHub, leave comments if needed
/fb                    # Address any issue comments
/ty                    # Gate 1: Approve the goal
```

In a **work-N/** pane:
```
/hi 42                 # Start working on issue #42
                       # Creates branch, work records, and draft PR on GitHub
                       # Review the PR on GitHub, leave comments if needed
/fb                    # Address any PR comments
/ty                    # Gate 2: Approve the approach → implementation begins
                       # ... CC implements, pushes commits ...
                       # Review on GitHub, leave comments if needed
/fb                    # Address any review comments
/ty                    # Gate 3: Verify goal achieved → squash merge
```

### Interrupting and resuming work

```
/bb                    # In any work-N/ pane: saves state to .ciya/issues/nnnnn/resume.md
                       # You can now work on a different issue in this pane

/hi 42                 # Later, in any work-N/: reads resume.md and picks up where you left off
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
├── up.sh               Symlink → main/scripts/up.sh
├── main/               Issue management worktree
│   ├── scripts/        wc.sh, up.sh
│   ├── .ciya/
│   │   └── issues/     Work records per issue
│   ├── .claude/        Commands, rules, hooks
│   └── ...
├── work-1/             Implementation worktree
├── work-2/
├── work-3/
└── work-4/
```
