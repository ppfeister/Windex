# Windex
# https://github.com/ppfeister/windex
#
# MAINTAINER : Paul Pfeister (github.com/ppfeister)
#            :
# PURPOSE    : Eliminate much of the crapware that comes with Windows 10 and Windows 11, and disable or otherwise
#            : mitigate certain baked-in telemetry items, to the greatest extent possible without breaking Windows.
#            :
# LICENSE    : GNU General Public License v3.0 : https://github.com/ppfeister/windex/blob/master/LICENSE

<#
.SYNOPSIS
Removes the search bar for all users on the system.
.PARAMETER Undo
Revert changes made by this script. Any users with the search bar removed will have it restored.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

param (
    [Parameter(Position = 0, Mandatory = $false)] [switch] $Undo = $false
)

#Requires -RunAsAdministrator

#TODO Adapt for users that are not currently logged in, such as the method used in the Declutter Start Menu tweak

$KnownSIDs = Get-ChildItem registry::HKEY_USERS\ `
| Select-Object -ExpandProperty Name `
| Select-String -Pattern '^HKEY_USERS\\S-1-5-21-[\d-]+?$'

foreach ($SID in $KnownSIDs) {
    if ($Undo) {
        Set-ItemProperty -Path "registry::$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 1 -Type DWord -Force | Out-Null
        continue
    }
    Set-ItemProperty -Path "registry::$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 0 -Type DWord -Force | Out-Null
}

REG LOAD HKU\UserSkel "$env:SystemDrive\Users\Default\NTUSER.DAT"
Set-ItemProperty -Path "registry::HKU\UserSkel\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 0 -Type DWord -Force
REG UNLOAD HKU\UserSkel