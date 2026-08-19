---
agent: 'agent'
description: Generate test cases from a ticket's acceptance criteria, in the tracker's native format
---
Generate test cases from this ticket: ${input:ticket:Paste the ticket URL, ID, or description}

Execute in order:

STEP 1 — RESOLVE TICKET
Check what tracker MCP tools are available (e.g. azure-devops, jira, github, linear, or any configured issue-tracker connector). If only one tracker MCP is configured, use it. If multiple are configured, try the ticket reference against each; if ambiguous, ask the user which tracker to use. If no tracker MCP is available, ask the user to paste the full ticket content.

Fetch the complete ticket details: title, description, acceptance criteria, steps to reproduce (for bugs), expected behavior, priority, and work item type. If the ticket has no explicit acceptance criteria, derive them from the description — state what you inferred so the user can correct it.

STEP 2 — ANALYZE ACCEPTANCE CRITERIA
Decompose every acceptance criterion into discrete, testable assertions — one assertion per line, don't collapse multiple requirements into one. For each assertion, identify:

- Edge cases: boundary values, empty inputs, max lengths, concurrent access
- Error states: invalid input, missing required fields, unauthorized access, timeout
- Happy path: the primary expected behavior
- Negative path: what should NOT happen

Map each test case to a type: happy-path, boundary, error-handling, negative, regression.

STEP 3 — GENERATE TEST CASES
For each test case, produce:
- **Title**: what is being tested (criterion + edge case identifier)
- **Preconditions**: setup required before execution
- **Steps**: numbered actions to perform
- **Expected result**: concrete, verifiable outcome
- **Priority**: P1 (critical path), P2 (important), P3 (edge case) — derive from the criterion's importance to the ticket's goal
- **Type**: happy-path | boundary | error-handling | negative | regression

STEP 4 — DELIVER
Use the tracker's MCP tool to create the test cases if it supports it (e.g. Azure DevOps test case work items, Jira with Xray/Zephyr). Link created test cases back to the source ticket as child items or related links.

If the tracker does not support direct test case creation, output the test cases in the tracker's native format (e.g. Azure DevOps test case fields, Jira+Zephyr test format, GitHub issue checklist, Linear sub-issue format).

If the tracker is unknown or no MCP tool is available, output as a structured markdown table:

| ID | Title | Preconditions | Steps | Expected Result | Priority | Type |
|----|-------|---------------|-------|-----------------|----------|------|

Always display the generated test cases in your response for review, regardless of whether they were also created in the tracker.
