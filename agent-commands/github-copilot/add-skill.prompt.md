---
agent: 'agent'
description: Add a new skill to the .catalyst/skills/ library
---
Add a new skill to the .catalyst/skills/ library: ${input:skillName:Skill name, e.g. performance-regression}

Reference: Read .catalyst/orchestration.md for the pattern (fan out, reduce, verify, synthesize).
Reference: Read one existing file in .catalyst/skills/ (any of them) to match the exact structure and tone.

DO NOT BUILD framework code. Build ONE markdown file only: .catalyst/skills/${input:skillName}.md

The file must include, in this order:
1. Problem Pattern — when a ticket matches this skill
2. Analysis Tasks — independent, parallelizable investigation tasks (FAN OUT)
3. Deduplication — how to consolidate/filter findings (REDUCE)
4. Verification Questions — skeptic checks with fresh context, assume false until proven (VERIFY)
5. Implementation Checklist — concrete build steps (SYNTHESIZE)
6. One worked example with a realistic ticket

Match the formatting, heading style, and level of specificity of the existing skill files exactly. This should feel like it belongs in the same library, not like a different author wrote it.

After creating the file, do not modify any other files.

If this repo ships native skills generated from .catalyst/skills/ (currently GitHub Copilot), note that the new playbook will need its Copilot-facing description added to the description map in scripts/generate-copilot-skills.ps1/.sh and the generator re-run before it appears as a native skill — say so in your summary, don't edit the generator yourself.
