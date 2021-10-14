$remoteLogPath = "\\abuas.ru\SYSVOL\abuas.ru\scripts\SignatureSetLog.csv"
$remoteLog = Get-Content $remoteLogPath
$tempLog = @()
$tempLog += $remoteLog[0]
$tempLog += $remoteLog[1]

for ($index = 2; $index -lt $remoteLog.Count; $index++) {
    if (($remoteLog[$index] -ne $remoteLog[0]) -and ($remoteLog[$index] -ne $remoteLog[1])) {
        $tempLog += $remoteLog[$index]
    }
}

$tempLog = $tempLog | ConvertFrom-Csv
[System.Collections.ArrayList]$fullUserList = Get-ADGroupMember "ABU Everybody"
$CompanyName = 'abuas'
$DomainName = 'abuas.ru'
$tempLog1 = @()

for ($index = 0; $index -le $tempLog.Count; $index++) {
    $removableIndex = 0
    if ($tempLog[$index].SignatureType -eq "MSK_Mobile") {
        $SigSource = "\\$DomainName\netlogon\sig_files\Mobile_MSK\$CompanyName"
        $RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.doc'
        $signatureVersionOfFile = (Get-ChildItem $RemoteSignaturePathFull).LastWriteTime
    }
    elseif ($tempLog[$index].SignatureType -eq "MSK") {
        $SigSource = "\\$DomainName\netlogon\sig_files\MSK\$CompanyName"
        $RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.doc'
        $signatureVersionOfFile = (Get-ChildItem $RemoteSignaturePathFull).LastWriteTime
    }
    elseif ($tempLog[$index].SignatureType -eq "SPB_Mobile") {
        $SigSource = "\\$DomainName\netlogon\sig_files\Mobile_SPB\$CompanyName"
        $RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.doc'
        $signatureVersionOfFile = (Get-ChildItem $RemoteSignaturePathFull).LastWriteTime
    }
    elseif ($tempLog[$index].SignatureType -eq "SPB") {
        $SigSource = "\\$DomainName\netlogon\sig_files\SPB\$CompanyName"
        $RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.doc'
        $signatureVersionOfFile = (Get-ChildItem $RemoteSignaturePathFull).LastWriteTime
    }
    elseif ($tempLog[$index].SignatureType -eq "MSK_Mobile_Legal") {
        $SigSource = "\\$DomainName\netlogon\sig_files\Mobile_MSK_Legal\$CompanyName"
        $RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.doc'
        $signatureVersionOfFile = (Get-ChildItem $RemoteSignaturePathFull).LastWriteTime
    }
    if (($fullUserList.SamAccountName -contains $tempLog[$index].User) -and ($tempLog[$index].SignatureVersion -eq $signatureVersionOfFile)) {
        for ($index2 = 0; $index2 -le $fullUserList.Count; $index2++) {
        #echo $fullUserList[$index2].SamAccountName $tempLog[$index2].SignatureVersion $signatureVersionOfFile
            if ($fullUserList[$index2].SamAccountName -eq $tempLog[$index].User) {
                $removableIndex = $index2
                $tempLog1 += $tempLog[$index]
                break
            }
        }
        $fullUserList.RemoveAt($removableIndex)
        $index2--
    }
}

$exceptionUserList = @('tempuser';'makopyan';'ykatronova';'ykopysova')
$index2 = $fullUserList.Count

for ($index=0; $index -lt $index2; $index++) {
    if ($exceptionUserList -contains $fullUserList[$index].SamAccountName) {
        $fullUserList.RemoveAt($index)
        $index2--
        $index--
    }

}

$tempLog1 | ConvertTo-Csv > $remoteLogPath

if ( $fullUserList.Count -eq 0 ) {
    Set-Content $null -Path "\\abuas.ru\SYSVOL\abuas.ru\scripts\SignatureSetLog.txt"
}

return $fullUserList | Sort-Object name | ft name -AutoSize -HideTableHeaders