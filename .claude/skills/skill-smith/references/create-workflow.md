# Create

Build a new skill from intent to a working, Guide-compliant skill folder.

## Step 1: Capture Intent

Understand what the user wants. The conversation might already contain the workflow to capture (e.g., "turn this into a skill"). If so, extract from context first: tools used, step sequence, corrections made, input/output formats observed.

Gather these answers (from context or by asking):

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What is the expected output format?
4. What category does this skill fall into?

Consult `references/patterns.md` to classify into one of the 5 workflow patterns. This shapes the skill's structure.

## Step 2: Interview and Research

Proactively ask about:
- Edge cases and failure scenarios
- Input/output formats and example files
- Success criteria — what makes the output "good"?
- Dependencies (MCP servers, packages, external tools)

Don't make the user think of everything. Propose reasonable defaults and let them adjust.

## Step 3: Draft the Skill

### 3a. Create the folder structure

```
skill-name/
├── SKILL.md
├── scripts/      (if the skill needs executable code)
├── references/   (if detailed docs are needed beyond SKILL.md)
└── assets/       (if templates/fonts/icons are needed)
```

Only create directories the skill actually needs. Empty directories add noise.

### 3b. Write the frontmatter

The description is the most important part of the entire skill. It determines whether Claude ever loads it. Follow these rules:

**Structure**: `[WHAT it does] + [WHEN to use it with trigger phrases] + [optional: NOT for]`

**Be appropriately pushy**: Claude undertriggers skills. Include natural-language phrases users would actually say, paraphrases, and related intents. Better to trigger on a borderline case than miss a valid one.

Example of a well-crafted description:
```
description: Generates professional PDF reports from tabular data files
  (.csv, .xlsx, .tsv). Use when the user wants to "create a report",
  "make a PDF from data", "turn this spreadsheet into a document",
  or asks for formatted output from any tabular source. Also triggers
  for "summarize this data as a PDF" or "export as report".
```

**Constraints**: ≤1024 chars, no XML angle brackets, name in kebab-case.

### 3c. Write the instructions

Consult `references/writing-guide.md` for detailed patterns. Key principles:

- **Imperative voice**: "Validate the input" not "The input should be validated"
- **Explain why, not just what**: Instead of barking orders, explain rationale — "Validate input before processing — invalid data causes silent corruption in downstream steps"
- **Step-ordered structure**: Numbered steps or clear phases. Claude follows step-by-step most faithfully
- **Concrete over abstract**: "Run `bash scripts/validate.sh --input {file}`" not "validate properly"
- **Include examples**: At least one Input → Action → Result example
- **Error handling**: At least one failure scenario with recovery steps
- **Success conditions**: Describe what good output looks like

**Progressive Disclosure**: Keep SKILL.md under 500 lines. Move detailed reference material to `references/` with clear pointers: "Before writing queries, consult `references/api-patterns.md` for rate limits and pagination patterns."

### 3d. Write supporting files

- **scripts/**: Deterministic operations. Validation, formatting, data processing. Code is more reliable than prose instructions for repetitive tasks.
- **references/**: Detailed docs Claude reads on demand. API guides, schema docs, compliance rules. Add a table of contents for files over 300 lines.
- **assets/**: Templates, fonts, icons used in output. Not loaded into context.

## Step 4: Validate

Run the validation script to catch structural issues:

```bash
bash scripts/validate.sh <skill-folder-path>
```

Fix any FAIL items. Review WARN items and fix or justify.

## Step 5: Test

Generate 2-3 realistic test prompts — things a real user would actually say. Share with the user: "Here are some test cases. Do these look right?"

If the environment supports it, run the test prompts to see how Claude behaves with the skill. The first run should be in the main loop (not a subagent) so the user can see the transcript and give feedback.

## Step 6: Present

Present the completed skill folder to the user. Summarize what was created and suggest next steps:
- Upload to Claude.ai via Settings > Capabilities > Skills
- Place in Claude Code skills directory
- Iterate further with Improve mode
