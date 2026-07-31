# Example: Code Review — "Review PR #1204: add bulk-delete to Inventory API"

This walkthrough applies `catalyst-skills/code-review.md` to a real-shaped ticket, start to finish, so you can see the pattern applied without needing to open any other file. It uses a GitHub issue (fetched here via the GitHub MCP server) as the tracker — the same walkthrough applies unchanged if the ticket comes from Jira, Azure DevOps, or Linear instead.

## The Ticket

> **GitHub Issue #7288** (`github.com/org/repo/issues/7288`) — "Review PR #1204: add bulk-delete to Inventory API"
>
> Linked ticket #7201 acceptance criteria:
> - `DELETE /api/inventory/bulk` accepts a list of item IDs
> - Only items owned by the requesting user's organization can be deleted
> - Returns a per-item success/failure report, not an all-or-nothing failure
> - Max 500 IDs per request

## PHASE 1 — FAN OUT

Analysis tasks (independent):

1. Read the full diff for PR #1204, every changed file.
2. Check test coverage of the diff — which changed lines have tests, which don't.
3. Search for callers of any changed public methods (e.g. `InventoryService.Delete`, if its signature changed).
4. Security scan: check ownership/authorization enforcement and injection risk in the new bulk query.
5. Compare against conventions in 2-3 recently merged, similar bulk-operation endpoints.
6. Check the diff against ticket #7201's four acceptance criteria explicitly.

**Results:**
1. Diff touches `InventoryController.cs` (new `BulkDelete` action), `InventoryService.cs` (new `DeleteMany` method), and `InventoryServiceTests.cs`.
2. `InventoryServiceTests.cs` has tests for "delete succeeds for owned items" and "delete skips non-owned items" — no test for the 500-ID cap, no test for a fully-empty ID list, no test for the per-item report format.
3. `InventoryService.Delete` (singular) is unchanged; `DeleteMany` is new, no existing callers to break.
4. `DeleteMany` builds a SQL `WHERE id IN (@ids) AND org_id = @orgId` using parameterized queries — no raw string concatenation found. Ownership filter (`org_id = @orgId`) is present in the query itself, not just checked after the fact.
5. Compared to `BulkArchiveController.cs` (merged 6 weeks ago) — that endpoint caps at 500 IDs and returns `429`-style rejection *before* attempting the operation if the cap is exceeded; this diff's `BulkDelete` doesn't check the cap at all before calling `DeleteMany`.
6. Criteria check: (a) accepts list of IDs ✅, (b) org-scoped ownership enforced in query ✅, (c) per-item report — checked `DeleteMany`'s return type, it returns a single `bool` (all-or-nothing), not a per-item report ❌, (d) 500-ID cap — not implemented ❌.

## PHASE 2 — REDUCE

- Blocking: no 500-ID cap enforced (criterion d unmet); `DeleteMany` returns all-or-nothing instead of a per-item report (criterion c unmet) — these are the two biggest gaps.
- Advisory: missing test coverage for cap, empty list, and per-item report format (contingent on the above being fixed first).
- Convention deviation: `BulkArchiveController.cs` rejects over-cap requests before attempting the operation; this diff has no equivalent guard.
- Lean: request changes.

## PHASE 3 — VERIFY

- **Is the per-item report gap real, or does `DeleteMany` return more detail than the return type suggests?** Read `InventoryService.cs:88-104` in full — `DeleteMany` executes one bulk SQL statement and returns `rowsAffected > 0` as a single bool. No per-item detail is captured or returned anywhere in the method. VALID, criterion c genuinely unmet.
- **Is the missing cap actually exploitable/harmful, or just a minor gap?** Traced what happens with e.g. 50,000 IDs — the SQL `IN` clause has no size limit enforced by the app, so this would build a massive parameterized query. Real risk (query size, performance, plus explicit ticket requirement). VALID, blocking.
- **Is the ownership/authorization check actually correct, or does it only look correct?** Re-read the full query builder method, including how `orgId` is sourced — it comes from `HttpContext.User.Claims`, matching the pattern used in `BulkArchiveController.cs`'s equivalent auth check. Confirmed VALID, no security issue here — this is one thing the diff does correctly.
- **Does the "no test for cap" finding matter if the cap doesn't exist yet?** It's downstream of the blocking cap issue — flag as advisory but tie it explicitly to the cap fix, not as an independent nitpick.

## PHASE 4 — SYNTHESIZE (Review Output)

**Blocking:**
- `InventoryService.cs:88` — `DeleteMany` must return a per-item success/failure result (e.g. `Dictionary<int, bool>` or a result-per-ID list), not a single bool. Criterion (c) in ticket #7201 is unmet.
- `InventoryController.cs` (new `BulkDelete` action) — add a cap check rejecting requests with more than 500 IDs before calling `DeleteMany`, following the pattern in `BulkArchiveController.cs`. Criterion (d) is unmet, and unbounded ID lists are a real performance/query-size risk.

**Advisory (once blocking items are fixed):**
- Add tests for: cap-exceeded rejection, empty ID list behavior, and per-item report content (mix of owned/non-owned/nonexistent IDs in one request).

**What's correct (no action needed):**
- Ownership scoping is enforced correctly in the query itself, matching the established auth pattern — good.
- Parameterized queries used throughout, no injection risk found.

**Acceptance criteria:** (a) met, (b) met, (c) not met, (d) not met.

**Verdict:** request changes.
