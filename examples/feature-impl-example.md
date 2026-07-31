# Example: Feature Implementation — "Allow users to schedule recurring report emails"

This walkthrough applies `catalyst-skills/feature-implementation.md` to a real-shaped ticket, start to finish, so you can see the pattern applied without needing to open any other file. It uses a GitHub issue (fetched here via the GitHub MCP server) as the tracker — the same walkthrough applies unchanged if the ticket comes from Jira, Azure DevOps, or Linear instead.

## The Ticket

> **GitHub Issue #6034** (`github.com/org/repo/issues/6034`) — "Allow users to schedule recurring report emails"
>
> Acceptance criteria:
> - User can select a report and a frequency (daily, weekly, monthly) from the Reports page
> - Scheduled report is emailed to the user's account email at the chosen frequency
> - User can view and cancel their active schedules
> - Max 5 active schedules per user

## PHASE 1 — FAN OUT

Analysis tasks (independent):

1. Extract each acceptance criterion as a discrete testable item.
2. Search for any existing scheduling/cron infrastructure in the codebase.
3. Search for any existing email-sending code (for the report itself, or other transactional emails).
4. Check for a design doc or prior discussion of this feature.
5. Search for a partial implementation (feature flags, stub methods, "TODO: recurring reports").
6. Search closed/related tickets for prior rejected approaches.

**Results:**
1. Four discrete criteria as listed above, plus an implied fifth: some way to *display* active schedules (needs a UI list, not just create/cancel).
2. Found `JobScheduler.cs` — a generic recurring-job system already used for nightly data syncs, supports cron-like frequency strings.
3. Found `EmailService.SendTemplatedEmail(templateId, recipient, data)` used by the password-reset and weekly-digest features.
4. Found `docs/design/report-scheduling.md` — a design doc from 4 months ago, marked "draft, not yet approved," proposing a `ReportSchedule` table and describing the exact same criteria.
5. No stub or TODO found — this hasn't been started.
6. One related closed ticket: "Allow scheduling for ANY frequency (custom cron)" — rejected as over-scoped; team decided to ship daily/weekly/monthly only, matching the current ticket's criteria exactly.

## PHASE 2 — REDUCE

Merged requirement set: build a `ReportSchedule` entity (per the existing design doc), driven by `JobScheduler.cs` for the recurring trigger, using `EmailService.SendTemplatedEmail` to deliver the report. UI needs create, list, and cancel actions on the Reports page, with a 5-schedule cap enforced server-side. The design doc's schema is directly usable — no conflict between ticket and doc since the doc's scope already matches the (previously rejected) narrower frequency set.

## PHASE 3 — VERIFY

- **Does `JobScheduler.cs`'s pattern actually fit per-user, per-report recurring jobs, or was it built only for fixed system jobs (like nightly sync)?** Read `JobScheduler.cs` in full — its job registration takes a `jobId`, `cronExpression`, and a callback; it's generic enough to register dynamic per-user jobs, but all current usages are static/registered at startup. Registering and *de-registering* jobs dynamically at runtime (for cancel) is untested territory. VALID concern — need a small extension or wrapper, not a blocking rewrite.
- **Are there edge cases the criteria don't address?** Re-read criteria — no mention of what happens if a report is deleted while a schedule references it, or if the user's account email changes. Both are real gaps to handle explicitly.
- **Will this break existing `JobScheduler.cs` consumers?** Checked other jobs registered via it (nightly sync, cache warm) — they're static and don't call any new dynamic register/deregister methods this feature would add. No breakage; purely additive.
- **Is the draft design doc still current, or was it superseded?** Checked doc history and recent architecture notes — no newer doc supersedes it; still the most recent word on this feature's shape. Usable as-is.
- **Does the rejected "custom cron" ticket's reasoning still apply?** Read the rejection reason — team didn't want to expose raw cron syntax to end users (support burden, error-prone UI). This ticket's daily/weekly/monthly criteria avoid that entirely. Doesn't conflict.

All findings verified; one implementation gap identified (dynamic job registration) is real and must be designed for, not dismissed.

## PHASE 4 — SYNTHESIZE

**Feature (verified):** A `ReportSchedule` entity, created/cancelled per user, driving `JobScheduler.cs` via new dynamic register/deregister support, delivering reports through the existing `EmailService`. UI adds create/list/cancel on the Reports page. Must handle report-deletion and email-change edge cases explicitly, and enforce the 5-schedule cap server-side.

**Implementation Checklist:**
- [ ] Tests: create schedule succeeds (daily/weekly/monthly), create fails at 6th schedule (cap), cancel removes schedule and stops future sends, listing shows only the user's own schedules, schedule referencing a deleted report is cancelled or errors gracefully, email delivered to *current* account email even if changed after schedule creation
- [ ] Extend `JobScheduler.cs` with dynamic register/deregister methods (additive, doesn't touch existing static job registrations)
- [ ] Add `ReportSchedule` entity per `docs/design/report-scheduling.md` schema
- [ ] Wire schedule trigger → `EmailService.SendTemplatedEmail` with the report data
- [ ] Add cap check (5 active schedules) at creation time, server-side
- [ ] Add cascade/guard behavior for report deletion affecting active schedules
- [ ] Build Reports page UI: create form (report + frequency), list of active schedules, cancel action
- [ ] Update `docs/design/report-scheduling.md` status from "draft" to "implemented"
- [ ] PR notes: satisfies all four stated criteria plus the implied list-view requirement; extends `JobScheduler.cs` additively; confirms no conflict with the previously rejected custom-cron approach
