# Windex
# github.com/ppfeister/windex
#
# MAINTAINER : Paul Pfeister (github.com/ppfeister)
# 
# PURPOSE    : Eliminate much of the crapware that comes with Windows 10 and Windows 11, and disable or otherwise
#              mitigate certain baked-in telemetry items, to the greatest extent possible without breaking Windows.
#
# WARRANTY   : No warranty provided whatsoever. Use at your own risk.

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

$KnownSIDs = Get-ChildItem registry::HKEY_USERS\ `
| Select-Object -ExpandProperty Name `
| Select-String -Pattern '^HKEY_USERS\\S-1-5-21-[\d-]+?$'

foreach ($SID in $KnownSIDs) {
    if ($Undo) {
        Set-ItemProperty -Path "registry::$SID\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 1 -Type DWord -Force | Out-Null
        continue
    }
    Set-ItemProperty -Path "registry::$SID\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force | Out-Null
}

# TODO: Make this work with the skel.
#REG LOAD HKU\UserSkel "$env:SystemDrive\Users\Default\NTUSER.DAT"
#Set-ItemProperty -Path "registry::HKU\UserSkel\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
#REG UNLOAD HKU\UserSkel

Write-Host "Changes made to the active user will be reflected in the next session."