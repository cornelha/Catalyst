# Template: Claude Code

## Setup

Claude Code reads instructions from a `CLAUDE.md` file at the repo root (or `~/.claude/CLAUDE.md` for global instructions across all projects). It also supports per-project custom slash commands as markdown files under `.claude/commands/`.

Two ways to install this pattern:

**Option A — Persistent project instruction (recommended for teams working the same ticket tracker repeatedly, whichever tracker that is):**
Paste the block below into `CLAUDE.md` at the repo root. Claude Code loads this automatically at the start of every session in that repo.

**Option B — On-demand slash command:**
Save the block below as `.claude/commands/catalyst.md` in the repo. Invoke it with `/catalyst <ticket-url>` whenever you want to apply the pattern, without it running on every session.

## Instruction Text to Paste

```markdown
## Ticket Orchestration Pattern

When given a ticket (URL or ID) from any tracker — GitHub Issues, Jira, Azure DevOps, Linear, etc. — do not
read it and immediately start coding. Follow this sequence:

1. FAN OUT — Decompose the ticket into independent analysis tasks (e.g. search codebase for related code,
   check for failing tests, search the tracker for related/duplicate tickets, read relevant docs, check git
   history). List these tasks explicitly before running them. Run them in parallel using multiple tool calls
   in a single turn wherever they don't depend on each other's output.

2. REDUCE — Consolidate findings. Remove duplicates and noise. State the leading root-cause or core
   requirement in one or two sentences.

3. VERIFY — For each significant finding, ask a skeptical question and check it against the actual code or
   tests (not your own summary). State a verdict: valid or false positive. Drop false positives.

4. SYNTHESIZE — Using only verified findings, produce a concrete implementation plan (files to change, tests
   to add, risks to check). Stop here and ask for confirmation before writing code, unless explicitly told to
   proceed automatically.

Never skip straight to implementation on an unverified finding.
```

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
