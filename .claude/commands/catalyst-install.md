Install the Catalyst orchestration pattern into this project's `CLAUDE.md` so it applies automatically every session (idempotent — safe to re-run).

Steps:
1. Read `catalyst-templates/claude-code.md` and find the "Instruction Text to Paste" section. Copy the content *inside* the ```markdown fence (not the fence itself).
2. Read `CLAUDE.md` (create it if it doesn't exist).
3. If `CLAUDE.md` already contains the sentinel `<!-- catalyst-orchestration -->`, do nothing and report "Catalyst pattern already installed in CLAUDE.md."
4. Otherwise append this block to the end of `CLAUDE.md`:

```markdown
<!-- catalyst-orchestration -->

(the Instruction Text to Paste content you copied from catalyst-templates/claude-code.md goes here)
```

5. Confirm the marker and pattern are now present.

Do not modify any other files and do not rewrite the rest of CLAUDE.md.
