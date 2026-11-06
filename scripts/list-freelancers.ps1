# List registered freelancers (all projects). Read-only.
. "$PSScriptRoot\common.ps1"
$files = @(Get-ChildItem $script:RegDir -Filter '*.json' -ErrorAction SilentlyContinue)
if (-not $files) { '(no freelancers registered)'; return }
foreach ($f in $files) {
    $j = Get-Content -Raw -Encoding UTF8 $f.FullName | ConvertFrom-Json
    $st = $j.status
    if ($st -ne 'closed' -and -not (Test-FreelancerAlive $j)) { $st = "dead($st)" }
    "$($j.name) | $st | $(if ($j.model) { $j.model } else { 'default' }) | $($j.root) | $($j.task)"
}
