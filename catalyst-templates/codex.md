# Template: Codex CLI

## Setup

OpenAI's Codex CLI (the terminal-based coding agent, `codex` command) reads custom instructions from `AGENTS.md` files, layered in this order of precedence:

1. **Global**: `~/.codex/AGENTS.md` — applies to every project you run `codex` in on that machine.
2. **Project root**: `AGENTS.md` at the repo root — applies to that repo only, and is merged with (added on top of) the global file.
3. **Subdirectory**: an `AGENTS.md` closer to the files being worked on can further refine instructions for that subtree.

Codex CLI also has a `~/.codex/config.toml` file for behavioral settings (approval mode, sandbox policy, default model) — but that file is for *tool behavior* configuration, not free-text instructions. Orchestration instructions belong in `AGENTS.md`, not `config.toml`.

For this pattern, use the project-root `AGENTS.md` if the orchestration approach should apply to one repo's ticket work; use `~/.codex/AGENTS.md` if you want it applied across every repo you run Codex against.

## Installing the Pattern

The instruction block lives once, in `.catalyst/install.md`, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers. Do not copy a per-tool copy — there isn't one.

- **Recommended:** run `/catalyst-install` (from `agent-commands/codex/catalyst-install.md`, installed to
  `~/.codex/prompts/`). It appends the block from `.catalyst/install.md` into `AGENTS.md` (project or
  `~/.codex/AGENTS.md` global) automatically, idempotently, and reports what it changed.
- **Manual:** append the full content of `.catalyst/install.md` to the project-root `AGENTS.md` (or
  `~/.codex/AGENTS.md`), preserving any existing content above it.

`.catalyst/orchestration.md` is the on-demand reference the block points at for depth (node types, safety
rules, anti-patterns, worked example).

## How Codex CLI Handles Parallel Task Execution

Codex CLI runs a single agentic loop that executes one shell command (or one file edit) at a time inside its sandbox, observes the result, and decides the next action — it does not issue multiple simultaneous tool/command calls within one step. This is closer to Cline's strictly sequential model than to Claude Code's same-turn concurrent tool calls.

**Workaround for FAN OUT:** since Codex CLI can chain shell commands, use a single shell invocation that runs multiple independent read-only lookups back-to-back before Codex reasons about any of them, e.g.:

```bash
rg -n "TimeoutSeconds|timeout" --type cs && \
  echo "---tests---" && rg -l "Timeout" -g '*Test*' && \
  echo "---history---" && git log --since="1 month ago" -- AuthService.cs
```

Instruct Codex explicitly to batch fan-out lookups into one combined command (or a short sequence issued rapidly, without pausing to analyze between each) and to defer analysis until all the output is visible. This gets the effect of "one fan-out pass" even though execution under the hood is still sequential.

## Worked Example

**Task given to Codex CLI:** `codex "Using our AGENTS.md orchestration pattern, work GitHub issue #4521: Fix login timeout handling. Issue text: [paste, or fetched via `gh issue view 4521` if the GitHub CLI is available in the sandbox]."` (Same flow applies verbatim for a Jira or Azure DevOps ticket.)

1. Codex CLI loads `AGENTS.md` (global, then project-root) and sees the four-phase instruction.
2. **FAN OUT** — Codex states the task list, then runs a combined shell command: greps for `TimeoutSeconds`/`timeout` across the codebase, greps for timeout-related test files, and runs `git log -p` on the affected file, all before evaluating any of the output.
3. **REDUCE** — Codex summarizes in its response: "Timeout hardcoded to 300s at `AuthService.cs:142`; spec (`TimeoutPolicy.md`) says 1800s; git history shows a prior revert referencing a refresh-loop bug."
4. **VERIFY** — Codex runs `cat -n AuthService.cs | sed -n '135,150p'` (or equivalent) to re-read the exact line directly, and `git show <revert-commit>` to re-read the full revert reason, rather than trusting its own REDUCE summary.
5. **SYNTHESIZE** — Codex writes out the implementation plan as text and stops, waiting for approval before applying any patch — unless the session was started in an auto-approval mode, in which case it proceeds to apply the patch and run tests.

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`). In Codex CLI, this is a plain shell step: `git worktree add ../<repo>-<ticketid> -b <branch>` at SYNTHESIZE, then run Codex from inside the worktree directory. `AGENTS.md` lives in the repo and travels with the branch, so the pattern applies in the worktree with no reinstallation. Keep the main checkout read-only during FAN OUT/VERIFY and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- No native parallel command execution — genuine fan-out concurrency isn't possible; the "combined command" workaround only simulates a single fan-out pass, and very broad fan-out (5+ distinct lookups) in one shell invocation can produce a wall of output that's hard for the model to parse cleanly.
- Approval mode matters a lot here: in auto-approval/full-auto modes, Codex CLI may apply patches or run destructive commands as soon as it decides to, which can undercut the "stop before SYNTHESIZE completes" instruction if not reinforced per-session — the `AGENTS.md` instruction to stop and wait is a request, not an enforced gate, when auto-approval is active.
- No built-in ticket-tracker connector — ticket content must be pasted into the prompt or fetched by a shell command against an API you've separately authenticated (e.g. `gh issue view` for GitHub, or `curl` with a personal access token for Jira/Azure DevOps), which the instruction file should account for if used regularly.
- `AGENTS.md` layering (global → project → subdirectory) means an orchestration instruction set at the project root can be silently overridden or extended by a more specific `AGENTS.md` deeper in the tree — check for conflicting subdirectory files if the pattern doesn't seem to be applied.

## Correcting the Tool

If Codex CLI starts applying patches right after reading the ticket:
> "Stop — you skipped FAN OUT and VERIFY. Run the read-only lookups first, state your findings, verify them, and show me the SYNTHESIZE plan before touching any files."

If Codex CLI's "verification" just restates its FAN OUT summary instead of re-checking source:
> "That's not verification — run the actual command again (cat the file, re-run the test) and confirm the finding against real output, not your earlier summary."

If Codex CLI applies a patch despite being asked to wait for confirmation:
> "Revert or don't apply that — this session should stop at the plan stage. Only proceed once I've explicitly said 'go ahead', and check whether auto-approval mode is on for this session."
