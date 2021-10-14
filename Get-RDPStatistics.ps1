###############################################################################
#                                                                             #
# Author: Pavel Karachun                                                      #
# Email: 113asn@gmail.com                                                     #
# Company: ABU Accounting Services                                            #
# Comment:                                                                    #
# This script calculates duration of RDP-sessions via Remote Desktop Gateway. #
#                                                                             #
#                                                                             #
############################################################################### 

Install-Module SQLServer
Import-Module SQLServer
#Install-Module ActiveDirectory
Import-Module ActiveDirectory


$sqlServerName='mowsql01'
$sqlParameters = @{'server'='mowsql01';'Database'='RDPStatistics'}

Function writeDiskInfo
{
    param($server,$startSessionDate,$startSessionTime,$endSessionDate,$currentUser,$totalSessionDuration,$totalSessionDurationHours)
$InsertResults = @"
INSERT INTO [RDPStatistics].[dbo].[stats](StartDate,StartTime,EndTime,Username,WorkTime,WorkTimeHours)
VALUES ('$($startSessionDate)','$($StartSessionTime)','$($endSessionDate)','$($currentUser)','$($totalSessionDuration)','$($totalSessionDurationHours)')
"@
    Invoke-sqlcmd @sqlParameters -Query $InsertResults
}

$userActivityList = @()

Get-WinEvent -ProviderName Microsoft-Windows-TerminalServices-Gateway | Where-Object { ($_.id -eq '302') -or ($_.id -eq '303') } | Where-Object {($_.TimeCreated).Date -eq ((Get-Date).AddDays(-1)).Date} | sort TimeCreated | ForEach-Object -Process {
    $sourceEventText = $_.message
    $username = $sourceEventText -replace 'The user "',$null
    $username = $username.Remove($username.IndexOf('"'),$username.LastIndexOf(".")-$username.IndexOf('"')+1)
    $username = $username.Remove(0,$username.LastIndexOf('\') + 1)
    if ( -not ((Get-ADUser $username -Properties nameCyrillic).NameCyrillic -eq $null)) {
        $username = (Get-ADUser $username -Properties nameCyrillic).NameCyrillic
    }
    else {
        $username = (Get-ADUser $username).Name
    }
    $sessionDurationSeconds = 0

    $ip = $sourceEventText.Remove(0,$sourceEventText.IndexOf('on client computer "')+20)
    $ip = $ip.Remove($ip.IndexOf('"'),$ip.LastIndexOf(".")-$ip.IndexOf('"')+1)
    
    if ($sourceEventText -like '*resource:*') {
        $pc = $sourceEventText.Remove(0,$sourceEventText.IndexOf('resource: "')+11)
        $pc = $pc.Remove($pc.IndexOf('"'),$pc.LastIndexOf(".")-$pc.IndexOf('"')+1)
    }
    else {
        $pc = $sourceEventText.Remove(0,$sourceEventText.IndexOf('resource "')+10)
        $pc = $pc.Remove($pc.IndexOf('"'),$pc.LastIndexOf(".")-$pc.IndexOf('"')+1)
    }

    if ($sourceEventText -like '*The client session duration was*') {
        $sessionDurationSeconds = $sourceEventText.Remove(0,$sourceEventText.IndexOf('The client session duration was ')+32)
        $sessionDurationSeconds = $sessionDurationSeconds.Remove($sessionDurationSeconds.IndexOf(' seconds'),$sessionDurationSeconds.LastIndexOf('.')-$sessionDurationSeconds.IndexOf(' seconds')+1)
    }
    
    $userActivityList += [pscustomobject]@{Timestamp=$_.TimeCreated;EventID=$_.id;User=$username;IP=$ip;TargetPC=$pc;SessionDurationSeconds=$sessionDurationSeconds}
}

$userActivityStatistics = @()
$listStringCount = $userActivityList.Count-1
$userActivityList = [System.Collections.ArrayList]$userActivityList


for ($index = 0; $index -le $listStringCount; $index++) {
    $currentUser = $userActivityList[$index].User
    $totalSessionDuration = 0
    $startSessionDate = $null #(Get-Date).AddDays(-1).Date
    $endSessionDate = $null
    $firstEndSessionDate = $null
    for ($index1 = $index; $index1 -le $listStringCount; $index1++) {
        if ($currentUser -eq $userActivityList[$index1].User) {
            $totalSessionDuration += $userActivityList[$index1].SessionDurationSeconds
            if ($userActivityList[$index1].EventID -eq '303') {
                if ($startSessionDate -eq $null) {
                    $startSessionDate = (Get-Date).AddDays(-1).Date
                }
                $endSessionDate = $userActivityList[$index1].Timestamp
            }
            elseif (($userActivityList[$index1].EventID -eq '302') -and ($startSessionDate -eq $null)) {
                $startSessionDate = $userActivityList[$index1].Timestamp
            }
            $userActivityList.RemoveAt($index1)
            $index1--
            $listStringCount--
        }
    }

    $totalSessionDurationHours = [math]::round($totalSessionDuration/3600,2)
    $totalSessionDuration = [timespan]::fromseconds($totalSessionDuration)
    $totalSessionDurationHours = [float]$totalSessionDurationHours
    $startSessionTime = Get-Date $startSessionDate -Format "dd.MM.yyyy HH:mm:ss"
    $startSessionDate = (Get-Date $startSessionDate).Date
    #$endSessionDate = Get-Date $endSessionDate -Format "dd.MM.yyyy HH:mm:ss"

    writeDiskInfo $sqlServerName $startSessionDate $startSessionTime $endSessionDate $currentUser $totalSessionDuration $totalSessionDurationHours
    $userActivityStatistics += [pscustomobject]@{StartDate=$startSessionDate;StartTime=$startSessionTime;EndTime=$endSessionDate;User=$currentUser;WorkTime=$totalSessionDuration;WorkTimeHours=$totalSessionDurationHours}
    $index--
}
