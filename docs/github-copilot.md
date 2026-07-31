# Getting Started: GitHub Copilot

## Prerequisites

- GitHub Copilot with Chat, available in VS Code, Visual Studio, or a JetBrains IDE.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp catalyst-templates/github-copilot.md .github/copilot-instructions.md
```

Or append the instruction block to an existing `.github/copilot-instructions.md` rather than overwriting it. Copilot Chat includes this file's content as context automatically for every request in this repo.

## Step 2 — Commands (Prompt Files)

```bash
mkdir -p .github/prompts
cp agent-commands/github-copilot/*.prompt.md .github/prompts/
```

This installs `/catalyst`, `/add-skill`, and `/add-template` as prompt files. Type `/catalyst` in Copilot Chat — it'll prompt you to fill in the ticket via the `${input:ticket:...}` placeholder rather than requiring it typed inline.

## Step 3 — Subagents (optional)

For large or high-stakes tickets, split the four phases into isolated custom agents. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .github/agents
cp agent-subagents/github-copilot/*.agent.md .github/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer`. Standard Copilot Chat subagents run sequentially within one session — for true parallel execution during FAN OUT, use Copilot CLI **Fleet mode** instead.

## Try it

In Copilot Chat:

```
/catalyst
```

Fill in the ticket when prompted (a GitHub issue URL or pasted description). Copilot will state its fan-out tasks, run them, consolidate, re-verify each finding against the real files, and present a plan before proposing code.

## Next steps

- Check `catalyst-skills/` for a playbook matching your ticket type.
- Copy `agent-commands/github-copilot/add-skill.prompt.md`'s pattern to add new prompt files as needed.
- Run `/add-template <tool>` (from Claude Code, if you also use it) for a tool not yet covered.
