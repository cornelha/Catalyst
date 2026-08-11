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
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

# Copilot-facing description for each skill (tuned for agent discovery; the canonical playbook
# body has no frontmatter, so the description lives here).
# NB: keep this file ASCII-only -- Windows PowerShell 5.1 parses .ps1 without a BOM as ANSI, so a
# literal em-dash byte would be mangled. The em-dash (U+2014) is injected via {0} below to match
# the em-dash the bash generator emits and the punctuation the canonical playbooks use.
$EmDash = [char]0x2014
$Descriptions = @{
    "bug-fix"                = "Use when a ticket reports something that used to work (or should per spec) but currently doesn't {0} a crash, wrong output, regression, error message, or failing test. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to find and fix the verified root cause." -f $EmDash
    "code-review"            = "Use when a ticket asks to review a PR, diff, or set of changes rather than write new code {0} evaluating correctness, quality, security, or fit before merge. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to produce a verified review verdict." -f $EmDash
    "feature-implementation" = "Use when a ticket asks for new capability that does not currently exist {0} a new endpoint, UI element, configuration option, integration, or workflow. Applies the Catalyst fan-out/reduce/verify/synthesize pattern to plan and build it against verified requirements and existing patterns." -f $EmDash
}

function Get-CanonicalBody {
    param([string]$SkillName)
    $path = Join-Path $Root ".catalyst\skills\$SkillName.md"
    $body = Get-Content -Raw -Encoding UTF8 $path

    # Drop the leading "# Skill: <Name>" heading -- the generated SKILL.md gets its own heading.
    $body = [regex]::Replace($body, '(?m)^#\s*Skill:\s*.+?\r?\n', '')

    # Make cross-skill references self-contained: "`bug-fix.md`" -> "`bug-fix`" (skill names,
    # not repo-root file paths that may not exist in the consumer's checkout).
    $body = [regex]::Replace($body, '(bug-fix|code-review|feature-implementation)\.md', '$1')

    # Strip repo-root worktree references (WORKTREE-WORKFLOW.md) so the skill has no dependency
    # on files outside its own folder. The worktree instruction itself stays, generic.
    $body = [regex]::Replace($body, '\(See\s+`WORKTREE-WORKFLOW\.md`\.\)\s*', '')
    $body = [regex]::Replace($body, '\(see\s+`WORKTREE-WORKFLOW\.md`\)\s*', '')
    $body = $body -replace '  +', ' '

    return $body.Trim()
}

function Get-Title {
    param([string]$SkillName)
    # "bug-fix" -> "Bug Fix", "feature-implementation" -> "Feature Implementation"
    return (($SkillName -split '-') | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' '
}

function New-Skill {
    param([string]$SkillName)
    $body = Get-CanonicalBody $SkillName
    $description = $Descriptions[$SkillName]
    $outPath = Join-Path $Root "agent-skills\github-copilot\$SkillName\SKILL.md"
    $frontmatter = "---`nname: $SkillName`ndescription: $description`nmetadata:`n  source: .catalyst/skills/$SkillName.md`n---`n`n"
    $heading = "# $(Get-Title $SkillName)`n`n"
    $content = $frontmatter + $heading + $body + "`n"
    [System.IO.File]::WriteAllText($outPath, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Regenerated agent-skills/github-copilot/$SkillName/SKILL.md"
}

New-Skill "bug-fix"
New-Skill "code-review"
New-Skill "feature-implementation"
