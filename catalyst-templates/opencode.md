# Template: OpenCode

## Setup

OpenCode (the open-source terminal-based AI coding agent) reads project configuration from an `opencode.json` (or `opencode.jsonc`) file at the repo root, and supports custom instruction files referenced from it via the `instructions` field. It also supports a plain `AGENTS.md` file at the repo root, which OpenCode automatically loads as system context if present — similar in spirit to Claude Code's `CLAUDE.md`.

Two ways to install this pattern:

**Option A — `AGENTS.md` (simplest):** create/edit `AGENTS.md` at the repo root with the instruction block below. OpenCode loads it automatically every session.

**Option B — explicit config reference:** add an `instructions` entry in `opencode.json` pointing at a dedicated file (e.g. `docs/catalyst-orchestration.md`), useful if you want this pattern kept separate from other agent instructions.

```jsonc
{
  "instructions": ["docs/catalyst-orchestration.md"]
}
```

## Instruction Text to Paste

```markdown
# Ticket Orchestration

When given a ticket from any tracker (GitHub Issues, Jira, Azure DevOps, Linear, etc.), do not start editing files immediately. Work through these phases:

1. FAN OUT — Identify independent analysis tasks (code search, test status, related tickets, docs, git
   history). State the task list, then run each one using available read-only tools (search/grep, file read,
   git log). Where the tool interface allows issuing multiple tool calls in one step, do so — don't
   artificially serialize independent lookups.

2. REDUCE — Consolidate findings, dropping duplicates and irrelevant matches. State the leading root cause
   or requirement in one or two sentences.

3. VERIFY — For each significant finding, ask a skeptical question and re-check it against the real file or
   test, not your own earlier summary. Mark each VALID or FALSE POSITIVE and drop false positives.

4. SYNTHESIZE — Using only verified findings, produce a concrete implementation plan (files, changes, tests,
   risks). Stop and wait for confirmation before editing files, unless told to proceed automatically.
```

## How OpenCode Handles Parallel Task Execution

OpenCode's agent loop supports issuing multiple tool calls within a single model turn when the underlying model (e.g. Claude, GPT-4-class models) chooses to do so — it is a thin, model-driven agent harness rather than a fixed sequential pipeline, so genuine parallel tool calls are possible if the instruction explicitly asks for it and the connected model supports multi-tool-call turns. This makes it closer to Claude Code's parallelism than to Cline's strictly sequential loop, but it depends on which model backend is configured — verify by checking whether your configured provider/model supports parallel tool calling before relying on it.

**Workaround if the configured model does not support parallel tool calls:** explicitly instruct fan-out tasks to be batched and reported together rather than interleaved with reasoning, the same way as the Cline workaround — list all fan-out tasks up front, execute them back-to-back, and defer analysis until all results are in.

## Worked Example

**Point OpenCode at:** GitHub issue #4521, "Fix login timeout handling," fetched via a GitHub MCP server configured in OpenCode's MCP settings (or pasted directly if no MCP server is configured). The same flow applies unchanged for a Jira or Azure DevOps ticket instead.

1. OpenCode loads `AGENTS.md`, sees the four-phase instruction.
2. **FAN OUT** — OpenCode states: "I'll check: (1) where timeout is configured, (2) related test status, (3) related tickets, (4) doc-stated policy, (5) recent history of the file." If the backend model supports it, these are issued as parallel tool calls (grep, test runner, doc read, git log) in one turn; otherwise sequential but batched before analysis.
3. **REDUCE** — OpenCode reports: "Timeout hardcoded to 300s in `AuthService.cs:142`, spec says 1800s, prior fix reverted (PR #4521) due to refresh-loop bug."
4. **VERIFY** — OpenCode re-reads `AuthService.cs:142` directly and re-reads the revert commit message in full, confirming both independently rather than trusting the REDUCE summary.
5. **SYNTHESIZE** — OpenCode outputs a numbered implementation plan and stops for confirmation before invoking any file-write tool.

## Known Limitations

- Parallel tool-call support is model-dependent, not a guaranteed OpenCode feature — behavior will differ across configured providers (some emit one tool call per turn regardless of instruction).
- No built-in ticket-tracker connector out of the box — requires either a configured MCP server for your tracker (e.g. the GitHub MCP server for GitHub Issues) or manual ticket paste.
- Being a newer, actively-changing tool, exact config file schema (`opencode.json` fields, `AGENTS.md` auto-load behavior) may shift between versions — confirm against the installed version's own `--help` or docs before assuming the field names above are current.
- Like other single-thread chat tools, there's no separate "fresh context" sub-agent concept by default for the VERIFY phase — verification happens in the same context as analysis, so the instruction must explicitly demand re-reading source rather than reusing the REDUCE summary.

## Correcting the Tool

If OpenCode proposes changes without a stated plan:
> "You skipped SYNTHESIZE as a distinct step — write out the plan (files, changes, tests, risks) and wait for my confirmation before editing anything."

If OpenCode's verification just repeats the REDUCE summary:
> "That's not a fresh check — go re-read the actual file/test now and tell me if it still shows what you found, or if it's a false positive."

If OpenCode serializes fan-out into a long chain of "first I'll... then I'll..." before doing anything:
> "List all the fan-out tasks first, then execute them together — don't reason between each one until they're all done."
