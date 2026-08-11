# Template: GitHub Copilot

## Setup

GitHub Copilot (in VS Code / Visual Studio / JetBrains, and Copilot Chat/Workspace) supports custom instructions via:

1. **Repository custom instructions**: a `.github/copilot-instructions.md` file at the repo root. Copilot Chat automatically includes this file's content as context for every chat request in that repository (supported in VS Code, Visual Studio, and github.com Copilot Chat).
2. **Path-specific instructions**: `.github/instructions/*.instructions.md` files with a front-matter `applyTo` glob, for instructions that should only apply to certain file types or directories.
3. **Copilot Workspace**: when using Workspace to plan a task from an issue, Copilot reads the issue text directly and generates a plan; custom instructions still apply from `.github/copilot-instructions.md` if present in the repo.

For this pattern, use `.github/copilot-instructions.md` since the orchestration approach should apply repo-wide, not to specific file types.

## Installing the Pattern

The instruction block lives once, in `.catalyst/install.md`, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers. Do not copy a per-tool copy — there isn't one.

- **Recommended:** run `/catalyst-install` (from `agent-commands/github-copilot/catalyst-install.prompt.md`,
  installed to `.github/prompts/`). It appends the block from `.catalyst/install.md` into
  `.github/copilot-instructions.md` automatically, idempotently, and reports what it changed.
- **Manual:** append the full content of `.catalyst/install.md` to `.github/copilot-instructions.md`,
  preserving any existing content above it.

`.catalyst/orchestration.md` is the on-demand reference the block points at for depth (node types, safety
rules, anti-patterns, worked example).

## How Copilot Handles Parallel Task Execution

In GitHub Copilot's agent-driven workflows, parallel work is often handled by subagents rather than by the user manually launching multiple chat turns. When a task has several independent investigation paths — such as code search, tests, docs, or recent history — Copilot can fan out to subagents to review those areas in parallel and then consolidate the findings.

This means the right mental model is not "one sequential chat turn only," but rather "the agent may delegate work to subagents to investigate multiple angles concurrently." You generally do not control the exact subagent scheduling or inspect each one directly, but you can still encourage effective fan-out by asking for a structured multi-part analysis up front.

**Recommended pattern for FAN OUT:** Ask Copilot to investigate several independent angles in a single request and explicitly require a consolidated summary before proposing a fix:

```
For the ticket "Fix login timeout handling": (1) find where timeout durations are configured,
(2) find tests referencing timeout/session expiry, (3) find any docs describing the intended
timeout policy, and (4) summarize recent changes to the relevant file(s). Investigate these areas
and return a consolidated summary before proposing any code changes.
```

This takes advantage of Copilot's subagent-based execution model, while still keeping the workflow explicit and reviewable.

## Worked Example

**Point Copilot Workspace at:** GitHub issue #4521, "Fix login timeout handling," with `.github/copilot-instructions.md` in place as above. (If the ticket originates in Jira or Azure DevOps, mirror it into a GitHub issue first — Copilot Workspace only reads GitHub-native issues/PRs.)

1. Copilot Workspace reads the issue and the repo instructions.
2. **FAN OUT** — in Copilot Chat, send the combined `@workspace` query above covering all four analysis angles in one message.
3. **REDUCE** — Copilot returns a combined answer; you (or a follow-up prompt) ask it to state the single leading root cause in one sentence.
4. **VERIFY** — send a second, explicit message: "Open `AuthService.cs` directly and confirm line 142 sets the timeout to 300 seconds — don't rely on your earlier summary." This forces Copilot to re-ground in the literal file content rather than its own paraphrase.
5. **SYNTHESIZE** — ask Copilot Workspace to generate its implementation plan; review the proposed file changes before accepting them (Workspace stages changes for review, it doesn't auto-commit).

## Git Worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic reference for doing implementation in a dedicated git worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`). In Copilot, create the worktree from a terminal (`git worktree add ../<repo>-<ticketid> -b <branch>`) at the Plan stage, then open the worktree as its own folder/workspace in your IDE — `.github/copilot-instructions.md`, `.github/skills/`, and `.github/prompts/` live in the repo and travel with the branch, so the instructions and skills apply in the worktree with no reinstallation. Keep the main checkout read-only during analysis and untouched afterwards. Cleanup is user-triggered after the PR merges (`git worktree remove` + `git branch -d`); nothing here depends on which tracker you use.

## Known Limitations

- Parallel execution is delegated to subagents or agentic runtimes when available, but you do not directly control the exact scheduling or inspect each subagent individually; the workflow still needs explicit consolidation and verification steps to make the results reviewable.
- Copilot Workspace's automatic plan generation can jump straight from issue-reading to a proposed diff without an explicit intermediate verification step — you must inject the VERIFY step manually as a separate prompt, it won't happen on its own.
- Repository custom instructions apply to Copilot Chat and Workspace, but not necessarily to every Copilot surface (e.g. inline code completions ignore `.github/copilot-instructions.md` — this pattern is only relevant to chat/workspace-driven ticket work, not autocomplete).
- If the ticket lives in a non-GitHub tracker (Jira, Azure DevOps, Linear), Copilot has no native connector for it — you must be working from a GitHub issue/PR that mirrors the ticket, or paste the ticket content manually into chat. GitHub Issues themselves are natively available via `@workspace`/Copilot's repo context without any extra setup.

## Correcting the Tool

If Copilot proposes a diff immediately after reading the issue:
> "Before any code changes — list the things you'd need to check to confirm this, check them, and tell me what you verified. Then propose the plan."

If Copilot's "verification" is just repeating its earlier analysis:
> "You're restating your summary, not verifying it. Open the actual file at that path and quote the real content before confirming."

If Copilot Workspace stages changes before a plan was discussed:
> "Discard that diff for now. Give me a written plan of the files and changes first, and wait for me to approve it."
