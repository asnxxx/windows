##################################################################################
#                                                                                #
# Author: Pavel Karachun                                                         #
# E-Mail: 113asn@gmail.com                                                       #
# Company: ABU Accounting Services                                               #
# Comment:                                                                       #
# It returns a list of tasks and its last run time from task manager.            #
#                                                                                #
##################################################################################

$lastRunTimeTaskList = @()
Get-ScheduledTask -TaskPath "\*" | where {($_.TaskName -contains "Synchronize SFTP Files") -or ($_.TaskName -contains "Get RDP Statistics") -or ($_.TaskName -contains "Get RDP Statistics NEW") -or ($_.TaskName -contains "Restart 1c agent on mow1c01") -or ($_.TaskName -contains "Archive 1c Log Files") -or ($_.TaskName -contains "Configure 1c Permissions") -or ($_.TaskName -contains "Get List of Users with Old Outlook Signature") -or ($_.TaskName -contains "Synchronize ALRUD users") -or ($_.TaskName -contains "Signature Update")} | ForEach-Object -Process {
    $taskRunTime = $(($_ | Get-ScheduledTaskInfo).LastRunTime)
    $taskStatus = $(($_ | Get-ScheduledTaskInfo).LastTaskResult)
    if ($taskstatus -eq 0) {
        $taskStatus = "Success"
    }
    else {
        $taskStatus = "Fail"
    }
    $lastRunTimeTaskList += [pscustomobject]@{TaskName=$_.TaskName;LastRunTime=$taskRunTime;TaskStatus=$taskStatus}
}
return $lastRunTimeTaskList