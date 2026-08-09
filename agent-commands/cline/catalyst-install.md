Ensure the Catalyst orchestration pattern is installed for this Cline project (idempotent — safe to re-run).

The pattern lives in a dedicated rules file, `.clinerules/catalyst-orchestration.md`, which Cline loads automatically.

Steps:
1. If `.clinerules/catalyst-orchestration.md` already exists, do nothing and report "Catalyst pattern already installed."
2. Otherwise create `.clinerules/catalyst-orchestration.md` with the full content of `catalyst-templates/cline.md` (the whole file — setup, instruction text, parallelism notes, worked example, known limitations, correction tips).
3. Confirm the rules file now exists.

Do not modify any other files.
