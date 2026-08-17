# Subagent Architecture

Everything in `.catalyst/orchestration.md` and `.catalyst/skills/` can be run inline, in one session — a single agent walking through FAN OUT → REDUCE → VERIFY → SYNTHESIZE itself. That works fine for small, contained tickets. This document describes the alternative: splitting each phase into a **named, purpose-built subagent**, coordinated by an **orchestrator**, so you can control cost, model choice, and context isolation per phase instead of running the whole pattern in one ever-growing context window. After SYNTHESIZE produces a confirmed plan, a `catalyst-impl` subagent handles the actual implementation (code, tests, worktree) and a `catalyst-code-reviewer` reviews the result — keeping the orchestrator purely in a coordination role.

**Composes with `WORKTREE-WORKFLOW.md`:** that file gives physical isolation per ticket (one git worktree per ticket, main checkout untouched); this file gives logical isolation per phase. Together: one ticket = one worktree = one orchestrator run, with all implementation happening inside the ticket's worktree.

## Why split phases into subagents at all

Two problems show up as a single-session pattern scales up:

1. **Context rot.** By the time a single agent reaches VERIFY, its context is full of its own FAN OUT reasoning — the very thing VERIFY is supposed to skeptically re-check. A verifier that inherits the analyst's framing tends to confirm it rather than challenge it. A fresh subagent, given only "here's a finding, here's how to check it," has no prior narrative to be biased by.
2. **Token/cost inefficiency.** FAN OUT is usually high-volume, mechanical work (grep, read, summarize) — it doesn't need your most expensive model. SYNTHESIZE is low-volume, high-judgment work — it benefits from your best model. Running the whole pattern in one session forces every phase through whatever model you picked at the start, whether that phase needs it or not.

Named subagents fix both: each phase gets an isolated context (no rot) and its own model assignment (no overpaying for grunt work, no underpaying for judgment work).

## The roles

| Role | Job | Spawned | Model guidance |
|---|---|---|---|
| **`catalyst-orchestrator`** | Reads the ticket, decomposes it into FAN OUT tasks, delegates each phase to the roles below, aggregates their (short) outputs, and presents the final plan. Never does deep analysis itself. | Once per ticket | Mid-tier — its job is coordination and judgment about *what* to delegate, not raw analysis, but it does need to reason about consolidation and final plan quality. |
| **`catalyst-fan-out-analyst`** | Runs exactly one independent, read-only analysis task (code search, test check, tracker query, doc read, git history) and returns a structured finding list — `finding: <claim> | evidence: <file:line/test/command output>`, one per line, no prose, no transcript. | Once per FAN OUT task, in parallel | Fast/cheap — narrow, mechanical, high-volume work. This is where token savings are largest: N parallel cheap agents instead of N sequential expensive turns. |
| **`catalyst-verifier`** | Given one finding and a skeptical question to check — not the analyst's reasoning trail — re-checks it against real code/tests and returns VALID or FALSE POSITIVE with cited evidence. | Once per significant finding (or batched, tool-dependent) | Mid-to-high — catching a false positive requires real judgment, not just pattern matching. |
| **`catalyst-synthesizer`** | Takes only verified findings and produces the concrete implementation plan (files, tests, risks). | Once, after VERIFY completes | Highest available — this is the actual engineering judgment step; underpowering it undermines the whole pattern. |
| **`catalyst-impl`** | Executes a confirmed implementation plan: creates a worktree, writes code, writes tests, runs tests, and reports results. Follows the plan literally — does not interpret or extend it. | Once, after SYNTHESIZE plan is confirmed | Highest available — code generation requires correctness; this is the most expensive phase and benefits from the strongest model available. Users should override per their budget. |
| **`catalyst-code-reviewer`** | After implementation, reviews the written code against the ticket for bugs/style (repo skills first, else industry best practice), and accuracy. Returns a compact structured report — no prose. | Once, after implementation, before the PR | High — post-implementation review needs real judgment, but its output must be token-lean (structured verdict + findings). |

