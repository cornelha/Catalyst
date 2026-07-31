# Getting Started: OpenCode

## Prerequisites

- OpenCode installed.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp catalyst-templates/opencode.md AGENTS.md
```

Or append the instruction block to an existing `AGENTS.md`. OpenCode loads this automatically every session. Alternatively, reference a separate file via the `instructions` field in `opencode.json` if you'd rather keep it apart from other agent instructions.

## Step 2 — Commands

```bash
mkdir -p .opencode/commands
cp agent-commands/opencode/*.md .opencode/commands/
```

This installs `/catalyst`, `/add-skill`, and `/add-template`. Commands are loaded at startup — restart your OpenCode session after adding these files before they'll appear.

## Step 3 — Subagents (optional)

For large or high-stakes tickets, split the four phases into isolated subagents. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .opencode/agents
cp agent-subagents/opencode/*.md .opencode/agents/
```

This installs `catalyst-orchestrator` (a primary agent you can switch to directly) and `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer` (subagents it delegates to).

**Known caveat**: there's a currently open upstream bug where subagents invoked via the Task tool ignore their own `model:` frontmatter and inherit the parent's model instead. The model assignments in these files are correct as written — confirm they're actually being honored in your installed version before relying on the cost/quality split between roles.

## Try it

```
/catalyst Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Watch it state its fan-out tasks, batch them together rather than interleaving with analysis, consolidate, re-verify against the real files, and present a plan before editing anything. Or switch to `catalyst-orchestrator` directly to run the full subagent-delegated version.

## Next steps

- Check `catalyst-skills/` for a playbook matching your ticket type.
- Adapt `agent-commands/opencode/add-skill.md`'s pattern to add new commands as needed.
- Run `/add-template <tool>` (from Claude Code, if you also use it) for a tool not yet covered.
