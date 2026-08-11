Install the Catalyst orchestration pattern into this project's always-loaded instructions so it applies automatically in every session, not just via `/catalyst`.

1. Check that .catalyst/install.md exists in this repo. If it does not, tell the user to copy the .catalyst/ folder from the Catalyst library into the project root first, then re-run this command.
2. Read .catalyst/install.md — it contains the canonical instruction block, delimited by `<!-- catalyst:start -->` and `<!-- catalyst:end -->` markers. The file is exactly that block — no explanatory header — so append its full content (markers included, for idempotency).
3. Read the project's AGENTS.md (create it if it doesn't exist). If you prefer a global install, use ~/.codex/AGENTS.md instead — ask the user which they want if it's not obvious.
4. If AGENTS.md already contains the block between the markers, make no changes and report that Catalyst is already installed.
5. Otherwise append the block from step 2 (markers included) to AGENTS.md (or the global file), preserving any existing content above it.
6. Report exactly what you changed and where. Do not modify any other files.

$ARGUMENTS
(NOTE: OpenAI has deprecated Codex CLI custom prompts in favor of "Skills" — see the caveat in agent-commands/README.md. This file works today if your Codex CLI version still supports `~/.codex/prompts/`, but check current Codex docs before relying on it long-term.)
