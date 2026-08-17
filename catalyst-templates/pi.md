# Template: Pi (pi.dev)

## Setup

Pi (the `pi` coding agent CLI, `earendil-works/pi`) loads project context automatically at startup from `AGENTS.md` files (it also accepts `CLAUDE.md` as an alternate filename), read in this order:

1. **Global**: `~/.pi/agent/AGENTS.md` — applies to every project you run `pi` in on that machine.
2. **Parent directories**: every `AGENTS.md` found walking up from your current working directory to the filesystem root.
3. **Current directory**: `AGENTS.md` in the directory you launched `pi` from.

Unlike Codex CLI's layering, Pi does not treat these as override-in-order — **all matching files are concatenated** into context. That means a project-root `AGENTS.md` doesn't replace or take precedence over the global one; both apply together. Context-file loading can be disabled entirely with `--no-context-files` (`-nc`), which would also disable this pattern.

Pi also supports a `~/.pi/agent/settings.json` (global) / `.pi/settings.json` (project) pair for *behavioral* configuration (model defaults, trust policy, etc.) — like Codex's `config.toml`, this is not where orchestration instructions go.

For this pattern, use the project-root `AGENTS.md` if the orchestration approach should apply to one repo's ticket work; use `~/.pi/agent/AGENTS.md` if you want it applied across every repo you run `pi` against. Since both are concatenated, you can also do both — e.g. a short global reminder plus project-specific ticket-tracker details.

## Installing the Pattern

The instruction block lives once, in `.catalyst/install.md`, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers. Do not copy a per-tool copy — there isn't one.

- **Recommended:** run `/catalyst-install` (from `agent-commands/pi/catalyst-install.md`, installed to
  `.pi/prompts/`). It appends the block from `.catalyst/install.md` into `AGENTS.md` (project or
  `~/.pi/agent/AGENTS.md` global) automatically, idempotently, and reports what it changed.
- **Manual:** append the full content of `.catalyst/install.md` to the project-root `AGENTS.md` (or
  `~/.pi/agent/AGENTS.md`), preserving any existing content above it.

`.catalyst/orchestration.md` ships alongside it as the canonical pattern reference. The `/catalyst` command points to it for on-demand depth when the work turns ambiguous — node types, node output contracts, safety rules, anti-patterns, anchors, and the worked example.

## How Pi Handles Parallel Task Execution

Pi runs a single agentic loop with four core tools — read, write, edit, bash — executing one tool call at a time, observing the result, then deciding the next action. There is no native concurrent/simultaneous tool-call support in the core agent (Pi's own philosophy explicitly pushes sub-agents and parallelism out to extensions or external orchestration — see Known Limitations). This puts Pi in the same sequential category as Codex CLI.

**Workaround for FAN OUT:** since Pi's `bash` tool can run any shell command, chain independent read-only lookups into a single invocation so Pi sees all the output before it starts reasoning about any of it, e.g.:

```bash
rg -n "TimeoutSeconds|timeout" --type cs && \
  echo "---tests---" && rg -l "Timeout" -g '*Test*' && \
  echo "---history---" && git log --since="1 month ago" -- AuthService.cs
```

Instruct Pi explicitly, either in the `AGENTS.md` block above or in the prompt, to batch fan-out lookups into one combined `bash` call rather than interleaving analysis between each one. This simulates a single fan-out pass even though execution underneath is still one tool call at a time.

## Worked Example

**Task given to Pi:** `pi "Using our AGENTS.md orchestration pattern, work GitHub issue #4521: Fix login timeout handling. Issue text: [paste, or fetched via `gh issue view 4521` if the GitHub CLI is available]."` (Same flow applies verbatim for a Jira or Azure DevOps ticket.)

1. Pi loads and concatenates its `AGENTS.md` files (global, then parent directories, then cwd) and sees the four-phase instruction.
2. **FAN OUT** — Pi states the task list, then issues one combined `bash` call: greps for `TimeoutSeconds`/`timeout` across the codebase, greps for timeout-related test files, and runs `git log -p` on the affected file, all before evaluating any of the output.
3. **REDUCE** — Pi summarizes in its response: "Timeout hardcoded to 300s at `AuthService.cs:142`; spec (`TimeoutPolicy.md`) says 1800s; git history shows a prior revert referencing a refresh-loop bug."
4. **VERIFY** — Pi uses its `read` tool to re-read the exact line directly, and `bash` (`git show <revert-commit>`) to re-read the full revert reason, rather than trusting its own REDUCE summary.
5. **SYNTHESIZE** — Pi writes out the implementation plan as text and stops, waiting for confirmation before using `edit`/`write` to apply any change.

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`). In Pi, this is a plain `bash` step: `git worktree add ../<repo>-<ticketid> -b <branch>` at SYNTHESIZE, then run Pi from inside the worktree directory. `AGENTS.md` and `.pi/prompts/` live in the repo and travel with the branch, so the pattern and commands apply in the worktree with no reinstallation. Keep the main checkout read-only during FAN OUT/VERIFY and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- No native parallel command execution — genuine fan-out concurrency isn't possible in core Pi; the "combined bash call" workaround only simulates a single fan-out pass, and very broad fan-out in one invocation can produce output that's hard for the model to parse cleanly.
- **No built-in permission system.** By design, Pi has no popups, no plan mode, and no restriction on filesystem/process/network/credential access — it runs with the full permissions of the user and process that launched it. If this pattern is used against a real ticket-tracker or production repo, run Pi inside a container or sandbox rather than relying on the instruction file alone to stop it from touching something it shouldn't.
- No native sub-agents, no MCP, and no built-in to-do tracking — Pi's philosophy pushes all of these to extensions or third-party packages rather than baking them into core, so this pattern (and any subagent split on top of it) depends on what's installed.
- No built-in ticket-tracker connector — ticket content must be pasted into the prompt or fetched by a `bash` call against an API you've separately authenticated (e.g. `gh issue view` for GitHub, or `curl` with a personal access token for Jira/Azure DevOps).
- If this pattern is placed in a project-level `.pi/prompts/*.md` command instead of `AGENTS.md` (see `agent-commands/pi/`), those files only load once the project has been marked trusted — check `/settings` or `~/.pi/agent/trust.json` if the command doesn't appear.

## Correcting the Tool

If Pi starts applying edits right after reading the ticket:
> "Stop — you skipped FAN OUT and VERIFY. Run the read-only lookups first, state your findings, verify them, and show me the SYNTHESIZE plan before touching any files."

If Pi's "verification" just restates its FAN OUT summary instead of re-checking source:
> "That's not verification — use the read tool to check the actual file again, or re-run the command, and confirm the finding against real output, not your earlier summary."

If Pi applies an edit despite being asked to wait for confirmation:
> "Revert that — this session should stop at the plan stage. Only use write or edit once I've explicitly said 'go ahead'."
