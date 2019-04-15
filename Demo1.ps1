break; # F5 protection

Install-Module PackageManagement -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -AcceptLicense
Install-Module powershellget -Scope CurrentUser -AllowClobber -Repository PSGallery -AcceptLicense
Import-Module PowerShellGet


Get-Command *PSRepository* 
<# Output
CommandType Name                    Version Source
----------- ----                    ------- ------
Function    Get-PSRepository        2.1.2   PowerShellGet
Function    Register-PSRepository   2.1.2   PowerShellGet
Function    Set-PSRepository        2.1.2   PowerShellGet
Function    Unregister-PSRepository 2.1.2   PowerShellGet
#>

Get-PSRepository -Name PSGallery
<# Output
Name      InstallationPolicy SourceLocation
----      ------------------ --------------
PSGallery Untrusted          https://www.powershellgallery.com/api/v2
#>


<#
    Using Register-PSRepository
#>

# Works with UNC shares
$networkShare = '.\FileShare'

# Create the folder for the demo
if( -not (Test-Path -Path $networkShare))
{
    New-Item -Path $networkShare -ItemType Directory
}

# Need to resolve the full path
# Issue https://github.com/PowerShell/PowerShellGet/issues/464
$networkShare = (Resolve-Path $networkShare).ProviderPath

# Register the share as a repository
$repo = @{
    Name = 'MyRepository'
    SourceLocation = $networkShare
    PublishLocation = $networkShare 
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repo

Get-PSRepository -Name 'MyRepository'
<# Output
Name                      InstallationPolicy   SourceLocation
----                      ------------------   --------------
MyRepository              Trusted              C:\workspace\ManagingModulesPresentation\FileShare
#>

Find-Module -Repository 'MyRepository' -Verbose
<# Output
VERBOSE: Repository details, Name = 'MyRepository', Location = 'C:\workspace\ManagingModulesPresentation\FileShare'; IsTrusted = 'True'; IsRegistered = 'True'.
VERBOSE: Using the provider 'PowerShellGet' for searching packages.
VERBOSE: Using the specified source names : 'MyRepository'.
VERBOSE: Getting the provider object for the PackageManagement Provider 'NuGet'.
VERBOSE: The specified Location is 'C:\workspace\ManagingModulesPresentation\FileShare' and PackageManagementProvider is 'NuGet'.VERBOSE: Total package yield:'0' for the specified package ''.
VERBOSE: Searching repository 'C:\workspace\ManagingModulesPresentation\FileShare' for ' tag:PSModule'.
VERBOSE: Total package yield:'0' for the specified package ''.
#>

# publish a local module
Get-Module -Name Watch-Command -ListAvailable
<#
ModuleType Version Name          PSEdition ExportedCommands
---------- ------- ----          --------- ----------------
Script     0.1.3   Watch-Command Desk      {Watch-Command, Watch}
#>

Publish-Module -Name Watch-Command -Repository 'MyRepository'


Find-Module -Repository 'MyRepository'
<# Output
Version Name          Repository   Description
------- ----          ----------   -----------
0.1.3   Watch-Command MyRepository A function to run a command ...
#>

