# Issue Format

**Title:** Use user story format: "As a [role], I want [goal] so that [benefit]"

- [goal] must be the user's desired outcome, not a technical means or implementation detail
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
- Good: "Developers can run multiple tasks in parallel"
- Bad: "Development throughput is improved"

## Success Criteria
- [ ] {Condition that verifies the Benefit is achieved}
- [ ] {Condition}

- Must verify Benefit achievement, not describe tasks to complete
- Good: "A developer can create a worktree and start parallel work by following the documented steps"
- Bad: "CLAUDE.md has a Worktree section with setup instructions"
```
