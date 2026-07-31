# Agent Subagents

Named, purpose-built subagents implementing the Catalyst pattern's four phases (FAN OUT, VERIFY, SYNTHESIZE — REDUCE handled inline by the orchestrator, see `SUBAGENT-ARCHITECTURE.md` for why), coordinated by a `catalyst-orchestrator`. Read `SUBAGENT-ARCHITECTURE.md` first — it explains the roles, the model-assignment principle, and when this is worth using over running the pattern inline in one session.

| Tool | Source folder | Copy files to | Format |
|---|---|---|---|
| **Claude Code** | `agent-subagents/claude-code/` | `.claude/agents/` in your repo (or `~/.claude/agents/` for global) | Markdown + YAML frontmatter |
| **Cursor** | `agent-subagents/cursor/` | `.cursor/agents/` in your repo (or `~/.cursor/agents/` for global) | Markdown + YAML frontmatter |
| **OpenCode** | `agent-subagents/opencode/` | `.opencode/agents/` in your repo (or `~/.config/opencode/agents/` for global) | Markdown + YAML frontmatter |
| **GitHub Copilot** | `agent-subagents/github-copilot/` | `.github/agents/` in your repo (`.agent.md` extension) | Markdown + YAML frontmatter |
| **Codex CLI** | `agent-subagents/codex/` | `.codex/agents/` in your repo (or `~/.codex/agents/` for personal) | **TOML**, not markdown |
| **Cline** | `agent-subagents/cline.md` | *(no drop-in files — read the file)* | N/A — SDK config or CLI-spawn pattern |

## Roles shipped

- `catalyst-orchestrator` — decomposes the ticket, delegates, consolidates, presents. Never analyzes/verifies/synthesizes itself.
- `catalyst-fan-out-analyst` — one read-only investigation task per instance, spawned in parallel.
- `catalyst-verifier` — skeptical re-check of one finding, with no inherited context from the analyst.
- `catalyst-synthesizer` — turns verified findings into an implementation plan.

No separate `catalyst-deduplicator` is shipped by default — REDUCE is cheap enough to run inline in the orchestrator. Add one yourself, following the same pattern as the other role files, if a given ticket's fan-out volume genuinely warrants it (see `SUBAGENT-ARCHITECTURE.md`).

## Verified caveats per tool

- **OpenCode**: there's a currently open upstream bug where subagents invoked via the Task tool ignore their own `model:` frontmatter and inherit the parent's model instead. The per-agent model assignments in `agent-subagents/opencode/` are correct as *written*, but confirm they're actually being *honored* in your installed version before relying on the cost/quality split.
- **Codex CLI**: subagents don't spawn automatically just because these `.toml` files exist in `.codex/agents/` — you have to explicitly ask Codex to spawn them (e.g. "spawn catalyst-fan-out-analyst to check X"). Concurrency is capped by `agents.max_threads` (default 6) and subagents cannot escalate beyond the parent's `sandbox_mode`.
- **GitHub Copilot**: standard Copilot Chat subagents run sequentially within one session; use Copilot CLI **Fleet mode** specifically to get true parallel execution for the FAN OUT phase.
- **Cline**: no native per-role agent-definition file exists. `cline.md` documents the two real options (Cline SDK agent teams, or spawning separate Claude Code/Cline CLI instances) — don't look for drop-in files here, there aren't any that would actually work.
- **Cursor**: subagents are a recent addition (v2.4, January 2026) — if your installed Cursor version predates this, the `.cursor/agents/` mechanism won't exist yet; fall back to `catalyst-templates/cursor.md`'s single-session pattern instead.

## Model names will drift

Every `model:` value in these files is a snapshot of what was current and reasonable at time of writing, not a permanent recommendation. Swap it for whatever your tool currently offers at the tier implied by the role (cheap/fast for fan-out, mid-tier for orchestration, high-capability for verify/synthesize) — that tier judgment is the part meant to last, not the specific model string.
