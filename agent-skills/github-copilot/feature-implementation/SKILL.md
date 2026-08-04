---
name: feature-implementation
description: Use when a ticket asks for new capability that does not currently exist — a new endpoint, UI element, configuration option, integration, or workflow. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to plan and build it against verified requirements and existing patterns.
---

# Feature Implementation

Applies the Catalyst four-phase pattern (fan out, reduce, verify, synthesize) to feature tickets. Read `catalyst-skills/feature-implementation.md` at the repo root for the full Analysis Tasks, Deduplication guidance, Verification Questions, Implementation Checklist, and a worked example — this file is the discovery pointer, that file is the source of truth.

Match signals: title/description contains "add", "implement", "support for", "new", "enable"; ticket includes acceptance criteria describing desired behavior, not corrective behavior; no prior working state is being restored — greenfield or additive work.

If the ticket is about restoring previously-working behavior, use the `bug-fix` skill instead.
