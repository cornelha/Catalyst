# Template: Cline

## Setup

Cline (VS Code extension) supports custom instructions in two places:
1. **Global**: Cline settings panel → "Custom Instructions" field — applies to every project opened in that VS Code instance.
2. **Per-project**: a `.clinerules` file at the repo root — Cline automatically reads this file if present and applies it as project-specific system instructions, without needing to open settings.

For a pattern you want applied consistently to ticket work (from any tracker — GitHub Issues, Jira, Azure DevOps, Linear) in one specific repo, use `.clinerules`. For a pattern you want on all repos, use the global Custom Instructions field.

## Installing the Pattern

The instruction block lives once, in `.catalyst/install.md`, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers. Do not copy a per-tool copy — there isn't one.

- **Recommended:** run `/catalyst-install.md` (from `agent-commands/cline/catalyst-install.md`). It appends
  the block from `.catalyst/install.md` into `.clinerules` (or the global Custom Instructions field)
  automatically, idempotently, and reports what it changed.
- **Manual:** append the full content of `.catalyst/install.md` to `.clinerules` at the repo root (or the
  global Custom Instructions field), preserving any existing content above it.

`.catalyst/orchestration.md` is the on-demand reference the block points at for depth (node types, safety
rules, anti-patterns, worked example).

## How Cline Handles Parallel Task Execution

Cline executes tool calls **one at a time, sequentially**, waiting for each result before deciding the next action — this is a fundamental part of its agent loop (plan → act → observe → repeat). It does not natively support issuing multiple simultaneous tool calls in one step the way Claude Code can.

**Workaround for FAN OUT:** Since true parallelism isn't available, get the closest approximation by:
- Batching read-only, low-risk lookups back-to-back in immediate succession before doing anything else — Cline will still run them sequentially, but instruct it explicitly not to reason deeply or take action between each one ("run these four searches first, don't analyze after each one, report all four results together, then analyze").
- Explicitly numbering the fan-out tasks in the instruction so Cline treats them as one batch to get through quickly, rather than interleaving analysis and action.
- If using a version of Cline with multi-file "checkpoints," you can also open several tabs/read multiple files in one instructed step so Cline's context includes them all before it starts reasoning — this simulates parallel gathering even though execution is sequential under the hood.

## Worked Example

**Task given to Cline:** "Using our orchestration rules, work this ticket: github.com/org/repo/issues/4521 — Fix login timeout handling. Paste issue description: [paste, or fetched via a configured GitHub MCP server if Cline's MCP support is enabled]." (Same flow applies verbatim if the ticket link is Jira, Azure DevOps, or Linear instead.)

1. Cline reads `.clinerules`, sees the FAN OUT/REDUCE/VERIFY/SYNTHESIZE sequence.
2. **FAN OUT** — Cline lists the four analysis tasks in its response, then executes them one by one: search for "TimeoutSeconds", search for timeout-related test files, read `TimeoutPolicy.md`, check git blame on `AuthService.cs`. Each is a separate tool call/result cycle, but Cline is instructed not to editorialize between them.
3. **REDUCE** — After all four results return, Cline writes a consolidated summary: hardcoded 300s vs. spec's 1800s, prior revert found in git history.
4. **VERIFY** — Cline re-opens `AuthService.cs:142` directly (not relying on the grep snippet) and re-reads the revert commit message in full to check the stated reason still applies.
5. **SYNTHESIZE** — Cline proposes a plan as a numbered list and stops, per the instruction, without invoking `write_to_file` or `replace_in_file` yet.

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`). In Cline, create the worktree from a terminal (`git worktree add ../<repo>-<ticketid> -b <branch>`) at SYNTHESIZE, then open the worktree directory as its own VS Code window — `.clinerules` lives in the repo and travels with the branch, so the rules apply in the worktree with no reinstallation. Keep the main checkout window read-only during FAN OUT/VERIFY and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- No native parallel tool execution — fan-out is sequential in practice, just organized to feel batch-like. On repos with many files to search, this is noticeably slower than Claude Code's concurrent tool calls.
- Cline's context window handling means very long sequential fan-out (6+ separate searches) can push earlier results out of relevant context by the time REDUCE happens — keep fan-out to 3-5 focused tasks, not exhaustive ones.
- No built-in ticket-tracker integration — ticket content must be pasted manually or fetched via an MCP server Cline is configured to use (e.g. the GitHub MCP server for GitHub Issues, or an equivalent MCP server/API integration for Jira or Azure DevOps).
- `.clinerules` applies uniformly; Cline doesn't have a native "slash command" concept like Claude Code, so switching between different tickets/skills means re-pasting or referencing a different rules file per session.

## Correcting the Tool

If Cline starts editing files right after reading the ticket:
> "You skipped the plan. Re-read `.clinerules` — do FAN OUT, REDUCE, VERIFY first, then present a SYNTHESIZE plan and stop for my approval."

If Cline treats its own grep results as verified fact:
> "That's not verified — open the actual file and confirm the line still says what the search result showed. Then tell me if it's VALID or a false positive."

If Cline merges REDUCE and VERIFY into one step:
> "Separate these: first tell me the consolidated finding, then verify it with a skeptical re-check before moving on."
