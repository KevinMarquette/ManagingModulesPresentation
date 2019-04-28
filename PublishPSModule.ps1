[CmdletBinding()]
param
(
    [Parameter(
        Mandatory = $true,
        Position = 0
    )]
    [String]
    $Path,

    [Parameter()]
    [String]
    $APIKey = $Env:nugetapikey,

    [Parameter()]
    [String]
    $RepositoryName = "MyRepository",

    [Parameter()]
    [String]
    $URI = $env:nugetendpoint
)
"Starting PublishPSModule [$Path]"

if ( -not ( Get-PSRepository -Name $RepositoryName -ErrorAction Ignore ) )
{
   $source = @{
        Name = $RepositoryName
        SourceLocation     = $URI
        PublishLocation    = $URI
        InstallationPolicy = 'Trusted'
    }
    $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Register-PSRepository @source
}

if ( Test-Path $Path )
{
    $moduleList = Get-ChildItem -Path $path -Include *.psd1 -Recurse
    foreach ( $file in $moduleList )
    {
        $manifest = Invoke-Expression (get-content $file.FullName -raw)
        "  Module [$($file.basename)] Version [$($manifest.ModuleVersion)]"

        $find = @{
            Name = $file.basename
            RequiredVersion = $manifest.ModuleVersion
            Repository = $RepositoryName
            ErrorAction = 'Ignore'
        }
        $published = Find-Module @find | Select-Object -First 1

        if ( $published )
        {
            '    This module has already been published'
        }
        else
        {
            '   Create module cache'
            $savePSModulePath = $ENV:PSModulePath
            New-Item -Path 'ModuleCache' -ItemType Directory -ErrorAction Ignore
            $ENV:PSModulePath = Resolve-Path ModuleCache

            "    Installing dependent modules"
            foreach($requiredModule in $manifest.RequiredModules)
            {
                "      [$requiredModule]"
                # using basic names, will need to expand this if we start using versions
                Save-Module -Repository $RepositoryName -Name $requiredModule -Verbose -Path $ENV:PSModulePath
            }

            "    Testing Module"
            Remove-Module -name $file.basename -Force -ErrorAction Ignore
            Test-ModuleManifest -Path $file.fullname -Verbose

            Import-Module -Force -Name (Split-Path $file.FullName)

            "    Publishing Module [$($file.FullName)]"
            $module = @{
                Name        = Split-Path $file.FullName
                Repository  = $RepositoryName
                NuGetApiKey = $APIKey
                Force       = $true
            }
            Publish-Module @module -Verbose

            $ENV:PSModulePath = $savePSModulePath
        }
    }
}
else
{
    Write-Error "Could not find path [$Path]" -ErrorAction Stop
}
