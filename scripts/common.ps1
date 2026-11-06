# Shared helpers for the freelancer skill scripts (Windows). Dot-source this file.
# Registry: one JSON per freelancer in <skill dir>\state\freelancers, shared by all projects.

$script:SkillDir = Split-Path -Parent $PSScriptRoot
$script:RegDir = Join-Path $script:SkillDir 'state\freelancers'

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $false))
}

# GNU-style flags from $args: --name x --claim "a b" -> Flags @{name='x'; claim='a b'}; the rest are positional.
function Read-Flags([object[]]$Argv) {
    $flags = @{}; $pos = @(); $i = 0
    while ($i -lt $Argv.Count) {
        $a = [string]$Argv[$i]
        if ($a -like '--*') {
            if ($i + 1 -ge $Argv.Count) { throw "Missing value for $a" }
            $flags[$a.Substring(2)] = [string]$Argv[$i + 1]; $i += 2
        } else { $pos += $a; $i++ }
    }
    [pscustomobject]@{ Flags = $flags; Positional = $pos }
}

function Get-FreelancerFile([string]$Name) { Join-Path $script:RegDir "$Name.json" }

function Read-Freelancer([string]$Name) {
    $f = Get-FreelancerFile $Name
    if (-not (Test-Path $f)) { return $null }
    Get-Content -Raw -Encoding UTF8 $f | ConvertFrom-Json
}

function Save-Freelancer($Fl) {
    Write-Utf8NoBom (Get-FreelancerFile $Fl.name) ($Fl | ConvertTo-Json -Depth 5)
}

function Set-FreelancerField([string]$Name, [hashtable]$Fields) {
    $w = Read-Freelancer $Name
    if (-not $w) { throw "No freelancer '$Name' registered" }
    foreach ($k in $Fields.Keys) {
        if ($w.PSObject.Properties[$k]) { $w.$k = $Fields[$k] }
        else { $w | Add-Member -NotePropertyName $k -NotePropertyValue $Fields[$k] }
    }
    Save-Freelancer $w
}

# Start time of a process as a number: with the PID it identifies one process (guards against PID reuse).
function Get-ProcStart([int]$ProcId) {
    $p = Get-Process -Id $ProcId -ErrorAction SilentlyContinue
    if ($p) { $p.StartTime.ToFileTimeUtc() } else { $null }
}

# The registered host process is still the same, running process.
function Test-FreelancerAlive($Fl) {
    if (-not $Fl -or -not $Fl.hostPid) { return $false }
    $st = Get-ProcStart ([int]$Fl.hostPid)
    $null -ne $st -and ([string]$st -eq [string]$Fl.hostStart)
}

# Index of the selected tab in the foreground Windows Terminal window (the one 'wt -w 0' targets),
# so a new tab can hand focus straight back to it. $null if it cannot be read.
function Get-SelectedTabIndex {
    try {
        Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
        Add-Type -Namespace FreelancerSkill -Name Win -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();' -ErrorAction SilentlyContinue
        $ae = [Windows.Automation.AutomationElement]
        $wtCond = New-Object Windows.Automation.PropertyCondition($ae::ClassNameProperty, 'CASCADIA_HOSTING_WINDOW_CLASS')
        $tabCond = New-Object Windows.Automation.PropertyCondition($ae::ControlTypeProperty, [Windows.Automation.ControlType]::TabItem)
        $windows = @($ae::RootElement.FindAll([Windows.Automation.TreeScope]::Children, $wtCond))
        if (-not $windows) { return $null }
        $fg = [FreelancerSkill.Win]::GetForegroundWindow().ToInt64()
        $win = $windows | Where-Object { $_.Current.NativeWindowHandle -eq $fg } | Select-Object -First 1
        if (-not $win) { $win = $windows[0] }
        $i = 0
        foreach ($t in $win.FindAll([Windows.Automation.TreeScope]::Descendants, $tabCond)) {
            if ($t.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected) { return $i }
            $i++
        }
    } catch {}
    $null
}

# Make sure .agents/ is ignored when the project is a git repo or already has a .gitignore.
function Ensure-AgentsIgnored([string]$Root) {
    $gi = Join-Path $Root '.gitignore'
    if (-not (Test-Path (Join-Path $Root '.git')) -and -not (Test-Path $gi)) { return }
    if ((Test-Path $gi) -and (Select-String -Path $gi -Pattern '^\.agents/?$' -Quiet)) { return }
    Add-Content -Path $gi -Value '.agents/' -Encoding UTF8
}
