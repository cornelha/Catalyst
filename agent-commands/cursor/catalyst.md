Apply the Catalyst orchestration pattern to a ticket, right now, in this session.

Reference: Read ORCHESTRATION-PROMPT.md for the pattern.
If a matching skill exists in catalyst-skills/, use it. Otherwise apply the general pattern from ORCHESTRATION-PROMPT.md directly.

Ticket / task: treat whatever text was typed after `/catalyst` when this command was invoked as the ticket URL, ID, or description to work.

Execute in order, showing your work at each phase:

PHASE 1 — FAN OUT
State the independent analysis tasks you'll run. List them before running them. Then actually run them (search the codebase, read files, check git history, query the issue tracker via an available MCP server, etc.) — genuinely in parallel where the tooling allows, not narrated-as-parallel-but-actually-sequential.

PHASE 2 — REDUCE
Consolidate what you found. Remove duplicates and noise. State the root cause or core finding in one or two sentences.

PHASE 3 — VERIFY
For each significant finding, ask a skeptical question and check it against the actual code/tests — don't just re-assert your own analysis. State a verdict: valid or false positive.

PHASE 4 — SYNTHESIZE
Only using verified findings, produce a concrete implementation plan: files to change, tests to add, risks to check.

Stop after the plan and ask for confirmation before writing any code, unless Auto-Apply/YOLO mode is explicitly intended for this session.
