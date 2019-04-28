# run on module load (in psm1)
$script:PublicModuleList = @()
$moduleListPath = "$PSScriptroot/modules.json"
if ( Test-Path -Path $moduleListPath )
{
    $script:PublicModuleList = Get-Content -Path $moduleListPath | 
        ConvertFrom-Json
}

function Get-LDPublicModuleList
{
    <#
        .Synopsis
        Gets the list of public modules
        .Example
        Get-LDPublicModuleList
        .Notes
    #>
    [cmdletbinding()]
    param()

    end
    {
        $script:PublicModuleList
    }
}


