# Issue Format

The issue defines user value. It is reviewed at Gate 1 (Goal): do Benefit and SC capture the right user value?

**Title:** Use user story format: "As a [role], I want [goal] so that [benefit]"

- [goal] must be the user's desired outcome, not a technical means or implementation detail
- [benefit] in the title must summarize the primary Benefit from the body's Benefit section
- Good: "I want to run multiple tasks in parallel"
- Bad: "I want a bare repo + worktree structure"

**Body:**

```
## Situation
{Concrete facts and observed circumstances}

## Pain
{Who is affected and what problem they face}

## Benefit
{Who benefits and how, once resolved}

- Use "[who] can [what]" form
- Each Benefit must trace from a Pain
- Good: "Developers can run multiple tasks in parallel"
- Bad: "Development throughput is improved"

## Success Criteria
- [ ] SC1: {Condition that verifies a Benefit is achieved}
- [ ] SC2: {Condition}

- Number each SC (SC1, SC2, ...) so the PR can reference them
- Each SC must verify a specific Benefit — an SC with no Benefit link is measuring the wrong thing
- Must be verifiable conditions, not tasks to complete
- Good: "SC1: A developer can create a worktree and start parallel work by following the documented steps"
- Bad: "SC1: CLAUDE.md has a Worktree section with setup instructions"
```
