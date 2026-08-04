---
name: code-review
description: Use when a ticket asks to review a PR, diff, or set of changes rather than write new code — evaluating correctness, quality, security, or fit before merge. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to produce a verified review verdict.
---

# Code Review

Applies the Catalyst four-phase pattern (fan out, reduce, verify, synthesize) to review tickets. Read `catalyst-skills/code-review.md` at the repo root for the full Analysis Tasks, Deduplication guidance, Verification Questions, Implementation Checklist (the review output itself), and a worked example — this file is the discovery pointer, that file is the source of truth.

Match signals: title/description contains "review", "PR #", "please check", "before merging"; ticket links a pull request, diff, or branch rather than describing desired new behavior; the ask is for feedback/approval, not an implementation.

If the ticket asks you to *also* fix what you find, run this skill first, then hand verified findings to the `bug-fix` skill for the fix phase.
