##################################################################################################
#                                                                                                #
# Author: Pavel Karachun                                                                         #
# E-Mail: 113asn@gmail.com                                                                       #
# Company: ABU Accounting Services                                                               #
# Comment:                                                                                       #
# This script deploys 1c configs to users. 1c confing allows to see a list of                    #
# all 1c databases the user has access to.                                                       #
# The user needs to be a member of AD groups that have same name as *.v8i configs                #
# and client company name. For example: client company "Company LLC", AD group "Company LLC",    #
# *.v8i config "Company LLC.v8i".                                                                #
# This script can starts by the current user or by other user with admin permissions remotely.   #
# In 1st case 1c config will be created with computer and username of current user.              #
# This case you can use if you deploy script via group policies.                                 #
# In 2nd case you should set computer name and user name as script attributers.                  #
# This case is for manual deploy. 1st attribute is username, 2nd is computer name.               #
# For example: .\Deploy-NewUsers.ps1 pkarachun mowts02                                           #
#                                                                                                #
##################################################################################################

# To use 1st case uncomment the strings below:
$currentUser = $env:username
$configPath = "$env:APPDATA\1C\1CEStart\1cestart.cfg"

#######################################

# To use 2nd case uncomment the strings below:
#$currentUser = $args[0]
#$hostName = $args[1]
#$configPath = "\\$hostName\c$\Users\$currentUser\AppData\Roaming\1C\1CEStart\1cestart.cfg"

########################################

$userGroups = ([ADSISEARCHER]"samaccountname=$($currentUser)").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1'
$v8iPath = "\\abuas.ru\ibases-configs\ext"

if (-Not (Test-Path -Path $configPath))
{
    New-Item $configPath -Force
}
else
{
    echo $null > $configPath
}
foreach ($groupName in $userGroups)
    {
        if (Test-Path -Path "$v8iPath\$groupName.v8i")
        {
            echo CommonInfoBases=$v8iPath\$groupName.v8i >> $configPath
        }
    
    }
echo "UseHWLicenses=1" >> $configPath