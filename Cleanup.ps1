<#
This script cleans up changes made in this demo
#>
$cleanUpPath = "$PSScriptRoot\FileShare"
if (Test-path -Path $cleanUpPath)
{
    Write-Verbose "Removing folder [$cleanUpPath]" -Verbose
    Remove-Item -Path $cleanUpPath -Recurse -Force -ErrorAction Ignore
}


if(Get-PSRepository -Name 'MyRepository' -ErrorAction Ignore)
{
    Write-Verbose "Removing repository [MyRepository]" -Verbose
    Get-PSRepository -Name 'MyRepository' |
        Unregister-PSRepository
}


