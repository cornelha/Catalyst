# Skill: Code Review

## Problem Pattern

Use this skill when a ticket asks you to review a PR, diff, or set of changes rather than write new code — evaluating correctness, quality, security, or fit before merge. Signals that a ticket matches this skill:
- Title/description contains "review", "PR #", "please check", "before merging"
- Ticket links a pull request, diff, or branch rather than describing desired new behavior
- The ask is to produce feedback/approval, not to write the implementation

If the ticket asks you to *also* fix what you find, run this skill first, then hand verified findings to `bug-fix.md` for the fix phase.

## Analysis Tasks (FAN OUT)

Run these independently and in parallel:

1. **Read the full diff** — every changed file, not just the ones mentioned in the PR description.
2. **Check test coverage of the diff** — which changed lines are exercised by new or existing tests; which are not.
3. **Search for callers of changed public functions/APIs** — anything outside the diff that depends on the old signature/behavior.
4. **Check for security-sensitive patterns in the diff** — input handling, auth checks, secrets, injection risk, unsafe deserialization.
5. **Compare against project conventions** — naming, error handling, logging, style — using 2-3 recently merged files in the same area as the reference.
6. **Check CI/build/lint status and any linked ticket's acceptance criteria** — does the diff actually satisfy what it claims to?

## Deduplication (REDUCE)

- Group findings by file and by severity (blocking vs. advisory), not by which task found them.
- Collapse repeated instances of the same pattern issue (e.g. "missing null check" in 5 places) into one finding with all 5 locations listed, rather than 5 separate findings.
- Discard purely stylistic nitpicks that don't violate an actual documented convention — state them separately as optional, don't mix with blocking issues.
- Rank remaining findings: correctness/security first, then test coverage gaps, then convention deviations.
- State the overall review verdict lean (approve / approve with changes / request changes) in one sentence before verification — then let verification confirm or overturn it.

## Verification Questions (VERIFY)

Ask each with fresh eyes — assume each flagged issue is a false alarm until the code proves otherwise:

- **Is this actually a bug, or does surrounding code (not visible in the diff alone) already handle it?** Open the full file, not just the diff hunk.
- **Does the missing test coverage matter, or is this line trivial/already covered indirectly by an integration test?** Run the existing suite and check coverage output, don't assume from reading alone.
- **Is the flagged caller actually broken by this change, or does it still satisfy the new contract?** Read the caller's code, don't infer from the function name.
- **Is the security concern exploitable given how this code is actually invoked, or is it theoretical?** Trace the real input path to this code.
- **Does the convention deviation break something, or is it a reasonable exception?** Check if similar exceptions exist elsewhere in the codebase for good reason.
- **Does the diff actually satisfy the linked ticket's acceptance criteria, or only partially?** Re-check each criterion against the actual changed code, not the PR description's claims.

Drop any finding that fails its question — mark it a false positive in the review output so the reviewer's reasoning is transparent. Keep only VALID verdicts with cited evidence.

## Implementation Checklist (SYNTHESIZE)

Since code review's output is feedback, not code, "implementation" here means producing the review itself:

- [ ] List blocking issues first, each with file:line, evidence, and a concrete suggested fix
- [ ] List advisory/non-blocking issues separately, clearly labeled as optional
- [ ] State test coverage gaps with specific missing test cases to add
- [ ] State the acceptance-criteria satisfaction check explicitly (which criteria met, which not)
- [ ] Give one clear overall verdict: approve / approve with minor changes / request changes
- [ ] If requesting changes, list them as an ordered checklist the author can work through
- [ ] Do not restate false-positive findings from verification in the final review — they were dropped for a reason

**Worktrees don't apply here.** This skill is read-only — it reviews a PR/diff/branch wherever that code lives. Unlike `bug-fix.md` and `feature-implementation.md`, it never creates a worktree (see `WORKTREE-WORKFLOW.md`). Tracker-agnostic: nothing here depends on which tracker the ticket came from.

## Worked Example

**Ticket:** "Review PR #892: add rate limiting to /api/upload"

**FAN OUT:**
1. Full diff read: adds `RateLimiter` middleware, registers it on `/api/upload` route, adds config for `maxRequestsPerMinute`
2. Test coverage: new `RateLimiterTests.cs` covers limiter logic; no test exercises it actually attached to the `/api/upload` route
3. Callers: `UploadController` is the only route using this middleware; no external callers of `RateLimiter` class itself yet
4. Security scan: rate limit key is derived from `Request.Headers["X-Forwarded-For"]` directly, no validation
5. Convention check: compared to `AuthMiddleware.cs` and `LoggingMiddleware.cs` — both validate/sanitize header input before use; this diff doesn't
6. CI/ticket check: linked ticket criteria — (a) limit to 10 req/min per user ✅ config default matches, (b) return 429 with retry-after header — diff returns 429 but no `Retry-After` header found

**REDUCE:**
- Blocking: unsanitized `X-Forwarded-For` header used directly as rate-limit key (spoofable, security concern); missing `Retry-After` header (fails acceptance criterion b)
- Advisory: no integration test for middleware actually attached to the route (unit tests only)
- Lean: request changes

**VERIFY:**
- Header spoofing actually exploitable? Traced request path — `X-Forwarded-For` is client-controlled unless a trusted proxy strips/sets it; checked `Startup.cs`, no proxy trust configuration exists. VALID, exploitable.
- Missing Retry-After actually missing? Read `RateLimiter.cs:78` — response only sets status code 429, no headers added. VALID.
- Missing integration test — does it matter? Checked `UploadControllerTests.cs` — no test hits the route enough times to trigger the limiter at all. VALID, real gap.
- Convention deviation — reasonable exception? Checked if any other middleware in the codebase trusts unsanitized headers — none do. VALID, should follow `AuthMiddleware.cs` sanitization pattern.

**SYNTHESIZE (review output):**
- Blocking:
  - `RateLimiter.cs:34` — sanitize/validate `X-Forwarded-For` per `AuthMiddleware.cs:22` pattern before using as rate-limit key (spoofing risk)
  - `RateLimiter.cs:78` — add `Retry-After` header on 429 response (ticket criterion b)
- Advisory:
  - Add an integration test in `UploadControllerTests.cs` that exceeds the limit via the real route, not just unit-level `RateLimiterTests.cs`
- Acceptance criteria: (a) met, (b) not met (see blocking item above)
- Verdict: request changes
