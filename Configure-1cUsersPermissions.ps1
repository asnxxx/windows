######################################################################################################
#                                                                                                    #
# Author: Pavel Karachun                                                                             #
# E-mail: 113asn@gmail.com                                                                           #
# Company: ABU Accounting Services                                                                   #
# Comment:                                                                                           #
# This script actualize AD Groups with active 1c Bases, sets NTFS permissions to 1c base folders.    #
# I run this script on DC. It requres module NTFS-Security,                                          #
# to install it run Install-Module NTFSSecurity | Import-Module NTFS-Security                        #
#                                                                                                    #
######################################################################################################

Install-Module NTFSSecurity
Import-Module NTFS-Security

$v8iPath = "\\abuas.ru\ibases-configs\ext"
$onecv7DatabasesPath = '\\abuas.ru\Bases\1CDB7'
$onecv8DatabasesPath = '\\abuas.ru\Bases\1CDB8'

# Очищение NTFS-разрешений. Оставляет только наследуемые разрешения.
#Get-ChildItem -Path $onecv7DatabasesPath -Recurse -Force | Clear-NTFSAccess
#Get-ChildItem -Path $onecv8DatabasesPath -Recurse -Force | Clear-NTFSAccess

Get-ChildItem $v8iPath | ForEach-Object -Process {
    $adGroupName = $null
    $adGroupName = $_.BaseName
    $adGroupName = Get-ADGroup -LDAPFilter "(SAMAccountName=$adGroupName)"
    $databasePath = $null
    $domainUsername = $null
    if ($adGroupName -eq $null) {
        echo $_.BaseName
        New-ADGroup $_.BaseName -path 'OU=ACCESS GROUPS,OU=OFFICE,DC=ABUAS,DC=RU' -GroupScope Global -PassThru –Verbose
    }
    foreach ($line in Get-Content "$v8iPath\$_")
    {
        if ($line -match 'Connect=File=')
        {
            $databasePath = $line -replace ".*=" -replace ";.*"
            $databasePath = $databasePath -replace '"', $null
            break
        }
    }
    [string]$domainUsername = "abuas\"+$_.BaseName
    
    if ($databasePath -like "*\\abuas.ru\*") {
        if ((Get-NTFSAccess $databasePath).Account.AccountName -ne $domainUsername) {
            Add-NTFSAccess -Path $databasePath -Account $domainUsername -AccessRights Modify
        }
    }
    
}