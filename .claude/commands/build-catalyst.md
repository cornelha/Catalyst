Build a skill library and agent templates for the Catalyst orchestration pattern.

Reference: Read ORCHESTRATION-PROMPT.md in this project for the core thinking pattern (fan out, reduce, verify, synthesize).

DO NOT BUILD:
- A TypeScript/C#/Python framework or library
- Executable orchestration engines
- Workflow parsers or config systems
- NPM/NuGet packages or build tooling

DO BUILD:
- SKILL FILES: markdown documents describing recurring ticket types
- AGENT TEMPLATES: tool-specific instructions for Claude Code, Cline, GitHub Copilot, OpenCode
- EXAMPLES: real ticket walkthroughs applying each skill

Create this structure:

```
catalyst-skills/
  bug-fix.md
  feature-implementation.md
  code-review.md

catalyst-templates/
  claude-code.md
  cline.md
  github-copilot.md
  opencode.md

examples/
  bug-fix-example.md
  feature-impl-example.md
  code-review-example.md
```

Each skill file must include:
- Problem Pattern (when to use this skill)
- Analysis Tasks (what to investigate in parallel — FAN OUT)
- Deduplication (how to consolidate findings — REDUCE)
- Verification Questions (skeptic check with fresh context — VERIFY)
- Implementation Checklist (what to build — SYNTHESIZE)
- One worked example

Each template file must include:
- Exact instructions/prompt syntax for that specific tool
- How that tool handles (or doesn't handle) parallelism
- A worked example of pointing that tool at a ticket (GitHub issue, Jira ticket, Azure DevOps work item, etc.)
- Known limitations for that tool

Standalone principle: a developer should open one skill file, one template file, point their agent at a ticket, and watch it work — no cross-referencing required.

$ARGUMENTS
