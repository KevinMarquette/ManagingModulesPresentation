# Use an existing key
$apikey = Get-Content -Path API.key 

# Docker arguments
$arguments = @(
    'run'
    '--detach=true'
    '--publish 5000:80'
    '--env', "NUGET_API_KEY=$apiKey"
    '--name', 'nuget-server'
    'sunside/simple-nuget-server'
)

# Start Container
Start-Process Docker -ArgumentList $arguments -Wait -NoNewWindow

