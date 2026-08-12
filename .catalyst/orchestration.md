# Graph-Based Orchestration (Reference)

The full Catalyst orchestration pattern, kept on disk for on-demand reading. The lean installable block is
in `install.md`; commands reference this file only when they need depth (node types, safety rules,
anti-patterns, worked example). This file is tracker-agnostic — GitHub Issues, Jira, Azure DevOps, Linear,
or any other tracker — and tool-agnostic — the same pattern applies in Claude Code, Cursor, Cline, Codex
CLI, GitHub Copilot, OpenCode, and Pi.

## How `install.md` is consumed

`install.md` holds only the canonical instruction block, delimited by `<!-- catalyst:start -->` /
`<!-- catalyst:end -->` markers — it carries no explanatory header. Every `/catalyst-install` command, the
build scripts' zip packaging, and manual installs (`cp install.md AGENTS.md`, or an `instructions` entry
in `opencode.json`) all use exactly that block. Keep the block self-contained and lean — it is read on
every message of every session, so nothing should ever be added outside the markers or bloat the block.

**Optional working-mode layers:** `WORKTREE-WORKFLOW.md` describes doing each ticket's implementation in a
dedicated git worktree (one worktree per ticket, branch named `{feature|bug}/{ticketid}_{summary-slug}`) so
`main` stays clean and parallel tickets don't conflict. `SUBAGENT-ARCHITECTURE.md` splits the phases into
named subagents (`catalyst-orchestrator`, `catalyst-fan-out-analyst`, `catalyst-verifier`,
`catalyst-synthesizer`, `catalyst-code-reviewer`) for isolated contexts and per-phase model sizing. Both
are tracker-agnostic, like this pattern.

---

## The Pattern: FAN OUT → REDUCE → VERIFY → SYNTHESIZE

When given a ticket, decompose it into three questions before touching any file:
- **What needs to be analyzed?** (data gathering phase)
- **What needs to be verified?** (validation phase)
- **What needs to be built/changed?** (implementation phase)

### PHASE 1: FAN OUT (Parallel Analysis)

Break analysis into **independent, parallelizable tasks**. Each task should be:
- **Scoped to one concern** (not "analyze everything")
- **Runnable independently** (no dependencies on other analysis tasks)
- **Cheap to execute** (use fast queries, grep patterns, simple reads)

**How to execute:**
- Query the tracker's API in parallel (issue search, related items, linked PRs)
- Run grep/search patterns on the codebase in parallel
- Extract relevant code sections
- Read documentation in parallel

**Example decomposition for "Fix authentication bug":**
```
ANALYZE:
  ├─ Find all authentication-related code (grep, search patterns)
  ├─ Find all failing tests related to auth
  ├─ Find all known auth issues in backlog
  ├─ Understand current auth flow (read docs, code structure)
  └─ Check the tracker for related tickets
```

**Output structure for each parallel task:**
```json
{
  "task": "Find failing auth tests",
  "results": [
    { "file": "AuthTests.cs", "line": 42, "test": "TestLoginFails", "status": "FAIL" }
  ],
  "source_urls": ["https://github.com/org/repo/issues/142"]
}
```

### PHASE 2: REDUCE (Consolidate)

Consolidate parallel results:
- **Remove duplicates** (same finding reported multiple ways)
- **Remove noise** (unrelated results, low signal)
- **Organize by severity/priority**

```
Input: 47 results from parallel searches
  - "auth bug" mentioned in 12 places (same root cause)
  - 3 similar test failures (same issue)
  - 2 unrelated security findings

Output after dedup:
  - 1 root auth bug with 12 references
  - 1 test failure pattern
  - 2 security findings (kept, different scope)
```

### PHASE 3: VERIFY (Skeptic Check)

For each significant finding, **ask a fresh question with fresh reasoning**:

**Question: "Is this finding real, or false positive?"**
- If it's a code finding: Does it actually exist? Is it actually broken?
- If it's a pattern: Do multiple instances confirm it, or is it coincidence?
- If it's a recommendation: Will this actually fix the problem?

