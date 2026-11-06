# Installs the freelancer skill on Windows: checks Windows Terminal, Git Bash (Claude Code runs the
# skill's dispatcher through it) and claude, then copies this folder to ~\.claude\skills\freelancer,
# keeping the runtime state\ already there.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$dest = Join-Path $HOME '.claude\skills\freelancer'
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) { throw 'Windows Terminal (wt.exe) is required: winget install Microsoft.WindowsTerminal' }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { throw "'claude' is not on PATH." }
if (-not (Test-Path (Join-Path $env:ProgramFiles 'Git\bin\bash.exe')) -and -not $env:CLAUDE_CODE_GIT_BASH_PATH) {
    Write-Warning 'Git Bash not found in the default location; Claude Code needs it to run the skill scripts.'
}
New-Item -ItemType Directory -Force (Join-Path $dest 'state\freelancers') | Out-Null
if ((Resolve-Path $src).Path -ne $dest) {
    Copy-Item -Recurse -Force (Join-Path $src 'SKILL.md'), (Join-Path $src 'freelancer-role.md'), (Join-Path $src 'scripts') $dest
}
Write-Host "Installed to $dest. Use: /freelancer <task>"
