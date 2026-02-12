Start new work by gathering requirements and creating an issue.

## Usage

Show this to the developer:

```
/hi              Start the hearing workflow (describe your goal → create issue → approve)
/hi <number>     Resume from an existing issue (skip hearing, go straight to PR drafting)
```

## If `$ARGUMENTS` is provided (a number)

The argument is an issue number:

1. Fetch the issue: `gh issue view $ARGUMENTS --json number,title,url,body,state`
2. If the issue does not exist, tell the developer
3. If the issue exists, treat it as approved (step 3 done) and proceed to step 4 (PR description drafting)

## If no `$ARGUMENTS`

Start the workflow from step 1 (Hearing):

1. Ask the developer to describe their goal — what they want to achieve and why
2. Ask clarifying questions until the goal and scope are clear
3. Draft the issue title in user story format (see `issue-format.md`)
4. Draft the issue body with Situation, Pain, Benefit, and Success Criteria
5. Present the draft to the developer and wait for `/ty` approval
