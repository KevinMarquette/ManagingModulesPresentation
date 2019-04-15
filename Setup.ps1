Remove-Module posh-git -ErrorAction Ignore
function prompt()
{
    "#KM404/>"
}

# Remove loanDepot repository
# Unregister-PSRepository DevOpsPowerShell

.\Cleanup.ps1

code .\Demo1.ps1
