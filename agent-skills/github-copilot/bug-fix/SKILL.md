---
name: bug-fix
description: Use when a ticket reports something that used to work (or should per spec) but currently doesn't — a crash, wrong output, regression, error message, or failing test. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to find and fix the verified root cause.
---

# Bug Fix

Applies the Catalyst four-phase pattern (fan out, reduce, verify, synthesize) to bug tickets. Read `catalyst-skills/bug-fix.md` at the repo root for the full Analysis Tasks, Deduplication guidance, Verification Questions, Implementation Checklist, and a worked example — this file is the discovery pointer, that file is the source of truth.

Match signals: title/description contains "bug", "broken", "fails", "regression", "unexpected behavior", "error", "crash"; ticket includes reproduction steps or an error log/stack trace; ticket references a specific version where behavior changed.

If the ticket instead asks for new capability that never existed, use the `feature-implementation` skill instead.
