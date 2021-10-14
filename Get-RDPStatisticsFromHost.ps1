$remoteLogPath = "\\abuas.ru\soft\Distrib\logs\"
$remoteLogFilename = "2021-07-27T15.21.28_msavochkina_RDP_Report.csv"
$remoteLogPathFull = $remoteLogPath+$remoteLogFilename
$tempEventList = Get-Content $remoteLogPathFull
$tempEventList = $tempEventList | ConvertFrom-Csv
$tempSessionStatistics = @()
$sessionStartTime = $null

for ($index = 0; $index -lt $FilteredOutput.Count; $index++) {
    if (($tempEventList[$index].Action -eq "logon") -or ($tempEventList[$index].Action -eq "reconnection")) {
        $sessionStartTime = $tempEventList[$index].TimeCreated
        for ($index2 = $index; $index2 -le $tempEventList.Count; $index2++) {
            $sessionEndTime = $null
            if (($tempEventList[$index2].Action -eq "logoff") -or ($tempEventList[$index2].Action -eq "disconnected")) {
                $sessionDuration = New-TimeSpan -Start $tempEventList[$index].TimeCreated -End $tempEventList[$index2].Timecreated
                $sessionDate = (Get-Date $tempEventList[$index].TimeCreated).Date
                $sessionEndTime = $tempEventList[$index2].TimeCreated
                break
            }
        }
    if ($sessionEndTime -eq $null) {
        $sessionDuration = [timespan]::FromSeconds(0)
    }
    $tempSessionStatistics += [pscustomobject]@{Date=$sessionDate;User=$tempEventList[$index].User;StartTime=$sessionStartTime;EndTime=$sessionEndTime;SessionDuration=$sessionDuration}
    }
}

$sessionStatistics = @()
$tempSessionStatistics = [System.Collections.ArrayList]$tempSessionStatistics
$currentWorkTime = $null
$workTime = $null

for ($index = 0; $index -lt $tempSessionStatistics.Count; $index++) {
    $currentDate = $tempSessionStatistics[$index].Date
    $currentUser = $tempSessionStatistics[$index].User
    $currentWorkTime = $null
    $workTime = $null
    $startTime = $tempSessionStatistics[$index].StartTime
    $endTime = $null
    for ($index2 = $index; $index2 -lt $tempSessionStatistics.Count; $index2++) {
        if (($tempSessionStatistics[$index2].Date -eq $currentDate) -and ($tempSessionStatistics[$index2].User -eq $currentUser)) {
            $currentWorkTime = ($tempSessionStatistics[$index2].SessionDuration).TotalSeconds
            $currentWorkTime = [math]::round($currentWorkTime/3600,2) 
            $workTime += $currentWorkTime
            $endTime = $tempSessionStatistics[$index2].EndTime
            $tempSessionStatistics.RemoveAt($index2)
            $index2--
        }
        else {
            break
        }
    }
    $sessionStatistics += [pscustomobject]@{Date=$currentDate;User=$currentUser;StartTime=$startTime;EndTime=$endTime;SesstionDurationHours=$workTime}
    $index--
}

$SessionStatistics | ft -AutoSize > $remoteLogPath"_remoteLog.txt"

