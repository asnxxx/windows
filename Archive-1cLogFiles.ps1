###############################################################################
#                                                                             #
# Author: Pavel Karachun                                                      #
# Email: 113asn@gmail.com                                                     #
# Company: ABU Accounting Services                                            #
# Comment:                                                                    #
# It archives 1c server log files via 7z and moves archive files to file      #
# server. You should add this script execution to task scheduler.             #
#                                                                             #
###############################################################################

$logFileDirectory = 'C:\Program Files\1cv8\srvinfo'
$logFileTempDirectory = 'C:\Program Files\1cv8\templogs'
$databaseList = @()
$firstDayofCurrentMonth = Get-Date -Day 01 -Month (Get-Date).Month -Year (Get-Date).Year

Clear-Content "$logFileTempDirectory\unassigned_id_log.txt"

Get-ChildItem $logFileDirectory -Recurse -Include "*.lgx", "*.lgp" | ForEach-Object -Process {
    $previousMonth = Get-Date $firstDayofCurrentMonth.AddMonths(-1) -Format "yyyyMM"
    $databaseId = (Get-Item $_.FullName).Directory.Parent.Name
    $databaseName = Select-String -Path 'C:\Program Files\1cv8\srvinfo\reg_1541\1CV8Clst.lst' -Pattern $databaseId
    if ( -not ($databaseName -eq $null)) {
        $databaseName = [string]$databaseName
        $firstCommaIndex = $databaseName.IndexOf(",") + 2
        $databaseName = $databaseName.Substring($firstCommaIndex)
        $secondCommaIndex = $databaseName.IndexOf(",") - 1
        $databaseName = $databaseName.Substring(0,$secondCommaIndex)
        if (( -not ($databaseName -eq $null)) -and ( -not (Test-Path "$logFileTempDirectory\$databaseName")) -and ($_.Name.IndexOf($previousMonth) -eq 0)) {
            New-Item -Path $logFileTempDirectory -Name $databaseName -ItemType Directory
            Move-Item "$_" "$logFileTempDirectory\$databaseName" -Force
            $databaseList += [PSCustomObject]@{DatabaseID=$databaseId; DatabaseName=$databaseName}
        }
        elseif (( -not ($databaseName -eq $null)) -and (Test-Path "$logFileTempDirectory\$databaseName") -and ($_.Name.IndexOf($previousMonth) -eq 0)) {
            Move-Item "$_" "$logFileTempDirectory\$databaseName" -Force
        }
    }
    else {
        echo $databaseId >> "$logFileTempDirectory\unassigned_id_log.txt"
    }
}

$databaseId = $null
$databaseName = $null
Get-ChildItem $logFileDirectory -Recurse -Include "*.lgf" | ForEach-Object -Process {
    $databaseId = (Get-Item $_.FullName).Directory.Parent.Name
    if ($databaseList.DatabaseID -contains $databaseId) {
        $currentIndex = [array]::indexof($databaseList.DatabaseID,$databaseId)
        $databaseName = $databaseList.DatabaseName[$currentIndex]
        Copy-Item $_ $logFileTempDirectory\$databaseName -Force
        $archiveDate = (Get-Date).AddMonths(-1).date
        $archiveDate = Get-Date $archiveDate -Format "yyyyMM"
        $archiveName = $archiveDate + '01' + '_1c_log_archive' + '.7z'
        $destinationFolder = '\\mowfs01\e$\1c_logs'
        & "C:\Program Files\7-Zip\7z.exe" a -t7z -mx9 "$logFileTempDirectory\$databaseName\$archiveName" "$logFileTempDirectory\$databaseName\*"
        if ( -not (Test-Path "$destinationFolder\$databaseName")) {
            New-Item -Path $destinationFolder -Name $databaseName -ItemType Directory
        }
        Move-Item "$logFileTempDirectory\$databaseName\$archiveName" "$destinationFolder\$databaseName" -Force
        Remove-Item "$logFileTempDirectory\$databaseName" -Force -Recurse
    }
}

$Error > 'C:\Program Files\Zabbix Agent\1cLogFiles.txt'
