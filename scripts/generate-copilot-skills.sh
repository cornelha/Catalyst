#!/usr/bin/env bash
# Regenerates the GitHub Copilot agent skills under agent-skills/github-copilot/<name>/SKILL.md
# from the canonical playbooks in .catalyst/skills/<name>.md.
#
# Why this exists: Catalyst is a meta-toolkit. The canonical, user-evolvable source of each
# ticket-type playbook is .catalyst/skills/<name>.md (edited via /add-skill and /learn, or by
# hand). Copilot requires skills to be self-contained -- SKILL.md must carry its own instructions,
# not point at a sibling folder. So the Copilot SKILL.md is a GENERATED artifact: frontmatter +
# the full canonical playbook body, with cross-skill and worktree references made self-contained.
#
# After you evolve .catalyst/skills/<name>.md, re-run this script to refresh the Copilot skills.
# Build-zips (build-zips.ps1/.sh) also runs it before packaging.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

title_of() {
  # "bug-fix" -> "Bug Fix", "feature-implementation" -> "Feature Implementation"
  local name="$1" word out=""
  for word in ${name//-/ }; do
    out+=" $(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')${word:1}"
  done
  echo "${out:1}"
}

declare -A DESCRIPTIONS
DESCRIPTIONS[bug-fix]="Use when a ticket reports something that used to work (or should per spec) but currently doesn't — a crash, wrong output, regression, error message, or failing test. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to find and fix the verified root cause."
DESCRIPTIONS[code-review]="Use when a ticket asks to review a PR, diff, or set of changes rather than write new code — evaluating correctness, quality, security, or fit before merge. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to produce a verified review verdict."
DESCRIPTIONS[feature-implementation]="Use when a ticket asks for new capability that does not currently exist — a new endpoint, UI element, configuration option, integration, or workflow. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to plan and build it against verified requirements and existing patterns."

regenerate() {
  local name="$1"
  local src="$ROOT/.catalyst/skills/$name.md"
  local out="$ROOT/agent-skills/github-copilot/$name/SKILL.md"
  local title description body

  title="$(title_of "$name")"
  description="${DESCRIPTIONS[$name]}"

  # Drop the leading "# Skill: <Name>" heading; the generated SKILL.md gets its own.
  # Make cross-skill references self-contained: "`bug-fix.md`" -> "`bug-fix`" (skill names,
  # not repo-root file paths). Strip WORKTREE-WORKFLOW.md file references so the skill has
  # no dependency on files outside its own folder.
  body=$(sed '/^#[[:space:]]*Skill:/d' "$src")
  body=$(printf '%s' "$body" | sed -E 's/(bug-fix|code-review|feature-implementation)\.md/\1/g')
  body=$(printf '%s' "$body" | sed -E 's/\(See[[:space:]]+`WORKTREE-WORKFLOW\.md`\.\)[[:space:]]*//g; s/\(see[[:space:]]+`WORKTREE-WORKFLOW\.md`\)[[:space:]]*//g')
  body=$(printf '%s' "$body" | tr -s ' ')
  body="${body#"${body%%[![:space:]]*}"}"  # trim leading whitespace
  body="${body%"${body##*[![:space:]]}"}"  # trim trailing whitespace

  {
    printf -- '---\nname: %s\ndescription: %s\nmetadata:\n  source: .catalyst/skills/%s.md\n---\n\n' \
      "$name" "$description" "$name"
    printf '# %s\n\n' "$title"
    printf '%s\n' "$body"
  } > "$out"
  echo "Regenerated agent-skills/github-copilot/$name/SKILL.md"
}

regenerate "bug-fix"
regenerate "code-review"
regenerate "feature-implementation"
