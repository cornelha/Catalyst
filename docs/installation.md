# Catalyst Installation Guide

Catalyst is a ticket orchestration pattern for AI coding agents — fan out, reduce, verify, synthesize. There are two ways to install it, depending on which tool you use:

- **Track 1 — Native Marketplace** (Claude Code, Copilot CLI): use built-in plugin commands
- **Track 2 — Manual Install** (all 7 tools): copy files or paste URLs

Every tool supports both global (user-wide, `~`) and per-project (`.`) installation. Global means every repo you open gets the pattern automatically; per-project means only the repo where you install it.

---

## Track 1: Native Marketplace (Claude Code & Copilot CLI)

### Claude Code

**Add the marketplace (once per machine):**

```
/plugin marketplace add https://github.com/cornelha/catalyst
```

**Install the plugin (per-project):**

```
/plugin install catalyst
```

**Install globally (every repo):**

```
/plugin install catalyst --global
```

This copies the commands, agents, skills, and instruction block into the right locations for Claude Code to discover them automatically. No manual file copying required.

**Verify:**

- Type `/` in chat — you should see `catalyst`, `add-skill`, `add-template`, `build-catalyst`, and `learn` in the autocomplete list.
- Agents (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`, `catalyst-code-reviewer`) appear when you reference them by name.

### Copilot CLI

**Add the marketplace (once per machine):**

```bash
copilot plugin marketplace add https://github.com/cornelha/catalyst
```

**Install the plugin (per-project):**

```bash
copilot plugin install catalyst
```

**Install globally (every repo):**

```bash
copilot plugin install catalyst --global
```

**Verify:**

- Run `/skills list` in Copilot CLI to confirm Catalyst skills are loaded.
- In Copilot Chat (VS Code / Visual Studio / JetBrains), type `/catalyst` to confirm prompt files are available.

### Cursor

Cursor reads the repo-root `.cursor-plugin/marketplace.json`. Add the marketplace, then install the plugin from the **Customize** panel (or interactively via the `cursor-agent` CLI):

```bash
cursor-agent plugin marketplace add https://github.com/cornelha/catalyst
```

- In Cursor, open **Customize → Marketplace**, find **catalyst**, and click **Install** (choose project or user scope).
- Commands (`/catalyst`, `/catalyst-install`, etc.), agents, and the always-on orchestration rule are installed automatically.

> Note: `cursor-agent plugin install` is not yet available as a non-interactive CLI command; install from the Customize panel after adding the marketplace.

### OpenCode

OpenCode has no native git marketplace, but the `opencode-marketplace` CLI installs commands and agents from a GitHub repo by convention. It reads the `opencode/` directory in this repo:

```bash
bunx opencode-marketplace install https://github.com/cornelha/catalyst/tree/main/opencode
```

- Add `--scope project` to install into `.opencode/` (project-local) instead of `~/.config/opencode/` (global).
- Updates: `bunx opencode-marketplace update catalyst`.

### oh-my-pi

oh-my-pi (omp) has a Claude-compatible marketplace. It reads the repo-root `.omp-plugin/marketplace.json`. Add the marketplace, then install the plugin:

```bash
omp plugin marketplace add https://github.com/cornelha/catalyst
omp plugin install catalyst@catalyst
```

- Run `omp plugin marketplace list` to confirm the registered marketplace name, then adjust the `@marketplace` suffix if yours differs.
- Commands (`/catalyst`, etc.) and agents are installed from the `oh-my-pi/` directory in this repo.

---

## Track 2: Manual Install (All 7 Tools)

For tools without a native marketplace, install by copying files from the repo or using the pre-built zip bundles.

### Option A: Zip Bundles (Recommended)

Build the per-tool bundles:

```bash
git clone https://github.com/cornelha/catalyst.git
cd catalyst
./scripts/build-zips.sh
```

This produces `dist/catalyst-<tool>.zip` for each supported tool. Unzip the bundle into the root of your project:

```bash
unzip dist/catalyst-claude-code.zip -d /path/to/your/project
```

Each bundle contains a `DEPLOY.md` with tool-specific post-install steps. The bundles are additive — nothing overwrites files you already have.

### Option B: Manual File Copy

Clone the repo and copy files for your tool:

```bash
git clone https://github.com/cornelha/catalyst.git
```

Then follow the steps for your tool below.

---

## Per-Tool Installation

### Claude Code (Manual)

**Per-project** (this repo only):

```
/catalyst-install
```

Or manually: append the content of `.catalyst/install.md` to your project's `CLAUDE.md`.

**Global** (every repo):

Append `.catalyst/install.md` to `~/.claude/CLAUDE.md`.

**Commands** are live the moment you're in the repo: `/catalyst`, `/add-skill`, `/add-template`, `/learn`. For other repos, copy `.claude/commands/*.md` into that repo's `.claude/commands/`.

**Subagents** (optional): copy `agent-subagents/claude-code/*.md` into `.claude/agents/` (project) or `~/.claude/agents/` (global). Restart Claude Code after copying.

### Cursor

**Per-project:**

1. Copy `.catalyst/install.md` content into a new rule file at `.cursor/rules/catalyst-orchestration.mdc` with frontmatter:
   ```yaml
   ---
   description: Ticket orchestration pattern - fan out, reduce, verify, synthesize
   alwaysApply: true
   ---
   ```
2. Copy `agent-commands/cursor/*.md` into `.cursor/commands/`.
3. Copy `agent-subagents/cursor/*.md` into `.cursor/agents/`.
4. Reload the Cursor window.

**Global:**

1. Paste `.catalyst/install.md` content as a rule via **Settings > Rules > Add Rule** (set to always apply).
2. Commands go in `~/.cursor/commands/`, agents in `~/.cursor/agents/`.

**Remote rule** (no clone needed):

In Cursor, go to **Settings > Rules > Add Rule > paste GitHub URL:**

```
https://raw.githubusercontent.com/cornelha/catalyst/main/.catalyst/install.md
```

### Cline

**Per-project:**

1. Copy `.catalyst/install.md` content into `.clinerules/catalyst-orchestration.md`.
2. Copy `agent-commands/cline/*.md` into `.clinerules/workflows/`.
3. Read `agent-subagents/cline.md` for subagent options (no native drop-in files).

Invoke workflows by typing the filename: `/catalyst.md <ticket>`.

**Global:**

1. Append to `~/Documents/Cline/rules/` or use Cline's global settings.
2. Workflows go in `~/Documents/Cline/Workflows/`.

### Codex CLI

**Per-project:**

1. Append `.catalyst/install.md` content to your project's `AGENTS.md` (create if needed).
2. Copy `agent-subagents/codex/*.toml` into `.codex/agents/`.
3. Copy `agent-commands/codex/*.md` into `~/.codex/prompts/` (home directory — Codex reads prompts from here).

**Global:**

Append `.catalyst/install.md` content to `~/.codex/AGENTS.md`.

**Note:** Codex custom prompts are deprecated in favor of Skills. Check `developers.openai.com/codex` for the current approach if setting up fresh.

### OpenCode

**Per-project:**

1. Append `.catalyst/install.md` content to your project's `AGENTS.md` (create if needed).
2. Copy `agent-commands/opencode/*.md` into `.opencode/commands/`.
3. Copy `agent-subagents/opencode/*.md` into `.opencode/agents/`.
4. Restart your OpenCode session.

**Global:**

1. Append to `~/.config/opencode/AGENTS.md`.
2. Commands go in `~/.config/opencode/commands/`, agents in `~/.config/opencode/agents/`.

**Via npx** (if supported by your version):

```bash
npx skills add https://github.com/cornelha/catalyst
```

### Cline

Cline has no git marketplace for consumers (its curated marketplace is submission-based), and its native plugin system is TypeScript. The Catalyst markdown content installs as Cline workflows and an always-on rule:

```bash
mkdir -p .clinerules/workflows
cp cline/workflows/*.md .clinerules/workflows/
cp cline/rules/*.mdc .clinerules/
```

- Workflows appear as `/<filename>` commands (e.g. `/catalyst.md`).
- The `catalyst-orchestration` rule applies the pattern to every session.

### Pi

Pi (`earendil-works/pi`) loads prompts from `.pi/prompts/` and concatenates every `AGENTS.md` it finds:

```bash
cp .catalyst/install.md AGENTS.md
mkdir -p .pi/prompts
cp pi/prompts/*.md .pi/prompts/
```

- Project-level prompts require the project to be marked trusted (`/settings` or `~/.pi/agent/trust.json`).
- For a global install, copy to `~/.pi/agent/prompts/` and `~/.pi/agent/AGENTS.md` instead.

### GitHub Copilot

**Per-project:**

1. Append `.catalyst/install.md` content to `.github/copilot-instructions.md` (create if needed).
2. Copy `agent-commands/github-copilot/*.prompt.md` into `.github/prompts/`.
3. Copy `agent-subagents/github-copilot/*.agent.md` into `.github/agents/`.
4. Copy `agent-skills/github-copilot/*/SKILL.md` into `.github/skills/<name>/`.

**Global:**

Append to `~/.github/copilot-instructions.md`.

**Note:** `.prompt.md` files work in Copilot Chat (VS Code, Visual Studio, JetBrains). Copilot CLI uses agents and skills directly.

### Pi

**Per-project:**

1. Append `.catalyst/install.md` content to your project's `AGENTS.md` (create if needed).
2. Copy `agent-commands/pi/*.md` into `.pi/prompts/`.
3. Read `agent-subagents/pi.md` for subagent options (requires `pi-subagents` extension or CLI-spawn).
4. Mark the project as trusted (`/settings` or `~/.pi/agent/trust.json`).

**Global:**

1. Append to `~/.pi/agent/AGENTS.md`.
2. Commands go in `~/.pi/agent/prompts/` (no trust check needed globally).

---

## What Gets Installed

Regardless of tool or method, you get:

| Component | What it does | File |
|---|---|---|
| **Core pattern** | The instruction block pasted into your agent's always-loaded config | `.catalyst/install.md` |
| **Orchestration reference** | Full pattern with node types, anti-patterns, anchors | `.catalyst/orchestration.md` |
| **Slash commands** | `/catalyst`, `/catalyst-install`, `/add-skill`, `/add-template`, `/learn` | Tool-specific paths (see above) |
| **Subagents** | Orchestrator, fan-out analyst, verifier, synthesizer, code-reviewer | Tool-specific paths (see above) |
| **Skills** | Bug fix, code review, feature implementation playbooks | `.catalyst/skills/` |
| **Worktree workflow** | Optional isolated git worktrees per ticket | `WORKTREE-WORKFLOW.md` |
| **Subagent architecture** | Optional role-based delegation layer | `SUBAGENT-ARCHITECTURE.md` |

## Updating

**Marketplace installs** (Claude Code / Copilot CLI):

```
/plugin update catalyst
```

or

```bash
copilot plugin update catalyst
```

**Manual installs:** pull the latest and re-copy changed files. The core instruction block is idempotent — re-appending it never duplicates.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Commands don't appear in autocomplete | Restart your agent session (commands load at startup) |
| Subagents not spawning | Verify the agent definition files are in the right directory and restart |
| Pattern not applied | Check that `install.md` content is in the right instruction file (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, or `.clinerules`) |
| "Plugin not found" error | Confirm the marketplace URL is correct and your machine has network access to the repo |
| OpenCode subagents ignoring `model:` frontmatter | Known upstream bug — verify your installed version before relying on model assignments |
