# Getting Started: Cursor

## Prerequisites

- Cursor installed, with Agent/Composer mode available.
- Cursor **v2.4 or later** if you want subagents (Step 3) — subagents were added January 2026. Everything else in this guide works on any recent version.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
mkdir -p .cursor/rules
cp catalyst-templates/cursor.md .cursor/rules/catalyst-orchestration.mdc
```

Open `catalyst-templates/cursor.md` and check the frontmatter block near the top (`description`, `alwaysApply: true`) — copy that plus the instruction body into the new `.mdc` file so Cursor treats it as an always-applied rule. Reload the Cursor window afterward so it picks up the new rule.

## Step 2 — Commands

```bash
mkdir -p .cursor/commands
cp agent-commands/cursor/*.md .cursor/commands/
```

This gives you `/catalyst`, `/add-skill`, and `/add-template` in Agent/Composer chat. Type `/` to see them listed alongside any other commands you already have.

## Step 3 — Subagents (optional, requires Cursor v2.4+)

For large or high-stakes tickets, split the four phases into isolated subagents instead of running everything in one session. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .cursor/agents
cp agent-subagents/cursor/*.md .cursor/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer`. In Agent Mode, describe the ticket and use Cursor's "Parallelize" flow, or just ask Cursor to use `catalyst-orchestrator` directly.

## Try it

In Agent/Composer chat:

```
/catalyst Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Watch it state its fan-out tasks, run them (codebase search, file reads, terminal commands, several within the same turn), consolidate, verify against the real files, and present a plan before touching anything.

## Next steps

- Check `catalyst-skills/` for a playbook matching your ticket type.
- Run `/add-skill <name>` to add a new one.
- Run `/add-template <tool>` for a tool not yet covered.
