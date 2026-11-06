# Runs inside the freelancer's terminal tab: sets the environment and starts claude.
# Usage: run-freelancer.ps1 -Name NAME   (cwd = project root, set by the tab's -d)
param([Parameter(Mandatory)][string]$Name)
. "$PSScriptRoot\common.ps1"

$w = Read-Freelancer $Name
if (-not $w) { Write-Host "No freelancer '$Name' registered"; Read-Host 'Press Enter to close'; exit 1 }

# Do not inherit the spawner's session identity: this claude is its own, unrelated session.
foreach ($v in 'CLAUDECODE', 'CLAUDE_PID', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_CHILD_SESSION',
               'CLAUDE_CODE_BRIDGE_SESSION_ID', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_SESSION_ATTENDED',
               'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'NO_COLOR', 'AI_AGENT',
               'GIT_ASKPASS', 'GIT_EDITOR', 'GIT_TERMINAL_PROMPT', 'GCM_INTERACTIVE', 'COREPACK_ENABLE_AUTO_PIN',
               'PSExecutionPolicyPreference') {
    Remove-Item "Env:\$v" -ErrorAction SilentlyContinue
}
$env:FREELANCER_NAME = $Name
$env:FREELANCER_SKILL_DIR = $script:SkillDir.Replace('\', '/')
$Host.UI.RawUI.WindowTitle = $Name

Set-FreelancerField $Name @{ status = 'running'; hostPid = $PID; hostStart = [string](Get-ProcStart $PID); started = (Get-Date).ToString('s') }

$role = (Get-Content -Raw -Encoding UTF8 (Join-Path $script:SkillDir 'freelancer-role.md')).Replace('{{NAME}}', $Name)
$prompt = "You are freelancer '$Name'. Read your brief at .agents/briefs/$Name.md, run the resources script described in your role prompt, then start."
$claudeArgs = @('--name', $Name, '--append-system-prompt', $role, '--permission-mode', $w.permissionMode)
if ($w.model) { $claudeArgs += @('--model', $w.model) }
$claudeArgs += $prompt

& claude @claudeArgs
$code = $LASTEXITCODE

Set-FreelancerField $Name @{ status = 'closed'; claims = @(); ended = (Get-Date).ToString('s'); exitCode = $code }
exit 0
