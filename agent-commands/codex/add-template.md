Add a new agent template to catalyst-templates/.

Reference: Read .catalyst/orchestration.md for the pattern.
Reference: Read one existing file in catalyst-templates/ to match structure and tone.

Agent/tool name: $ARGUMENTS
(NOTE: OpenAI has deprecated Codex CLI custom prompts in favor of "Skills" — see the caveat in agent-commands/README.md. This file works today if your Codex CLI version still supports `~/.codex/prompts/`, but check current Codex docs before relying on it long-term.)

DO NOT BUILD framework code. Build ONE markdown file only: catalyst-templates/[agent-name].md

The file must include:
1. Exact setup steps for that specific tool (where instructions go — system prompt, config file, workspace settings, etc.)
2. An "Installing the Pattern" section: where that tool's always-loaded instruction file lives (CLAUDE.md, AGENTS.md, .clinerules, .github/copilot-instructions.md, .cursor/rules/*.mdc, etc.), and how to install the canonical block — run the tool's /catalyst-install command, or append .catalyst/install.md. The instruction text itself is NOT repeated here; it lives once in .catalyst/install.md
3. How that tool handles parallel task execution — if it can't natively parallelize, explain the workaround
4. A worked example: pointing the tool at a ticket (GitHub issue, Jira ticket, Azure DevOps work item, etc.) and walking through what it does at each phase (fan out, reduce, verify, synthesize)
5. A Git Worktrees section: how the worktree workflow (WORKTREE-WORKFLOW.md) applies to this tool — where the tool's config/commands live so they travel with the branch
6. Known limitations specific to that tool
7. Tips for correcting the tool if it skips a phase (e.g. jumps straight to implementation without verifying)

Research the actual tool's configuration mechanism if you're not certain how it accepts custom instructions — don't guess at syntax.

After creating the file, do not modify any other files.
