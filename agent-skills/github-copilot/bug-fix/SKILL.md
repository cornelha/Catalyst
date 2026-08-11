---
name: bug-fix
description: Use when a ticket reports something that used to work (or should per spec) but currently doesn't — a crash, wrong output, regression, error message, or failing test. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to find and fix the verified root cause.
metadata:
  source: .catalyst/skills/bug-fix.md
---

# Bug Fix

## Problem Pattern

Use this skill when a ticket reports something that used to work (or should work per spec) but currently doesn't: a crash, wrong output, regression, error message, or failing test. Signals that a ticket matches this skill:
- Title/description contains "bug", "broken", "fails", "regression", "unexpected behavior", "error", "crash"
- Ticket includes reproduction steps or an error log/stack trace
- Ticket references a specific version where behavior changed

If the ticket instead asks for new capability that never existed, use `feature-implementation` instead.

## Analysis Tasks (FAN OUT)

Run these independently and in parallel — none depends on another's output:

1. **Search for the error/symptom in code** — grep for the exact error message string, exception type, or symptom keyword (e.g. "TimeoutSeconds", "NullReferenceException", the failing field name).
2. **Find related tests** — search test files for the feature area; run the test suite (or the relevant subset) to see current pass/fail state.
3. **Check version/change history** — `git log -p` or blame on the suspected file(s) to find when the behavior last changed, and read the commit message/PR for intent.
4. **Search issue tracker for duplicates or related tickets** — same error message, same component, previously reverted fixes.
5. **Read the spec/docs for expected behavior** — README, design doc, API contract, or code comments stating what *should* happen.
6. **Trace the call path** — find callers of the suspected function/method to understand what inputs reach it and from where.

## Deduplication (REDUCE)

- Group findings by root cause candidate, not by which search task found them (the same bug is often surfaced by 3+ tasks).
- Discard findings that are merely "this file mentions the word from the ticket" with no logical connection to the symptom.
- If multiple candidate root causes remain, rank by: (a) directly explains the reported symptom, (b) has a failing test attached, (c) touches code changed most recently.
- Collapse near-duplicate tickets/issues into one reference list; keep only the ticket IDs that add new evidence.
- State the single leading root-cause hypothesis in one sentence before moving to verification. If you can't get to one sentence, the fan-out wasn't tight enough — narrow it.

## Verification Questions (VERIFY)

Ask each of these with fresh eyes — assume the hypothesis is wrong until the code proves otherwise:

- **Is the bug actually reproducible?** Read the exact code path with the reported inputs; don't trust the analysis summary — open the file and step through the logic yourself.
- **Does a test currently fail because of this, or is the "failing test" actually testing something else?** Run it; read its assertion, not just its name.
- **Is this a bug, or is it working-as-designed per the spec?** Compare actual spec text against actual behavior, not against the ticket author's assumption.
- **Was this already fixed and reverted?** If a prior PR touched this exact code, read why it was reverted — your fix may repeat the same mistake.
- **Does the root cause explain ALL reported symptoms, or only some?** If only some, there may be a second bug hiding behind the first.
- **Are there other callers who rely on the current (buggy) behavior?** Changing it could break them — check before concluding the fix is safe.

Drop any finding that fails its question. Keep only VALID verdicts with cited evidence (file:line, test name, spec quote).

## Implementation Checklist (SYNTHESIZE)

- [ ] Write a failing test that reproduces the bug exactly as reported (add it before touching the fix)
- [ ] Confirm the new test fails for the *verified* root cause, not a different reason
- [ ] Apply the minimal code change at the verified location(s)
- [ ] Confirm the new test now passes
- [ ] Run the full existing test suite for the affected module — check for regressions in callers found during verification
- [ ] Update docs/comments only if they described the now-incorrect behavior
- [ ] Note in the PR/commit message which root cause was fixed and which verification evidence confirmed it

**Working in a git worktree?** This skill yields the `bug/` branch prefix. Create the worktree at `../<repo>-<ticketid>` on branch `bug/{ticketid}_{summary-slug}` once the plan is confirmed, and do the implementation/tests/PR inside it. Tracker-agnostic: nothing here depends on which tracker the ticket came from.

## Worked Example

**Ticket:** "Login times out after 5 minutes instead of the documented 30 minutes"

**FAN OUT:**
1. Grep "TimeoutSeconds", "timeout" across `AuthService.cs`, `LoginController.cs` → found `TimeoutSeconds = 300` at `AuthService.cs:142`
2. Ran `AuthTests`: `TestSessionExpiry` and `TestTimeoutRefresh` both FAIL
3. `git log -p AuthService.cs` → last touched 6 months ago, commit message "revert timeout fix, caused refresh loop"
4. Backlog search "timeout" → 2 duplicate tickets, 1 previously closed PR #4521 (the reverted fix)
5. `TimeoutPolicy.md:8` → "Default: 1800 seconds (30 min)"
6. Callers of `AuthService.Validate()` → `LoginController.cs`, `RefreshMiddleware.cs` both assume `TimeoutSeconds` is authoritative, no other assumptions found

**REDUCE:** Root cause — `TimeoutSeconds` hardcoded to 300 instead of spec's 1800; a prior attempt to fix this (PR #4521) was reverted due to a refresh-loop side effect in `RefreshMiddleware.cs`.

**VERIFY:**
- Reproducible? YES — `AuthService.cs:142` literally sets 300; traced no override anywhere in call path.
- Tests confirm it? YES — both failing tests assert 1800s and observe 300s.
- Working-as-designed? NO — spec explicitly states 1800s.
- Previously reverted — why? PR #4521 changed the constant but `RefreshMiddleware.cs` had a race condition where refresh fired every 5 min regardless, causing a loop once timeout was extended. That middleware bug is separate and still present.
- Explains all symptoms? YES, for the timeout complaint. The refresh-loop risk is a second, related bug that must be fixed in the same change or the old revert reason recurs.

**SYNTHESIZE:**
- [ ] Add test `TestSessionExpiryAt30Min` asserting session survives to 1800s
- [ ] Fix `RefreshMiddleware.cs` race condition (make refresh interval derive from `TimeoutSeconds`, not a separate hardcoded value)
- [ ] Change `AuthService.cs:142` to `TimeoutSeconds = 1800`
- [ ] Run `AuthTests` full suite + `RefreshMiddlewareTests`
- [ ] Update `TimeoutPolicy.md` only if example values elsewhere are stale (checked — they aren't)
- [ ] PR description references ticket + notes PR #4521's revert reason and how this change avoids it
