# ciya-dev

Claude Code in your area — multiple Claude Code instances, right in your dev environment.

- **No babysitting** — Three gates (Goal → Approach → Verification) guard quality so you don't have to watch over every step
- **Scale as one** — Async checkpoints let you run multiple instances in parallel and multiply your throughput
- **Walk away anytime** — Save and restore work state on demand. Step away, come back, pick up where you left off

## Traceability Chain

Every element in the workflow traces back to user value. If a link is missing, the process breaks.

```mermaid
flowchart TD
    subgraph p1["Phase 1: Goal — Define user value"]
        direction LR
        S[Situation] --> P[Pain]
        P --> B[Benefit]
        B --> SC[Success Criteria]
    end
    p1 --> G1{{"Gate 1: Right value?"}}
    G1 --> p2
    subgraph p2["Phase 2: Approach — Design means to achieve SC"]
        direction LR
        A[Approach] --> T[Steps]
    end
    T -.->|achieves| SC
    p2 --> G2{{"Gate 2: Right means?"}}
    G2 --> p3
    subgraph p3["Phase 3: Delivery — Verify achievement"]
        direction LR
        EX[Execute Steps] --> V[Verify SC met]
    end
    p3 --> G3{{"Gate 3: Value delivered?"}}
```

**Issue (what):**
- **Situation** — Observable facts and circumstances
- **Pain** — Who suffers and how (the problem to solve)
- **Benefit** — Who gains what, once resolved (the value to deliver)
- **Success Criteria** — Verifiable conditions that prove Benefit is achieved

**PR (how):**
- **Approach** — SC-to-means mapping table: what means will achieve each SC
- **Steps** — Concrete work steps to implement each Approach, grouped by Approach

Issue-side rules:
- Every Pain must arise from the Situation. A Pain with no Situation basis is an ungrounded assumption.
- Every Benefit must trace from a Pain. A Benefit with no Pain link is solving a problem that doesn't exist.
- Every SC must connect to a Benefit. An SC with no Benefit link is measuring the wrong thing.

PR-side rules:
- Every SC must appear in the Approach table. An uncovered SC will not be achieved.
- Every Step must be grouped under its Approach. A Step unrelated to any Approach indicates a misalignment.
- Steps must fully implement the Approach they belong to.

## Phases and Gates

The workflow has three phases. Each phase has a clear purpose, and a gate where the developer reviews whether that purpose is met.

| Phase | Purpose | Gate | The developer asks |
|-------|---------|------|--------------------|
| **Goal** | Define user value | Gate 1: Goal | Do Benefit and SC capture the right user value? |
| **Approach** | Design means to achieve SC | Gate 2: Approach | Can Approach and Steps achieve all SC? |
| **Delivery** | Verify achievement | Gate 3: Verification | Are SC met and Benefits realized? |

### Goal Phase (main/ worktree)

**Purpose:** Define what user value we want to deliver.

The developer and agent identify Pain, articulate the desired Benefit, and define Success Criteria that verify the Benefit is achieved.

**Gate 1 — Goal:**
- **Relevant:** Situation, Pain, Benefit, SC — are the facts accurate, the problem real, and the measure of success right?
- **Irrelevant:** Implementation details, current architecture, technical feasibility

### Approach Phase (work-N/ worktree)

**Purpose:** Design the means to achieve the Success Criteria.

The agent drafts an Approach table mapping each SC to its means, then defines Steps grouped by Approach.

**Gate 2 — Approach:**
- **Relevant:** Does Approach cover all SC? Do Steps implement the Approach? Is this the optimal strategy?
- **Irrelevant:** Whether the goal itself is right (already approved at Gate 1)

### Delivery Phase (work-N/ worktree)

**Purpose:** Implement and verify that the goal is achieved.

The agent implements Steps, verifies SC are met, and confirms Benefits are realized.

**Gate 3 — Verification:**
- **Relevant:** Are SC met? Are Benefits realized? Does the implementation match the approved Approach?
- **Irrelevant:** Whether the approach was optimal (already approved at Gate 2)

