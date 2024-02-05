<#
.SYNOPSIS
Removes the search bar for all users on the system.
.PARAMETER Undo
Revert changes made by this script. Any users with the search bar removed will have it restored.
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
        Set-ItemProperty -Path "registry::$SID\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 1 -Type DWord -Force
        continue
    }
    Set-ItemProperty -Path "registry::$SID\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
}

# TODO: Make this work with the skel.
#REG LOAD HKU\UserSkel "$env:SystemDrive\Users\Default\NTUSER.DAT"
#Set-ItemProperty -Path "registry::HKU\UserSkel\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
#REG UNLOAD HKU\UserSkel

Write-Host "Changes made to the active user will be reflected in the next session."