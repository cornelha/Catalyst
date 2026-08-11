# Getting Started: GitHub Copilot

## Prerequisites

- GitHub Copilot with Chat, available in VS Code, Visual Studio, or a JetBrains IDE.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp .catalyst/install.md .github/copilot-instructions.md
```

Or, if you already have a `.github/copilot-instructions.md`, append `.catalyst/install.md`'s content to it rather than overwriting. Copilot Chat includes this file's content as context automatically for every request in this repo. Or run `/catalyst-install` (after Step 3) and it will append the same block for you, idempotently.

## Step 2 — Skills (native discovery)

```bash
mkdir -p .github/skills
cp -r agent-skills/github-copilot/* .github/skills/
cp -r .catalyst . 
```

This installs `bug-fix`, `code-review`, and `feature-implementation` as native Copilot Agent Skills — auto-discovered by both Copilot Chat and Copilot CLI (`/skills list` in the CLI to confirm). Each skill is **self-contained**: its `SKILL.md` carries the full Analysis Tasks, Verification Questions, and Implementation Checklist, so it works standalone per the agentskills.io specification (metadata + instructions, `<500` lines, no dependency on files outside the skill folder). The `cp -r .catalyst .` step is still required because the `catalyst-orchestrator`, `catalyst-synthesizer`, and `/catalyst`/`/add-skill` commands reference `.catalyst/skills/*.md` at your project's root — but the *skills themselves* no longer depend on it.

**Regenerating after you evolve the toolkit:** `.catalyst/skills/<name>.md` is the canonical, user-editable source of each playbook. When you change it (by hand, or via `/add-skill`/`/learn`), refresh the Copilot skills by re-running the generator in this repo:

```bash
scripts/generate-copilot-skills.sh    # or scripts/generate-copilot-skills.ps1 on Windows
```

then copy `agent-skills/github-copilot/*` over your `.github/skills/` again.

## Step 3 — Commands (Prompt Files)

```bash
mkdir -p .github/prompts
cp agent-commands/github-copilot/*.prompt.md .github/prompts/
```

This installs `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, and `/learn` as prompt files. Type `/catalyst` in Copilot Chat — it'll prompt you to fill in the ticket via the `${input:ticket:...}` placeholder rather than requiring it typed inline.

## Step 4 — Subagents (optional)

For large or high-stakes tickets, split the four phases into isolated custom agents. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .github/agents
cp agent-subagents/github-copilot/*.agent.md .github/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer`. The orchestrator should use subagents for the FAN OUT phase; standard Copilot Chat execution remains sequential within one session, so use Copilot CLI **Fleet mode** (or equivalent subagent delegation) when you want true parallel fan-out.

## Step 5 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`), opened as its own folder/workspace in your IDE. The instructions, skills, and prompts you installed above live in the repo, so they travel with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

In Copilot Chat:

```
/catalyst
```

Fill in the ticket when prompted (a GitHub issue URL or pasted description). Copilot will state its fan-out tasks, run them, consolidate, re-verify each finding against the real files, and present a plan before proposing code.

## Next steps

- Check `.catalyst/skills/` for a playbook matching your ticket type.
- Copy `agent-commands/github-copilot/add-skill.prompt.md`'s pattern to add new prompt files as needed.
- Run `/learn` to turn this session's lessons into new or updated skills.
- Run `/add-template <tool>` (from Claude Code, if you also use it) for a tool not yet covered.
