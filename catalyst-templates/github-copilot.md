# Template: GitHub Copilot

## Setup

GitHub Copilot (in VS Code / Visual Studio / JetBrains, and Copilot Chat/Workspace) supports custom instructions via:

1. **Repository custom instructions**: a `.github/copilot-instructions.md` file at the repo root. Copilot Chat automatically includes this file's content as context for every chat request in that repository (supported in VS Code, Visual Studio, and github.com Copilot Chat).
2. **Path-specific instructions**: `.github/instructions/*.instructions.md` files with a front-matter `applyTo` glob, for instructions that should only apply to certain file types or directories.
3. **Copilot Workspace**: when using Workspace to plan a task from an issue, Copilot reads the issue text directly and generates a plan; custom instructions still apply from `.github/copilot-instructions.md` if present in the repo.

For this pattern, use `.github/copilot-instructions.md` since the orchestration approach should apply repo-wide, not to specific file types.

## Instruction Text to Paste

Into `.github/copilot-instructions.md`:

```markdown
# Ticket Handling Instructions

When asked to address a work item or ticket — a GitHub issue, or one mirrored from Jira/Azure DevOps/another tracker — follow this process before proposing code:

1. Analysis (fan out): Identify the independent things that need investigating — related code locations,
   existing tests, related/duplicate issues, relevant docs, recent history of the affected files. List them,
   then look at each one.

2. Consolidate: Summarize findings into a short list, removing repeats and irrelevant matches. State the
   most likely root cause or the concrete requirement in one or two sentences.

3. Verify: For each notable finding, double-check it against the real file or test content — don't just
   restate the summary. Explicitly say whether each finding held up or turned out to be a false lead.

4. Plan: Based only on findings that held up, describe the specific files and changes needed, and the tests
   to add or run. Present this as a plan before writing the actual code changes.
```

## How Copilot Handles Parallel Task Execution

GitHub Copilot Chat and Copilot Workspace process one request at a time in a single conversational thread; there is no native mechanism for issuing multiple simultaneous searches or reads in parallel the way an agentic CLI tool can. Copilot's underlying retrieval (workspace indexing, `@workspace` context) happens automatically when you reference `@workspace` in a query, but you don't control or observe it as discrete parallel "tasks."

**Workaround for FAN OUT:** Structure a single Copilot Chat message as a multi-part question, explicitly using `@workspace` to trigger its retrieval across the whole indexed repo in one pass, rather than issuing four separate chat turns:

```
@workspace For the ticket "Fix login timeout handling": (1) find where timeout durations are
configured, (2) find tests referencing timeout/session expiry, (3) find any docs describing the
intended timeout policy, (4) summarize recent changes to the relevant file(s). Answer all four
before proposing anything.
```

This leans on Copilot's own internal retrieval doing the equivalent of parallel lookups in one indexing pass, even though you can't inspect or control that internal parallelism directly.

## Worked Example

**Point Copilot Workspace at:** GitHub issue #4521, "Fix login timeout handling," with `.github/copilot-instructions.md` in place as above. (If the ticket originates in Jira or Azure DevOps, mirror it into a GitHub issue first — Copilot Workspace only reads GitHub-native issues/PRs.)

1. Copilot Workspace reads the issue and the repo instructions.
2. **FAN OUT** — in Copilot Chat, send the combined `@workspace` query above covering all four analysis angles in one message.
3. **REDUCE** — Copilot returns a combined answer; you (or a follow-up prompt) ask it to state the single leading root cause in one sentence.
4. **VERIFY** — send a second, explicit message: "Open `AuthService.cs` directly and confirm line 142 sets the timeout to 300 seconds — don't rely on your earlier summary." This forces Copilot to re-ground in the literal file content rather than its own paraphrase.
5. **SYNTHESIZE** — ask Copilot Workspace to generate its implementation plan; review the proposed file changes before accepting them (Workspace stages changes for review, it doesn't auto-commit).

## Known Limitations

- No user-controllable parallel execution — everything is effectively sequential turns, and Copilot's internal retrieval parallelism is opaque, so you can't verify it actually searched all four things distinctly (it may blend them into one pass).
- Copilot Workspace's automatic plan generation can jump straight from issue-reading to a proposed diff without an explicit intermediate verification step — you must inject the VERIFY step manually as a separate prompt, it won't happen on its own.
- Repository custom instructions apply to Copilot Chat and Workspace, but not necessarily to every Copilot surface (e.g. inline code completions ignore `.github/copilot-instructions.md` — this pattern is only relevant to chat/workspace-driven ticket work, not autocomplete).
- If the ticket lives in a non-GitHub tracker (Jira, Azure DevOps, Linear), Copilot has no native connector for it — you must be working from a GitHub issue/PR that mirrors the ticket, or paste the ticket content manually into chat. GitHub Issues themselves are natively available via `@workspace`/Copilot's repo context without any extra setup.

## Correcting the Tool

If Copilot proposes a diff immediately after reading the issue:
> "Before any code changes — list the things you'd need to check to confirm this, check them, and tell me what you verified. Then propose the plan."

If Copilot's "verification" is just repeating its earlier analysis:
> "You're restating your summary, not verifying it. Open the actual file at that path and quote the real content before confirming."

If Copilot Workspace stages changes before a plan was discussed:
> "Discard that diff for now. Give me a written plan of the files and changes first, and wait for me to approve it."
