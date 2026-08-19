# Catalyst

A library of orchestration patterns for coding agents working tickets — from GitHub Issues, Jira, Azure DevOps, or any other tracker — fan out, reduce, verify, synthesize — written as plain markdown, not code.

## The Problem

Point an LLM coding agent at a ticket and left to its own devices it usually does one of two things: reads the description and starts editing files immediately, or runs a pile of unfocused searches and drowns in its own results before it finds the actual root cause. Either way, verification gets skipped — the agent implements against its first guess instead of checking whether that guess is even correct.

The fix for this isn't a new framework, SDK, or orchestration engine to install. It's a thinking pattern: decompose the ticket into independent investigation tasks, run them, consolidate what comes back, skeptically re-check each finding against the actual code before trusting it, and only then write an implementation plan. Every mainstream agent tool (Claude Code, Cursor, Cline, Codex CLI, GitHub Copilot, OpenCode, Pi) can already do this — they just need to be told to, in their own configuration format.

## The Goal

Give developers copy-pasteable instructions and reference material for applying a fan-out/reduce/verify/synthesize pattern to recurring ticket types, in whatever agent tool they already use — without adopting a new dependency, package, or workflow runner.

Explicitly out of scope: this is not a TypeScript/C#/Python library, not an executable orchestration engine, and not a workflow config format. There is no code to install. Everything here is markdown meant to be read by a human, pasted into an agent's instruction file, or handed to an agent as a prompt.

Target audience: developers and teams using AI coding agents against a ticket-based workflow — GitHub Issues, Jira, Azure DevOps, Linear, or anything else — who want more reliable, verified output instead of first-guess implementations.

## Key Features

