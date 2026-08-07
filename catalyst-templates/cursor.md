# Template: Cursor

## Setup

Cursor (the AI-native code editor) reads custom instructions from **Project Rules**: `.mdc` files under `.cursor/rules/` at the repo root. Each rule file has YAML frontmatter controlling when it's applied, plus a markdown body with the instruction content. This replaced the older single `.cursorrules` file, which Cursor still reads for backward compatibility but which is no longer the recommended mechanism.

Rule frontmatter supports four modes:
- `alwaysApply: true` — included in every chat/agent session in the repo, regardless of what files are open.
- `globs: ["**/*.cs"]` — auto-attached only when matching files are in context.
- Agent-requested — the rule has a `description` and the agent decides whether to pull it in based on relevance.
- Manual — only included when explicitly referenced with `@ruleName` in a chat.

For an orchestration pattern you want applied to every ticket regardless of file type, use `alwaysApply: true` so it isn't accidentally left out.

**Setup steps:**
1. Create the folder `.cursor/rules/` at the repo root if it doesn't exist.
2. Create a file `.cursor/rules/catalyst-orchestration.mdc`.
3. Paste the frontmatter + instruction block below.
4. Restart or reload the Cursor window so it picks up the new rule (Cursor indexes `.cursor/rules/` on project load).

## Instruction Text to Paste

Into `.cursor/rules/catalyst-orchestration.mdc`:

```markdown
---
description: Ticket orchestration pattern — fan out, reduce, verify, synthesize
alwaysApply: true
---

# Ticket Orchestration Pattern

When given a ticket (URL, ID, or pasted text) from any tracker — GitHub Issues, Jira, Azure DevOps,
Linear, etc. — in Agent/Composer mode, do not begin editing files immediately. Work through these
phases explicitly:

1. FAN OUT — Identify independent analysis tasks: related code locations, existing test status,
   related/duplicate tickets, relevant docs, recent history of the affected files. State the task list
   before running anything. Use codebase search, file reads, and terminal commands (git log, running
   tests) to gather each one.

2. REDUCE — Consolidate findings. Remove duplicates and irrelevant matches. State the leading root cause
   or requirement in one or two sentences.

3. VERIFY — For each significant finding, ask a skeptical question and re-check it against the actual
   file or test output — do not just restate the FAN OUT summary. Mark each finding VALID or FALSE
   POSITIVE and drop false positives.

4. SYNTHESIZE — Using only verified findings, produce a concrete implementation plan (files, changes,
   tests, risks). Present the plan and stop — do not apply edits until the plan is confirmed, unless
   the session is explicitly running in an auto-apply / YOLO mode.
```

## How Cursor Handles Parallel Task Execution

Cursor's Agent mode can call multiple tools within a single turn — codebase search, file reads, and terminal commands can be issued together, and Cursor's own semantic codebase index (built automatically on project open) means a single "search the codebase for X" call often returns results equivalent to several manual greps at once. This gives Cursor a reasonable approximation of Claude Code's same-turn parallelism for the FAN OUT phase, though the exact degree of concurrency is managed internally by Cursor and not fully exposed or controllable by the user.

**Workaround if a given fan-out task isn't covered by one tool call:** explicitly list the fan-out tasks in the rule (as done above) so Cursor's agent treats them as one batch to complete before reasoning, rather than letting it drift into "search, then think, then search again" — the risk without this instruction is that Cursor interleaves fan-out and analysis rather than doing fan-out as a distinct upfront pass.

## Worked Example

**Point Cursor at:** Agent/Composer chat, with `.cursor/rules/catalyst-orchestration.mdc` present and a GitHub MCP server configured in Cursor's MCP settings, prompted with: "Work GitHub issue #4521: Fix login timeout handling." (Same flow applies verbatim if the ticket is pasted from Jira or Azure DevOps instead.)

1. Cursor's agent auto-attaches the `alwaysApply` rule and sees the four-phase instruction.
2. **FAN OUT** — Cursor states the task list, then uses its semantic codebase search for "timeout" and "session expiry," reads `AuthService.cs` and `TimeoutPolicy.md`, calls the GitHub MCP server's `search_issues` tool for related/duplicate issues, and runs a terminal command (`git log -p -- AuthService.cs`) to check history — several of these happen within the same agent turn.
3. **REDUCE** — Cursor summarizes: "Timeout hardcoded to 300s at `AuthService.cs:142`; `TimeoutPolicy.md` states 1800s; git history shows a prior revert citing a refresh-loop bug."
4. **VERIFY** — Cursor re-opens `AuthService.cs` at the specific line via a direct file read (not relying on the search snippet) and re-reads the full revert commit message, confirming both independently.
5. **SYNTHESIZE** — Cursor presents a numbered implementation plan in chat and waits for the user to click "Apply" or explicitly approve before editing any files (unless Auto-Apply/YOLO mode is enabled for the session, in which case it proceeds directly to edits).

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`). In Cursor, create the worktree from a terminal (`git worktree add ../<repo>-<ticketid> -b <branch>`) at SYNTHESIZE, then open the worktree directory as its own Cursor window — `.cursor/rules/` and `.cursor/commands/` live in the repo and travel with the branch, so the rule and commands apply in the worktree with no reinstallation. Keep the main checkout window read-only during FAN OUT/VERIFY and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- The degree of internal parallelism during FAN OUT is not user-controllable or fully observable — Cursor may batch some lookups and serialize others depending on its own agent-loop heuristics, so don't assume every fan-out task happens in the same turn.
- No built-in ticket-tracker connector — for GitHub Issues, add the GitHub MCP server in Cursor's MCP settings; for Jira or Azure DevOps, either configure an equivalent MCP server or paste ticket content into chat / fetch it via a terminal command (`curl` against the tracker's REST API) that the rule should account for if this is a frequent workflow.
- Auto-Apply / YOLO modes let Cursor apply file edits and run terminal commands without per-step confirmation — if enabled, the "stop before SYNTHESIZE is confirmed" instruction becomes advisory rather than enforced, similar to auto-approval modes in other agentic CLIs.
- Rule files under `.cursor/rules/` are project-scoped; there's no single global rules file equivalent to `~/.claude/CLAUDE.md` — a pattern you want on every repo must be copied into each repo's `.cursor/rules/` folder (or added via Cursor's team/workspace-level rule sync, if using Cursor for Business).
- The legacy single `.cursorrules` file still works but doesn't support the `globs`/`alwaysApply` targeting — if both `.cursorrules` and `.cursor/rules/*.mdc` exist, check for instruction conflicts between them.

## Correcting the Tool

If Cursor starts editing files right after reading the ticket:
> "Stop — you skipped FAN OUT and VERIFY. Search and read the relevant files first, state your findings, verify them, then show me the SYNTHESIZE plan before applying any edits."

If Cursor's "verification" just restates its FAN OUT summary instead of re-checking source:
> "That's not a fresh check — open the actual file again and confirm the finding directly, don't reuse your earlier search result."

If Cursor applies edits despite being asked to wait for approval:
> "Undo that — this session should stop at the plan stage. Check whether Auto-Apply/YOLO mode is on, and turn it off for orchestration tasks like this."
