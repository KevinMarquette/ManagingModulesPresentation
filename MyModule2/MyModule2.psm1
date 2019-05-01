function Get-Something2
{
    <#
    .Description
    Example function
    #>

    [cmdletbinding()]
    param ()

    process
    {
        Write-VsoError -Message "An error has occured"
    }
}