- **`.catalyst/install.md`** — the single canonical instruction block (delimited by `<!-- catalyst:start -->` / `<!-- catalyst:end -->` markers). This is the *only* text that ever gets pasted into an agent's always-loaded instruction file — small enough to read on every message without taxing the context window.
- **`.catalyst/orchestration.md`** — the full fan-out/reduce/verify/synthesize pattern, with node types (Agent/Verifier/Implementation), node output contracts, safety rules, anti-patterns (including silent node failure and its count-your-inputs fix), anchors (ground truth that cannot be argued with), and when to skip the graph plus a first-run CAP. Read on demand by commands and agents, never loaded by default.
- **`WORKTREE-WORKFLOW.md`** — an optional working-mode layer: doing each ticket's implementation in a dedicated git worktree (branch `{feature|bug}/{ticketid}_{summary-slug}`, main checkout untouched, cleanup after the PR merges), so parallel tickets never conflict. With no ticket ID (a bare description), the `{ticketid}_` prefix is dropped: `{feature|bug}/{summary-slug}`. Tracker-agnostic, like everything else.
- **`.catalyst/skills/`** — per-ticket-type playbooks (`bug-fix.md`, `feature-implementation.md`, `code-review.md`), each with a problem pattern, parallelizable analysis tasks, deduplication guidance, skeptical verification questions, an implementation checklist, and one fully worked example.
- **`catalyst-templates/`** — tool-specific setup instructions for applying the pattern in seven agents: Claude Code, Cursor, Cline, Codex CLI, GitHub Copilot, OpenCode, and Pi. Each covers exact config file locations, how to install via `/catalyst-install`, how that tool actually handles (or fakes) parallel execution, a worked ticket walkthrough, known limitations, and phrasing to correct the tool if it skips a phase. The instruction text itself is *not* duplicated here — it lives once in `.catalyst/install.md`.
- **`examples/`** — standalone, realistic ticket walkthroughs showing the full four-phase pattern applied end to end, independent of any specific agent tool.
- **`agent-commands/`** — copy-paste slash-command counterparts of `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, `/learn` for Cursor, Cline, GitHub Copilot, OpenCode, Codex CLI, and Pi, each in that tool's actual custom-command format (Claude Code's originals live in `.claude/commands/`).
- **`SUBAGENT-ARCHITECTURE.md`** — an optional layer on top of the core pattern: splits FAN OUT/VERIFY/SYNTHESIZE into named, purpose-built subagents (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`, `catalyst-code-reviewer`) coordinated by an orchestrator, so each phase can run in an isolated context on a model sized to its job — cheap/fast for fan-out, high-capability for verify/synthesize/review — cutting both token cost and context rot versus running the whole pattern in one growing session. Includes the anchors principle (all roles ground verdicts in evidence that actually happened — tests run, files read — never in a paraphrase) and a first-run CAP.
- **`agent-subagents/`** — ready-to-copy subagent definitions implementing that architecture for Claude Code, Cursor, OpenCode, GitHub Copilot, and Codex CLI (each in that tool's real agent-definition format — markdown+frontmatter for most, TOML for Codex), plus guidance docs for Cline and Pi, neither of which has a native per-role agent file format in core.
- **`agent-skills/`** — native skill-discovery wrappers for tools that support one (currently GitHub Copilot's `SKILL.md`/`.github/skills/<name>/` format). Each Copilot skill is **self-contained** per the agentskills.io specification (its `SKILL.md` carries the full playbook instructions), generated from the canonical `.catalyst/skills/*.md` files by `scripts/generate-copilot-skills.ps1`/`.sh` — so you evolve the canonical playbook once and regenerate the native skills.
- **`scripts/`** — build helpers: `build-zips.*` packages each tool's files into deployable zips under `dist/`, and `generate-copilot-skills.*` regenerates the self-contained Copilot `SKILL.md` files from the canonical playbooks.
- **`docs/`** — one getting-started guide per tool, walking through installing the pattern, the commands, and (where supported) the subagents together, end to end.
- Every file is standalone by design — open one skill file and one template file, point an agent at a ticket, and it works without cross-referencing anything else in the repo.

## Installation

**Marketplace** (Claude Code):

```
/plugin marketplace add cornelha/catalyst
/plugin install catalyst@catalyst-marketplace
```

**Zip bundles** (all 7 tools):

```bash
git clone https://github.com/{org}/catalyst.git && cd catalyst
./scripts/build-zips.sh
unzip dist/catalyst-<tool>.zip -d /path/to/your/project
```

**Manual** (copy files for your tool):

```bash
git clone https://github.com/{org}/catalyst.git
```

See [`docs/installation.md`](docs/installation.md) for the full per-tool guide covering global and per-project installation for all 7 tools.

## Getting Started

Open the getting-started guide for your tool in `docs/` — it walks through installing the core pattern, the commands, and (where supported) the subagents, together, with a first ticket to try it on. In short: run the tool's `/catalyst-install` command (or manually append `.catalyst/install.md` to your agent's instruction file), copy the commands for your tool from `agent-commands/`, and you're set.

## Usage

**Installing the pattern into a Claude Code session**, once per repo:

```
/catalyst-install
```

This appends the canonical block from `.catalyst/install.md` into `CLAUDE.md` (or `~/.claude/CLAUDE.md`) — idempotently, so re-running it never duplicates the block. The equivalent command exists for every tool in `agent-commands/`.

**Applying the pattern live**, using the bundled slash command:

```
/catalyst Fix login timeout handling — https://dev.azure.com/org/project/_workitems/edit/4521
```

This runs the four phases in order — stating fan-out tasks before executing them, consolidating findings, verifying each one against real code, and stopping at a plan for your confirmation before any file is touched — then, once you approve the implementation, runs a fifth review pass over the written code (bugs, style, accuracy against the ticket) before you open the PR.

**Adding a new ticket-type skill** to the library:

```
/add-skill performance-regression
```

This reads the existing skill files to match structure and tone, then writes a new standalone `.catalyst/skills/performance-regression.md`.

**Wiring the pattern into a different tool** not yet covered:

```
/add-template windsurf
```

This researches the tool's actual configuration mechanism (not guessed syntax) and writes a new `catalyst-templates/windsurf.md` following the same structure as the existing templates.

**Turning session lessons into new skills**, at the end of a working session:

```
/learn
```

This reviews what the session taught you about the repo, distills the durable, repo-specific lessons into proposed new `.catalyst/skills/*.md` files (or edits to existing ones), and waits for your confirmation before writing anything. Run it again later and it respects what's already been recorded — only genuinely new lessons get proposed.
