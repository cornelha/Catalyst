---
description: Research-only architecture explanation using diamond pattern (fan-out > reduce > verify > synthesize) - no edits, mermaid/tables output
---

Explain the following question/task using the Catalyst diamond pattern. Pure research - DO NOT edit any files unless user explicitly asks to write result to markdown.

Question: $ARGUMENTS

If $ARGUMENTS is empty, ask the user what they want explained.

Execute in order, showing your work at each phase:

PHASE 1 — FAN OUT (parallel research)
State the independent research tasks you'll run. List them before running them. Then actually run them — issued together in as few turns as possible, not interleaved with analysis. Cap at 5-8 tasks for the first run on an unfamiliar topic.

Suggested task types (pick relevant ones for the question):
- Codebase structure / module boundaries (get_architecture, folder/file layout)
- Service/component internals (search_graph for classes, handlers, routes)
- Data flow / call graph (trace_path inbound/outbound, cross_service if relevant)
- Dependencies & integrations (imports, HTTP/async calls, DB models)
- Config & wiring (entry points, DI, env, feature flags)
- History & evolution (git log for the area)

Rules:
- Use graph tools first (search_graph, trace_path, get_code_snippet, query_graph, get_architecture). Fall back to grep/glob for string literals, configs, or when graph coverage is insufficient.
- If an agent encounters a binary, generated file, or unknown reference it cannot resolve directly, it MUST research effectively: identify file type, find its source/generator, trace callers/callers via graph + grep, check git history and docs. Never hand-wave as "unknown/binary — skipping".
- Every finding must cite evidence as `file:line` or `command output`. No uncited claims.

PHASE 2 — REDUCE
First count results returned vs fan-out tasks launched — if any task returned nothing, flag the gap out loud before consolidating; never reduce on a silent partial set. Then consolidate: deduplicate, drop noise, and state the core answer in 2-3 sentences. Group findings by theme (e.g., "How it works", "Where it fits", "Extension points"). Do not invent details to fill gaps — mark gaps explicitly as UNKNOWN with why.

PHASE 3 — VERIFY
For each significant finding, ask a skeptical question and check it against actual code/tests — don't re-assert your own analysis. Open the real file, run the real check. State verdict per finding: VALID (with file:line / test / output) | FALSE POSITIVE (what was actually found) | PARTIAL (what holds, what doesn't). If verification fails, drop the finding from synthesis.

PHASE 4 — SYNTHESIZE (present to user)
Using ONLY verified findings, produce the final explanation. Structure it for the question type:

For "How does X work?" questions:
- Overview (1 paragraph + mermaid diagram if structure/behavior benefits from it)
- Components table: | Component | Location | Responsibility |
- Flow diagram (mermaid sequence or flowchart) showing key call/data path
- Key files table: | File | Role |

For "Where can I implement X?" questions:
- Current architecture fit (where X belongs + why, with evidence)
- Options table: | Option | Location | Pros | Cons | Effort |
- Recommended approach with concrete file:line anchors
- Risks / open questions

General rules for synthesis:
- Use tables and mermaid diagrams where they guide the user better than prose. Prefer mermaid `graph TD` for structure, `sequenceDiagram` for flows, `flowchart` for decisions.
- Every non-trivial claim keeps its `file:line` citation.
- Explicitly list UNKNOWNs / gaps (binary refs that couldn't be fully resolved, missing coverage) — do not hide them.
- End with "Sources" list (all cited files) and offer: "Want this written to markdown? Tell me the path."

Constraints:
- NO edits, NO file writes, NO commits during this command. Research only.
- If user afterwards says "write to <path>", then write the synthesized output verbatim to that markdown file — no extra edits.
- Truth over completeness: if evidence is thin, say so rather than guessing.
