function prompt { '#PHSSummit:\>' }

$networkShare = '.\FileShare'
$apikey = Get-Content -Path API.key 
$ENV:nugetapikey = $apikey
$configPath = ".\UpdateModule\communityModules.json"

Clear-Host

# Need adminrights for docker
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "Restart Demo as Administrator (for Docker)" -BackgroundColor Red -ForegroundColor Black 
    Pause
}