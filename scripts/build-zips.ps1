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

# Refresh the generated Copilot skills from the canonical .catalyst/skills/ playbooks
# before packaging, so the zips always ship self-contained, spec-compliant SKILL.md files.
& (Join-Path $Root "scripts\generate-copilot-skills.ps1")

Remove-Item -Recurse -Force $Stage -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $Dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Dist | Out-Null

function New-Dirs {
    param([string[]]$Paths)
    foreach ($p in $Paths) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Get-InstallBlock {
    # The installable instruction: .catalyst/install.md holds exactly the block between
    # the start/end markers (no explanatory header), and that is what ships.
    $raw = Get-Content -Raw -Encoding UTF8 (Join-Path $Root ".catalyst\install.md")
    $m = [regex]::Match($raw, '(?ms)^\s*(<!-- catalyst:start -->.*?<!-- catalyst:end -->)\s*$')
    if (-not $m.Success) { throw "Could not find catalyst:start/end markers in .catalyst/install.md" }
    return $m.Groups[1].Value.Trim()
}

function Copy-Common {
    # The whole .catalyst/ folder (install.md, orchestration.md, skills/) plus
    # SUBAGENT-ARCHITECTURE.md and WORKTREE-WORKFLOW.md are referenced by every
    # tool's agents/commands, so every bundle ships them.
    param([string]$Dir)
    New-Item -ItemType Directory -Path (Join-Path $Dir ".catalyst\skills") -Force | Out-Null
    Copy-Item (Join-Path $Root ".catalyst\install.md") (Join-Path $Dir ".catalyst")
    Copy-Item (Join-Path $Root ".catalyst\orchestration.md") (Join-Path $Dir ".catalyst")
    Copy-Item (Join-Path $Root ".catalyst\skills\*.md") (Join-Path $Dir ".catalyst\skills")
    Copy-Item (Join-Path $Root "SUBAGENT-ARCHITECTURE.md") $Dir
    Copy-Item (Join-Path $Root "WORKTREE-WORKFLOW.md") $Dir
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
New-Dirs @("$d\.claude\commands", "$d\.claude\agents", "$d\.claude-plugin", "$d\_manual")
Copy-Item (Join-Path $Root ".claude\commands\catalyst.md"), (Join-Path $Root ".claude\commands\catalyst-install.md"), (Join-Path $Root ".claude\commands\add-skill.md"), (Join-Path $Root ".claude\commands\add-template.md"), (Join-Path $Root ".claude\commands\learn.md") "$d\.claude\commands\"
Copy-Item (Join-Path $Root "agent-subagents\claude-code\*.md") "$d\.claude\agents\"
Copy-Item (Join-Path $Root ".claude-plugin\plugin.json"), (Join-Path $Root ".claude-plugin\marketplace.json") "$d\.claude-plugin\"
$installBlock = Get-InstallBlock
Set-Content -Path "$d\_manual\CLAUDE.md.append.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Common $d
Write-DeployNote $d @"
- **Option A — Marketplace (recommended):** with this bundle unzipped into your project root, run ``/plugin marketplace add .`` then ``/plugin install catalyst`` inside Claude Code.
- **Option B — Manual:** append ``_manual/CLAUDE.md.append.md`` to your project's ``CLAUDE.md`` (or ``~/.claude/CLAUDE.md`` for every repo) so the pattern applies automatically, not just via ``/catalyst``.
- ``/catalyst``, ``/add-skill``, ``/add-template`` work immediately, no restart needed.
- Restart Claude Code after unzipping so it picks up ``.claude/agents/*``.
"@
Build-Zip "claude-code" $d

# --- cursor ---
$d = Join-Path $Stage "cursor"
New-Dirs @("$d\.cursor\rules", "$d\.cursor\commands", "$d\.cursor\agents")
# Generate the always-applied rule from the canonical install block, not the template
# (the template is a tool-specific reference doc; the rule is the install block + frontmatter).
$installBlock = Get-InstallBlock
$mdc = "---`ndescription: Ticket orchestration pattern - fan out, reduce, verify, synthesize`nalwaysApply: true`n---`n`n" + $installBlock + "`n"
Set-Content -Path "$d\.cursor\rules\catalyst-orchestration.mdc" -Value $mdc -Encoding UTF8
Copy-Item (Join-Path $Root "agent-commands\cursor\*.md") "$d\.cursor\commands\"
Copy-Item (Join-Path $Root "agent-subagents\cursor\*.md") "$d\.cursor\agents\"
Copy-Common $d
Write-DeployNote $d @"
- Reload the Cursor window after unzipping so it picks up the new rule, commands, and agents.
- Requires Cursor v2.4+ for ``.cursor/agents/`` to work as subagents; everything else works on any recent version.
"@
Build-Zip "cursor" $d

# --- cline ---
$d = Join-Path $Stage "cline"
New-Dirs @("$d\.clinerules\workflows")
# Generate the .clinerules rule from the canonical install block.
$installBlock = Get-InstallBlock
Set-Content -Path "$d\.clinerules\catalyst-orchestration.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Item (Join-Path $Root "agent-commands\cline\*.md") "$d\.clinerules\workflows\"
Copy-Item (Join-Path $Root "agent-subagents\cline.md") "$d\cline-subagent-guidance.md"
Copy-Common $d
Write-DeployNote $d @"
- Cline has no native per-role subagent file format. Read ``cline-subagent-guidance.md`` for the Cline SDK / spawned-CLI alternatives.
- Invoke workflows with the extension included: ``/catalyst.md``, ``/add-skill.md``, ``/add-template.md``.
"@
Build-Zip "cline" $d

# --- codex ---
$d = Join-Path $Stage "codex"
New-Dirs @("$d\.codex\agents", "$d\_manual\codex-prompts")
Copy-Item (Join-Path $Root "catalyst-templates\codex.md") "$d\_manual\codex-template.md"
$installBlock = Get-InstallBlock
Set-Content -Path "$d\_manual\AGENTS.md.append.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Item (Join-Path $Root "agent-commands\codex\*.md") "$d\_manual\codex-prompts\"
Copy-Item (Join-Path $Root "agent-subagents\codex\*.toml") "$d\.codex\agents\"
Copy-Common $d
Write-DeployNote $d @"
- Append ``_manual/AGENTS.md.append.md`` to your project's ``AGENTS.md`` (or ``~/.codex/AGENTS.md`` globally) -- create it if it doesn't exist yet.
- Copy ``_manual/codex-prompts/*.md`` into ``~/.codex/prompts/`` (a home-directory path, so it can't be pre-placed by this zip) to get ``/catalyst``, ``/add-skill``, ``/add-template``.
- ``.codex/agents/*.toml`` is already in place for subagents, but Codex won't spawn them without being asked explicitly.
"@
Build-Zip "codex" $d

# --- opencode ---
$d = Join-Path $Stage "opencode"
New-Dirs @("$d\.opencode\commands", "$d\.opencode\agents", "$d\_manual")
Copy-Item (Join-Path $Root "catalyst-templates\opencode.md") "$d\_manual\opencode-template.md"
$installBlock = Get-InstallBlock
Set-Content -Path "$d\_manual\AGENTS.md.append.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Item (Join-Path $Root "agent-commands\opencode\*.md") "$d\.opencode\commands\"
Copy-Item (Join-Path $Root "agent-subagents\opencode\*.md") "$d\.opencode\agents\"
Copy-Common $d
Write-DeployNote $d @"
- Append ``_manual/AGENTS.md.append.md`` to your project's ``AGENTS.md`` -- create it if it doesn't exist yet.
- Restart your OpenCode session after unzipping so it picks up the commands/agents.
- Known upstream bug: subagents invoked via the Task tool may ignore their own ``model:`` frontmatter -- verify on your installed version before relying on the cost/quality split.
"@
Build-Zip "opencode" $d

# --- pi ---
$d = Join-Path $Stage "pi"
New-Dirs @("$d\.pi\prompts", "$d\_manual")
Copy-Item (Join-Path $Root "catalyst-templates\pi.md") "$d\_manual\pi-template.md"
$installBlock = Get-InstallBlock
Set-Content -Path "$d\_manual\AGENTS.md.append.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Item (Join-Path $Root "agent-commands\pi\*.md") "$d\.pi\prompts\"
Copy-Item (Join-Path $Root "agent-subagents\pi.md") "$d\pi-subagent-guidance.md"
Copy-Common $d
Write-DeployNote $d @"
- Append ``_manual/AGENTS.md.append.md`` to your project's ``AGENTS.md`` (or ``~/.pi/agent/AGENTS.md`` globally) -- create it if it doesn't exist yet. Pi concatenates every ``AGENTS.md`` it finds, so global and project-level files both apply.
- ``.pi/prompts/*.md`` is already in place for ``/catalyst``, ``/add-skill``, ``/add-template`` -- restart your pi session and mark the project trusted if the commands don't show up in autocomplete.
- Pi has no native per-role subagent file format. Read ``pi-subagent-guidance.md`` for the extension-based or CLI-spawn alternatives.
"@
Build-Zip "pi" $d

# --- github-copilot ---
$d = Join-Path $Stage "github-copilot"
New-Dirs @("$d\.github\skills\bug-fix", "$d\.github\skills\code-review", "$d\.github\skills\feature-implementation", "$d\.github\prompts", "$d\.github\agents", "$d\_manual")
Copy-Item (Join-Path $Root "catalyst-templates\github-copilot.md") "$d\_manual\copilot-template.md"
$installBlock = Get-InstallBlock
Set-Content -Path "$d\_manual\copilot-instructions.md.append.md" -Value ($installBlock + "`n") -Encoding UTF8
Copy-Item (Join-Path $Root "agent-skills\github-copilot\bug-fix\SKILL.md") "$d\.github\skills\bug-fix\"
Copy-Item (Join-Path $Root "agent-skills\github-copilot\code-review\SKILL.md") "$d\.github\skills\code-review\"
Copy-Item (Join-Path $Root "agent-skills\github-copilot\feature-implementation\SKILL.md") "$d\.github\skills\feature-implementation\"
Copy-Item (Join-Path $Root "agent-commands\github-copilot\*.prompt.md") "$d\.github\prompts\"
Copy-Item (Join-Path $Root "agent-subagents\github-copilot\*.agent.md") "$d\.github\agents\"
Copy-Common $d
Write-DeployNote $d @"
- Append ``_manual/copilot-instructions.md.append.md`` to ``.github/copilot-instructions.md`` -- create it if it doesn't exist yet.
- ``/catalyst``, ``/add-skill``, ``/add-template`` prompt files only work in Copilot Chat (VS Code, Visual Studio, JetBrains) -- Copilot CLI has no ``.prompt.md`` support yet. On CLI, invoke ``catalyst-orchestrator`` directly as a custom agent instead.
- Skills and agents are auto-discovered by both Copilot Chat and Copilot CLI (``/skills list`` in the CLI to confirm).
"@
Build-Zip "github-copilot" $d

Remove-Item -Recurse -Force $Stage
Write-Host "All bundles built in $Dist"
