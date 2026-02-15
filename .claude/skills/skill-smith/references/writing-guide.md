# Skill Writing Guide

Detailed patterns for writing effective SKILL.md instructions. Read this when creating or rewriting skill instructions.

## Table of Contents

1. Description Craft
2. Instruction Patterns
3. Structural Patterns
4. Anti-patterns

---

## 1. Description Craft

The description field is the single most important element of any skill. It is the only information Claude has when deciding whether to load the skill.

### Structure

```
[WHAT: concrete function] + [WHEN: trigger conditions with phrases] + [optional: scope limits]
```

### Good Examples

**Document creation skill:**
```
description: Generates professional PDF reports from tabular data files
  (.csv, .xlsx, .tsv). Use when the user wants to "create a report",
  "make a PDF from data", "turn this spreadsheet into a document",
  or asks for formatted output from any tabular source. Also triggers
  for "summarize this data as a PDF" or "export as report".
  Do NOT use for simple data exploration (use data-viz skill instead).
```

Why it works: Concrete function (PDF reports from tabular data), multiple natural trigger phrases, file types listed, scope boundary with negative trigger.

**MCP integration skill:**
```
description: Manages Linear project workflows including sprint planning,
  task creation, and status tracking. Use when user mentions "sprint",
  "Linear tasks", "project planning", or asks to "create tickets",
  "plan the next sprint", or "what's the project status". Also use
  when user references Linear-specific concepts like cycles or initiatives.
```

Why it works: Names the specific service, lists both technical terms and natural phrases, covers different aspects of the workflow.

### Bad Examples and Fixes

**Too vague:**
```
# Bad
description: Helps with projects.

# Fixed
description: Creates and manages project task boards with kanban-style
  workflows. Use when user says "set up a project", "create a task board",
  "organize my tasks", or wants to track work items across stages.
```

**Missing WHEN:**
```
# Bad
description: Advanced statistical analysis tool with regression, clustering,
  and time series capabilities.

# Fixed
description: Performs statistical analysis including regression, clustering,
  and time series modeling. Use when user says "analyze this data",
  "find trends", "run a regression", "cluster these points", or uploads
  a dataset and asks for statistical insights.
```

**Too narrow (undertriggering):**
```
# Bad
description: Generates PDF reports from CSV data files using reportlab.

# Fixed (appropriately pushy)
description: Generates PDF reports from tabular data (.csv, .xlsx, .tsv).
  Use when user wants to "create a report", "make a PDF", "export data",
  "turn this into a document", or asks for formatted output from any
  data source, even if they don't specifically mention PDF.
```

---

## 2. Instruction Patterns

### Imperative Voice

Write direct commands. Passive and conditional language invites Claude to skip steps.

```
# Weak
The data should be validated before proceeding.
It would be good to check for errors.

# Strong
Validate the data before proceeding. Run `scripts/validate.py --input {file}`.
Check for errors: missing required fields, invalid date formats (use YYYY-MM-DD),
and duplicate entries.
```

### Explain Why (Not Just What)

The Guide explicitly recommends explaining rationale over mandatory language.

```
# Heavy-handed (avoid)
MUST ALWAYS validate input. NEVER skip this step.
MUST use the provided template. ALWAYS check for errors.

# Better — explains why
Validate input before processing — invalid data causes silent corruption
in downstream steps that's expensive to debug. Use the provided template
because it handles edge cases (unicode, empty fields) that raw formatting misses.
```

### Concrete Over Abstract

Every instruction should be specific enough that Claude can execute it without guessing.

```
# Vague (Claude will improvise — inconsistent results)
Make sure to validate things properly.
Process the document appropriately.
Ensure the output is well-formatted.

# Concrete (Claude knows exactly what to do)
Run `python scripts/validate.py --input {filename}` to check data format.
If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)

Extract text from the PDF, organize by heading hierarchy,
and output as Markdown with ## for top-level sections and ### for sub-sections.

Format the output as a table with columns: Name, Date, Amount.
Right-align numeric columns. Use comma separators for amounts > 999.
```

### Step-ordered Structure

Claude follows numbered steps most faithfully.

