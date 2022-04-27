#demo prep
Remove-Module posh-git -ErrorAction Ignore
function prompt {"#PSHSummit\>"}

.\Cleanup.ps1 -Docker

$apiKey = New-Guid
$ENV:nugetapikey = $apiKey
Set-Content -Path API.key -Value $apikey 

Clear-Host

. '.\Summit 2022.pptx'
code .\PSHSummit.ps1

break;

