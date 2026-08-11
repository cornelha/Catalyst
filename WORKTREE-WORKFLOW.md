# Worktree Workflow

An optional working-mode layer on top of `.catalyst/orchestration.md`: instead of editing files in your main checkout, do each ticket's implementation in a dedicated **git worktree** — a separate working directory linked to the same repo, on its own branch. This keeps `main` clean, lets several tickets be implemented in parallel without conflicting working trees, and gives every PR a branch that is trivially linkable back to its ticket.

This file is deliberately **tracker-agnostic** — it never assumes GitHub, Jira, Azure DevOps, or any other tracker. The only inputs it needs are the ticket ID and the ticket title, both of which any tracker provides. The signal for when cleanup happens comes from your tracker's own merge notification, not from a tool-specific API call.

## When to use it

Use a worktree when:
- You're implementing a bug-fix or feature ticket (see the `bug-fix.md` and `feature-implementation.md` skills) and want the main checkout to stay untouched while you work.
- Multiple tickets are being worked at once — one worktree per ticket means zero cross-ticket working-tree conflicts.
- You want the ticket's branch to be easily discoverable later, by name, without storing any state.

Do **not** use a worktree when the ticket is `code-review.md` work. Reviewing is read-only: read the target branch's code wherever it lives, produce the review, done. No worktree is needed.

## Branch naming strategy

Every implementation worktree gets a branch named:

```
{feature|bug}/{ticketid}_{summary-slug}
```

- **`{feature|bug}`** — derived from the skill the pattern selected during FAN OUT, never guessed: the `feature-implementation.md` skill yields `feature/`, the `bug-fix.md` skill yields `bug/`.
- **`{ticketid}`** — the tracker's ticket ID, verbatim (e.g. `4521`). Strip any `#` prefix or URL wrapper, but otherwise don't alter it.
- **`{summary-slug}`** — a deterministic slug of the ticket title:
  1. lowercase the title
  2. replace every non-alphanumeric run (spaces, punctuation, etc.) with a single `-`
  3. truncate to **40 characters**, splitting on word boundaries (never mid-word) and trimming any trailing `-`

**Why deterministic:** the same ticket must produce the same branch every run, because the branch name is the linkage between the worktree, the ticket, and the PR. It lets a later cleanup step find the branch (and the PR for it) purely from the ticket ID, and lets `git branch -d` in cleanup need no lookup at all.

**Examples:**

| Skill | Ticket | Title | Branch |
|---|---|---|---|
| bug-fix | #4521 | Login times out after 5 minutes | `bug/4521_login-times-out-after-5-minutes` |
| feature-implementation | #6034 | Allow users to schedule recurring report emails | `feature/6034_allow-users-to-schedule-recurring-report` |
| bug-fix | #5190 | Export button silently fails for large date ranges | `bug/5190_export-button-silently-fails-for-large` |

## Worktree path convention

The **branch** contains a `/`, so it cannot be used directly as a flat directory name. Keep the worktree's on-disk path flat and separate:

```
../<repo>-<ticketid>
```

A sibling directory of the main checkout (e.g. `../catalyst-4521` when the repo is `catalyst`). A sibling keeps the main repo free of untracked directories — nothing inside the repo needs a `.gitignore` entry, and agent search/indexing tools never walk it. The worktree path is a local filesystem concern and never leaves your machine; only the branch name is shared (via push).

## Lifecycle

### 1. CREATE — at SYNTHESIZE, after the plan is confirmed, before any edit

FAN OUT, REDUCE, and VERIFY all stay read-only in the main checkout — they read code and produce findings, they don't modify anything. Only when the SYNTHESIZE plan has been presented **and confirmed** do you create the worktree and do the implementation there:

```bash
git worktree add ../<repo>-<ticketid> -b <branch>
```

