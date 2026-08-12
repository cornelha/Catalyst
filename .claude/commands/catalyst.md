Apply the Catalyst orchestration pattern to a ticket, right now, in this session.

The four-phase pattern is below — no need to read the reference file. If a matching skill exists in .catalyst/skills/, read that ONE file and follow it; otherwise apply the pattern below directly.

Ticket / task: $ARGUMENTS

Execute in order, showing your work at each phase:

PHASE 1 — FAN OUT
State the independent analysis tasks you'll run. List them before running them. Then actually run them (search the codebase, read files, check git history, etc.) — genuinely in parallel where the tooling allows, not narrated-as-parallel-but-actually-sequential.

PHASE 2 — REDUCE
Consolidate what you found. Remove duplicates and noise. State the root cause or core finding in one or two sentences.

PHASE 3 — VERIFY
For each significant finding, ask a skeptical question and check it against the actual code/tests — don't just re-assert your own analysis. State a verdict: valid or false positive.

PHASE 4 — SYNTHESIZE
Only using verified findings, produce a concrete implementation plan: files to change, tests to add, risks to check.

Stop after the plan and ask me to confirm before writing any code.

WORKTREES (after confirmation): if the repo uses git worktrees and this is a bug/feature ticket (not a code review), propose creating one at `../<repo>-<ticketid>` on branch `{feature|bug}/{ticketid}_{summary-slug}` (prefix from the skill used; slug = lowercase title, non-alphanumerics → `-`, truncate to 40 chars) and do the implementation inside it — see WORKTREE-WORKFLOW.md. If the ticket has no ID (bare description), use `{feature|bug}/{summary-slug}` and `../<repo>-{summary-slug}` instead. Cleanup is user-triggered after the PR merges.

PHASE 5 — REVIEW (after implementation, before the PR)
Review the written code against the ticket on three axes: (1) bugs — correctness, edge cases, broken callers; (2) style — check `.catalyst/skills/` and repo skills (`.github/skills/`, `.opencode/skills/`) first, else industry best practice for the language; (3) accuracy — does it satisfy the ticket's requirements? Delegate to the `catalyst-code-reviewer` subagent if available; otherwise run the review inline. Return ONLY this structured report — no prose:
```
verdict: APPROVE | REQUEST_CHANGES | BLOCK
summary: <one sentence>
findings:
- severity: blocker | warning | nit
  category: bug | style | accuracy
  file: <path>
  line: <n or range>
  issue: <one line>
  fix: <one line, only if obvious>
```
BLOCK if any blocker, REQUEST_CHANGES if any warning, APPROVE otherwise. Fix blockers before the PR.
