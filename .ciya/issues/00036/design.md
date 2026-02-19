## Problem Summary

The workflow, issue format, and PR format rules had structural gaps:
1. No explicit traceability between Approach/Tasks and Benefit/SC
2. Gates lacked purpose definitions — unclear what's relevant vs. irrelevant at each gate
3. Workflow philosophy was only in agent rules, not shared with the developer
4. Agent behavior lacked rules for proactive hearing and research

## Approach

1. Define a traceability chain: Situation → Pain → Benefit → SC ← Tasks ← Approach ← Pain
2. Restructure workflow.md around three phases (Goal, Approach, Delivery), each with purpose and gate definition
3. Create a README section explaining the philosophy with a diagram
4. Update issue-format.md and pr-format.md to make traceability explicit in the templates
5. Add agent behavior rules for hearing and research

## Key Decisions

- **Phase names match gate names:** Goal Phase → Goal Gate, Approach Phase → Approach Gate, Delivery Phase → Verification Gate. This makes the relationship between phase purpose and gate evaluation obvious.
- **Gate definitions include "relevant" and "irrelevant":** Explicitly stating what doesn't matter at each gate prevents scope creep in reviews (e.g., debating implementation details at the Goal gate).
- **Task → SC traceability in PR template:** Changed the Task format to include `→ SC: {which SC}` so each Task explicitly links to the SC it achieves. This closes the original gap where Tasks were not verified against SC.
- **README as shared reference:** The traceability chain and phase/gate philosophy are documented in README.md so both developers and agents work from the same mental model.

## Open Questions

None.
