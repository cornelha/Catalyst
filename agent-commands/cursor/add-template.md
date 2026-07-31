Add a new agent template to catalyst-templates/.

Reference: Read ORCHESTRATION-PROMPT.md for the pattern.
Reference: Read one existing file in catalyst-templates/ to match structure and tone.

Agent/tool name: treat whatever text was typed after `/add-template` when this command was invoked as the agent/tool name.

DO NOT BUILD framework code. Build ONE markdown file only: catalyst-templates/[agent-name].md

The file must include:
1. Exact setup steps for that specific tool (where instructions go — system prompt, config file, workspace settings, etc.)
2. The literal prompt/instruction text to paste or configure, written in that tool's expected format
3. How that tool handles parallel task execution — if it can't natively parallelize, explain the workaround
4. A worked example: pointing the tool at a ticket (GitHub issue, Jira ticket, Azure DevOps work item, etc.) and walking through what it does at each phase (fan out, reduce, verify, synthesize)
5. Known limitations specific to that tool
6. Tips for correcting the tool if it skips a phase (e.g. jumps straight to implementation without verifying)

Research the actual tool's configuration mechanism if you're not certain how it accepts custom instructions — don't guess at syntax.

After creating the file, do not modify any other files.
