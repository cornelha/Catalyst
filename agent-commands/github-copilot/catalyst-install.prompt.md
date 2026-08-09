---
agent: 'agent'
description: Install the Catalyst orchestration pattern into .github/copilot-instructions.md if it isn't there yet
---
Install the Catalyst orchestration pattern into this repo's `.github/copilot-instructions.md` so it applies automatically (idempotent — safe to re-run).

Steps:
1. Read `catalyst-templates/github-copilot.md` and find the "Instruction Text to Paste" section. Copy the content *inside* the ```markdown fence (not the fence itself).
2. Read `.github/copilot-instructions.md` (create the `.github` directory and file if they don't exist).
3. If it already contains the sentinel `<!-- catalyst-orchestration -->`, do nothing and report "Catalyst pattern already installed."
4. Otherwise append this block to the end of the file:

```markdown
<!-- catalyst-orchestration -->

(the Instruction Text to Paste content you copied from catalyst-templates/github-copilot.md goes here)
```

5. Confirm the marker and pattern are now present.

Do not modify any other files and do not rewrite the rest of copilot-instructions.md.
