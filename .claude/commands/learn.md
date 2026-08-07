Review what you learned about this repo during this session, and turn the durable lessons into new or updated skills in catalyst-skills/ so future sessions start smarter.

Reference: Read ORCHESTRATION-PROMPT.md for the pattern (fan out, reduce, verify, synthesize).
Reference: Read every existing file in catalyst-skills/ before proposing anything — a lesson is only worth a skill if it is NOT already covered by an existing skill.

Optional focus: $ARGUMENTS (a topic, ticket type, or area of the repo to limit the review to; if empty, review the whole session).

Work through these steps in order:

STEP 1 — RECALL
Review what actually happened in this session: which tasks took longer than they should have, which repo-specific conventions or quirks you discovered the hard way, which mistakes you corrected, which commands/tooling behavior surprised you, what you'd tell a fresh session before it started. Pull these from the session itself — do not invent lessons, and do not go searching the codebase for new material. Only confirm specifics (file names, conventions, commands) against the code if you're unsure you have them right.

STEP 2 — DISTILL
For each candidate lesson, decide which of three buckets it belongs in:
- NEW SKILL — a recurring, repo-specific pattern that no existing catalyst-skills/ file covers (e.g. "how this repo does migrations", "the build is slow, run only the affected project's tests"). These become new files.
- UPDATE — a lesson that refines or corrects an existing skill's Analysis Tasks, Verification Questions, or Implementation Checklist. These become edits to the existing file.
- DISCARD — anything generic (true of any repo), one-off, or already fully covered. Discard it explicitly and don't record it.

Keep a lesson only if all three hold: it is specific to THIS repo, it will recur, and recording it would make a future session measurably faster or more correct.

STEP 3 — DRAFT
For each NEW SKILL, write the full `catalyst-skills/<name>.md` with the exact structure and tone of the existing files:
1. Problem Pattern — when a ticket matches this skill
2. Analysis Tasks — independent, parallelizable investigation tasks (FAN OUT)
3. Deduplication — how to consolidate/filter findings (REDUCE)
4. Verification Questions — skeptic checks with fresh context, assume false until proven (VERIFY)
5. Implementation Checklist — concrete build steps (SYNTHESIZE)
6. One worked example grounded in this repo's real files/conventions

For each UPDATE, specify the exact edit to the existing file: which section, what changes, and why. Prefer small, surgical changes that preserve the existing structure.

STEP 4 — CONFIRM
Present a complete plan to the user: for each NEW SKILL, its name and one-sentence Problem Pattern; for each UPDATE, the file, section, and change. Stop and wait for approval before creating or editing anything.

STEP 5 — WRITE
After approval, create the approved new files and apply the approved edits exactly as planned. Do not modify any other files. If a skill's name collides with an existing file, treat it as an UPDATE and merge rather than overwriting.
