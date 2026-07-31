Apply the Catalyst orchestration pattern to a ticket, right now, in this session.

Reference: Read ORCHESTRATION-PROMPT.md for the pattern.
If a matching skill exists in catalyst-skills/, use it. Otherwise apply the general pattern from ORCHESTRATION-PROMPT.md directly.

Ticket / task: use whatever text the user included in the same chat message as `/catalyst.md` as the ticket URL, ID, or description to work.

Execute in order, showing your work at each phase:

PHASE 1 — FAN OUT
State the independent analysis tasks you'll run. List them before running them. Then run each one using read-only tools (search, read file, list files, terminal commands like git log or a tracker MCP query) — issue them back-to-back without pausing to analyze between each.

PHASE 2 — REDUCE
Consolidate what you found. Remove duplicates and noise. State the root cause or core finding in one or two sentences.

PHASE 3 — VERIFY
For each significant finding, ask a skeptical question and check it against the actual code/tests — don't just re-assert your own analysis. State a verdict: valid or false positive.

PHASE 4 — SYNTHESIZE
Only using verified findings, produce a concrete implementation plan: files to change, tests to add, risks to check.

Do not use write/edit tools until the plan has been presented and confirmed.
