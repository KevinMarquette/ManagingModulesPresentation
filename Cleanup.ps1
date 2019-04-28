param([switch]$Docker)
<#
    This script cleans up changes made in this demo
#>
$cleanUpPathList = @(
    "$PSScriptRoot\FileShare",
    "$PSScriptRoot\Container"
    "$PSScriptRoot\downloads"
)
foreach ($cleanUpPath in $cleanUpPathList)
{
    if (Test-path -Path $cleanUpPath)
    {
        Write-Verbose "Removing folder [$cleanUpPath]" -Verbose
        Remove-Item -Path $cleanUpPath -Recurse -Force -ErrorAction Ignore
    }
}


$repositoryList = 'MyRepository','MyNugetRepository'
foreach ($repoToRemove in $repositoryList)
{
    if (Get-PSRepository -Name $repoToRemove -ErrorAction Ignore)
    {
        Write-Verbose "Removing repository [$repoToRemove]" -Verbose
        Get-PSRepository -Name $repoToRemove |
            Unregister-PSRepository
    }
}

if($Docker)
{
    docker.exe kill nuget-server
    docker.exe rm nuget-server
}

Get-Module MyModule -ListAvailable | 
    Uninstall-Module -ErrorAction Ignore