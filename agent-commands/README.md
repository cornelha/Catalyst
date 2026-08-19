# Agent Commands

Copy/paste command counterparts of Catalyst's Claude Code slash commands (`/catalyst`, `/catalyst-install`, `/catalyst-testcases`, `/add-skill`, `/add-template`, `/learn`), reformatted for each agent tool's actual custom-command mechanism, verified against each tool's official docs. Pick the folder for your tool and drop its files into the path shown below.

| Tool | Source folder | Copy files to | Invoke with |
|---|---|---|---|
| **Claude Code** | `.claude/commands/` (already at repo root — nothing to copy) | *(n/a — already installed)* | `/catalyst`, `/catalyst-install`, `/catalyst-testcases`, `/add-skill`, `/add-template`, `/learn` |
| **Cursor** | `agent-commands/cursor/` | `.cursor/commands/` in your repo (or `~/.cursor/commands/` for global) | `/catalyst <ticket>`, `/catalyst-testcases <ticket>` in Agent/Composer chat |
| **Cline** | `agent-commands/cline/` | `.clinerules/workflows/` in your repo | `/catalyst.md <ticket>`, `/catalyst-testcases.md <ticket>` in chat |
| **GitHub Copilot** | `agent-commands/github-copilot/` | `.github/prompts/` in your repo | `/catalyst`, `/catalyst-testcases` in Copilot Chat (VS Code / Visual Studio / JetBrains) — prompts for the ticket input |
| **OpenCode** | `agent-commands/opencode/` | `.opencode/commands/` in your repo (or `~/.config/opencode/commands/` for global) | `/catalyst <ticket>`, `/catalyst-testcases <ticket>` |
| **Codex CLI** | `agent-commands/codex/` | `~/.codex/prompts/` (top-level files only, no subfolders) | `/catalyst <ticket>`, `/catalyst-testcases <ticket>` — **see deprecation note below** |
| **Pi** | `agent-commands/pi/` | `.pi/prompts/` in your repo (or `~/.pi/agent/prompts/` for global) | `/catalyst <ticket>`, `/catalyst-testcases <ticket>` |

`/catalyst-install` (available in every tool above) appends the canonical instruction block from `.catalyst/install.md` into the tool's always-loaded instruction file (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, or `.clinerules`) — idempotently, so re-running it never duplicates the block.

`/learn` (available in every tool above) is the self-improvement loop: run it at the end of a session to review what you learned about the repo and turn durable lessons into new or updated files in `.catalyst/skills/`. It proposes a plan (new skills + edits to existing skills) and waits for your approval before writing anything.

## Notes per tool (verified)

- **Cursor** (added in v1.6): commands are plain markdown files under `.cursor/commands/` (project) or `~/.cursor/commands/` (global, personal). Typing `/` in chat lists both and inserts the full file content as the prompt. No required frontmatter; text typed after the command name in chat becomes additional context appended to the prompt.
- **Cline**: these are "Workflows" — reusable, on-demand markdown files under `.clinerules/workflows/` (project) or `~/Documents/Cline/Workflows` (global). Invoke by typing the filename with its extension, e.g. `/catalyst.md`, in the same message as your ticket text. Workflows run once and complete, unlike `.clinerules` which persist across every message.
- **GitHub Copilot**: `.prompt.md` files in `.github/prompts/`, with YAML frontmatter (`agent`, `description`) and `${input:name:placeholder}` variable syntax — Copilot Chat prompts you to fill these in when you run `/catalyst`, rather than requiring inline arguments. Available in VS Code, Visual Studio, and JetBrains IDEs.
- **OpenCode**: markdown files in `.opencode/commands/` (project, note the plural "commands") or `~/.config/opencode/commands/` (global). Frontmatter supports `description`, `agent`, `model`, `subtask`. Body supports `$ARGUMENTS` (all args as one string), `$1`/`$2`/etc. (positional args), `` !`shell command` `` (inject shell output), and `@file` (include a file's contents). Commands are loaded at startup — restart the session after adding new files.
- **Codex CLI — ⚠️ deprecated mechanism**: custom prompts under `~/.codex/prompts/` still work as of this writing (filename → `/name`, with `$1`–`$9`, `$ARGUMENTS`, named `KEY=value` placeholders, and `$$` for a literal `$`), but OpenAI's own docs mark this feature **deprecated** in favor of "Skills" (reusable instructions Codex can invoke explicitly *or* implicitly, shareable via the repo rather than living only in `~/.codex`). The files in `agent-commands/codex/` will work today but are not the forward-looking approach — if you're setting this up fresh, check `developers.openai.com/codex/custom-prompts` for the current Skills-based equivalent before committing to this folder long-term.
- **Pi**: markdown "prompt templates" under `.pi/prompts/` (project) or `~/.pi/agent/prompts/` (global). Optional YAML frontmatter (`description`, `argument-hint`); body syntax is `$1`/`$2` for positional args, `$@`/`$ARGUMENTS` for all args, `${1:-default}`/`${@:-default}` for fallbacks, `${@:N}`/`${@:N:L}` for slicing — close to OpenCode's convention. Filename minus `.md` becomes `/name`. Project-level `.pi/prompts/*.md` files only load once the project has been marked trusted (check `/settings` or `~/.pi/agent/trust.json`); this doesn't apply to the global `~/.pi/agent/prompts/` location.

## A note on how Impeccable actually does this

Impeccable (referenced as the model for this structure) doesn't ship per-command markdown files — it distributes full **skill** folders per tool, each mirroring that tool's native skill/hook location (`.claude/`, `.cursor/`, `.codex/`, `.github/skills/`, `.opencode/skills/impeccable`, etc.), compiled from one shared source into `dist/<provider>/`. The underlying principle we borrowed is the same — use each tool's actual native customization mechanism rather than a generic lowest-common-denominator format — just applied here to individual *commands* (since that's what Catalyst ships) rather than to a bundled skill package.

## Why these paths specifically

Every path and syntax detail above was checked against each tool's current official documentation (or, for Codex, OpenAI's developer docs) rather than assumed. Tool config surfaces move fast — if a path below 404s in your installed version, that's the tool having moved on since this was verified, not a guess we made up.

## Adding an eighth tool

Run `/add-template <tool-name>` (from Claude Code, using the reference command) to generate `catalyst-templates/<tool-name>.md` first — that file should research and document the tool's actual configuration mechanism using live web search, not recalled training data. Once confirmed, add a matching `agent-commands/<tool-name>/` folder with the five command files reformatted to that mechanism, and add a row to the table above.
