# Agent Commands

Copy/paste command counterparts of Catalyst's three Claude Code slash commands (`/catalyst`, `/add-skill`, `/add-template`), reformatted for each agent tool's actual custom-command mechanism, verified against each tool's official docs. Pick the folder for your tool and drop its files into the path shown below.

| Tool | Source folder | Copy files to | Invoke with |
|---|---|---|---|
| **Claude Code** | `.claude/commands/` (already at repo root — nothing to copy) | *(n/a — already installed)* | `/catalyst`, `/add-skill`, `/add-template` |
| **Cursor** | `agent-commands/cursor/` | `.cursor/commands/` in your repo (or `~/.cursor/commands/` for global) | `/catalyst <ticket>` in Agent/Composer chat |
| **Cline** | `agent-commands/cline/` | `.clinerules/workflows/` in your repo | `/catalyst.md <ticket>` in chat |
| **GitHub Copilot** | `agent-commands/github-copilot/` | `.github/prompts/` in your repo | `/catalyst` in Copilot Chat (VS Code / Visual Studio / JetBrains) — prompts for the ticket input |
| **OpenCode** | `agent-commands/opencode/` | `.opencode/commands/` in your repo (or `~/.config/opencode/commands/` for global) | `/catalyst <ticket>` |
| **Codex CLI** | `agent-commands/codex/` | `~/.codex/prompts/` (top-level files only, no subfolders) | `/catalyst <ticket>` — **see deprecation note below** |

## Notes per tool (verified)

- **Cursor** (added in v1.6): commands are plain markdown files under `.cursor/commands/` (project) or `~/.cursor/commands/` (global, personal). Typing `/` in chat lists both and inserts the full file content as the prompt. No required frontmatter; text typed after the command name in chat becomes additional context appended to the prompt.
- **Cline**: these are "Workflows" — reusable, on-demand markdown files under `.clinerules/workflows/` (project) or `~/Documents/Cline/Workflows` (global). Invoke by typing the filename with its extension, e.g. `/catalyst.md`, in the same message as your ticket text. Workflows run once and complete, unlike `.clinerules` which persist across every message.
- **GitHub Copilot**: `.prompt.md` files in `.github/prompts/`, with YAML frontmatter (`agent`, `description`) and `${input:name:placeholder}` variable syntax — Copilot Chat prompts you to fill these in when you run `/catalyst`, rather than requiring inline arguments. Available in VS Code, Visual Studio, and JetBrains IDEs.
- **OpenCode**: markdown files in `.opencode/commands/` (project, note the plural "commands") or `~/.config/opencode/commands/` (global). Frontmatter supports `description`, `agent`, `model`, `subtask`. Body supports `$ARGUMENTS` (all args as one string), `$1`/`$2`/etc. (positional args), `` !`shell command` `` (inject shell output), and `@file` (include a file's contents). Commands are loaded at startup — restart the session after adding new files.
- **Codex CLI — ⚠️ deprecated mechanism**: custom prompts under `~/.codex/prompts/` still work as of this writing (filename → `/name`, with `$1`–`$9`, `$ARGUMENTS`, named `KEY=value` placeholders, and `$$` for a literal `$`), but OpenAI's own docs mark this feature **deprecated** in favor of "Skills" (reusable instructions Codex can invoke explicitly *or* implicitly, shareable via the repo rather than living only in `~/.codex`). The files in `agent-commands/codex/` will work today but are not the forward-looking approach — if you're setting this up fresh, check `developers.openai.com/codex/custom-prompts` for the current Skills-based equivalent before committing to this folder long-term.

## A note on how Impeccable actually does this

Impeccable (referenced as the model for this structure) doesn't ship per-command markdown files — it distributes full **skill** folders per tool, each mirroring that tool's native skill/hook location (`.claude/`, `.cursor/`, `.codex/`, `.github/skills/`, `.opencode/skills/impeccable`, etc.), compiled from one shared source into `dist/<provider>/`. The underlying principle we borrowed is the same — use each tool's actual native customization mechanism rather than a generic lowest-common-denominator format — just applied here to individual *commands* (since that's what Catalyst ships) rather than to a bundled skill package.

## Why these paths specifically

Every path and syntax detail above was checked against each tool's current official documentation (or, for Codex, OpenAI's developer docs) rather than assumed. Tool config surfaces move fast — if a path below 404s in your installed version, that's the tool having moved on since this was verified, not a guess we made up.

## Adding a seventh tool

Run `/add-template <tool-name>` (from Claude Code, using the reference command) to generate `catalyst-templates/<tool-name>.md` first — that file should research and document the tool's actual configuration mechanism using live web search, not recalled training data. Once confirmed, add a matching `agent-commands/<tool-name>/` folder with the three command files reformatted to that mechanism, and add a row to the table above.
