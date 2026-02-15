# Skill Workflow Patterns

The Guide defines 5 common skill patterns. Classify every skill into one (or a hybrid) to apply pattern-specific quality criteria.

## How to Classify

Read the skill's instructions and match against these signals:

| Pattern | Signals |
|---------|---------|
| Sequential Workflow | Numbered steps, linear flow, "Step 1... Step 2..." |
| Multi-MCP Coordination | Multiple MCP references, phases across services |
| Iterative Refinement | Quality loops, "repeat until", validation + retry |
| Context-aware Selection | Decision trees, "if X then Y", conditional paths |
| Domain Intelligence | Specialized knowledge, compliance rules, expert logic |

---

## Pattern 1: Sequential Workflow

The most common pattern. Steps execute in fixed order.

**Quality checks:**

| Check | Why |
|-------|-----|
| Step dependencies are explicit | Implicit dependencies cause Claude to skip prerequisites |
| Validation gates between steps | Without gates, errors propagate silently through the chain |
| Rollback guidance for mid-workflow failures | Partial execution without cleanup leaves bad state |
| Data handoff: output of step N named as input to N+1 | Unclear handoffs cause Claude to re-derive or hallucinate |

**Good example:**
```
Step 1: Fetch data → output: projects.json
Step 2: Validate projects.json → if fails, stop and report errors
Step 3: Generate report from projects.json → output: report.pdf
```

## Pattern 2: Multi-MCP Coordination

Workflows that span multiple external services.

**Quality checks:**

| Check | Why |
|-------|-----|
| Each MCP interaction in its own phase | Mixing MCP calls creates debugging nightmares |
| Cross-MCP data passing instructions | Claude doesn't auto-serialize data between MCPs |
| Error isolation: one MCP failure doesn't cascade | Cascading failures waste all prior work |
| MCP availability check before starting | Failing mid-workflow wastes effort |

## Pattern 3: Iterative Refinement

Output improves through repeated cycles.

**Quality checks:**

| Check | Why |
|-------|-----|
| Stop condition defined | Without it, Claude loops indefinitely or stops randomly |
| Quality threshold is measurable | "Good enough" isn't a threshold; "all checks pass" is |
| Max iteration limit | Prevents infinite loops |
| Each iteration knows what to fix | Blind retrying without direction rarely converges |

## Pattern 4: Context-aware Selection

Different actions depending on input characteristics.

**Quality checks:**

| Check | Why |
|-------|-----|
| Decision criteria are measurable | "If large" is vague; "if > 10MB" is concrete |
| All branches lead to an action | Missing branches cause Claude to stall |
| Default/fallback exists | Real inputs often don't fit expected categories |
| Skill explains its choice to user | Users need to understand and potentially override |

## Pattern 5: Domain Intelligence

Specialized knowledge embedded in workflow logic.

**Quality checks:**

| Check | Why |
|-------|-----|
| Domain rules are verifiable | Wrong domain rules cause real harm |
| Audit trail for key decisions | Compliance requires traceability |
| Governance is documented | Who approves, what needs review |
| Time-sensitive knowledge is dated | Stale rules cause violations |

---

## Hybrid Skills

Many skills combine patterns. When classifying a hybrid:

1. Identify primary and secondary patterns
2. Apply primary pattern checks fully
3. Apply secondary pattern checks where engaged
4. Watch for pattern interaction issues

Example: A skill using Sequential Workflow (main flow) with Iterative Refinement (at one step for validation retry) needs full sequential checks plus stop condition / max iteration checks for the retry step.
