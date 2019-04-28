function Test-ModuleVersion
{
    <#
        .Synopsis
        Used to compare 2 version numbers to see if they are the same

        .Example
        Test-ModuleVersion -Primary $Primary

        .Notes
        Nuget publishes module that have a version of 1.0.0.0 as 1.0.0
        This test will account for that version change and treat them as equal.
    #>
    [cmdletbinding()]
    param(
        # Version numbers to check
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [AllowNull()]
        [version[]]
        $Source,

        # Target version to compare with
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName
        )]
        [AllowNull()]
        [version]
        $Target
    )

    end
    {
        foreach ($version in $Source)
        {
            if ( $version -eq $Target )
            {
                return $true
            }
            elseif (
                # Need to compare 1.0.0 and 1.0.0.0 as equal because nuget
                $version.Revision -le 0 -and
                $Target.Revision -le 0 -and
                $version.Major -eq $Target.Major -and
                $version.Minor -eq $Target.Minor -and
                $version.Build -eq $Target.Build
            )
            {
              return $true
            }
        }

        return $false
    }
}