At each gate: review on GitHub, leave comments if needed (`/fb` to address them), then `/ty` to approve.

## Workflow

```mermaid
flowchart TD
    subgraph "main/ worktree"
        H["/hi — Hearing"] --> I["Issue → GitHub"]
        I --> R1["Developer reviews"]
        R1 --> FB1["/fb — Address comments"]
        FB1 --> R1
        R1 --> G1["/ty — Gate 1: Goal"]
    end

    subgraph "work-N/ worktree"
        HI["/hi N — Start or resume"] --> WR{Work records?}
        WR -- new --> BR["Create branch + PR"]
        WR -- resume --> RS["Restore state"]
        BR --> R2["Developer reviews"]
        RS --> R2
        R2 --> FB2["/fb — Address comments"]
        FB2 --> R2
        R2 --> G2["/ty — Gate 2: Approach"]
        G2 --> IMPL["Implementation"]
        IMPL --> CHK["Checks & Expert Review"]
        CHK --> R3["Developer reviews"]
        R3 --> FB3["/fb — Address comments"]
        FB3 --> R3
        R3 --> G3["/ty — Gate 3: Verification"]
        G3 --> MRG["Merge"]
    end

    G1 -.->|"/hi N in work-N/"| HI
    BB["/bb — Interrupt & save"] -.-> WR
```

**How it works:**
- You create issues in `main/` and assign them to `work-N/` panes — the agent handles the rest autonomously
- Your only job is to review at three gates: approve the goal, the approach, and the final result
- You interact through four commands (`/hi`, `/ty`, `/fb`, `/bb`) and review comments on GitHub — nothing else
- At any point, `/bb` saves progress for later resumption

## Usage

### First-time setup

```bash
curl -fsSL https://raw.githubusercontent.com/lovaizu/ciya-dev/main/scripts/wc.sh | bash

cd ciya-dev
vi .env    # Set GH_TOKEN and other tokens
```

### Starting sessions

```bash
./up.sh 4
# Opens 4 parallel workers (plus 1 for issue management)
# Launches tmux session "ciya" with 5 panes
# Each pane runs Claude Code automatically
```

### Resuming a previous session

```bash
./up.sh
# No arguments → reads saved config (or CIYA_WORK_COUNT from .env)
```

### Scaling up and down

```bash
./up.sh 6    # Scale up to 6 parallel workers
./up.sh 4    # Scale back to 4 (removes idle workers)
```

### Working on issues

In the **main/** pane:
```
/hi                    # Start hearing → brainstorm → create issue on GitHub
/fb                    # Address any issue comments
/ty                    # Gate 1: Approve the goal
```

In a **work-N/** pane:
```
/hi 42                 # Start working on issue #42
/fb                    # Address any PR comments
/ty                    # Gate 2: Approve the approach → implementation begins
                       # ... CC implements, pushes commits ...
/fb                    # Address any review comments
/ty                    # Gate 3: Verify goal achieved → squash merge
```

### Interrupting and resuming work

```
/bb                    # Saves state to .ciya/issues/nnnnn/resume.md
/hi 42                 # Later, in any work-N/: resumes where you left off
```

## Commands

| Command | Where | What it does |
|---------|-------|-------------|
| `/hi` | main/ | Start hearing → create issue |
| `/hi <issue#>` | work-N/ | Start or resume work on an issue |
| `/bb` | work-N/ | Interrupt work, save state for resumption |
| `/fb` | any | Address feedback comments on Issues or PRs |
| `/ty` | any | Approve the current gate |

## Directory Structure

```
ciya-dev/
├── .bare/              Bare clone
├── .env                Environment variables (CIYA_* prefix)
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

## Skills

| Skill | Description |
|-------|-------------|
| skill-smith | Create, improve, and evaluate Claude skills following Anthropic's Guide. Includes structural validation with PASS/FAIL/WARN grading. |
