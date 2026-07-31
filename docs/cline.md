# Getting Started: Cline

## Prerequisites

- Cline installed (VS Code extension), or the Cline CLI/SDK if you plan to use Step 3.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
mkdir -p .clinerules
cp catalyst-templates/cline.md .clinerules/catalyst-orchestration.md
```

Cline combines every `.md`/`.txt` file in `.clinerules/` into one rule set applied to every message, so this makes the fan-out/reduce/verify/synthesize instruction persistent across your whole project.

## Step 2 — Commands (Workflows)

```bash
mkdir -p .clinerules/workflows
cp agent-commands/cline/*.md .clinerules/workflows/
```

This installs three Workflows — `catalyst.md`, `add-skill.md`, `add-template.md`. Invoke them by typing the filename with its extension in chat, e.g. `/catalyst.md`, followed by your ticket text in the same message. Unlike `.clinerules`, workflows run once and complete — they don't persist across every message.

## Step 3 — Subagents (optional, no drop-in files)

Cline has no native "one markdown file per named subagent" mechanism like the other tools in this library. Read `agent-subagents/cline.md` instead of copying anything — it walks through the two real options:

- **Cline SDK agent teams** (if you're using the newer Cline SDK runtime) — native support for delegating to specialist team members, each with its own model/tools/prompt.
- **Spawning separate CLI instances** (Claude Code CLI or Cline CLI, run as subprocesses with `--max-turns` and permission limits) — more manual, works with tools you already have.

Both map the same four roles (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`) from `SUBAGENT-ARCHITECTURE.md` onto Cline's actual mechanisms — read that file first for the role definitions to reuse.

## Try it

In chat:

```
/catalyst.md Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Cline wraps the workflow content in explicit instructions for that message, works through fan-out (batched read-only tool calls), reduce, verify, and synthesize, and stops before editing any files until you confirm the plan.

## Next steps

- Check `catalyst-skills/` for a playbook matching your ticket type.
- Copy `agent-commands/cline/add-skill.md`'s pattern to create new workflows as you notice recurring ticket types.
- Run the Claude Code `/add-template <tool>` command (from this repo, if you also use Claude Code) to cover a tool not yet in `catalyst-templates/`.
