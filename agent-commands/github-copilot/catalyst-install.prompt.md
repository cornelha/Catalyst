---
agent: 'agent'
description: Install the Catalyst orchestration pattern into this project's always-loaded instructions
---
Install the Catalyst orchestration pattern into this project's always-loaded instructions so it applies automatically in every request, not just via `/catalyst`.

1. Check that `.catalyst/install.md` exists in this repo. If it does not, tell the user to copy the `.catalyst/` folder from the Catalyst library into the project root first, then re-run this command.
2. Read `.catalyst/install.md` — it contains the canonical instruction block, delimited by `<!-- catalyst:start -->` and `<!-- catalyst:end -->` markers. The file is exactly that block — no explanatory header — so append its full content (markers included, for idempotency).
3. Read the project's `.github/copilot-instructions.md` (create it if it doesn't exist).
4. If `.github/copilot-instructions.md` already contains the block between the markers, make no changes and report that Catalyst is already installed.
5. Otherwise append the block from step 2 (markers included) to `.github/copilot-instructions.md`, preserving any existing content above it.
6. Report exactly what you changed and where. Do not modify any other files.

${input:extra:Any additional context or preferences (optional; leave blank to proceed as described)}
