# Worktree

This repository uses a bare repo + worktree structure to enable parallel Claude Code instances.

## Directory Layout

```
<repo-root>/
├── .bare/             # bare repository (metadata only)
├── .git               # pointer file to .bare
├── main/              # main branch worktree (always present)
├── feature-branch/    # work branch worktree
└── another-branch/    # work branch worktree
```

## Setup (first time)

Run the setup script provided in the repository's `scripts/up.sh`.

## Creating a Work Worktree

```bash
cd <repo-root>
./main/scripts/hi.sh <branch-name>
```

## Removing a Work Worktree

```bash
cd <repo-root>
./main/scripts/bb.sh <branch-name-or-path>
```

## Rules

- Worktree directory name must match the branch name
- The `main` worktree must always be present — it is the base for running scripts
- Always run `hi.sh` / `bb.sh` from the repository root directory
- Do not modify the `main` worktree directly — always work in a branch worktree
