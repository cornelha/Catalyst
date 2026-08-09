Ensure the Catalyst orchestration pattern is installed for this Cursor project (idempotent — safe to re-run).

The pattern lives in a dedicated rule file, `.cursor/rules/catalyst-orchestration.mdc`, which Cursor loads automatically.

Steps:
1. If `.cursor/rules/catalyst-orchestration.mdc` already exists, do nothing and report "Catalyst pattern already installed."
2. Otherwise create `.cursor/rules/catalyst-orchestration.mdc` with the full content of `catalyst-templates/cursor.md` (the whole file — setup, instruction text, parallelism notes, worked example, known limitations, correction tips).
3. Confirm the rule file now exists.

Tell the user to reload the Cursor window so the new rule takes effect. Do not modify any other files.
