# Stop a freelancer and close its tab. Only on the user's request: freelancers end themselves otherwise.
# Usage: close-freelancer.ps1 --name N
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$name = (Read-Flags $args).Flags['name']
if (-not $name) { throw 'Usage: close-freelancer.ps1 --name N' }
$w = Read-Freelancer $name
if (-not $w) { throw "No freelancer '$name'" }
if (Test-FreelancerAlive $w) {
    # Stop only claude (the tab's child process); run-freelancer.ps1 then exits cleanly and the tab closes.
    Get-CimInstance Win32_Process -Filter "ParentProcessId=$($w.hostPid)" | Where-Object { $_.Name -eq 'claude.exe' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    $deadline = (Get-Date).AddSeconds(15)
    while ((Test-FreelancerAlive (Read-Freelancer $name)) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
    if (Test-FreelancerAlive (Read-Freelancer $name)) { Stop-Process -Id $w.hostPid -Force -ErrorAction SilentlyContinue }
}
Set-FreelancerField $name @{ status = 'closed'; claims = @(); ended = (Get-Date).ToString('s') }
"Closed '$name'."
