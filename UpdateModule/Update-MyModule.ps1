using namespace System.Collections.Generic
function Update-MyModule
{
    <#
        .Description
        This installs all modules off of the internal gallery by default

        .Example
        Update-MyModule -Verbose

        .Notes
        Requires that you first run BootstrapModules.ps1
    #>
    [cmdletbinding( SupportsShouldProcess )]
    param(
        # Module name
        [alias('ModuleName')]
        [parameter(ValueFromPipeline)]
        [string[]]
        $Name = '*',

        # Install scope
        [validateset('CurrentUser', 'AllUsers')]
        [string]
        $Scope = 'CurrentUser',

        # Uninstalls old versions of loanDepot modules
        [switch]
        $Clean,

        # Forces a reinstall, even if already installed
        [switch]
        $Force,

        # Imports the module after installing it
        [switch]
        $Import
    )

    begin
    {
        # manual import instead of using requires to hide verbose import noise
        Import-Module PackageManagement -Verbose:$false
        Import-Module PowerShellGet -Verbose:$false

        $moduleInstallOptions = @{
            Scope              = $Scope
            ErrorAction        = 'Stop'
            AllowClobber       = $true
            SkipPublisherCheck = $true
            Force              = $true
        }

        [list[string]]$moduleNames = [list[string]]::new()
    }

    process
    {
        foreach($node in $Name)
        {
            $moduleNames.Add($node)
        }
    }

    end
    {
        #region Special update logic for AZ module
        try
        {
            if ( $Name -eq '*' -or $moduleNames -contains 'AZ' )
            {
                # pull AZ out of the update list
                $moduleNames = $moduleNames | Where {$_ -ne 'AZ'}
                Update-LDAZModule -Scope:$Scope -ErrorAction Stop

                if ( $moduleNames.Count -eq 0 )
                {
                    # if AZ is the only module we should stop here
                    return
                }
            }
        }
        catch
        {
            Write-Warning "Errors trying to update [AZ] module [$PSItem]"
        }
        #endregion

        try
        {
            $myModules = @(Find-MyModule -Name $moduleNames)
        }
        catch
        {
            Write-Warning "Errors trying to search for modules to update [$PSItem]"
        }

        if ( $myModules -and $myModules.Count -gt 0 )
        {
            $installList = $myModules.Name
            Write-Verbose ("  [{0}]" -f ( $installList -join ','))

            Write-Verbose "Gathering local matching modules"
            $prevVerbosePreference = $VerbosePreference
            $VerbosePreference = 'SilentlyContinue'
            $currentModuleList = Get-Module -ListAvailable $installList
            $VerbosePreference = $prevVerbosePreference


            # Walk list of modules to install/update
            foreach ( $module in $myModules )
            {
                $moduleName = $module.Name
                Write-Verbose "  [$moduleName]"

                if ( $null -ne $module )
                {
                    # Currently installed modules
                    $currentModule = $currentModuleList | 
                        Where-Object Name -eq $moduleName

                    Write-Verbose "    Current version [$($currentModule.version -join ',')]"
                    Write-Verbose "    Published Version [$($module.version)] [$($module.Repository)]"

                    # Special test to handle 1.0.0 -eq 1.0.0.0 as $true
                    if ( $force -or -not ( Test-ModuleVersion -Source $currentModule.version -Target $module.version ) )
                    {
                        try
                        {
                            Write-Verbose "  + Installing [$($module.version)]"
                            if ($PSCmdlet.ShouldProcess("$moduleName $($module.version)", 'Install'))
                            {
                                $module | Install-Module @moduleInstallOptions

                                # only remove if the install did not throw
                                if (($currentModule -and $module.Tags -contains 'loanDepot') -and
                                    ($Clean -or $currentModule.version -match '^\d+\.\d+.\d+(\.[01])?$'))
                                {
                                    Write-Verbose "  - Removing [$($currentModule.version -join ',')]"
                                    UnInstall-MyModule -ModuleName $moduleName -ExcludeVersion $module.version
                                }
                            }
                        }
                        catch
                        {
                            $writeError = @{
                                Message     = "had issues installing or removing [$moduleName] [$PSItem]"
                                Exception   = $PSItem.Exception
                                ErrorAction = 'Stop'
                            }
                            Write-Error @writeError
                        }
                    }
                }

                if ($Import)
                {
                    $prevVerbosePreference = $VerbosePreference
                    $VerbosePreference = 'SilentlyContinue'
                    $importModuleSplat = @{
                        Name            = $moduleName
                        RequiredVersion = $module.Version
                        Force           = $true
                        ErrorAction     = "Stop"
                    }
                    
                    try
                    {
                        Import-Module @importModuleSplat
                    }
                    catch
                    {
                        Write-Warning "Could not import module [$moduleName] [$PSItem]"
                        Write-Verbose "    Installed versions:"
                        Get-Module $moduleName -ListAvailable | Foreach-Object {
                            Write-Verbose "      [$($_.Name)] $($_.Version)"
                        }
                    }
                    $VerbosePreference = $prevVerbosePreference
                }
            }
        }
        else
        {
            Write-Warning "The requested module [$Name] was not available in our repository. Make sure the name is correct and that you have published this module to that repository or added it to the public modules.json list in the module."
        }
    }
}