**How to verify:**
- Read the actual code (not summaries)
- Check if the test actually fails (not just marked as such)
- Trace through the logic path
- Look for edge cases that contradict the finding

**Output structure:**
```json
{
  "finding": "Authentication fails when token expires",
  "verdict": "VALID",
  "evidence": [
    "Line 142: Token expiry not checked before use",
    "Test TokenRefreshFails confirms behavior",
    "Issue #4521 in backlog matches this"
  ],
  "confidence": 0.95
}
```

**Invalid findings get DROPPED** (marked as false positives).

### PHASE 4: SYNTHESIZE (Build Implementation Plan)

From verified findings, create **actionable implementation steps**:

```
# Implementation Plan: [Ticket Title]

## Problem (Verified Findings)
- [Finding 1 with evidence]
- [Finding 2 with evidence]

## Solution Approach
- Step 1: [Specific file/location, what to change]
- Step 2: [Dependency on step 1]
- Step 3: [Dependency on steps 1-2]

## Code Changes
### File: AuthService.cs
- Line 142: Add token expiry check
- Line 150: Add refresh logic
- Add test coverage

### File: AuthTests.cs
- Add test for expired token
- Add test for refresh retry

## Verification Steps
1. Run auth tests locally
2. Check all callers of auth methods
3. Verify backward compatibility

## Estimates
- Dev: 2 hours
- Testing: 1 hour
- Review: 30 min
```

**If working in a git worktree (see `WORKTREE-WORKFLOW.md`):** once this plan is confirmed, create a
worktree for this ticket — branch `{feature|bug}/{ticketid}_{summary-slug}` (prefix from the selected
skill), path `../<repo>-<ticketid>` — and do all implementation, tests, and PR work inside it, leaving the
main checkout untouched.

---

## Node Types (How to Reason About Work)

When you see work to do, ask: **What kind of node is this?**

### Agent Node
**"Do this task, return findings"**
- Analyze codebase structure
- Search for patterns
- Query the issue tracker
- Read documentation
- Extract data

**Cost:** Low (information gathering, no changes)

### Verifier Node
**"Take this finding, assume it's false, try to disprove it. Keep only if it survives."**
- Read actual code (not grep results)
- Run tests to confirm behavior
- Trace logic paths
- Check edge cases

**Cost:** Medium (deeper investigation)

### Implementation Node
**"Based on verified findings, write code to fix this."**
- Write code changes
- Write tests
- Update documentation
- Create PR

**Cost:** High (requires correctness, will be reviewed)

---

## Safety Rules

1. **Never implement based on unverified findings**
   - Analysis → Verify → Only then implement
   - If using worktrees, this maps to: fan-out and verify run read-only in the main checkout; create the
     implementation worktree only after the plan is confirmed (see `WORKTREE-WORKFLOW.md`).

2. **Parallel tasks must be independent**
   - If Task B needs output of Task A, make B depend on A (run sequentially)
   - Don't run tasks in parallel if they interfere

3. **Verification must use fresh context**
   - Verifier doesn't inherit analyzer's assumptions
   - Reads source code directly, not analyst summary

4. **Stop before implementing if uncertain**
   - Better to ask for clarification than guess
   - Unverified findings → comment on ticket, ask for guidance

---

## Anti-Patterns (Don't Do This)

1. **Analysis without deduplication**
   - Running searches without consolidating results
   - Leads to confusion about what's actually happening

2. **Implementation without verification**
   - Building fix based on first analysis
   - Will miss false positives, create bugs

3. **Sequential when parallel is possible**
   - "First search for code, THEN search tests, THEN read docs"
   - Takes 3x longer than parallel approach

4. **Trusting grep/search output without reading code**
   - Pattern matches ≠ actual bugs
   - Always verify by reading actual source

5. **Forgetting fresh context in verification**
   - Verifier reusing analyzer's reasoning
   - Defeats purpose of independent validation

---

## Worked Example

**Ticket:** "Fix login timeout handling"

