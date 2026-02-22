# Tool Adoption

## When This Applies

Any introduction of a new external tool, library, framework, or runtime that is not already part of the project.

## Process

1. **Identify the need**: What problem does the tool solve? Can it be solved with what we already have?
2. **Compare alternatives**: Evaluate at least 2 options (including "do nothing" / "use existing tools")
3. **Document the comparison**: Create a table with pros, cons, and fit for this project
4. **Get developer approval**: Present the comparison and recommendation; wait for approval before adopting
5. **Update setup**: If approved, add the tool to the setup script (`setup/wc.sh`) so all worktrees get it automatically

## Evaluation Criteria

- Does it solve a real, current problem (not a hypothetical future one)?
- Is the maintenance burden proportional to the benefit?
- Does it work in all environments the project targets?
- Can it be installed automatically via the setup script?
