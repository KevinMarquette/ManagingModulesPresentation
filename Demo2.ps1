<#
    Using a NuGet Feed
#>
# Create folders for persistent storage
$DB = "$pwd\container\db"
$Package = "$pwd\container\package"

New-Item -Path $DB -Force -ErrorAction Ignore
New-Item -Path $Package -Force -ErrorAction Ignore


$apiKey = New-Guid
$arguments = @(
    'run'
    '--detach=true'
    '--publish 5000:80'
    '--env', "NUGET_API_KEY=$apiKey"
    #'--volume', "${DB}:/var/www/db"
    #'--volume', "${Package}:/var/www/packagefiles"
    '--name', 'nuget-server'
    'sunside/simple-nuget-server'
)

Set-Content -Path API.key -Value $apikey
Start-Process Docker -ArgumentList $arguments -Wait -NoNewWindow
# Remove container if already exists
# docker.exe rm nuget-server

<#
    Register the Repository
#>

Import-Module PowerShellGet

$uri = 'http://localhost:5000'
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
VERBOSE: Repository details, Name = 'MyNuGetRepository', Location = 'http://localhost:5000/'; IsTrusted = 'True'; IsRegistered = 'True'.
VERBOSE: Using the provider 'PowerShellGet' for searching packages.
VERBOSE: Using the specified source names : 'MyNuGetRepository'.
VERBOSE: Getting the provider object for the PackageManagement Provider 'NuGet'.
VERBOSE: The specified Location is 'http://localhost:5000/' and PackageManagementProvider is 'NuGet'.
VERBOSE: Total package yield:'0' for the specified package ''.
VERBOSE: Searching repository 'http://localhost:5000/' for ''.
VERBOSE: Total package yield:'0' for the specified package ''.
#>

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