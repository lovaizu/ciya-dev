# Improve

Make an existing skill better. Improvement can be driven by:
- Evaluation results (from Evaluate mode)
- User feedback ("this skill doesn't trigger", "output quality is bad")
- Known issues ("MCP calls keep failing")

## Step 1: Diagnose

If no evaluation exists, run a quick assessment:

1. Run `bash scripts/validate.sh <skill-path>` for structural checks
2. Read the SKILL.md and identify the most obvious issues
3. Classify the skill's pattern (consult `references/patterns.md`)

If evaluation results exist, use them directly — skip redundant analysis.

Identify the category of problems:

| Problem Type | Symptoms | Priority |
|-------------|----------|----------|
| **Won't load** | Structural/frontmatter violations | Fix first |
| **Won't trigger** | Description too narrow, missing phrases | Fix second |
| **Triggers wrong** | Description too broad, no negative triggers | Fix second |
| **Bad output** | Vague instructions, no examples, no error handling | Fix third |
| **Inefficient** | Too long, poor progressive disclosure, overfit | Fix fourth |

## Step 2: Plan Fixes

Present the diagnosis and proposed fixes to the user. For each fix:
- What the current state is
- What the fix changes
- Why it matters (tied to Guide principles)

Get user approval before applying, especially for description changes (they affect when the skill triggers) and instruction rewrites (they change behavior).

## Step 3: Apply Fixes

### Description Fixes

When the description needs improvement:

1. Extract current WHAT and WHEN components
2. Identify missing trigger phrases by considering how different users would request this functionality — experts, beginners, people who don't know the exact terminology
3. Draft new description following the structure: `[WHAT] + [WHEN with phrases] + [optional: NOT for]`
4. Verify ≤1024 chars, no angle brackets
5. Show the before/after to the user

### Instruction Fixes

When instructions need improvement:

1. Find all vague instructions — anything that could mean different things to different people
2. Rewrite each as a concrete action with specific commands or clear criteria
3. Replace mandatory-keyword overuse with rationale-based explanations
4. Add error handling for steps that could fail
5. Add examples where behavior is ambiguous
6. Verify step ordering and data flow between steps

### Structural Fixes

When the skill structure needs improvement:

1. If SKILL.md > 500 lines, identify content that belongs in `references/`
2. Move it, add clear pointers from SKILL.md
3. If scripts are missing for deterministic tasks, create them
4. Remove unused directories and placeholder files

### Generalize, Don't Overfit

When improving based on specific failures, look for the pattern behind the failure, not just the specific case. A fix that only helps one test prompt but doesn't generalize is a liability. Ask: "Would this fix help for any similar request, or just this exact one?"

If a stubborn issue resists targeted fixes, try a completely different approach — different metaphors, different workflow structure, different tool usage. It's cheap to experiment.

## Step 4: Re-validate

Run `bash scripts/validate.sh <skill-path>` again. Confirm the grade improved. If new WARNs appeared, review them.

## Step 5: Recommend Testing

After static improvement, recommend runtime testing:
- "Try these 3 prompts with the improved skill and see if it behaves better"
- If the user has skill-creator available, suggest Eval mode for systematic testing
