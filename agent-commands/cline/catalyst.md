Apply the Catalyst orchestration pattern to a ticket, right now, in this session.

The four-phase pattern is below — no need to read the reference file. If a matching skill exists in .catalyst/skills/, read that ONE file and follow it; otherwise apply the pattern below directly.

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

WORKTREES (after confirmation): if the repo uses git worktrees and this is a bug/feature ticket (not a code review), propose creating one at `../<repo>-<ticketid>` on branch `{feature|bug}/{ticketid}_{summary-slug}` (prefix from the skill used; slug = lowercase title, non-alphanumerics → `-`, truncate to 40 chars) and do the implementation inside it — see WORKTREE-WORKFLOW.md. Cleanup is user-triggered after the PR merges.
