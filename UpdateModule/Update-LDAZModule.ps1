function Update-LDAZModule
{
    <#
        .Description
        This installs the AZ module off the PSGallery or updates it if needed

        .Example
        Update-LDAZModule -Verbose

        .Notes
        In PowerShell 5.1, Get-Module will not list the AZ module (because AZ is a country locaization code)
        This function is a manual workaround for that bug
        It only pulls AZ from the PSGallery if there is an update
        https://github.com/PowerShell/PowerShell/pull/8777
    #>
    [cmdletbinding( SupportsShouldProcess )]
    param(
        # Install scope
        [validateset('CurrentUser', 'AllUsers')]
        [string]
        $Scope = 'CurrentUser',

        # Imports the module after installing it
        [switch]
        $Import
    )

    begin
    {
        # manual import instead of requires to hide verbose import noise
        Import-Module PackageManagement -Verbose:$false
        Import-Module PowerShellGet -Verbose:$false

        $moduleName = 'AZ'

        $moduleInstallOptions = @{
            Scope              = $Scope
            ErrorAction        = 'Stop'
            AllowClobber       = $true
            SkipPublisherCheck = $true
            Force              = $true
        }

        Write-Verbose "Custom processing for [$moduleName] module"
    }

    end
    {
        Write-Verbose "  [$moduleName]"
        [Version]$maxVersion = '0.0.0.0'
        foreach($folder in $env:PSModulePath -split ';')
        {
            $azModule = $null

            if($folder -and (Test-Path -Path $folder))
            {
                $azModule = Get-ChildItem -Path $folder -Filter $moduleName

                if($azModule)
                {
                    $installedVersions = Get-ChildItem -Path $azModule.FullName |
                        Select-Object -ExpandProperty BaseName

                    foreach($version in $installedVersions)
                    {
                        Write-Verbose "    Current version [$version]"
                        if($maxVersion -lt [version]$version)
                        {
                            $maxVersion = $version
                        }
                    }
                }
            }
        }

        $module = Find-Module -Repository PSGallery -Name $moduleName
        Write-Verbose "    Published Version [$($module.version)]"

        if ($MaxVersion -lt [version]$module.Version)
        {
            Write-Verbose "  + Installing [$($module.version)]"
            $module | Install-Module @moduleInstallOptions
        }
    }
}
