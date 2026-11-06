# Launch an independent freelancer Claude session in its own Windows Terminal tab, then return.
# The brief must already exist at <root>\.agents\briefs\<name>.md.
# Usage: spawn-freelancer.ps1 --name N --task T [--root DIR] [--model X] [--permission-mode M] [--claim "gpu:0 port:6006"]
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$f = (Read-Flags $args).Flags
$name = $f['name']; $task = $f['task']
$root = if ($f['root']) { $f['root'] } else { (Get-Location).Path }
$mode = if ($f['permission-mode']) { $f['permission-mode'] } else { 'auto' }
$model = if ($f['model']) { $f['model'] } else { '' }
$claims = @(([string]$f['claim'] -split '\s+') | Where-Object { $_ })

if (-not $name -or -not $task) { throw 'Need --name and --task' }
if ($name -notmatch '^fl-[a-z0-9][a-z0-9-]{0,36}$') {
    throw "Name must start with 'fl-', then lowercase letters, digits, hyphens (max 40 total), e.g. fl-fix-parser"
}
if ($mode -notin 'auto', 'acceptEdits', 'manual', 'plan', 'dontAsk', 'bypassPermissions') { throw "Bad permission mode: $mode" }
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) { throw 'Windows Terminal (wt.exe) is required' }
$root = (Resolve-Path $root).Path.TrimEnd('\')
$brief = Join-Path $root ".agents\briefs\$name.md"
if (-not (Test-Path $brief)) { throw "Brief not found: $brief (write it before spawning)" }
if (Test-FreelancerAlive (Read-Freelancer $name)) { throw "Freelancer '$name' is already running" }

Ensure-AgentsIgnored $root
Save-Freelancer ([pscustomobject]@{
    name = $name; task = $task; root = $root; permissionMode = $mode; model = $model
    claims = $claims; status = 'starting'; hostPid = $null; hostStart = $null
    created = (Get-Date).ToString('s')
})

# wt.exe treats ';' as a command separator, so none of these values may contain one.
$runner = Join-Path $PSScriptRoot 'run-freelancer.ps1'
# --reloadEnvironment: fresh environment like a normally opened tab (no inherited session identity,
# NO_COLOR or git prompt settings from the spawner's command environment).
$wtArgs = "-w 0 new-tab --reloadEnvironment --title `"$name`" --tabColor `"#00897B`" -d `"$root`" powershell -NoProfile -ExecutionPolicy Bypass -File `"$runner`" -Name $name"
# Windows Terminal always focuses a new tab; switch straight back to the tab the user was on.
$back = Get-SelectedTabIndex
if ($null -ne $back) { $wtArgs += " ; focus-tab -t $back" }
Start-Process -FilePath 'wt.exe' -ArgumentList $wtArgs

$deadline = (Get-Date).AddSeconds(20)
do { Start-Sleep -Milliseconds 500; $w = Read-Freelancer $name } while ($w.status -eq 'starting' -and (Get-Date) -lt $deadline)

if ($w.status -eq 'running') {
    "Spawned freelancer '$name' (mode $mode$(if ($model) { ", model $model" })). It is independent; nothing will report back."
    "Terminal tab title: $name (a new Windows Terminal tab; switch to it, or find it by that title)"
} else {
    "WARNING: '$name' did not report running within 20s (status: $($w.status)). Check the Windows Terminal tabs."
}
