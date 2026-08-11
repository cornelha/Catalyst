# Getting Started: Claude Code

## Prerequisites

- Claude Code installed and working in this repo (or the repo you want to apply Catalyst to).
- This repo (or a clone of it) available so you can copy files from it — nothing here needs to be published or installed as a package.

## Step 1 — Install the core pattern

Claude Code's commands are already installed: `.claude/commands/catalyst.md`, `.claude/commands/catalyst-install.md`, `.claude/commands/add-skill.md`, `.claude/commands/add-template.md`, and `.claude/commands/learn.md` are live the moment you're working in this repo. If you want the fan-out/reduce/verify/synthesize pattern applied automatically to *every* session (not just when you type `/catalyst`), run:

```
/catalyst-install
```

It appends the canonical block from `.catalyst/install.md` into your project's `CLAUDE.md` (or `~/.claude/CLAUDE.md` for every repo on your machine) — idempotently, so re-running it won't duplicate the block. To install manually, append `.catalyst/install.md`'s content to `CLAUDE.md` yourself.

## Step 2 — Commands

Nothing to copy — `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, and `/learn` work as soon as you're in this repo. If you're setting Catalyst up in a *different* repo, copy the five files from `.claude/commands/` into that repo's own `.claude/commands/` folder.

## Step 3 — Subagents (optional)

For large or high-stakes tickets, split the four phases into isolated, purpose-built subagents instead of running everything in one session. Read `SUBAGENT-ARCHITECTURE.md` first for the reasoning, then:

```bash
cp agent-subagents/claude-code/*.md .claude/agents/
```

This installs `catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, and `catalyst-synthesizer`. Restart your Claude Code session afterward — subagent files are loaded at session start, so edits on disk won't be picked up until you do.

## Step 4 — Git worktrees (optional)

For parallel or isolated ticket work, read `WORKTREE-WORKFLOW.md` and do each ticket's implementation in its own worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`). The commands/agents you installed above live in the repo, so they travel with the branch into the worktree automatically — no reinstallation. Cleanup is user-triggered after the PR merges.

## Try it

Point `/catalyst` at a real ticket:

```
/catalyst Fix login timeout handling — https://github.com/org/repo/issues/4521
```

Watch it work through FAN OUT (parallel tool calls in one turn), REDUCE, VERIFY, and SYNTHESIZE, then stop and ask you to confirm before writing any code. If you installed the subagents in Step 3, you can instead ask explicitly for orchestrator-led delegation: "Use catalyst-orchestrator to work this ticket," and Claude Code will spawn the analyst/verifier/synthesizer subagents itself.

## Next steps

- Check `.catalyst/skills/` for a playbook matching your ticket type (bug fix, feature, code review) — `/catalyst` uses these automatically if one matches.
- Run `/add-skill <name>` to add a new ticket-type playbook once you notice a recurring pattern not yet covered.
- Run `/learn` at the end of a session to review what you learned about the repo and turn the durable lessons into new or updated skills.
- Run `/add-template <tool>` if your team also uses a tool not yet in `catalyst-templates/`.
