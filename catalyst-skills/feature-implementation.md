# Skill: Feature Implementation

## Problem Pattern

Use this skill when a ticket asks for new capability that does not currently exist — a new endpoint, UI element, configuration option, integration, or workflow. Signals that a ticket matches this skill:
- Title/description contains "add", "implement", "support for", "new", "enable"
- Ticket includes acceptance criteria describing desired behavior, not corrective behavior
- No prior working state is being restored — this is greenfield or additive work

If the ticket is about restoring previously-working behavior, use `bug-fix.md` instead. If it's about improving existing code without changing behavior, this skill doesn't apply (no ticket type currently covers pure refactors in this library).

## Analysis Tasks (FAN OUT)

Run these independently and in parallel:

1. **Read acceptance criteria closely** — extract every discrete, testable requirement as a separate line item (don't paraphrase into one big requirement).
2. **Find similar existing features in the codebase** — search for analogous patterns (e.g. if adding a new API endpoint, find how the last 2-3 endpoints were structured: routing, validation, auth, error handling).
3. **Check for design docs or API/schema specs** — search docs folder, wiki links in the ticket, or comments referencing design intent.
4. **Search for existing partial implementation** — someone may have started this; check for feature flags, TODO comments, or stubbed methods matching the feature name.
5. **Identify integration points** — what existing modules/services will call into or be called by this feature (config system, auth, database schema, other endpoints).
6. **Check for related open/closed tickets** — duplicate requests, prior discussion of approach, rejected designs (and why they were rejected).

## Deduplication (REDUCE)

- Merge the acceptance-criteria list with any authoritative design doc requirements — the design doc wins on technical detail, the ticket wins on scope/priority if they conflict (flag the conflict, don't silently pick one).
- Discard "similar feature" examples that are structurally different (e.g. a read endpoint pattern isn't a good template for a write endpoint).
- If a partial implementation exists, determine whether to build on it or discard it — don't blend both without a decision.
- Collapse integration points into a single list of "systems this feature touches," each with one sentence on what it needs from this feature (not the reverse).
- State the feature's core behavior in one or two sentences before verification.

## Verification Questions (VERIFY)

Ask each with fresh eyes — assume the planned design is wrong until the code proves it's compatible:

- **Does the proposed approach actually match the pattern of similar existing features, or does it just look similar on the surface?** Open the actual files, compare method signatures, error handling, and naming conventions line by line.
- **Do the acceptance criteria have edge cases that aren't addressed?** (empty input, concurrent access, permission boundaries, pagination limits) Check the criteria text again for anything implied but not stated.
- **Will this feature break or change behavior for any existing caller?** Search for existing consumers of any shared code/schema this feature touches.
- **Is the "similar existing feature" actually still the current pattern, or is it legacy code scheduled for replacement?** Check recent commits/docs for migration notes.
- **If a partial implementation exists, does it still compile/pass tests, or was it abandoned for a reason?** Read any comments or commit history explaining abandonment.
- **Does this duplicate a rejected prior design?** If a related ticket shows a similar approach was rejected, confirm the rejection reason no longer applies.

Drop any finding that fails its question. Keep only VALID verdicts with cited evidence.

## Implementation Checklist (SYNTHESIZE)

- [ ] Write tests for each verified acceptance-criteria line item (one test per discrete requirement, including edge cases surfaced in verification)
- [ ] Confirm all new tests fail before implementation (proves they test the right thing)
- [ ] Implement following the verified existing pattern (matching structure, naming, error handling conventions found in analysis)
- [ ] Wire up each verified integration point explicitly
- [ ] Confirm all new tests pass
- [ ] Run the existing test suite for every system identified as an integration point — check no regressions
- [ ] Update docs/schema/API spec to describe the new feature
- [ ] Note in the PR which design doc/ticket criteria were satisfied and cite the pattern file(s) followed

## Worked Example

**Ticket:** "Add support for exporting user activity as CSV via API"

**FAN OUT:**
1. Acceptance criteria extracted: (a) `GET /api/users/{id}/activity/export` returns CSV, (b) supports date-range query params, (c) requires same auth as activity view, (d) max 90-day range per request
2. Similar features: found `GET /api/users/{id}/activity` (JSON) and `GET /api/reports/export` (CSV, different resource) — the latter has the CSV-writer pattern to reuse
3. Design doc: `docs/api/exports.md` specifies CSV column order and header format
4. Partial implementation: none found, no stub or TODO
5. Integration points: `ActivityService` (data source), `AuthMiddleware` (existing auth check reused), `CsvWriter` util (from reports export)
6. Related tickets: one closed ticket rejected "export as PDF" due to library licensing cost — not relevant to CSV

**REDUCE:** Core behavior — new endpoint returns CSV of user activity within a bounded date range, reusing existing auth and the `CsvWriter` utility already proven in reports export; column format governed by `docs/api/exports.md`.

**VERIFY:**
- Pattern match real? Compared `ReportsExportController.cs` line by line — same base controller, same `CsvWriter.Write(IEnumerable<T>, Stream)` signature. Compatible.
- Edge cases in criteria? Date-range criteria doesn't state what happens if `end < start` or range > 90 days — needs explicit validation error, not silently truncating.
- Breaks existing callers? `ActivityService.GetActivity()` is read-only, adding a new caller doesn't change its contract. Safe.
- Is reports-export pattern current? Checked — added 2 months ago, referenced in latest architecture doc as the standard for export endpoints. Current.
- Partial implementation risk? N/A, none exists.
- Rejected prior design? PDF rejection was about licensing, unrelated to CSV. Doesn't apply.

**SYNTHESIZE:**
- [ ] Tests: valid range returns CSV, invalid range (end<start) returns 400, range >90 days returns 400, unauthorized request returns 401, empty activity returns header-only CSV
- [ ] Implement `ActivityExportController.cs` following `ReportsExportController.cs` structure
- [ ] Wire `AuthMiddleware`, `ActivityService`, `CsvWriter`
- [ ] Run `ActivityServiceTests` and `ReportsExportTests` for regressions
- [ ] Update `docs/api/exports.md` to add the new endpoint under the existing export list
- [ ] PR notes: satisfies criteria (a)-(d), follows `ReportsExportController.cs` pattern, explicit validation added for date range not covered in original criteria