```
## Workflow

### Step 1: Fetch data
Call MCP tool: `fetch_projects`
Parameters: status=active, limit=50

### Step 2: Validate
Run `scripts/validate.py --data projects.json`
Expected: "Validation passed" message
If validation fails, check the error log and fix data issues before continuing.

### Step 3: Generate report
Use the template in `assets/report-template.md`
Fill in: project names, dates, status, metrics
Expected output: A Markdown file with one section per project
```

### Examples Pattern

Include at least one complete example showing Input → Action → Result.

```
## Example

User says: "Set up a new marketing campaign"

Actions:
1. Fetch existing campaigns via MCP: `list_campaigns --status active`
2. Ask user for campaign name, budget, and target dates
3. Create campaign: `create_campaign --name "Q2 Launch" --budget 50000`
4. Create 3 default tasks: creative brief, audience research, channel plan
5. Assign tasks to user

Result: Campaign "Q2 Launch" created with 3 tasks, accessible at [campaign URL]
```

### Error Handling

Include at least one failure scenario with recovery.

```
## Common Issues

### MCP Connection Failed
If you see "Connection refused":
1. Verify the MCP server is running (Settings > Extensions > [Service])
2. Confirm API key is valid and not expired
3. Try reconnecting: Settings > Extensions > [Service] > Reconnect
If still failing, inform the user and suggest checking the service's status page.

### Validation Failed
If `scripts/validate.py` reports errors:
- Missing fields: Add the required fields to the input file
- Invalid format: Check the expected format in `references/schema.md`
- Data too large: Split into batches of 1000 rows or fewer
```

---

## 3. Structural Patterns

### When to Use scripts/

Use scripts for deterministic, repetitive operations where code is more reliable than prose instructions:
- Input validation
- Data format conversion
- File manipulation
- Calculation and aggregation
- Output formatting

Scripts can be executed without being loaded into context. They reduce SKILL.md size and improve consistency.

### When to Use references/

Use references for detailed information Claude needs to read on demand but not always:
- API documentation
- Schema definitions
- Compliance rules
- Comprehensive workflow guides (>100 lines)

Always add a clear pointer from SKILL.md:
```
Before writing database queries, consult `references/schema.md`
for table definitions and relationship constraints.
```

For files over 300 lines, add a table of contents at the top.

### When to Use assets/

Use assets for files that become part of the output, not information for Claude to read:
- Document templates (.pptx, .docx)
- Font files
- Logo images
- Boilerplate code directories

### Progressive Disclosure Targets

| Content Type | Where It Goes | Size Target |
|-------------|---------------|-------------|
| Trigger conditions | description field | ≤1024 chars |
| Core workflow | SKILL.md body | ≤500 lines |
| Detailed reference | references/*.md | Unlimited (add TOC if >300 lines) |
| Executable logic | scripts/*.py | As needed |
| Output materials | assets/ | As needed |

---

## 4. Anti-patterns

### The MUST Overload

```
# Anti-pattern: every instruction is "mandatory"
MUST validate input. MUST check format. MUST verify schema.
ALWAYS run tests. NEVER skip validation. MUST log results.
CRITICAL: format output correctly. IMPORTANT: check all fields.

# Problem: When everything is critical, nothing is. Claude treats them all equally.
```

Fix: Reserve mandatory language for genuine safety/security constraints. For everything else, explain why.

### The Exclusive Claim

```
# Anti-pattern: claims to be the only skill
You are a document processing assistant. Your sole purpose is to handle
all document-related tasks. All document operations must go through this skill.

# Problem: Blocks other skills from functioning. Skills must coexist.
```

Fix: Describe what this skill does without claiming exclusive ownership of a domain.

### The Wall of Text

```
# Anti-pattern: 1000-line SKILL.md with everything inline
## Background
[200 lines of API documentation]
## Schema
[300 lines of table definitions]
## Workflow
[50 lines of actual instructions]
## Reference
[400 lines of edge cases]

# Problem: Core instructions buried. Wastes context window.
```

Fix: Keep the 50 lines of workflow in SKILL.md. Move the rest to `references/`.

### The Overfit Fix

```
# Anti-pattern: fixing one specific failure
If the user's name is "John" and the date is a Tuesday,
use format A instead of format B.

# Problem: Works for this exact case. Fails for everything else.
```

Fix: Find the pattern — "When names contain special characters, escape them before formatting." Generalize from the specific failure.
