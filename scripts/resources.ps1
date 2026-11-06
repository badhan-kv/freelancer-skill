# Snapshot of machine resources and of what the other agents are using. Read-only.
# Usage: resources.ps1 [--self NAME]   (NAME is left out of the "other freelancers" list)
. "$PSScriptRoot\common.ps1"
$self = (Read-Flags $args).Flags['self']
if (-not $self) { $self = $env:FREELANCER_NAME }
'== Machine =='
$cpu = Get-CimInstance Win32_Processor
"CPU: $(($cpu | Measure-Object NumberOfLogicalProcessors -Sum).Sum) logical cores, load $(($cpu | Measure-Object LoadPercentage -Average).Average)%"
$os = Get-CimInstance Win32_OperatingSystem
"RAM: {0:N1} GB total, {1:N1} GB available" -f ($os.TotalVisibleMemorySize / 1MB), ($os.FreePhysicalMemory / 1MB)
$d = Get-PSDrive -Name ($HOME.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($d) { "Disk ($($d.Name):): {0:N0} GB free of {1:N0} GB" -f ($d.Free / 1GB), (($d.Free + $d.Used) / 1GB) }
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>$null | ForEach-Object { "GPU $_" }
    nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader 2>$null | ForEach-Object { "  GPU process: $_" }
}
$ports = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique
"Listening ports: $($ports -join ' ')"
''
'== Other freelancers (claimed resources) =='
$found = $false
foreach ($f in @(Get-ChildItem $script:RegDir -Filter '*.json' -ErrorAction SilentlyContinue)) {
    $j = Get-Content -Raw -Encoding UTF8 $f.FullName | ConvertFrom-Json
    if ($j.name -eq $self -or -not (Test-FreelancerAlive $j)) { continue }
    $found = $true
    $c = @($j.claims); "- $($j.name) | $($j.root) | $($j.task) | claims: $(if ($c) { $c -join ' ' } else { 'none' })"
}
if (-not $found) { '(none running)' }
''
'== All Claude sessions on this machine (any spawner) =='
Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | ForEach-Object {
    $p = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
    "- pid $($_.ProcessId) | {0:N0} MB RSS | {1}" -f $(if ($p) { $p.WorkingSet64 / 1MB } else { 0 }), $_.CommandLine
}
''
'Heaviest processes (by RAM):'
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 6 | ForEach-Object {
    "  pid $($_.Id) | {0:N0} MB | $($_.ProcessName)" -f ($_.WorkingSet64 / 1MB)
}
