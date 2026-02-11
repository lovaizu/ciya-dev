# Worktree

This repository uses a bare repo + worktree structure to enable parallel Claude Code instances.

## Directory Layout

```
ciya-dev/
├── .bare/             # bare repository (metadata only)
├── .git               # pointer file to .bare
├── main/              # main branch worktree (always present)
├── feature-branch/    # work branch worktree
└── another-branch/    # work branch worktree
```

## Setup (first time)

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/up.sh | bash
```

## Creating a Work Worktree

```bash
cd /path/to/ciya-dev
./main/scripts/hi.sh <branch-name>
```

## Removing a Work Worktree

```bash
cd /path/to/ciya-dev
./main/scripts/bb.sh <branch-name-or-path>
```

## Rules

- Worktree directory name must match the branch name
- The `main` worktree must always be present — it is the base for running scripts
- Always run `hi.sh` / `bb.sh` from the `ciya-dev` root directory
- Do not modify the `main` worktree directly — always work in a branch worktree