**PHASE 1 - FAN OUT (parallel):**
```
Task 1: Find all timeout-related code
  → Found: AuthService.cs:142, LoginController.cs:89, etc.

Task 2: Find timeout-related tests
  → Found: 3 tests, 2 failing

Task 3: Check the tracker for related issues
  → Found: 2 duplicate issues, 1 related PR (open)

Task 4: Read timeout handling documentation
  → Found: Spec says timeout should be 30min, actual is 5min

Task 5: Check git history for timeout changes
  → Found: Last change 6 months ago, no related issues at that time
```

**PHASE 2 - REDUCE:**
```
Consolidated findings:
- Root cause: Timeout hardcoded to 5min (spec says 30min)
- Evidence: Code, docs, test failures all point here
- Related: PR #4521 attempted fix but was reverted
```

**PHASE 3 - VERIFY:**
```
Skeptic check:
- "Is timeout really hardcoded to 5min?" → YES, line 142: TimeoutSeconds = 300
- "Is spec really 30min?" → YES, TimeoutPolicy.md line 8: "Default: 1800 seconds"
- "Why does PR #4521 exist?" → It fixed this, was reverted due to side effects
- "Do the 2 failing tests confirm this?" → YES, both timeout at 5min mark, expect 30min

Verdict: VALID - root cause confirmed
```

**PHASE 4 - SYNTHESIZE:**
```
Plan:
1. Change AuthService.cs:142 from 300 to 1800
2. Review PR #4521 to understand revert reason
3. Add test case for timeout at 30min
4. Check all callers—any assuming 5min?
5. Update docs if examples mention timing
6. Run full test suite
```

---

## Key Differences from Naive Approach

### ❌ Naive (No Graph)
```
Agent reads ticket: "Fix login timeout"
Agent guesses: "Maybe search for 'timeout'? Maybe check tests? Maybe look at config?"
Result: Finds 47 results, overwhelmed, misses root cause
```

### ✅ Graph-Based (This Approach)
```
Agent reads ticket: "Fix login timeout"
Agent decomposes: "I need to find: (1) where timeout is used, (2) what the spec says,
  (3) what tests fail, (4) why previous attempts failed"
Runs all 4 in parallel → 12 high-signal results → Verifies → Implements
Result: Finds root cause, understands context, safe implementation
```

---

## Expanding This

### Add Skills/Templates
For recurring ticket types (bugs, features, refactoring), create templates in `skills/`:

**Bug Template:**
```
ANALYZE:
  - Search for error messages
  - Find related test failures
  - Check the tracker's history
  - Read error logs
VERIFY:
  - Is the bug reproducible?
  - Does it happen on all platforms?
  - Is this actually a bug or user error?
IMPLEMENT:
  - Add test that reproduces bug
  - Fix code
  - Verify fix doesn't break others
```

**Feature Template:**
```
ANALYZE:
  - Read acceptance criteria
  - Find similar features in codebase
  - Check for design docs
  - Query API/schema design
VERIFY:
  - Does design match acceptance criteria?
  - Are there edge cases?
  - Will this impact existing features?
IMPLEMENT:
  - Add tests for criteria
  - Implement feature
  - Update docs
```

### Bind to Code Graph
When you have a code-graph MCP server or graph tooling:

```
ANALYZE phase can query:
  - Find all calls to AuthService.Validate()
  - Find all implementations of IAuthProvider
  - Find error handling for TokenExpiredException
  - Find tests that cover login flow

This gives agent structured code knowledge instead of just grep results
```

---

## Summary

**This is not a framework to build.** It's a thinking pattern your agent should follow:

1. **Decompose work into independent tasks** (FAN OUT)
2. **Consolidate results** (REDUCE)
3. **Verify each finding** (VERIFY)
4. **Only then implement** (SYNTHESIZE)

Point your agent at any ticket — a GitHub issue, a Jira ticket, an Azure DevOps work item — and it will
automatically apply this pattern instead of naively reading the whole ticket and guessing.
