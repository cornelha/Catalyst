# Subagents in Pi

Pi is, like Cline, a tool without a native "drop a markdown file with frontmatter into a folder" mechanism for named, per-role subagents built into core. Pi's own project philosophy is direct about this: "No sub-agents. There's many ways to do this. Spawn pi instances via tmux, or build your own with extensions, or install a package that does it your way." There's nothing to copy-paste into core Pi — instead, two real mechanisms exist, and this file explains how to apply the Catalyst orchestrator/fan-out/verify/synthesize roles to each.

## Option A — the `pi-subagents` extension

A third-party Pi extension (`tintinweb/pi-subagents`) adds Claude-Code-style autonomous subagents to Pi: custom agent types defined via YAML frontmatter files at `.pi/agents/<name>.md` (project) or a global equivalent, each with its own system prompt, model, thinking level, and tool restrictions, run in foreground or background, with parallel execution, a live widget, and mid-run steering.

To apply Catalyst's roles here, define five agent files once the extension is installed:

- **`catalyst-orchestrator`** — the primary session. Give it the same responsibilities as `agent-subagents/claude-code/catalyst-orchestrator.md` (decompose, delegate, consolidate, present, never analyze/verify/synthesize directly).
- **`catalyst-fan-out-analyst`** — an agent definition with read-only tools and a fast/cheap model, given one FAN OUT task at a time. Use the same system prompt as `agent-subagents/claude-code/catalyst-fan-out-analyst.md`.
- **`catalyst-verifier`** — an agent definition with read-only tools and a mid-to-high capability model, given only a finding + skeptical question, never the analyst's reasoning trail. Same system prompt as the Claude Code verifier file.
- **`catalyst-synthesizer`** — an agent definition with edit-capable tools and your highest-capability model, given only verified findings. Same system prompt as the Claude Code synthesizer file.
- **`catalyst-code-reviewer`** — a read-only agent definition with a high-capability model, given the ticket and the implemented changes after SYNTHESIZE/implementation, reviewing for bugs, style (repo skills first, else industry best practice), and accuracy against the ticket. Returns a compact structured report. Same system prompt as the Claude Code code-reviewer file.

Check the `pi-subagents` extension's own README for its current YAML schema (model/tool/thinking-level keys) before assuming field names — it's a third-party package that moves independently of Pi core.

## Option B — spawn separate `pi` CLI instances

Since Pi has no built-in restriction on what a `bash` call can do, and its own docs suggest tmux as the go-to pattern, you can spawn independent `pi` processes as subprocesses — each with its own session, model flag, and prompt, monitored via background shell jobs or a headless/RPC mode (`pi --mode rpc` or `pi -p "..."` for print-and-exit) rather than an interactive TUI.

This maps onto Catalyst's roles more manually:

- Run the **orchestrator** role in your main interactive `pi` session, using `.catalyst/orchestration.md` and the relevant `.catalyst/skills/*.md` file directly.
- For each FAN OUT task, spawn a separate `pi -p "..."` subprocess scoped to a read-only instruction (no `write`/`edit` mentioned in its prompt), running the fan-out analyst's instructions from `agent-subagents/claude-code/catalyst-fan-out-analyst.md`. Launch these as background shell jobs so they run concurrently, then `wait` for all of them before REDUCE.
- For VERIFY, spawn one `pi -p "..."` instance per finding with the verifier's instructions and only that finding as input.
- For SYNTHESIZE, spawn one `pi -p "..."` instance with the synthesizer's instructions and only the verified findings list as input.
- After implementation, spawn one `pi -p "..."` instance with the code-reviewer's instructions (`agent-subagents/claude-code/catalyst-code-reviewer.md`) and the ticket + changed files as input; review for bugs, style, and accuracy and return the structured report.

This is more manual than Option A, but works today with nothing installed beyond Pi itself, and gives you the same context-isolation and per-role model-selection benefits (pass a different model flag per spawned instance).

## Which to pick

If you're comfortable installing a third-party extension and want live steering/parallelism with less scripting, use Option A. If you'd rather stay dependency-free and are already comfortable with background shell jobs, Option B gets you the same isolation and cost-control benefits with nothing but Pi's own CLI.
