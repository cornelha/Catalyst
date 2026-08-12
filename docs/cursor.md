# Getting Started: Cursor

## Prerequisites

- Cursor installed, with Agent/Composer mode available.
- Cursor **v2.4 or later** if you want subagents (Step 3) — subagents were added January 2026. Everything else in this guide works on any recent version.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp .catalyst/install.md AGENTS.md
```

Or, if you already have an `AGENTS.md`, append `.catalyst/install.md`'s content to it rather than overwriting. Cursor auto-loads `AGENTS.md` into every Agent/Composer session in the repo. Or run `/catalyst-install` (after Step 2) and it will append the same block for you, idempotently.

For an always-applied `.cursor/rules/*.mdc` rule instead (equivalent behavior, different file): create `.cursor/rules/catalyst-orchestration.mdc` with the frontmatter below, then append `.catalyst/install.md`'s content beneath it:

```markdown
---
description: Ticket orchestration pattern — fan out, reduce, verify, synthesize
alwaysApply: true
---
```

Reload the Cursor window afterward so it picks up the new rule.

## Step 2 — Commands

```bash
mkdir -p .cursor/commands
cp agent-commands/cursor/*.md .cursor/commands/
```

This gives you `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, and `/learn` in Agent/Composer chat. Type `/` to see them listed alongside any other commands you already have.

## Step 3 — Subagents (optional, requires Cursor v2.4+)

For large or high-stakes tickets, split the four phases into isolated subagents instead of running everything in one session. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .cursor/agents
cp agent-subagents/cursor/*.md .cursor/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer`. In Agent Mode, describe the ticket and use Cursor's "Parallelize" flow, or just ask Cursor to use `catalyst-orchestrator` directly.

## Step 4 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`), opened as its own Cursor window. The rule and commands you installed above live in the repo, so they travel with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

In Agent/Composer chat:

```
/catalyst Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Watch it state its fan-out tasks, run them (codebase search, file reads, terminal commands, several within the same turn), consolidate, verify against the real files, and present a plan before touching anything.

## Next steps

- Check `.catalyst/skills/` for a playbook matching your ticket type.
- Run `/add-skill <name>` to add a new one.
- Run `/learn` to turn this session's lessons into new or updated skills.
- Run `/add-template <tool>` for a tool not yet covered.
