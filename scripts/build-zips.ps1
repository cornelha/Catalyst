# Packages each supported tool's Catalyst files into a deployable zip under dist/.
# Each zip is an overlay: unzip it into the root of the project you want Catalyst
# applied to. It only adds new files/directories -- nothing it contains overwrites
# a file that commonly already exists in a real project (CLAUDE.md, AGENTS.md,
# .github/copilot-instructions.md). Those go under _manual/ instead, with the
# exact append step spelled out in the bundle's own DEPLOY.md.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Dist = Join-Path $Root "dist"
$Stage = Join-Path $Root ".build-stage"

Remove-Item -Recurse -Force $Stage -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $Dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Dist | Out-Null

function New-Dirs {
    param([string[]]$Paths)
    foreach ($p in $Paths) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Copy-Skills {
    # catalyst-skills/ and SUBAGENT-ARCHITECTURE.md are referenced by every
    # tool's agents/commands, so every bundle ships them.
    param([string]$Dir)
    New-Item -ItemType Directory -Path (Join-Path $Dir "catalyst-skills") -Force | Out-Null
    Copy-Item (Join-Path $Root "catalyst-skills\*.md") (Join-Path $Dir "catalyst-skills")
    Copy-Item (Join-Path $Root "SUBAGENT-ARCHITECTURE.md") $Dir
}

function Write-DeployNote {
    param([string]$Dir, [string]$Body)
    $header = "# Deploying this bundle`n`nUnzip this archive into the root of the project you want Catalyst applied to.`nEverything here is additive -- nothing in this zip overwrites a file that`nalready exists in your project.`n`n"
    Set-Content -Path (Join-Path $Dir "DEPLOY.md") -Value ($header + $Body) -Encoding UTF8
}

function Build-Zip {
    param([string]$Name, [string]$Dir)
    $zipPath = Join-Path $Dist "catalyst-$Name.zip"
    Compress-Archive -Path (Join-Path $Dir "*") -DestinationPath $zipPath -Force
    Write-Host "Built dist/catalyst-$Name.zip"
}

# --- claude-code ---
$d = Join-Path $Stage "claude-code"
New-Dirs @("$d\.claude\commands", "$d\.claude\agents", "$d\_manual")
Copy-Item (Join-Path $Root ".claude\commands\catalyst.md"), (Join-Path $Root ".claude\commands\add-skill.md"), (Join-Path $Root ".claude\commands\add-template.md") "$d\.claude\commands\"
Copy-Item (Join-Path $Root "agent-subagents\claude-code\*.md") "$d\.claude\agents\"
Copy-Item (Join-Path $Root "catalyst-templates\claude-code.md") "$d\_manual\CLAUDE.md.append.md"
Copy-Skills $d
Write-DeployNote $d @"
- **Optional, recommended:** append ``_manual/CLAUDE.md.append.md`` to your project's ``CLAUDE.md`` (or ``~/.claude/CLAUDE.md`` for every repo) so the pattern applies automatically, not just via ``/catalyst``.
- ``/catalyst``, ``/add-skill``, ``/add-template`` work immediately, no restart needed.
- Restart Claude Code after unzipping so it picks up ``.claude/agents/*``.
"@
Build-Zip "claude-code" $d

# --- cursor ---
$d = Join-Path $Stage "cursor"
New-Dirs @("$d\.cursor\rules", "$d\.cursor\commands", "$d\.cursor\agents")
Copy-Item (Join-Path $Root "catalyst-templates\cursor.md") "$d\.cursor\rules\catalyst-orchestration.mdc"
Copy-Item (Join-Path $Root "agent-commands\cursor\*.md") "$d\.cursor\commands\"
Copy-Item (Join-Path $Root "agent-subagents\cursor\*.md") "$d\.cursor\agents\"
Copy-Skills $d
Write-DeployNote $d @"
- Reload the Cursor window after unzipping so it picks up the new rule, commands, and agents.
- Requires Cursor v2.4+ for ``.cursor/agents/`` to work as subagents; everything else works on any recent version.
"@
Build-Zip "cursor" $d

# --- cline ---
$d = Join-Path $Stage "cline"
New-Dirs @("$d\.clinerules\workflows")
Copy-Item (Join-Path $Root "catalyst-templates\cline.md") "$d\.clinerules\catalyst-orchestration.md"
Copy-Item (Join-Path $Root "agent-commands\cline\*.md") "$d\.clinerules\workflows\"
Copy-Item (Join-Path $Root "agent-subagents\cline.md") "$d\cline-subagent-guidance.md"
Copy-Skills $d
Write-DeployNote $d @"
- Cline has no native per-role subagent file format. Read ``cline-subagent-guidance.md`` for the Cline SDK / spawned-CLI alternatives.
- Invoke workflows with the extension included: ``/catalyst.md``, ``/add-skill.md``, ``/add-template.md``.
"@
Build-Zip "cline" $d

# --- codex ---
$d = Join-Path $Stage "codex"
New-Dirs @("$d\.codex\agents", "$d\_manual\codex-prompts")
Copy-Item (Join-Path $Root "catalyst-templates\codex.md") "$d\_manual\AGENTS.md.append.md"
Copy-Item (Join-Path $Root "agent-commands\codex\*.md") "$d\_manual\codex-prompts\"
Copy-Item (Join-Path $Root "agent-subagents\codex\*.toml") "$d\.codex\agents\"
Copy-Skills $d
Write-DeployNote $d @"
- Append ``_manual/AGENTS.md.append.md`` to your project's ``AGENTS.md`` (or ``~/.codex/AGENTS.md`` globally) -- create it if it doesn't exist yet.
- Copy ``_manual/codex-prompts/*.md`` into ``~/.codex/prompts/`` (a home-directory path, so it can't be pre-placed by this zip) to get ``/catalyst``, ``/add-skill``, ``/add-template``.
- ``.codex/agents/*.toml`` is already in place for subagents, but Codex won't spawn them without being asked explicitly.
"@
Build-Zip "codex" $d

# --- opencode ---
$d = Join-Path $Stage "opencode"
New-Dirs @("$d\.opencode\commands", "$d\.opencode\agents", "$d\_manual")
Copy-Item (Join-Path $Root "catalyst-templates\opencode.md") "$d\_manual\AGENTS.md.append.md"
Copy-Item (Join-Path $Root "agent-commands\opencode\*.md") "$d\.opencode\commands\"
Copy-Item (Join-Path $Root "agent-subagents\opencode\*.md") "$d\.opencode\agents\"
Copy-Skills $d
Write-DeployNote $d @"
- Append ``_manual/AGENTS.md.append.md`` to your project's ``AGENTS.md`` -- create it if it doesn't exist yet.
- Restart your OpenCode session after unzipping so it picks up the commands/agents.
- Known upstream bug: subagents invoked via the Task tool may ignore their own ``model:`` frontmatter -- verify on your installed version before relying on the cost/quality split.
"@
Build-Zip "opencode" $d

# --- github-copilot ---
$d = Join-Path $Stage "github-copilot"
New-Dirs @("$d\.github\skills\bug-fix", "$d\.github\skills\code-review", "$d\.github\skills\feature-implementation", "$d\.github\prompts", "$d\.github\agents", "$d\_manual")
Copy-Item (Join-Path $Root "catalyst-templates\github-copilot.md") "$d\_manual\copilot-instructions.md.append.md"
Copy-Item (Join-Path $Root "agent-skills\github-copilot\bug-fix\SKILL.md") "$d\.github\skills\bug-fix\"
Copy-Item (Join-Path $Root "agent-skills\github-copilot\code-review\SKILL.md") "$d\.github\skills\code-review\"
Copy-Item (Join-Path $Root "agent-skills\github-copilot\feature-implementation\SKILL.md") "$d\.github\skills\feature-implementation\"
Copy-Item (Join-Path $Root "agent-commands\github-copilot\*.prompt.md") "$d\.github\prompts\"
Copy-Item (Join-Path $Root "agent-subagents\github-copilot\*.agent.md") "$d\.github\agents\"
Copy-Skills $d
Write-DeployNote $d @"
- Append ``_manual/copilot-instructions.md.append.md`` to ``.github/copilot-instructions.md`` -- create it if it doesn't exist yet.
- ``/catalyst``, ``/add-skill``, ``/add-template`` prompt files only work in Copilot Chat (VS Code, Visual Studio, JetBrains) -- Copilot CLI has no ``.prompt.md`` support yet. On CLI, invoke ``catalyst-orchestrator`` directly as a custom agent instead.
- Skills and agents are auto-discovered by both Copilot Chat and Copilot CLI (``/skills list`` in the CLI to confirm).
"@
Build-Zip "github-copilot" $d

Remove-Item -Recurse -Force $Stage
Write-Host "All bundles built in $Dist"
