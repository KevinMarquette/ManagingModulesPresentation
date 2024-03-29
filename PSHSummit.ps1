                                                                                           break; # F5 protection, you saw nothing
#region    #1 Basic Repository Creation and Publishing 
# 5-13
# Create our first repository



# Load commands
Import-Module 'PowerShellGet'


# Show Commands
Get-Command -Module PowerShellGet *PSRepository*
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



<# Using Register-PSRepository #>

# Works with UNC shares (using local for demo)
$networkShare = '.\FileShare'

# Create the folder for the demo
if ( -not (Test-Path -Path $networkShare))
{
    New-Item -Path $networkShare -ItemType Directory
}



# #464 Need to resolve the full path
# Issue https://github.com/PowerShell/PowerShellGet/issues/464
$networkShare = (Resolve-Path $networkShare).ProviderPath

# Register the share as a repository
$repo = @{
    Name               = 'MyRepository'
    SourceLocation     = $networkShare
    PublishLocation    = $networkShare 
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repo


# Show new repository
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

# Publish a Demo module
Get-ChildItem '.\MyModule'


$publishModuleSplat = @{
    Repository = 'MyRepository'
    Path       = '.\MyModule'
}
Publish-Module @publishModuleSplat



Find-Module -Repository 'MyRepository'
<# Output
Version Name       Repository   Description
------- ----       ----------   -----------
0.1.0   MyModule   MyRepository Demo module ...
#>

$installModuleSplat = @{
    Repository = 'MyRepository'
    Name       = 'MyModule'
    Scope      = 'CurrentUser'
    Force      = $true
}
Install-Module @installModuleSplat

# Available locally
Get-Module MyModule -ListAvailable

# Auto loads when calling a command
Get-Something


# Show contents of share
Get-ChildItem -Path $networkShare
<# Output
Directory: C:\workspace\ManagingModulesPresentation\FileShare
Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         1/14/2022 10:17 PM           5941 MyModule.0.1.0.nupkg
#>


# Using RequiredModules = @('VsoLoggingCommands')
code .\MyModule2\MyModule2.psd1



$publishModuleSplat = @{
    Repository = 'MyRepository'
    Path       = '.\MyModule2'
}
Publish-Module @publishModuleSplat -Verbose -Force
<# Output
Publish-PSArtifactUtility: PowerShellGet cannot resolve the module dependency 
'VsoLoggingCommands' of the module 'MyModule2' on the repository 'MyRepository'. 
Verify that the dependent module 'VsoLoggingCommands' is available in the repository
'MyRepository'. If this dependent module 'VsoLoggingCommands' is managed      
externally, add it to the ExternalModuleDependencies entry in the PSData      
section of the module manifest.
#>


# Fix With ExternalModuleDependencies = @('VsoLoggingCommands')



Find-Module -Repository 'MyRepository'
<# Output 
Version Name          Repository   Description
------- ----          ----------   -----------
0.1.0   MyModule      MyRepository Fake module
0.1.0   MyModule2     MyRepository A function to run a command over and over so you can watch the results
#>




# Quickly publish a locally installed module
Get-Module -Name 'Watch-Command' -ListAvailable
<# Output
ModuleType Version Name          PSEdition ExportedCommands
---------- ------- ----          --------- ----------------
Script     0.1.3   Watch-Command Desk      {Watch-Command, Watch}

#>

$publishModuleSplat = @{
    Repository      = 'MyRepository'
    Name            = 'Watch-Command'
    RequiredVersion = '0.1.3'
}
Publish-Module @publishModuleSplat


Find-Module -Repository 'MyRepository'




# Always specify repository
# #340 Allow multiple repositories to contain the same package
# https://github.com/PowerShell/PowerShellGet/issues/340

Find-Module -Name 'Watch-Command'

$installModuleSplat = @{
    Name  = 'Watch-Command'
    #Repository = 'MyRepository'
    Force = $true
}
Install-Module @installModuleSplat

<# Output Start .\replay\installWithRepository.gif
WARNING: 'Watch-Command' matched module 'Watch-Command/0.1.3' from prov
ackage:Installider: 'PowerShellGet', repository 'MyRepository'.
WARNING: 'Watch-Command' matched module 'Watch-Command/0.1.3' from prov
allPackageManagemeider: 'PowerShellGet', repository 'PSGallery'.
PackageManagement\Install-Package : Unable to install, multiple 
modules matched 'Watch-Command'. Please specify a single -Repository.  ll.
At C:\Users\kmarquette\Documents\WindowsPowerShell\Modules\PowerShellGet
\2.1.2\PSModule.psm1:9349 char:21
#>



# Set default parameter values 
$PSDefaultParameterValues["Find-Module:Repository"]    = 'MyRepository'
$PSDefaultParameterValues["Install-Module:Repository"] = 'MyRepository'
$PSDefaultParameterValues["Install-Module:Scope"]      = 'CurrentUser'


#endregion
#region    #2 Using a NuGet Feed 
# 13-18
# Repository as a service
# https://cloudsmith.com/





# We will need an api key
$apikey = Get-Content -Path API.key 
$apikey


$arguments = @(
    'run'
    '--detach=true'
    '--publish 5000:80'
    '--env', "NUGET_API_KEY=$apiKey"
    '--name', 'nuget-server'
    'sunside/simple-nuget-server'
)
Start-Process Docker -ArgumentList $arguments -Wait -NoNewWindow

# Remove container if already exists (save the demo)
# docker.exe kill nuget-server; docker.exe rm nuget-server


#Verify we are live
$uri = 'http://localhost:5000'
Invoke-WebRequest $uri | Format-Table Status*



<# Register the Repository #>

$repo = @{
    Name               = 'MyNuGetRepository'
    SourceLocation     = $uri
    PublishLocation    = $uri
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repo


Get-PSRepository -Name 'MyNuGetRepository'
<# Output
Name              InstallationPolicy SourceLocation
----              ------------------ --------------
MyNuGetRepository Trusted            http://localhost:5000/
#>


Find-Module -Repository 'MyNuGetRepository' -Verbose
<# Output
VERBOSE: Repository details, Name = 'MyNuGetRepository', 
  Location = 'http://localhost:5000/'; IsTrusted = 'True'; IsRegistered = 'True'.
VERBOSE: Using the provider 'PowerShellGet' for searching packages.
VERBOSE: Using the specified source names : 'MyNuGetRepository'.
VERBOSE: Getting the provider object for the PackageManagement Provider 'NuGet'.
VERBOSE: The specified Location is 'http://localhost:5000/' and PackageManagementProvider is 'NuGet'.
VERBOSE: Total package yield:'0' for the specified package ''.
VERBOSE: Searching repository 'http://localhost:5000/' for ''.
VERBOSE: Total package yield:'0' for the specified package ''.
#>

# recover from integrated terminal crash
# $apikey = Get-Content -Path API.key 

$publishModuleSplat = @{
    Name        = 'Watch-Command'
    Repository  = 'MyNuGetRepository'
    NuGetApiKey = $apiKey
}
Publish-Module @publishModuleSplat


Find-Module -Repository 'MyNuGetRepository'

<# output
Version Name          Repository        Description
------- ----          ----------        -----------
0.1.3   Watch-Command MyNuGetRepository A function to run a command over and over so you can watch the results
#>

Find-Module -Repository 'MyNuGetRepository' | 
    Install-Module -Force

Get-Module 'Watch-Command' -ListAvailable

#endregion



#region    #3 Publish Module Scripts 
# 18-24
# Tooling to make it happen

<# Basic publish script #>
# from BuildHelpers module
Step-ModuleVersion -Path '.\MyModule\MyModule.psd1'
# code .\updatemodule\publishsimple.ps1 

$modulePath = '.\MyModule'
$myRepository = 'MyRepository'

"Files in module output:"
Get-ChildItem $modulePath -Recurse -File |
    Select-Object -Expand FullName

"Publishing [$modulePath] to [$myRepository]"
$publishModuleSplat = @{
    Path        = $modulePath
    NuGetApiKey = $ENV:nugetapikey
    Verbose     = $true
    Force       = $true
    Repository  = $myRepository
    ErrorAction = 'Stop'
}
Publish-Module @publishModuleSplat



<# Publishing when it all goes sideways #>

# common variables
$file = Get-ChildItem '.\MyModule\MyModule.psd1'

# Use Test-ModuleManifest to pre-validate
Test-ModuleManifest -Path $file.fullname -Verbose



# Verify you can import the module
Remove-Module -Name $file.basename -Force -ErrorAction Ignore
Import-Module -Force -Name $file.DirectoryName



# Publish the folder, not the psd1
# #85 Publish-Module with -Path requires directory and 
#     cannot use path to manifest file (*.psd1) 
# https://github.com/PowerShell/PowerShellGet/issues/85
Step-ModuleVersion -Path $file.FullName
$publishOptions = @{
    NuGetApiKey = $apikey
    Repository = 'MyRepository'
}
Publish-Module -Path $file.FullName @publishOptions
Publish-Module -Path $file.DirectoryName @publishOptions



# Verify module actually published
# Resolved: #316 Publish-Module doesn't report error but fails to publish module
# https://github.com/PowerShell/PowerShellGet/issues/316
$manifest = Invoke-Expression (Get-Content $file.FullName -raw)
$manifest

$find = @{
    Name       = 'MyModule'
    Repository = 'MyRepository'
    RequiredVersion = $manifest.ModuleVersion
}
try {
    Find-Module @find -ErrorAction Stop
} catch {
    Write-Error "Newer version of module did not publish" -Verbose 
}



# Verify the API key is not blank
if ( [string]::IsNullOrEmpty( $ENV:nugetapikey))
{
    Write-Error "[nugetapikey] is not defined" -ErrorAction Stop
}

#endregion



#region    #4 Hosting public modules internally
# 24-28
Start .\replay\republish.gif

# Create download folder
New-Item -Path '.\downloads' -ItemType Directory -ErrorAction Ignore

$configPath = ".\UpdateModule\communityModules.json"
code $configPath

# download modules in config
$config = Get-Content -Path $configPath | 
    ConvertFrom-Json

foreach ( $module in $config.Modules ){
    $saveParam = @{
        Name = $module.Name
        Path = '.\downloads'
        Repository = 'PSGallery'
    }

    if ( $null -ne $module.RequiredVersion ){
        $saveParam.RequiredVersion = $module.RequiredVersion
    }

    Save-Module @saveParam
}

# Import each module
foreach( $module in $config.Modules ){
    $path = Join-Path .\downloads $module.Name
    Import-Module $path -Force
}

# Test everything
foreach($project in $config.TestOrder){
    $repo = 'https://github.com/KevinMarquette/{0}.git' -f $project
    $buildScript = '{0}\build.ps1' -f $project
    git clone $repo
    & $buildScript -Task 'DependencyTest'
}

# Publish Everything
foreach($module in $config.Modules){
    $path = '.\downloads\{0}\*\{0}.psd1' -f $module.Name

    $publishParam = @{
        Path        = Split-Path (Resolve-Path $path)
        Repository  = 'MyRepository'
        NuGetApiKey = $apiKey
        Force       = $true
    }
    Publish-Module @publishParam
}

# Show results
Find-Module -Repository MyRepository

<# Output Start .\replay\republish.gif
Version Name             Repository   Description
------- ----             ----------   -----------
4.3.1   Pester           MyRepository Pester provides a framework for running BDD style Tests…
1.1.3   Plaster          MyRepository Plaster scaffolds PowerShell projects and files.
1.18.0  PSScriptAnalyzer MyRepository PSScriptAnalyzer provides script analysis and checks fo…
#>

#endregion
#region    #5 System Bootstrapping 
# 28-34
# In the beginning there was 1.0.0.1




<#
    As administrator
    Add package provider
    Register repository
    Update PowerShellGet
#>

$repository = "MyNuGetRepository"
$uri = "http://localhost:5000"

Write-Verbose "Registering PSRepository [$repository] for with [$uri]" -Verbose
# Using job to prevent loading PackageManagement in current session
Start-Job -ScriptBlock {
    if ( -Not ( Get-PSRepository -Name $using:repository -ErrorAction Ignore ) )
    {
        "Installing Nuget PackageProvider"
        $PackageProvider = @{
            Name           = 'NuGet'
            Force          = $true
            MinimumVersion = '2.8.5.201'
        }
        $null = Install-PackageProvider @PackageProvider

        "Registering repository [$using:repository]"
        $PSRepository = @{
            Name               = $using:repository
            SourceLocation     = $using:uri
            PublishLocation    = $using:uri
            InstallationPolicy = 'Trusted'
        }
        Register-PSRepository @PSRepository
    }

    $PowerShellGet = Get-Module 'PowerShellGet' -ListAvailable | 
        Sort-Object Version -Descending | 
        Select-Object -First 1

    if ($PowerShellGet.Version -lt [version]'2.2.5')
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



<#
    Offline/Manual package provider install
    copy files from existing system
    Import-PackageProvider
#>
"$env:ProgramFiles\Program Files\PackageManagement\ProviderAssemblies"
"$env:LocalAppData\PackageManagement\ProviderAssemblies"
Import-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201



<#
    Bootstrap module management
    Have a module with a command for updating/installing
#>

$installOptions = @{
    Scope        = 'CurrentUser'
    AllowClobber = $true
    Force        = $true
}
Find-Module -Repository $repository -Name 'MyModuleManager' | 
    Install-Module @installOptions

Update-MyModule -Verbose
# Start .\replay\UpdateModule.gif

#endregion
#region    #6 Tips for Update-MyModule 
# 34-40
# What modules to update/install?



# Everything from internal repo?
$findModuleSplat = @{
    Name        = '*'
    ErrorAction = 'SilentlyContinue'
    Repository  = $repository
}
$privateModuleList = Find-Module @findModuleSplat



# Specified modules?
code '.\UpdateModule\modules.json'
$moduleListPath = '.\UpdateModule\modules.json'
$publicModuleList = (Get-Content -Path $moduleListPath -Raw |
        ConvertFrom-Json) |
    Find-Module

$allModules = @($privateModuleList) + $publicModuleList



<#
    Only update modules that need it
    Update-Module vs Install-Module

    #466 Update-Module doesn't update dependencies and is generally not good enough
    https://github.com/PowerShell/PowerShellGet/issues/466
#>
$currentModuleList = Get-Module -ListAvailable $allModules.Name

foreach ( $module in $allModules )
{
    # Get matching local modules
    $localModules = $currentModuleList | 
        Where-Object Name -eq $module.Name

    # Compare version
    if (-not $module.version -in $localModules.version)
    {
        # Please install my module
        $installOptions = @{
            Scope              = 'CurrentUser'
            AllowClobber       = $true
            SkipPublisherCheck = $true
            Force              = $true
            ErrorAction        = 'Stop'
        }
        $module | Install-Module @installOptions

    # remove/cleanup old modules
    # ...
    }
}



# Not all versions are the same
#  NuGet pack ignores nuspec versions
#  https://github.com/NuGet/Home/issues/3050
Find-Module SqlServerDsc 

<# Output Start .\replay\FindModuleVersion.gif
Version  Name         Repository       Description
-------  ----         ----------       -----------
12.4.0.0 SqlServerDsc PSGallery        Module with DSC Resources for deployment and confi…
12.4.0   SqlServerDsc DevOpsPowerShell Module with DSC Resources for deployment and confi…
#>

[version]$version = '12.4.0.0'
[version]$target = '12.4.0'

$version -eq $target
$version, $target 

# compare logic helper function
if ( $version -eq $target )
{
    return $true
}
elseif (
    # Need to compare 1.0.0 and 1.0.0.0 as equal because nuget
    $version.Revision -le 0 -and
    $Target.Revision -le 0 -and
    $version.Major -eq $target.Major -and
    $version.Minor -eq $target.Minor -and
    $version.Build -eq $target.Build
)
{
    return $true
}


# Watch those verison types
Get-Module 'Watch-Command' -ListAvailable -OutVariable local
Find-Module 'Watch-Command' -Repository 'MyRepository' -OutVariable gallery
$local.Version.GetType()    #-> [Version]
$gallery.Version.GetType()  #-> [String]

<# Output start .\replay\VersionTypes.gif
IsPublic IsSerial Name    BaseType
-------- -------- ----    --------
True     True     Version System.Object

IsPublic IsSerial Name   BaseType
-------- -------- ----   --------
True     True     String System.Object
#>



#endregion
#region    #7 Updating AZ Module 
# 40-43, cut for time if needed
# Does not play by the rules


# Fixed in PowerShell 6.2, Broken in 5.1
# Start .\replay\az.gif
Get-Module AZ -ListAvailable
Get-Module AZ* -ListAvailable

code .\UpdateModule\Update-LDAZModule.ps1

#endregion









<#END#>