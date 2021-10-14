##################################################################################
#                                                                                #
# Author: Pavel Karachun                                                         #
# E-Mail: 113asn@gmail.com                                                       #
# Company: ABU Accounting Services                                               #
# Comment:                                                                       #
# This script moves 1c bases to remote archive and creates *.txt log files.      #
# Some clients may request a proof of deleting his databases from our servers,   #
# so use this script if you get a request to move 1c database to archive.        #
#                                                                                #
##################################################################################

$fullPath = Read-Host 'Enter full path to database folder:'
$destinationFolder = "\\mowfs01\e$\archive\"
$shortFolderName = Split-Path $fullPath -Leaf

if (Test-Path "$destinationFolder$shortFolderName")
{
    echo "The folder with the same name is already exists at archive directory. Please, rename or delete it and try again..."
    Pause
    Exit
}
Copy-Item -Path $fullPath -Destination $destinationFolder -Recurse
if (Test-Path Remove-Log.txt)
{
Clear-Content Remove-Log.txt
}
(Get-ChildItem $fullPath).fullname | ForEach {
    $deletingTime = Get-Date -Format 'yyyyMMdd HH:mm:ss'
    echo $deletingTime" "$_" was deleted" >> Remove-Log-$shortFolderName.txt
    Remove-Item $_ -Force -Recurse
}
Remove-Item $fullPath -Recurse -Force

# Creating 7-z archive file
$deletingDate = Get-Date -Format 'yyyyMMdd'
$archiveName = $destinationFolder + $deletingDate + '_1c83_' + $shortFolderName + '_.7z'
& "C:\Program Files\7-Zip\7z.exe" a -t7z -mx9 $archiveName "$destinationFolder$shortFolderName\*"
Remove-Item "$destinationFolder$shortFolderName" -Force -Recurse
New-Item $destinationFolder$shortFolderName -ItemType Directory
Move-Item $archiveName "$destinationFolder$shortFolderName\" -Force
Move-Item Remove-Log-$shortFolderName.txt "$destinationFolder$shortFolderName\"
Add-Content -Path "\\mowfs01\e$\archive_log.txt" -Value "$deletingTime $fullPath moved to $archiveName"