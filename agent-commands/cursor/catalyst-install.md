Install the Catalyst orchestration pattern into this project's always-loaded instructions so it applies automatically in every session, not just via `/catalyst`.

1. Check that `.catalyst/install.md` exists in this repo. If it does not, tell the user to copy the `.catalyst/` folder from the Catalyst library into the project root first, then re-run this command.
2. Read `.catalyst/install.md` — it contains the canonical instruction block, delimited by `<!-- catalyst:start -->` and `<!-- catalyst:end -->` markers. The file is exactly that block — no explanatory header — so append its full content (markers included, for idempotency).
3. Read the project's `AGENTS.md` (create it if it doesn't exist). Cursor applies this automatically to every Agent/Composer session. If you prefer a global install, use `~/.cursor/rules/` instead — ask the user which they want if it's not obvious.
4. If `AGENTS.md` already contains the block between the markers, make no changes and report that Catalyst is already installed.
5. Otherwise append the block from step 2 (markers included) to `AGENTS.md` (or the global rule), preserving any existing content above it.
6. Report exactly what you changed and where. Do not modify any other files.

Treat whatever text was typed after `/catalyst-install` when this command was invoked as additional context: $ARGUMENTS
