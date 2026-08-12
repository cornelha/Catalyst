# Getting Started: Pi

## Prerequisites

- Pi (the `pi` coding agent CLI, `earendil-works/pi`) installed — `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` or `curl -fsSL https://pi.dev/install.sh | sh`.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp .catalyst/install.md AGENTS.md
```

Or, if you already have an `AGENTS.md`, append `.catalyst/install.md`'s content to it rather than overwriting. Unlike some other tools, Pi **concatenates** every `AGENTS.md` it finds (global, then each parent directory, then cwd) — it doesn't just take the closest one — so a project-root file and a `~/.pi/agent/AGENTS.md` both apply together if you have both. Or run `/catalyst-install` (after Step 2) and it will append the same block for you, idempotently.

## Step 2 — Commands

```bash
mkdir -p .pi/prompts
cp agent-commands/pi/*.md .pi/prompts/
```

Or copy to `~/.pi/agent/prompts/` instead for a global install available in every project. Filename minus `.md` becomes the slash command (`/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, `/learn`), with `$ARGUMENTS` in the body expanding to whatever you type after the command name.

**Caveat**: project-level `.pi/prompts/*.md` files only load once the project has been marked trusted — check `/settings` or `~/.pi/agent/trust.json` if a command doesn't show up in autocomplete.

## Step 3 — Subagents (optional)

Pi has no native subagent format in core — its own philosophy pushes this to extensions or external orchestration. Read `SUBAGENT-ARCHITECTURE.md` first, then `agent-subagents/pi.md` for the two real options: installing the third-party `pi-subagents` extension (Claude-Code-style `.pi/agents/<name>.md` definitions, parallel execution), or spawning separate `pi -p "..."` subprocesses yourself via background shell jobs. There are no drop-in files to copy here — `agent-subagents/pi.md` is a guidance doc, not a template folder.

## Step 4 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`), running Pi from inside the worktree directory. `AGENTS.md` and any prompts live in the repo, so they travel with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

```bash
pi "Using our AGENTS.md orchestration pattern, work GitHub issue #4521: Fix login timeout handling."
```

Or, with prompts installed: `/catalyst <ticket text or URL>`.

Pi will state its fan-out tasks, run a batched read-only `bash` call, consolidate, re-verify against the actual files, and present a plan before using `edit`/`write` to apply any change.

## Next steps

- Check `.catalyst/skills/` for a playbook matching your ticket type.
- Adapt `agent-commands/pi/add-skill.md`'s pattern to add new prompts for recurring ticket types.
- Run `/learn` to turn this session's lessons into new or updated skills.
- Run `/add-template <tool>` (from Claude Code, if you also use it) for a tool not yet covered.
