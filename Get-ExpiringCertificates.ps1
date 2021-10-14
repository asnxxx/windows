###############################################################################
#                                                                             #
# Author: Pavel Karachun                                                      #
# E-mail: 113asn@gmail.com                                                    #
# Company: ABU Accounting Services                                            #
# Comment:                                                                    #
# It returns a list of expiring certificates to load it to Zabbix monitoring. #
#                                                                             #
###############################################################################


$expiringCertList = @()
$certNameList = Get-ChildItem -Path cert:\LocalMachine\My -Recurse -ExpiringInDays 30
$certNameList | ForEach-Object -Process {
    $expiringCertList += [pscustomobject]@{Name=$_.SubjectName.Name;WillExpire=$_.NotAfter.Date}
}

return $expiringCertList