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

#Install-Module SQLServer
Import-Module SQLServer
#Install-Module ActiveDirectory
Import-Module ActiveDirectory


$sqlServerName='mowsql01'
$sqlParameters = @{'server'='mowsql01';'Database'='RDPStatistics'}

Function writeDiskInfo
{
    param($server,$startSessionDate,$currentUser,$currentUserDepartment,$currentUserGrade,$startSessionTime,$endSessionTime,$totalSessionDurationHours)
$InsertResults = @"
INSERT INTO [RDPStatistics].[dbo].[stat](Date,Person,Department,Grade,StartTime,EndTime,WorkTimeHours)
VALUES ('$($startSessionDate)','$($currentUser)','$($currentUserDepartment)','$($currentUserGrade)','$($startSessionTime)','$($endSessionTime)','$($totalSessionDurationHours)')
"@
    Invoke-sqlcmd @sqlParameters -Query $InsertResults
}

$userActivityList = @()

Get-WinEvent -ProviderName Microsoft-Windows-TerminalServices-Gateway | Where-Object { ($_.id -eq '302') -or ($_.id -eq '303') } | Where-Object {($_.TimeCreated).Date -eq ((Get-Date).AddDays(-1)).Date} | sort TimeCreated | ForEach-Object -Process {
    $sourceEventText = $_.message
    $username = $sourceEventText -replace 'The user "',$null
    $username = $username.Remove($username.IndexOf('"'),$username.LastIndexOf(".")-$username.IndexOf('"')+1)
    $username = $username.Remove(0,$username.LastIndexOf('\') + 1)
#    $currentUserDepartment = (Get-ADUser $username -Properties department).Department
#    $currentUserGrade = (Get-ADUser $username -Properties title).Title
#    $username = (Get-ADUser $username).Name
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
#    $username = $userActivityList[$index].User
    $currentUser = $userActivityList[$index].User
    
    $totalSessionDuration = 0
    $startSessionDate = $null #(Get-Date).AddDays(-1).Date
    $endSessionTime = $null
    $firstEndSessionDate = $null
    for ($index1 = $index; $index1 -le $listStringCount; $index1++) {
        if ($currentUser -eq $userActivityList[$index1].User) {
            $totalSessionDuration += $userActivityList[$index1].SessionDurationSeconds
            if ($userActivityList[$index1].EventID -eq '303') {
                if ($startSessionDate -eq $null) {
                    $startSessionDate = (Get-Date).AddDays(-1).Date
                }
                $endSessionTime = $userActivityList[$index1].Timestamp
            }
            elseif (($userActivityList[$index1].EventID -eq '302') -and ($startSessionDate -eq $null)) {
                $startSessionDate = $userActivityList[$index1].Timestamp
            }
            $userActivityList.RemoveAt($index1)
            $index1--
            $listStringCount--
        }
    }

    $currentUserDepartment = (Get-ADUser $currentUser -Properties department).Department
    $currentUserGrade = (Get-ADUser $currentUser -Properties title).Title
    if ( -not ((Get-ADUser $currentUser -Properties nameCyrillic).NameCyrillic -eq $null)) {
        $currentUser = (Get-ADUser $currentUser -Properties nameCyrillic).NameCyrillic
    }
    else {
        $currentUser = (Get-ADUser $currentUser).Name
    }

    $totalSessionDurationHours = [math]::round($totalSessionDuration/3600,2)
    $totalSessionDuration = [timespan]::fromseconds($totalSessionDuration)
    $totalSessionDurationHours = [float]$totalSessionDurationHours
#    $startSessionDate = Get-Date $startSessionDate -Format "dd.MM.yyyy"
    

    
    $startSessionTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss" $startSessionDate
    $startSessionDate = ($startSessionDate).Date
    $startSessionDate = Get-Date -Format "dd.MM.yyyy HH:mm:ss" $startSessionDate
    $endSessionTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss" $endSessionTime

    writeDiskInfo $sqlServerName $startSessionDate $currentUser $currentUserDepartment $currentUserGrade $startSessionTime $endSessionTime $totalSessionDurationHours
    $userActivityStatistics += [pscustomobject]@{Date=$startSessionDate;User=$currentUser;Department=$currentUserDepartment;Grade=$currentUserGrade;StartTime=$startSessionTime;EndTime=$endSessionTime;WorkTimeHours=$totalSessionDurationHours}
    $index--
}
