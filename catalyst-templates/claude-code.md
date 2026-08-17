# Template: Claude Code

## Setup

Claude Code reads instructions from a `CLAUDE.md` file at the repo root (or `~/.claude/CLAUDE.md` for global instructions across all projects). It also supports per-project custom slash commands as markdown files under `.claude/commands/`.

## Installing the Pattern

The instruction block lives once, in `.catalyst/install.md`, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers. Do not copy a per-tool copy — there isn't one.

- **Recommended:** run `/catalyst-install` (from `.claude/commands/catalyst-install.md`). It appends the
  block from `.catalyst/install.md` into `CLAUDE.md` (or `~/.claude/CLAUDE.md`) automatically, idempotently,
  and reports what it changed.
- **Manual:** append the full content of `.catalyst/install.md` to `CLAUDE.md` at the repo root (or
  `~/.claude/CLAUDE.md` for global), preserving any existing content above it.

Either way, the `# Ticket Orchestration (Catalyst)` block is what Claude Code loads every session, and
`.catalyst/orchestration.md` ships alongside it as the canonical pattern reference. The `/catalyst`
command points to it for on-demand depth when the work turns ambiguous — node types, node output
contracts, safety rules, anti-patterns, anchors, and the worked example.

## How Claude Code Handles Parallelism

Claude Code can genuinely execute multiple independent tool calls (Grep, Read, Glob, Bash, WebFetch) within a single assistant turn — these run concurrently, not one-at-a-time. This is the native mechanism for PHASE 1 fan-out: instead of "search for X, then search for Y," issue both tool calls in the same response.

For work that benefits from a completely separate reasoning context (e.g. a large independent investigation thread), Claude Code also supports the `Agent` tool to launch a sub-agent with the `Explore` or `general-purpose` type. Use this when a fan-out task is large enough to pollute the main context window if done inline — the sub-agent returns only its findings, not its full transcript.

Verification (PHASE 3) benefits from literally invoking a fresh sub-agent for the skeptic check, since a sub-agent starts with no inherited assumptions from the analysis phase — closer to true "fresh context" than continuing in the same conversation.

## Worked Example

**Point Claude Code at:** `https://github.com/org/repo/issues/4521` ("Fix login timeout handling"), fetched via the [GitHub MCP server](https://github.com/github/github-mcp-server) configured in Claude Code's MCP settings. (The same flow applies unchanged if the ticket lives in Jira, Azure DevOps, or Linear instead — swap the MCP server/tool used to fetch it.)

1. Claude Code reads the issue via the GitHub MCP server's `get_issue` tool.
2. **FAN OUT** — issues parallel tool calls in one turn: `Grep "TimeoutSeconds"`, `Grep "timeout" --glob *Test*`, `Bash git log -p AuthService.cs`, the GitHub MCP server's `search_issues` tool for related/duplicate issues, `Read TimeoutPolicy.md`.
3. **REDUCE** — states in text: "Root cause candidate: `AuthService.cs:142` hardcodes 300s vs. spec's 1800s; PR #4521 previously attempted this and was reverted."
4. **VERIFY** — either continues inline or spawns an `Explore` sub-agent with the prompt "Assume this finding is false: verify `AuthService.cs:142` actually sets 300 and check what `RefreshMiddleware.cs` does with that value." Sub-agent returns confirmation plus the previously-missed refresh-loop risk.
5. **SYNTHESIZE** — produces a numbered implementation plan and stops, asking "Should I proceed with these changes?"

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`). In Claude Code, this is just a `Bash` step: `git worktree add ../<repo>-<ticketid> -b <branch>` at SYNTHESIZE, then work inside that directory. `CLAUDE.md`, `.claude/commands/`, and `.claude/agents/` all live in the repo and therefore travel with the branch into the worktree — the pattern, commands, and subagents keep working there with no reinstallation. Open the worktree as its own session/window; the main checkout session stays read-only during the ticket's FAN OUT/VERIFY and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- Claude Code has no built-in ticket-tracker connector by default — fan-out queries against a tracker (GitHub, Jira, Azure DevOps, etc.) require an MCP server configured for it (e.g. the GitHub MCP server), or manually pasting ticket content/links into the conversation.
- "Parallel" tool calls are parallel within one turn, but Claude Code will not automatically re-parallelize across turns — if you ask a follow-up that fans out again, you must explicitly request it or the model may default to sequential exploration.
- Sub-agents (via the `Agent` tool) return only a summary of their work, not the full transcript — if you need the raw evidence trail for an audit, ask the sub-agent to include file:line citations in its returned findings.

## Correcting the Tool

If Claude Code jumps straight to writing code after reading the ticket:
> "Stop — you skipped fan-out and verification. Decompose this into independent analysis tasks first, run them, then verify before touching any files."

If Claude Code verifies using its own analysis summary instead of fresh evidence:
> "That's not verification, that's restating your analysis. Re-read the actual file/test and check whether the finding holds — don't reuse your prior reasoning."

If Claude Code proposes changes without listing them as a plan first:
> "Don't write code yet. Give me the SYNTHESIZE plan and wait for my confirmation."
