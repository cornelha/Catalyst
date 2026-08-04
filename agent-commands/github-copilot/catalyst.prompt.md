---
agent: 'agent'
description: Apply the Catalyst fan-out/reduce/verify/synthesize pattern to a ticket
---
Apply the Catalyst orchestration pattern to this ticket: ${input:ticket:Paste the ticket URL, ID, or description}

Reference: Read ORCHESTRATION-PROMPT.md for the pattern.
If a matching skill exists in catalyst-skills/, use it. Otherwise apply the general pattern from ORCHESTRATION-PROMPT.md directly.

Execute in order, showing your work at each phase:

PHASE 1 — FAN OUT
State the independent analysis tasks you'll run. List them before running them. Then actually run them (search the codebase, read files, check git history, check related issues, etc.). For this phase, the orchestrator must delegate investigation work to subagents whenever possible rather than doing all analysis inline in the main session.

PHASE 2 — REDUCE
Consolidate what you found. Remove duplicates and noise. State the root cause or core finding in one or two sentences.

PHASE 3 — VERIFY
For each significant finding, ask a skeptical question and check it against the actual code/tests — don't just re-assert your own analysis. State a verdict: valid or false positive.

PHASE 4 — SYNTHESIZE
Only using verified findings, produce a concrete implementation plan: files to change, tests to add, risks to check.

Stop after the plan and ask for confirmation before writing any code.
