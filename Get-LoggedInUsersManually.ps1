<#Param(
    [array]$ServersToQuery = (hostname),
    [datetime]$StartTime = "January 1, 1970"
)
#>
#    foreach ($Server in $ServersToQuery) {
$server = "abu0096"

        $LogFilter = @{
            LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
            ID = 21, 23, 24, 25
            StartTime = $StartTime
            }

        $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

        $AllEntries | Foreach { 
            $entry = [xml]$_.ToXml()
            [array]$Output += New-Object PSObject -Property @{
                TimeCreated = $_.TimeCreated
                User = $entry.Event.UserData.EventXML.User
                IPAddress = $entry.Event.UserData.EventXML.Address
                EventID = $entry.Event.System.EventID
                ServerName = $Server
                }        
            } 

#    }

    $FilteredOutput += $Output | Select TimeCreated, User, ServerName, IPAddress, @{Name='Action';Expression={
                if ($_.EventID -eq '21'){"logon"}
                if ($_.EventID -eq '22'){"Shell start"}
                if ($_.EventID -eq '23'){"logoff"}
                if ($_.EventID -eq '24'){"disconnected"}
                if ($_.EventID -eq '25'){"reconnection"}
                }
            }

    $Date = Get-Date -Format "yyyyMMdd"
    $FilePath = "\\abuas.ru\soft\distrib\logs\$Date`_$server`_RDP_Report.csv"
    $FilteredOutput | Sort TimeCreated | Export-Csv $FilePath -NoTypeInformation

Write-host "Writing File: $FilePath" -ForegroundColor Cyan
Write-host "Done!" -ForegroundColor Cyan
