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
Replace the wallpaper for all user profiles on the system.
.DESCRIPTION
Replaces the current wallpaper for all existing and future users without tampering with the TrustedInstaller-protected defaults in %SystemRoot%\Web\Wallpaper.
.PARAMETER Undo
Revert changes made by this script. Any users with their wallpaper set to $StoredUri will have their wallpaper set to the default Windows wallpaper.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>
#Requires -RunAsAdministrator

param (
    [Parameter(Position = 0, Mandatory = $false)] [switch] $Undo = $false
)

$SourceUri = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\..\assets\Wallpapers\"
$StoredUri = "$env:SystemRoot\Windex\Wallpapers\"
$WallpaperToUse = "Wallpaper_01.jpg"


New-Item -ItemType Directory -Path (Split-Path -Path $StoredUri -Parent) -Force -ErrorAction Stop | Out-Null
Copy-Item -Path $SourceUri -Destination $StoredUri -Recurse -ErrorAction Stop | Out-Null

$KnownSIDs = Get-ChildItem registry::HKEY_USERS\ `
| Select-Object -ExpandProperty Name `
| Select-String -Pattern '^HKEY_USERS\\S-1-5-21-[\d-]+?$'

foreach ($SID in $KnownSIDs) {
    if ($Undo) {
        Set-ItemProperty -Path "registry::$SID\Control Panel\Desktop\" -Name Wallpaper -Value "$env:SystemRoot\Web\Wallpaper\Windows\img0.jpg"
        continue
    }
    Set-ItemProperty -Path "registry::$SID\Control Panel\Desktop\" -Name Wallpaper -Value "$StoredUri\$WallpaperToUse"
}

# This value is typically replaced by the default theme, but we'll set it here just in case.
REG LOAD HKU\UserSkel "$env:SystemDrive\Users\Default\NTUSER.DAT"
Set-ItemProperty -Path "registry::HKU\UserSkel\Control Panel\Desktop\" -Name Wallpaper -Value "$StoredUri\$WallpaperToUse"
REG UNLOAD HKU\UserSkel

# Changing the wallpaper used by the default aero theme
takeown /f $env:SystemRoot\Resources\Themes\aero.theme
icacls --% %SystemRoot%\Resources\Themes\aero.theme /grant "Administrators":m
if ($Undo){
    (Get-Content $env:SystemRoot\Resources\Themes\aero.theme).Replace("\Windex\Wallpapers\$WallpaperToUse", '\web\wallpaper\Windows\img0.jpg') `
    | Set-Content $env:SystemRoot\Resources\Themes\aero.theme
} else {
    (Get-Content $env:SystemRoot\Resources\Themes\aero.theme).Replace('\web\wallpaper\Windows\img0.jpg', "\Windex\Wallpapers\$WallpaperToUse") `
    | Set-Content $env:SystemRoot\Resources\Themes\aero.theme
}
icacls --% %SystemRoot%\Resources\Themes\aero.theme /setowner "NT SERVICE\TrustedInstaller"
icacls --% %SystemRoot%\Resources\Themes\aero.theme /grant:r "Administrators":rx

Write-Host "Changes made to the active user will be reflected in the next session."