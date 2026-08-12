# Subagents in Cline

Cline is the one tool in this library without a native "drop a markdown file with frontmatter into a folder" mechanism for named, per-role subagents. There's nothing to copy-paste here — instead, two real mechanisms exist, and this file explains how to apply the Catalyst orchestrator/fan-out/verify/synthesize roles to each.

## Option A — Cline SDK "agent teams"

The Cline SDK (its newer agent runtime, separate from the IDE extension) has native support for agent teams: a session can delegate to specialists, track progress, and exchange handoff notes inside one runtime, with each subagent running its own model, tools, and prompts — no custom orchestration code required.

To apply Catalyst's roles here, define five team members in your Cline SDK session config:

- **`catalyst-orchestrator`** — the primary session. Give it the same responsibilities as `agent-subagents/claude-code/catalyst-orchestrator.md` (decompose, delegate, consolidate, present, never analyze/verify/synthesize directly).
- **`catalyst-fan-out-analyst`** — a team member with read-only tools and a fast/cheap model, given one FAN OUT task at a time. Use the same system prompt as `agent-subagents/claude-code/catalyst-fan-out-analyst.md`.
- **`catalyst-verifier`** — a team member with read-only tools and a mid-to-high capability model, given only a finding + skeptical question, never the analyst's reasoning trail. Same system prompt as the Claude Code verifier file.
- **`catalyst-synthesizer`** — a team member with edit-capable tools and your highest-capability model, given only verified findings. Same system prompt as the Claude Code synthesizer file.
- **`catalyst-code-reviewer`** — a read-only team member with a high-capability model, given the ticket and the implemented changes after SYNTHESIZE/implementation, reviewing for bugs, style (repo skills first, else industry best practice), and accuracy against the ticket. Returns a compact structured report. Same system prompt as the Claude Code code-reviewer file.

Consult the Cline SDK docs for the current config schema for defining team members and their per-member model/tool overrides — this moves faster than the IDE extension's customization surface, so check before assuming a specific config key name.

## Option B — Orchestrate separate CLI instances

Cline (via its CLI, or via the IDE extension acting as a coordinator) can spawn and manage independent Claude Code CLI or Cline CLI instances as subprocesses — each with its own session, permission mode, and turn limit, monitored by parsing JSON output or exit codes.

This maps onto Catalyst's roles more manually:

- Run the **orchestrator** role in your main Cline IDE session, using `.catalyst/orchestration.md` and the relevant `.catalyst/skills/*.md` file directly.
- For each FAN OUT task, spawn a separate CLI instance (`claude -p "..."` or the Cline CLI equivalent) scoped to read-only tools, with a low `--max-turns`, running the fan-out analyst's instructions from `agent-subagents/claude-code/catalyst-fan-out-analyst.md`. Run these in parallel using background shell jobs, then `wait` for all to finish before REDUCE.
- For VERIFY, spawn one CLI instance per finding with the verifier's instructions and only that finding as input.
- For SYNTHESIZE, spawn one CLI instance with the synthesizer's instructions and only the verified findings list as input.
- After implementation, spawn one CLI instance with the code-reviewer's instructions (`agent-subagents/claude-code/catalyst-code-reviewer.md`) and the ticket + changed files as input; review for bugs, style, and accuracy and return the structured report.

This is more manual than Option A, but works today without depending on SDK-specific config, and gives you the same context-isolation and per-role model-selection benefits (pass a different `--model` flag per spawned instance).

## Which to pick

If you're already using the Cline SDK for other agent-team work, use Option A — it's the maintained, native path. If you're working purely from the Cline IDE extension or CLI without SDK integration, Option B gets you the same isolation and cost-control benefits with tools you already have.
