# Declare or release resources so other freelancers can see them (GPU, ports, big RAM, a directory...).
# Usage: claim.ps1 add gpu:0 port:6006 ram:6G | claim.ps1 remove port:6006 | claim.ps1 show
# Needs FREELANCER_NAME (set automatically in a freelancer's tab) or --name N before the verb.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$p = Read-Flags $args
$name = if ($p.Flags['name']) { $p.Flags['name'] } else { $env:FREELANCER_NAME }
if (-not $name) { throw 'No freelancer name (set FREELANCER_NAME or pass --name)' }
$verb = if ($p.Positional.Count) { $p.Positional[0] } else { 'show' }
$items = @($p.Positional | Select-Object -Skip 1)
$w = Read-Freelancer $name
if (-not $w) { throw "No freelancer '$name' registered" }
$claims = @($w.claims)
switch ($verb) {
    'add'    { $claims = @(($claims + $items) | Where-Object { $_ } | Sort-Object -Unique) }
    'remove' { $claims = @($claims | Where-Object { $items -notcontains $_ }) }
    'show'   { }
    default  { throw 'Usage: claim.ps1 [--name N] add|remove|show [claim...]' }
}
if ($verb -ne 'show') { Set-FreelancerField $name @{ claims = $claims } }
"Claims of ${name}: $($claims -join ' ')"
