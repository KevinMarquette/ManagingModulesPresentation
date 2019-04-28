using namespace System.Collections.Generic

function Find-LDModule
{
    <#
        .Synopsis
        Will search the repositories for the specified module

        .Example
        Find-LDModule -Name $Name

        .Notes

    #>
    [CmdletBinding()]
    param(
        # Module Name to search for
        [Alias('ModuleName')]
        [Parameter(
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name = '*'
    )

    end
    {
        $repository = "MyRepository"

        try
        {
            #All available modules
            $allModules = @()

            # Collect and dedup modules
            $moduleList = @{}

            try
            {
                Write-Verbose "Searching internal modules"
                # silently continue because searching for an external module that is not internal will generate an error
                $findModuleSplat = @{
                    Name        = $Name
                    ErrorAction = 'SilentlyContinue'
                    Repository  = $repository
                }
                $allModules += Find-Module @findModuleSplat
            }
            catch
            {
                Write-Verbose "Could not find module [$($name -join ',')] in the internal repository [$repository] [$PSItem]"
            }

            # If we grow past 10-15 public modules, this will become slower than just find-module * and filtering with where-object.
            # The array based query is searching linearly, and takes quite awhile for each new name in the array
            try
            {
                Write-Verbose "Searching public modules"
                if ( $Name -eq '*' )
                {
                    $allModules += Get-LDPublicModuleList |
                        Find-Module -Repository 'PSGallery' -ErrorAction SilentlyContinue
                }
                else
                {
                    $allModules += Get-LDPublicModuleList |
                        Where-Object { $_.Name -in $Name } |
                        Find-Module -Repository 'PSGallery' -ErrorAction SilentlyContinue
                }
            }
            catch
            {
                Write-Warning "Could not search for modules in the public PSGalley [$PSItem]"
            }

            $moduleList += $allModules | 
                Group-Object -AsHashTable -Property Name

            $results = if ( $Name -eq '*' )
            {
                $moduleList.Values
            }
            else
            {
                # if $Name is an array, return all that match
                $moduleList[$Name]
            }

            Write-Debug "Found [$(@($results).Count)] modules"
            if ( @($results).Count -gt 1 )
            {
                $results | Where-Object {$_ -ne $null} |
                    Resolve-DependencyOrder -Key { $_.Name } -DependsOn {
                        $PSItem.Dependencies.Name
                    }
            }
            elseif ( $results )
            {
                $results
            }
            else
            {
                Write-Verbose "No modules found matching filter [$($Name -join ',')]"
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