Create the worktree from the default branch (`main`, `master`, or whatever the repo's default is — use `git symbolic-ref refs/remotes/origin/HEAD` if you need to discover it), never from a dirty or half-finished branch. If the worktree already exists, reuse it rather than creating a second one.

### 2. WORK — in the worktree

Everything from here on happens **inside the worktree directory**, not the main checkout:

- write and run tests against the worktree's branch
- make the implementation edits
- commit on the worktree's branch (conventional commits referencing the ticket ID are welcome but not required)
- push the branch and open the PR from it

Your tracker's notification for that PR (and its eventual merge) is the natural signal — the tracker stays a black box to this kit, exactly as the orchestration pattern intends.

### 3. REMOVE — after the PR is merged, triggered by you

Cleanup is **user-triggered, not agent-observed**. You know when the PR merged — you got the review/merge notification in whatever tracker you use. When you're confident the PR has landed:

```bash
git worktree remove ../<repo>-<ticketid>
git branch -d <branch>
```

`git worktree remove` **refuses to run** while the worktree has uncommitted changes or untracked files (same protection as switching branches), so the rule is: commit or discard, then remove. If a worktree registration goes stale for any reason, `git worktree prune` clears orphaned registrations.

**Why no status check:** removing a worktree whose branch is *not* merged deletes only the working directory — the branch and its commits still exist in the repo's refs, so nothing is lost. Verifying "is the PR actually merged" is therefore optional hygiene, not data protection, and checking it would require a tracker-specific API call — which this kit deliberately avoids. If your setup can query PR status (e.g. via your tracker's CLI), you may wire a cleanup command that refuses to remove until the PR is merged; the default is no check, because your own merge notification is the trigger.

**Never remove the main checkout.** Worktrees are purely additive on top of it; `main` stays untouched for the entire lifecycle.

## Parallel tickets

One worktree per ticket, created as each reaches its confirmed plan:

```
catalyst/                        <- main checkout, stays clean
catalyst-4521/                   <- bug/4521_login-times-out-after-5-minutes
catalyst-6034/                   <- feature/6034_allow-users-to-schedule-recurring-report
```

Each can be worked, tested, committed, and pushed independently with no working-tree conflicts — the physical counterpart of the logical isolation `SUBAGENT-ARCHITECTURE.md` gives you per phase. This pairs naturally with the subagent split: one ticket = one worktree = one orchestrator run.

## Safety rules

1. **Create at SYNTHESIZE, never earlier.** Fan-out/verify read the main checkout; only confirmed plans get a worktree.
2. **Base off the default branch.** Never branch off a dirty or in-progress branch.
3. **Branch name is deterministic and derived from the skill, never guessed.** `feature/` or `bug/` comes from the selected skill; the slug comes from the title by the fixed rule.
4. **All implementation happens in the worktree, never in `main`.**
5. **Remove only after you (the user) know the PR is merged.** The kit never watches your tracker; your merge notification is the trigger.
6. **Clean worktrees only.** `git worktree remove` needs a clean checkout — commit or discard first, and `git worktree prune` if a registration goes stale.
7. **Never remove the main checkout.**

## Worked example

**Ticket:** bug #4521, "Login times out after 5 minutes," worked with `.catalyst/skills/bug-fix.md`.

1. **FAN OUT → REDUCE → VERIFY** run read-only in the main checkout. The `bug-fix` skill is selected, so the branch prefix is `bug/`. Title slugified deterministically: `login-times-out-after-5-minutes` (well under 40 chars).
2. **SYNTHESIZE** presents the plan; the user confirms.
3. **CREATE:**
   ```bash
   git worktree add ../catalyst-4521 -b bug/4521_login-times-out-after-5-minutes
   ```
4. **WORK** inside `../catalyst-4521`: add the failing test, fix `AuthService.cs:142` and the `RefreshMiddleware.cs` race, run the auth test suite, commit, push, open the PR.
5. The PR goes through review in the tracker. The user gets the merge notification.
6. **REMOVE** (user-triggered, after merge):
   ```bash
   git worktree remove ../catalyst-4521
   git branch -d bug/4521_login-times-out-after-5-minutes
   ```
7. Main checkout was never touched; the only trace left is the merged PR and its (now deleted) branch.

## Where this fits in the library

- `.catalyst/orchestration.md` — the core pattern; this file is the working-mode layer for its SYNTHESIZE/implementation phase.
- `SUBAGENT-ARCHITECTURE.md` — logical isolation per phase; this file is physical isolation per ticket, and the two compose.
- `.catalyst/skills/bug-fix.md`, `.catalyst/skills/feature-implementation.md` — the skills whose Implementation Checklists reference this workflow.
- `.catalyst/skills/code-review.md` — explicitly out of scope: reviews are read-only, no worktree.
