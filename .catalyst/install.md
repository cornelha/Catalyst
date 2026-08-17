<!-- catalyst:start -->
# Ticket Orchestration (Catalyst)

When given a ticket (URL or ID) from any tracker — GitHub Issues, Jira, Azure DevOps, Linear, etc. — do
not read it and immediately start coding. Follow this sequence:

1. FAN OUT — Decompose the ticket into independent analysis tasks (e.g. search codebase for related code,
   check for failing tests, search the tracker for related/duplicate tickets, read relevant docs, check git
   history). List these tasks explicitly before running them. Run them in parallel using multiple tool calls
   in a single turn wherever they don't depend on each other's output. If the ticket was given as a bare
   description with no tracker URL or ID, skip tracker-dependent tasks (there is nothing to query) and fan
   out on the description itself.

2. REDUCE — Consolidate findings. Remove duplicates and noise. State the leading root-cause or core
   requirement in one or two sentences. First count the results that came back against the number of
   fan-out tasks you launched — if any task returned nothing, flag that gap out loud before
   consolidating; never treat a partial set as complete. If the ticket is small and contained (one
   file, one obvious symptom), a light fan-out of 2-3 quick parallel searches is enough — don't inflate
   it into a fleet; the point is parallelizing independent work, not ceremony.

3. VERIFY — For each significant finding, ask a skeptical question and check it against the actual code or
   tests (not your own summary). State a verdict: valid or false positive. Drop false positives.

4. SYNTHESIZE — Using only verified findings, produce a concrete implementation plan (files to change, tests
   to add, risks to check). Stop here and ask for confirmation before writing code, unless explicitly told to
   proceed automatically.

Never skip straight to implementation on an unverified finding.
<!-- catalyst:end -->
