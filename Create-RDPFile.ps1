#################################################
#                                               #
# Author: Pavel Karachun                        #
# E-Mail: 113asn@gmail.com                      #
# Company: ABU Accounting Services              #
# Comment:                                      #
# It creates an RDP-file with options below.    #
#                                               #
#################################################


# Enter username in format "pkarachun"
#$user = "pkarachun"

# 2nd case to set username. For manual use.
$user = Read-Host "Введите имя пользователя без указания домена. Например: pkarachun"
$remoteComputer = "abu0096"
$gateway = "rgts.abuas.ru"
$domain = "abuas.ru"
$rdpFileName = $user + ".rdp"

echo $null > $rdpFileName
echo "screen mode id:i:2" >> $rdpFileName
echo "use multimon:i:0" >> $rdpFileName
echo "desktopwidth:i:1920" >> $rdpFileName
echo "desktopheight:i:1080" >> $rdpFileName
echo "session bpp:i:32" >> $rdpFileName
echo "winposstr:s:0,1,0,0,848,717" >> $rdpFileName
echo "compression:i:1" >> $rdpFileName
echo "keyboardhook:i:2" >> $rdpFileName
echo "audiocapturemode:i:0" >> $rdpFileName
echo "videoplaybackmode:i:1" >> $rdpFileName
echo "connection type:i:7" >> $rdpFileName
echo "networkautodetect:i:1" >> $rdpFileName
echo "bandwidthautodetect:i:1" >> $rdpFileName
echo "displayconnectionbar:i:1" >> $rdpFileName
echo "enableworkspacereconnect:i:0" >> $rdpFileName
echo "disable wallpaper:i:0" >> $rdpFileName
echo "allow font smoothing:i:0" >> $rdpFileName
echo "allow desktop composition:i:0" >> $rdpFileName
echo "disable full window drag:i:1" >> $rdpFileName
echo "disable menu anims:i:1" >> $rdpFileName
echo "disable themes:i:0" >> $rdpFileName
echo "disable cursor setting:i:0" >> $rdpFileName
echo "bitmapcachepersistenable:i:1" >> $rdpFileName
echo "full address:s:$remoteComputer" >> $rdpFileName
echo "audiomode:i:0" >> $rdpFileName
echo "redirectprinters:i:1" >> $rdpFileName
echo "redirectcomports:i:0" >> $rdpFileName
echo "redirectsmartcards:i:1" >> $rdpFileName
echo "redirectclipboard:i:1" >> $rdpFileName
echo "redirectposdevices:i:0" >> $rdpFileName
echo "autoreconnection enabled:i:1" >> $rdpFileName
echo "authentication level:i:2" >> $rdpFileName
echo "prompt for credentials:i:1" >> $rdpFileName
echo "negotiate security layer:i:1" >> $rdpFileName
echo "remoteapplicationmode:i:0" >> $rdpFileName
echo "alternate shell:s:" >> $rdpFileName
echo "shell working directory:s:" >> $rdpFileName
echo "gatewayhostname:s:$gateway" >> $rdpFileName
echo "gatewayusagemethod:i:2" >> $rdpFileName
echo "gatewaycredentialssource:i:4" >> $rdpFileName
echo "gatewayprofileusagemethod:i:1" >> $rdpFileName
echo "promptcredentialonce:i:1" >> $rdpFileName
echo "gatewaybrokeringtype:i:0" >> $rdpFileName
echo "use redirection server name:i:0" >> $rdpFileName
echo "rdgiskdcproxy:i:0" >> $rdpFileName
echo "kdcproxyname:s:" >> $rdpFileName
echo "username:s:$user@$domain" >> $rdpFileName