**REDUCE is usually not a separate subagent.** Consolidating a handful of fan-out results is cheap enough that spawning an isolated agent for it just adds latency and orchestration overhead without meaningfully reducing context rot. Have the orchestrator do REDUCE inline — but *first* count the returned results against the number of fan-out tasks launched and flag any silent gap out loud (a fan-out that lost a node yields a report that looks complete and isn't). Only spawn a `catalyst-deduplicator` subagent instead if FAN OUT produced a large number of parallel analyst outputs (a big, ambiguous ticket touching many subsystems), whose only job is consolidating those raw outputs into one short findings list before they ever reach the orchestrator's own context — check the per-tool files for whether this is worth wiring up for your case.

## Naming convention

Prefix every Catalyst-managed agent with `catalyst-` (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`, `catalyst-synthesizer`, `catalyst-impl`, `catalyst-code-reviewer`, optionally `catalyst-deduplicator`). This keeps them easy to find in a tool's agent list, avoids colliding with a user's own custom agents, and makes it obvious at a glance which agents belong to this pattern versus the rest of a user's setup.

## What the orchestrator passes and expects back

To keep the isolation benefit real (not just theoretical), be deliberate about the handoff:

- **To a fan-out analyst**: the single task description, nothing else. Not the whole ticket, not other analysts' findings.
- **To the verifier**: the finding plus the specific skeptical question from the relevant `.catalyst/skills/*.md` file's Verification Questions section — not the analyst's reasoning, not the REDUCE summary's framing, just "here's a claim, here's how to check it."
- **To the synthesizer**: only the list of verified findings (VALID verdicts with their evidence), never the false positives, never the raw fan-out transcripts.
- **To the implementation agent**: the confirmed plan (from the synthesizer), the ticket (for context), and the relevant skill file (for the Implementation Checklist and worktree branch prefix). The impl agent creates its own worktree, executes the plan, and reports back with changed files, test results, and any deviations.
- **To the code reviewer**: the ticket (requirements/acceptance criteria) plus the changed files/diff — enough to judge accuracy, without the analysis trail.
- **Back from every subagent**: a short structured result (finding + evidence, or verdict + citation, or a plan, or a review report) — never the subagent's full internal transcript. The code-reviewer in particular must return only its structured report (verdict + one-line findings), never prose. The implementation agent must return only its structured report (changed files, test results, deviations), never the full transcript of its work. If a subagent's output is bloating the orchestrator's context, that's a sign it's over-returning, not that the pattern isn't working.

## Model-assignment principle, generalized

Regardless of which tool you're in, the same cost curve applies: **cheap/fast models for high-volume mechanical work (fan-out), capable models for judgment work (verify, synthesize), the strongest available model for implementation (correctness matters), and a mid-tier model for coordination (orchestrator).** The exact model names differ per tool and change over time — the per-tool files in `agent-subagents/` set a sensible default, but treat the specific model name as the one thing you should feel free to override immediately based on what's available and what your budget looks like.

**Run it capped.** On an unfamiliar ticket type, cap the first run's FAN OUT at 5-8 tasks (say so when you do), then widen only once a capped run proved its shape and cost. A graph's whole point is running wide without you — the cap is what keeps that from becoming "running away without you."

## Anchors — ground truth that cannot be argued with

Topology alone does not buy truth. The subagent split isolates context, but if every isolated context reads the *same* generated report, the graph is consistent and still wrong — it fails like a single loop, just later and more expensively. Anchor the pattern in evidence that refuses to move:

- **Tests that actually ran** — a verdict citing a passing/failing test only counts if the test was executed in that subagent's context, not if it was "expected to pass."
- **Code actually read** — evidence is anchor-grade only when the verifier/reviewer opened the real file at the cited line, not when it accepted the analyst's paraphrase.
- **External ground truth** — acceptance criteria quoted verbatim, spec/docs text, and API contracts are anchors; a paraphrased memory of them is not.
- **Frozen rules** — never skip VERIFY to save time, never implement on an unverified finding, never reduce a checked gap into silence. These are off-limits exactly because an optimizer would be tempted to bend them.

## When to use the full subagent split vs. running inline

Use the full orchestrator + subagent team when:
- The ticket is large, ambiguous, or touches many subsystems (fan-out would otherwise mean many sequential searches in one context)
- The work is high-stakes enough that a genuinely fresh-context VERIFY pass matters (security-sensitive changes, anything touching auth/payments/data integrity)
- You want to deliberately assign a cheaper model to the grunt work to control cost on a big investigation

Run inline (single session, no subagents) when:
- The ticket is small and contained (one file, one obvious symptom)
- Spinning up multiple isolated contexts would cost more in latency/coordination overhead than it saves in token cost or verification quality
- Your tool doesn't have a mature subagent mechanism yet (see `agent-subagents/cline.md` for the one tool in this library where that's currently true)

## Where to find ready-to-copy definitions

See `agent-subagents/<tool>/` for each tool's actual agent-definition format, or `agent-subagents/cline.md` for Cline's SDK/CLI-based alternative (Cline has no native per-role agent-definition file). Each file is scoped to one role and references the relevant phase instructions in `.catalyst/orchestration.md` and `.catalyst/skills/` rather than duplicating them, so updates to the core pattern don't require touching every agent definition.

## If you also use git worktrees

`WORKTREE-WORKFLOW.md` is the tracker-agnostic companion to this file: one worktree per ticket (branch `{feature|bug}/{ticketid}_{summary-slug}`, path `../<repo>-<ticketid>`; with no ticket ID, drop the `{ticketid}_` prefix and use `{feature|bug}/{summary-slug}` / `../<repo>-{summary-slug}`), created by the `catalyst-impl` subagent once the orchestrator's plan is confirmed, all implementation happening inside it. FAN OUT/VERIFY subagents read the main checkout; only implementation moves into the worktree. Review tickets (`code-review.md`) stay read-only and never create a worktree.
