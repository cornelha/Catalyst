Build a skill library and agent templates for the Catalyst orchestration pattern.

Reference: Read .catalyst/orchestration.md in this project for the core thinking pattern (fan out, reduce, verify, synthesize).
Reference: Read .catalyst/install.md for the canonical installable instruction block.

DO NOT BUILD:
- A TypeScript/C#/Python framework or library
- Executable orchestration engines
- Workflow parsers or config systems
- NPM/NuGet packages or build tooling

DO BUILD:
- CANONICAL SOURCE: the installable block and the full pattern reference, plus per-ticket-type playbooks
- AGENT TEMPLATES: tool-specific instructions for Claude Code, Cursor, Cline, Codex CLI, GitHub Copilot, OpenCode, Pi
- COMMANDS: per-tool slash-command counterparts of /catalyst, /catalyst-install, /add-skill, /add-template, /learn
- SUBAGENTS: per-tool definitions of catalyst-orchestrator, catalyst-fan-out-analyst, catalyst-verifier, catalyst-synthesizer
- EXAMPLES: real ticket walkthroughs applying each skill
- SCRIPTS: build-zips.* (packaging) and generate-copilot-skills.* (regenerating native skills from canonical playbooks)

Create this structure:

```
.catalyst/
  install.md              # the single canonical instruction block (start/end markers)
  orchestration.md        # the full pattern reference (node types, safety rules, anti-patterns)
  skills/
    bug-fix.md
    feature-implementation.md
    code-review.md

catalyst-templates/
  claude-code.md
  cursor.md
  cline.md
  codex.md
  github-copilot.md
  opencode.md
  pi.md

agent-commands/<tool>/    # catalyst.md, catalyst-install.md, add-skill.md, add-template.md, learn.md
agent-subagents/<tool>/
agent-skills/github-copilot/<name>/SKILL.md   # generated from .catalyst/skills/ by scripts/generate-copilot-skills.*

examples/
  bug-fix-example.md
  feature-impl-example.md
  code-review-example.md

scripts/
  build-zips.ps1
  build-zips.sh
  generate-copilot-skills.ps1
  generate-copilot-skills.sh
```

Each skill file must include:
- Problem Pattern (when to use this skill)
- Analysis Tasks (what to investigate in parallel — FAN OUT)
- Deduplication (how to consolidate findings — REDUCE)
- Verification Questions (skeptic check with fresh context — VERIFY)
- Implementation Checklist (what to build — SYNTHESIZE)
- One worked example

Each template file must include:
- Setup: exact config file locations for that specific tool
- Installing the Pattern: how the canonical block from .catalyst/install.md is installed for that tool (its /catalyst-install command, or manual append) — the instruction text is NOT duplicated in the template
- How that tool handles (or doesn't handle) parallelism
- A worked example of pointing that tool at a ticket (GitHub issue, Jira ticket, Azure DevOps work item, etc.)
- Git Worktrees: how the worktree workflow applies to this tool
- Known limitations for that tool
- Correcting the Tool: phrasing to fix it if it skips a phase

Standalone principle: a developer should open one skill file, one template file, point their agent at a ticket, and watch it work — no cross-referencing required.

$ARGUMENTS
