#!/usr/bin/env bash
# Packages each supported tool's Catalyst files into a deployable zip under dist/.
# Each zip is an overlay: unzip it into the root of the project you want Catalyst
# applied to. It only adds new files/directories — nothing it contains overwrites
# a file that commonly already exists in a real project (CLAUDE.md, AGENTS.md,
# .github/copilot-instructions.md). Those go under _manual/ instead, with the
# exact append step spelled out in the bundle's own DEPLOY.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
STAGE="$ROOT/.build-stage"

rm -rf "$STAGE" "$DIST"
mkdir -p "$DIST"

stage_common() {
  # catalyst-skills/ and SUBAGENT-ARCHITECTURE.md are referenced by every
  # tool's agents/commands, so every bundle ships them.
  local dir="$1"
  mkdir -p "$dir/catalyst-skills"
  cp "$ROOT"/catalyst-skills/*.md "$dir/catalyst-skills/"
  cp "$ROOT/SUBAGENT-ARCHITECTURE.md" "$dir/"
}

deploy_note() {
  local dir="$1" body="$2"
  cat > "$dir/DEPLOY.md" <<EOF
# Deploying this bundle

Unzip this archive into the root of the project you want Catalyst applied to.
Everything here is additive — nothing in this zip overwrites a file that
already exists in your project.

$body
EOF
}

# Prefers `zip` (standard on Linux/macOS); falls back to `python3 -m zipfile`,
# then to PowerShell's Compress-Archive (always present on Windows, including
# Git Bash, where `zip` commonly isn't installed).
zip_it() {
  local name="$1" dir="$2"
  local out="$DIST/catalyst-$name.zip"
  if command -v zip >/dev/null 2>&1; then
    ( cd "$dir" && zip -rq "$out" . )
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m zipfile -c "$out" "$dir"/* "$dir"/.[!.]* 2>/dev/null || python3 -m zipfile -c "$out" "$dir"/*
  elif command -v powershell.exe >/dev/null 2>&1; then
    local win_dir win_out
    win_dir="$(cd "$dir" && pwd -W 2>/dev/null || echo "$dir")"
    win_out="$(cd "$DIST" && pwd -W 2>/dev/null || echo "$DIST")/catalyst-$name.zip"
    powershell.exe -NoProfile -Command "Compress-Archive -Path '$win_dir\\*' -DestinationPath '$win_out' -Force"
  else
    echo "error: need 'zip', 'python3', or 'powershell.exe' on PATH to build archives" >&2
    exit 1
  fi
  echo "Built dist/catalyst-$name.zip"
}

# --- claude-code ---
d="$STAGE/claude-code"
mkdir -p "$d/.claude/commands" "$d/.claude/agents" "$d/_manual"
cp "$ROOT"/.claude/commands/{catalyst,add-skill,add-template}.md "$d/.claude/commands/"
cp "$ROOT"/agent-subagents/claude-code/*.md "$d/.claude/agents/"
cp "$ROOT/catalyst-templates/claude-code.md" "$d/_manual/CLAUDE.md.append.md"
stage_common "$d"
deploy_note "$d" "- **Optional, recommended:** append \`_manual/CLAUDE.md.append.md\` to your project's \`CLAUDE.md\` (or \`~/.claude/CLAUDE.md\` for every repo) so the pattern applies automatically, not just via \`/catalyst\`.
- \`/catalyst\`, \`/add-skill\`, \`/add-template\` work immediately, no restart needed.
- Restart Claude Code after unzipping so it picks up \`.claude/agents/*\`."
zip_it "claude-code" "$d"

# --- cursor ---
d="$STAGE/cursor"
mkdir -p "$d/.cursor/rules" "$d/.cursor/commands" "$d/.cursor/agents"
cp "$ROOT/catalyst-templates/cursor.md" "$d/.cursor/rules/catalyst-orchestration.mdc"
cp "$ROOT"/agent-commands/cursor/*.md "$d/.cursor/commands/"
cp "$ROOT"/agent-subagents/cursor/*.md "$d/.cursor/agents/"
stage_common "$d"
deploy_note "$d" "- Reload the Cursor window after unzipping so it picks up the new rule, commands, and agents.
- Requires Cursor v2.4+ for \`.cursor/agents/\` to work as subagents; everything else works on any recent version."
zip_it "cursor" "$d"

# --- cline ---
d="$STAGE/cline"
mkdir -p "$d/.clinerules/workflows"
cp "$ROOT/catalyst-templates/cline.md" "$d/.clinerules/catalyst-orchestration.md"
cp "$ROOT"/agent-commands/cline/*.md "$d/.clinerules/workflows/"
cp "$ROOT/agent-subagents/cline.md" "$d/cline-subagent-guidance.md"
stage_common "$d"
deploy_note "$d" "- Cline has no native per-role subagent file format. Read \`cline-subagent-guidance.md\` for the Cline SDK / spawned-CLI alternatives.
- Invoke workflows with the extension included: \`/catalyst.md\`, \`/add-skill.md\`, \`/add-template.md\`."
zip_it "cline" "$d"

# --- codex ---
d="$STAGE/codex"
mkdir -p "$d/.codex/agents" "$d/_manual/codex-prompts"
cp "$ROOT/catalyst-templates/codex.md" "$d/_manual/AGENTS.md.append.md"
cp "$ROOT"/agent-commands/codex/*.md "$d/_manual/codex-prompts/"
cp "$ROOT"/agent-subagents/codex/*.toml "$d/.codex/agents/"
stage_common "$d"
deploy_note "$d" "- Append \`_manual/AGENTS.md.append.md\` to your project's \`AGENTS.md\` (or \`~/.codex/AGENTS.md\` globally) — create it if it doesn't exist yet.
- Copy \`_manual/codex-prompts/*.md\` into \`~/.codex/prompts/\` (a home-directory path, so it can't be pre-placed by this zip) to get \`/catalyst\`, \`/add-skill\`, \`/add-template\`.
- \`.codex/agents/*.toml\` is already in place for subagents, but Codex won't spawn them without being asked explicitly."
zip_it "codex" "$d"

# --- opencode ---
d="$STAGE/opencode"
mkdir -p "$d/.opencode/commands" "$d/.opencode/agents" "$d/_manual"
cp "$ROOT/catalyst-templates/opencode.md" "$d/_manual/AGENTS.md.append.md"
cp "$ROOT"/agent-commands/opencode/*.md "$d/.opencode/commands/"
cp "$ROOT"/agent-subagents/opencode/*.md "$d/.opencode/agents/"
stage_common "$d"
deploy_note "$d" "- Append \`_manual/AGENTS.md.append.md\` to your project's \`AGENTS.md\` — create it if it doesn't exist yet.
- Restart your OpenCode session after unzipping so it picks up the commands/agents.
- Known upstream bug: subagents invoked via the Task tool may ignore their own \`model:\` frontmatter — verify on your installed version before relying on the cost/quality split."
zip_it "opencode" "$d"

# --- github-copilot ---
d="$STAGE/github-copilot"
mkdir -p "$d/.github/skills/bug-fix" "$d/.github/skills/code-review" "$d/.github/skills/feature-implementation" "$d/.github/prompts" "$d/.github/agents" "$d/_manual"
cp "$ROOT/catalyst-templates/github-copilot.md" "$d/_manual/copilot-instructions.md.append.md"
cp "$ROOT/agent-skills/github-copilot/bug-fix/SKILL.md" "$d/.github/skills/bug-fix/"
cp "$ROOT/agent-skills/github-copilot/code-review/SKILL.md" "$d/.github/skills/code-review/"
cp "$ROOT/agent-skills/github-copilot/feature-implementation/SKILL.md" "$d/.github/skills/feature-implementation/"
cp "$ROOT"/agent-commands/github-copilot/*.prompt.md "$d/.github/prompts/"
cp "$ROOT"/agent-subagents/github-copilot/*.agent.md "$d/.github/agents/"
stage_common "$d"
deploy_note "$d" "- Append \`_manual/copilot-instructions.md.append.md\` to \`.github/copilot-instructions.md\` — create it if it doesn't exist yet.
- \`/catalyst\`, \`/add-skill\`, \`/add-template\` prompt files only work in Copilot Chat (VS Code, Visual Studio, JetBrains) — Copilot CLI has no \`.prompt.md\` support yet. On CLI, invoke \`catalyst-orchestrator\` directly as a custom agent instead.
- Skills and agents are auto-discovered by both Copilot Chat and Copilot CLI (\`/skills list\` in the CLI to confirm)."
zip_it "github-copilot" "$d"

rm -rf "$STAGE"
echo "All bundles built in $DIST/"
