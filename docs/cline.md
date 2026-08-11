# Getting Started: Cline

## Prerequisites

- Cline installed (VS Code extension), or the Cline CLI/SDK if you plan to use Step 3.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
mkdir -p .clinerules
cp .catalyst/install.md .clinerules/catalyst-orchestration.md
```

Cline combines every `.md`/`.txt` file in `.clinerules/` into one rule set applied to every message, so this makes the fan-out/reduce/verify/synthesize instruction persistent across your whole project. Or run `/catalyst-install.md` (after Step 2) and it will append the same block for you, idempotently.

## Step 2 — Commands (Workflows)

```bash
mkdir -p .clinerules/workflows
cp agent-commands/cline/*.md .clinerules/workflows/
```

This installs five Workflows — `catalyst.md`, `catalyst-install.md`, `add-skill.md`, `add-template.md`, `learn.md`. Invoke them by typing the filename with its extension in chat, e.g. `/catalyst.md`, followed by your ticket text in the same message. Unlike `.clinerules`, workflows run once and complete — they don't persist across every message.

## Step 3 — Subagents (optional, no drop-in files)

Cline has no native "one markdown file per named subagent" mechanism like the other tools in this library. Read `agent-subagents/cline.md` instead of copying anything — it walks through the two real options:

- **Cline SDK agent teams** (if you're using the newer Cline SDK runtime) — native support for delegating to specialist team members, each with its own model/tools/prompt.
- **Spawning separate CLI instances** (Claude Code CLI or Cline CLI, run as subprocesses with `--max-turns` and permission limits) — more manual, works with tools you already have.

Both map the same four roles (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`) from `SUBAGENT-ARCHITECTURE.md` onto Cline's actual mechanisms — read that file first for the role definitions to reuse.

## Step 4 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`), opened as its own VS Code window. The rules you installed above live in the repo, so they travel with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

In chat:

```
/catalyst.md Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Cline wraps the workflow content in explicit instructions for that message, works through fan-out (batched read-only tool calls), reduce, verify, and synthesize, and stops before editing any files until you confirm the plan.

## Next steps

- Check `.catalyst/skills/` for a playbook matching your ticket type.
- Copy `agent-commands/cline/add-skill.md`'s pattern to create new workflows as you notice recurring ticket types.
- Run `/learn.md` to turn this session's lessons into new or updated skills.
- Run the Claude Code `/add-template <tool>` command (from this repo, if you also use Claude Code) to cover a tool not yet in `catalyst-templates/`.
