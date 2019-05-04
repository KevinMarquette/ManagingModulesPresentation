$settingsPath = '.\.vscode\settings.json'
$startTime = [datetime]"2019/04/30 4:15:00PM"

$ColorMap = @(
    @{
        Name = "Demo Prep"
        Time = $startTime.AddMinutes(-10)
        Color = "#ffff66"
    },
    @{
        Name = "Start Presentation"
        Time = $startTime
        Color = "#99ff99"
    },
    @{
        Name = "Presentation"
        Time = $startTime.AddMinutes(1)
        Color = "#91acbb"
    },
    @{
        Name = "#1 Basic Repository Creation and Publishing"
        Time = $startTime.AddMinutes(5)
        Color = "#6666FF"
    },
    @{
        Name = "Basic Repository Creation and Publishing: Half way done"
        Time = $startTime.AddMinutes(8)
        Color = "#6666FF"
    },
    @{
        Name = "Basic Repository Creation and Publishing: Finish"
        Time = $startTime.AddMinutes(12)
        Color = "#DDDDFF"
    },
    @{
        Name = "#2 Using a NuGet Feed"
        Time = $startTime.AddMinutes(13)
        Color = "#33AAAA"
    },  
    @{
        Name = "#2 Using a NuGet Feed: Finish"
        Time = $startTime.AddMinutes(17)
        Color = "#AAFFFF"
    },
    @{
        Name = "#3 Publish Module Scripts"
        Time = $startTime.AddMinutes(18)
        Color = "#AA66AA"
    },
    @{
        Name = "#3 Publish Module Scripts: Finish"
        Time = $startTime.AddMinutes(23)
        Color = "#FFDDFF"
    },
    @{
        Name = "#4 Hosting public modules internally"
        Time = $startTime.AddMinutes(24)
        Color = "#99FF99"
    },
    @{
        Name = "#4 Hosting public modules internally: Finish"
        Time = $startTime.AddMinutes(27)
        Color = "#DDFFDD"
    },
    @{
        Name = "#5 System Bootstrapping"
        Time = $startTime.AddMinutes(28)
        Color = "#FFFF00"
    },
    @{
        Name = "#5 System Bootstrapping: Finished"
        Time = $startTime.AddMinutes(33)
        Color = "#FFFF99"
    },
    @{
        Name = "#6 Tips for Update-MyModule"
        Time = $startTime.AddMinutes(34)
        Color = "#FFAA00"
    },
    @{
        Name = '5 min warning: Wrap it up'
        Time = $startTime.AddMinutes(40)
        Color = "#FF6666"
    },
    @{
        Name = 'No more time: Show PPT end slide'
        Time = $startTime.AddMinutes(44)
        Color = "#FF0000"
    },
    @{
        Name = 'Done, back to default'
        Time = $startTime.AddMinutes(55)
        Color = "#91acbb"
    }
)
$index = 0
while($true)
{
    $settings = Get-Content $settingsPath | 
        ConvertFrom-JSON
    $color = $ColorMap[$index].Color
    Write-Host ''
    Write-Host ('[{0}] {1:HH:mm:ss} {2}' -f $color, (Get-Date),   $ColorMap[$index].Name) -NoNewline
    $settings.'workbench.colorCustomizations'.'statusBar.background' = $color
    $settings.'workbench.colorCustomizations'.'titleBar.activeBackground' = $color
    $settings.'workbench.colorCustomizations'.'titleBar.inactiveBackground' = $color
    $settings | ConvertTo-Json | Set-Content -Path $settingsPath -Encoding utf8
    Start-Sleep -Seconds 5

    if($ColorMap[$index + 1].Time -le (Get-Date))
    {
        $index++        
        Write-Host ''
        Write-Host ("  [{0}] Next Index [{1}]" -f $ColorMap[$index].Time, $index) -NoNewline
    }
    if($index -ge $ColorMap.Length)
    {
        break
    }
}