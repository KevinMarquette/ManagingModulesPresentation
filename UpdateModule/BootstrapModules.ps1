#requires -RunAsAdministrator
<#
    .Description
    This bootstraps a workstation by adding repositories and updating package managment modules
    It then installs all the DevOps PowerShell modules from our internal feed.

    .Notes
    Must run in clean PowerShell session
    Using a Job to perform part of this on another thread
    The package management modules don't like to be updated and refreshed in the active shell
#>
[cmdletbinding()]
Param(
    [switch]
    $SkipBootstrap,
    
    $repository = "MyRepository",

    $uri = "http://localhost:5000"
)

#Ensure Session PSModulePath has user module path.
if ( $PSVersionTable.PSEdition -ne 'Core')
{
    $env:PSModulePath = ( 
        ( 
            ($env:PSModulePath -split ";") + 
            "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        ) | Select-Object -Unique 
    ) -join ";"
        
    Write-Verbose "Ensuring User-Level Module Path Exists"
    [Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath, "User")
}


if ( -not $SkipBootstrap )
{
    "Registering PSRepository [$repository] $uri"
    # Using job to prevent loading PackageManagement in current session
    Start-Job -ScriptBlock {
        if ( -Not ( Get-PSRepository -Name $using:repository -ErrorAction Ignore ) )
        {
            "  Installing Nuget PackageProvider"
            $PackageProvider = @{
                Name           = 'NuGet'
                Force          = $true
                MinimumVersion = '2.8.5.201'
            }
            $null = Install-PackageProvider @PackageProvider

            $PSRepository = @{
                Name               = $using:repository
                SourceLocation     = $using:uri
                PublishLocation    = $using:uri
                InstallationPolicy = 'Trusted'
            }
            Register-PSRepository @PSRepository
        }

        $PowerShellGet = Get-Module PowerShellGet -ListAvailable | 
            Sort-Object Version -Descending | 
            Select-Object -First 1

        if ($PowerShellGet.Version -lt [version]'1.6.0')
        {
            "Updating [PowerShellGet]"

            $installOptions = @{
                Repository = $using:repository
                Force      = $true
                Scope      = "AllUsers"
            }
            "  Installing PackageManagement"
            Install-Module -Name PackageManagement @installOptions
            "  Installing PowerShellGet"
            Install-Module -Name PowerShellGet @installOptions
        }
    } | Wait-Job | Receive-Job


    
    # Bootstrap module management
    if (Get-Module PowerShellGet)
    {
        Write-Error "[PowerShellGet] module is already loaded, start clean powershell session"
        return
    }

    "Installing LDUtility"
    $installModuleSplat = @{
        Scope        = 'CurrentUser'
        AllowClobber = $true
        Force        = $true
    }
    Find-Module -Repository $repository -Name LDUtility | 
        Install-Module @installModuleSplat
}
"Calling Update-LDModules -Verbose to update/install all modules"
Update-LDModule -Verbose
