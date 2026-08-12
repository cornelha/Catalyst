---
agent: 'agent'
description: Apply the Catalyst fan-out/reduce/verify/synthesize pattern to a ticket
---
Apply the Catalyst orchestration pattern to this ticket: ${input:ticket:Paste the ticket URL, ID, or description}

The four-phase pattern is below — no need to read the reference file. If a matching skill exists in .catalyst/skills/, read that ONE file and follow it; otherwise apply the pattern below directly.

Before FAN OUT: if the ticket was given as a bare ID (e.g. #4521 or 4521, not a URL or pasted
description), resolve it to full ticket content first — pass the numeric ID only (strip any `#`
or URL wrapper) to the tracker's configured MCP tool. Do this before decomposing into FAN OUT
tasks below. If the ticket is a bare description with no ID or URL, skip tracker resolution and
work from the description itself.

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

WORKTREES (after confirmation): if the repo uses git worktrees and this is a bug/feature ticket (not a code review), propose creating one at `../<repo>-<ticketid>` on branch `{feature|bug}/{ticketid}_{summary-slug}` (prefix from the skill used; slug = lowercase title, non-alphanumerics → `-`, truncate to 40 chars) and do the implementation inside it — see WORKTREE-WORKFLOW.md. If the ticket has no ID (bare description), use `{feature|bug}/{summary-slug}` and `../<repo>-{summary-slug}` instead. Cleanup is user-triggered after the PR merges.
