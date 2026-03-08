---
name: skill-smith
description: Create, improve, evaluate, and profile Claude skills following Anthropic's official Guide. Use when the user wants to "make a skill", "create a skill", "build a skill from scratch", "turn this into a skill", "improve this skill", "make this skill better", "fix my skill", "evaluate my skill", "review this skill", "audit this skill", "check skill quality", "profile this skill", "how fast is this skill", "optimize skill performance", "measure skill cost", "benchmark this skill", or references any skill development workflow. Also use when user uploads a SKILL.md and wants feedback or changes. Do NOT use for running execution-based evals or benchmarks (use skill-creator Eval/Benchmark modes instead).
---

# Skill Smith

Create, improve, evaluate, and profile Claude skills following the standards in Anthropic's "The Complete Guide to Building Skills for Claude."

Four capabilities, equal weight:

- **Create**: Build a new skill from a user's intent through interview, drafting, and validation
- **Improve**: Make an existing skill better through diagnosis and targeted fixes
- **Evaluate**: Assess a skill's quality against the Guide's standards
- **Profile**: Measure per-step execution metrics and identify bottlenecks

## Deciding What To Do

Read the user's request and jump in at the right point:

- "I want to make a skill for X" → **Create**
- "Turn this conversation/workflow into a skill" → **Create** (extract from context)
- "Make this skill better" / "Fix my skill" → **Improve**
- "Is this skill any good?" / "Review this skill" → **Evaluate**
- "Improve based on evaluation results" → **Evaluate** first, then **Improve**
- "Profile this skill" / "How fast is this skill?" / "Optimize performance" → **Profile**
- "Why is this skill slow?" / "Measure skill cost" → **Profile**

When unclear, ask the user which they need. When the user gives you a skill and a vague request, default to **Evaluate** first — it reveals what needs work.

After selecting a mode, tell the user which mode you chose and why — the user should understand what will happen before it starts.

For Evaluate, Improve, and Profile: if the user has not provided a skill folder path, ask for it before proceeding — these modes require an existing skill to work on.

---

# Create

Read `references/create-workflow.md` and follow the steps.

---

# Improve

Read `references/improve-workflow.md` and follow the steps.

---

# Evaluate

Read `references/evaluate-workflow.md` and follow the steps.

---

# Profile

Read `references/profile-workflow.md` and follow the steps.

---

# Principles

These guide all four modes. They come from the Guide itself.

1. **Description is king.** It determines whether Claude ever loads the skill. Prioritize it above everything else.

2. **Explain why, not just what.** Skills that explain rationale produce more consistent behavior than skills that bark orders with mandatory keywords.

3. **Appropriately pushy.** Claude undertriggers. Descriptions should lean toward inclusivity. Better to trigger on a borderline case than miss a valid one.

4. **Generalize, don't overfit.** When improving, address patterns, not individual examples. A fix that works for one case but doesn't generalize is a liability.

5. **Progressive disclosure.** SKILL.md is the core. References are for depth. Assets are for output. Respect the three-level loading hierarchy.

6. **Composability.** Skills coexist. Don't claim exclusive roles or restrict tools beyond your scope.
