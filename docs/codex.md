# Getting Started: Codex CLI

## Prerequisites

- Codex CLI installed.
- This repo (or a clone of it) available so you can copy files from it.

## Step 1 — Install the core pattern

```bash
cp catalyst-templates/codex.md AGENTS.md
```

Or, if you already have an `AGENTS.md`, append `catalyst-templates/codex.md`'s instruction block to it rather than overwriting. `AGENTS.md` at your project root is loaded automatically every session; `~/.codex/AGENTS.md` applies it globally across every repo.

## Step 2 — Commands

```bash
mkdir -p ~/.codex/prompts
cp agent-commands/codex/*.md ~/.codex/prompts/
```

**Caveat**: OpenAI has deprecated Codex CLI custom prompts (this mechanism) in favor of "Skills." These files work today — filename minus `.md` becomes `/name` — but check `developers.openai.com/codex/custom-prompts` before building long-term workflows on this specifically. Only top-level `.md` files in `~/.codex/prompts/` are scanned, not subfolders.

## Step 3 — Subagents (optional)

Codex CLI's subagent system (GA'd March 2026) uses a genuinely different format from the other tools — TOML, not markdown. Read `SUBAGENT-ARCHITECTURE.md` first, then:

```bash
mkdir -p .codex/agents
cp agent-subagents/codex/*.toml .codex/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer` as custom agents. Codex doesn't spawn them automatically just because the files exist — ask explicitly, e.g. "spawn catalyst-fan-out-analyst to check X." Concurrency is capped by `agents.max_threads` (default 6), and subagents can't escalate beyond the parent's `sandbox_mode`.

## Step 4 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`), running Codex from inside the worktree directory. `AGENTS.md` lives in the repo, so it travels with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

```bash
codex "Using our AGENTS.md orchestration pattern, work GitHub issue #4521: Fix login timeout handling."
```

Or, with prompts installed: `/catalyst` (paste the ticket text if argument substitution doesn't work on your installed version — see the note in `agent-commands/codex/catalyst.md`).

Codex will state its fan-out tasks, run batched read-only shell commands, consolidate, re-verify against the actual files, and present a plan before applying any patch (unless running in an auto-approval mode).

## Next steps

- Check `catalyst-skills/` for a playbook matching your ticket type.
- Adapt `agent-commands/codex/add-skill.md`'s pattern to add new prompts for recurring ticket types — or look at Codex's newer Skills system as the more future-proof equivalent.
- Run `/learn` to turn this session's lessons into new or updated skills.
- Run `/add-template <tool>` (from Claude Code, if you also use it) for a tool not yet covered.
