---
description: Install the Catalyst orchestration pattern into AGENTS.md if it isn't there yet
---
Install the Catalyst orchestration pattern into this project's `AGENTS.md` so it applies automatically every session (idempotent — safe to re-run).

Steps:
1. Read `catalyst-templates/opencode.md` and find the "Instruction Text to Paste" section. Copy the content *inside* the ```markdown fence (not the fence itself).
2. Read `AGENTS.md` (create it if it doesn't exist).
3. If `AGENTS.md` already contains the sentinel `<!-- catalyst-orchestration -->`, do nothing and report "Catalyst pattern already installed in AGENTS.md."
4. Otherwise append this block to the end of `AGENTS.md`:

```markdown
<!-- catalyst-orchestration -->

(the Instruction Text to Paste content you copied from catalyst-templates/opencode.md goes here)
```

5. Confirm the marker and pattern are now present.

Do not modify any other files and do not rewrite the rest of AGENTS.md.
