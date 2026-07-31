# Example: Bug Fix — "Export button silently fails for large date ranges"

This walkthrough applies `catalyst-skills/bug-fix.md` to a real-shaped ticket, start to finish, so you can see the pattern applied without needing to open any other file. It uses a GitHub issue (fetched here via the GitHub MCP server) as the tracker — the same walkthrough applies unchanged if the ticket comes from Jira, Azure DevOps, or Linear instead.

## The Ticket

> **GitHub Issue #5190** (`github.com/org/repo/issues/5190`) — "Export button silently fails for large date ranges"
>
> Users report that clicking "Export CSV" on the Activity page does nothing when the selected date range is longer than about 60 days. No error is shown. Works fine for shorter ranges. Started happening sometime in the last month — no one recalls a specific release.

## PHASE 1 — FAN OUT

Analysis tasks (independent, run in parallel):

1. Grep for "export" and "CSV" across the frontend and backend to find the relevant code paths.
2. Search for any tests covering the export feature, and run them.
3. `git log` on the files found in task 1, filtered to the last month.
4. Use the GitHub MCP server's `search_issues` tool for related/duplicate issues mentioning "export" or "CSV."
5. Check server logs or error-handling code for silent failure patterns (swallowed exceptions, unhandled promise rejections) in the export path.

**Results:**
1. Found `ExportButton.tsx` (frontend, calls `POST /api/activity/export`) and `ActivityExportController.cs` (backend, streams CSV).
2. `ExportButtonTests.tsx` exists but only tests the button click handler wiring, not actual export behavior. No backend test exists for large ranges.
3. `git log --since="1 month ago" -- ActivityExportController.cs ExportButton.tsx` shows one commit 3 weeks ago: "Add request timeout of 10s to activity endpoints (perf)."
4. No duplicate tickets found; one older unrelated ticket about CSV column formatting.
5. `ActivityExportController.cs` wraps the query in a try/catch that logs to a log sink but returns a generic 200 with an empty body on exception — the frontend doesn't check for an empty body, so nothing visibly fails.

## PHASE 2 — REDUCE

Consolidated finding: a 3-week-old commit added a 10-second request timeout to activity endpoints for performance reasons. Large date-range exports likely exceed 10 seconds to generate, causing the request to time out; the controller's try/catch then swallows that error and returns an empty 200 response instead of propagating a real error, which is why the frontend shows nothing.

Root cause candidate: timeout + silent exception swallowing combination introduced by the perf commit.

## PHASE 3 — VERIFY

- **Is the 60-day threshold consistent with a 10s timeout?** Read `ActivityExportController.cs` query logic — it does a per-day aggregation loop with no batching. Estimated at ~150ms/day × 60 days ≈ 9s, consistent with tipping over a 10s timeout around that range. VALID.
- **Does the try/catch actually swallow a timeout exception specifically, or just database errors?** Read the catch block — it catches `Exception` broadly (not just DB exceptions), including `TaskCanceledException` from the timeout. VALID, confirms the mechanism.
- **Is this reproducible, not just theoretical?** Ran the export locally with a 65-day range against a seeded dataset — request took 11.2s and returned an empty 200 body, confirming the exact reported symptom (no error shown, nothing happens). VALID.
- **Did the perf commit have a reason that would make raising the timeout unsafe?** Read the commit message and linked ticket — it was added because a single misbehaving client was issuing runaway queries; the intent was to protect the server, not to cap legitimate long exports. Raising the timeout for exports specifically (not all activity endpoints) doesn't reintroduce that risk. VALID, safe to fix.

All findings verified — no false positives.

## PHASE 4 — SYNTHESIZE

**Problem (verified):** The perf-motivated 10s timeout on activity endpoints applies to `/api/activity/export`, which legitimately needs longer for large ranges; when it times out, the controller's broad exception handler swallows the error and returns an empty success response, so the frontend shows nothing.

**Implementation Checklist:**
- [ ] Add a failing test: request a 65+ day export against seeded data, assert either a real error response or successful completion — not an empty 200
- [ ] Give the export endpoint its own longer timeout (e.g. 60s) separate from the shared activity-endpoint timeout, so the original perf protection for other endpoints is untouched
- [ ] Fix the catch block in `ActivityExportController.cs` to return a proper error status (e.g. 504 or 500 with a message) instead of an empty 200
- [ ] Update `ExportButton.tsx` to check for and surface a non-200/error response to the user (toast or inline message)
- [ ] Add a test for the case where export genuinely still exceeds the new timeout, confirming the user now sees an error instead of silence
- [ ] Run the full activity-endpoint test suite to confirm other endpoints are unaffected by scoping the timeout change to export only
- [ ] PR notes: root cause was the perf-timeout commit combined with silent exception handling; fix scopes the timeout increase narrowly and makes failures visible
