<#
.SYNOPSIS
Replace the wallpaper for all user profiles on the system.
.DESCRIPTION
Replaces the current wallpaper for all existing and future users without tampering with the TrustedInstaller-protected defaults in %SystemRoot%\Web\Wallpaper.
.PARAMETER WindexRoot
The absolute or relative path to the Windex directory. Defaults to "..\..\".
.PARAMETER SourceUri
The absolute or relative path to the wallpaper image file you want to make the default.
.PARAMETER StoredDir
The absolute or relative path to the directory where you want the wallpaper to be stored. This must be a directory that all users have read access to. Defaults to "%SystemRoot%\Windex\Wallpapers\".
.PARAMETER Undo
Revert changes made by this script. Any users with their wallpaper set to $StoredUri will have their wallpaper set to the default Windows wallpaper.
#>
#Requires -RunAsAdministrator

param (
    [Parameter(Position = 0, Mandatory = $false)] [string] $SourceUri = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\assets\Wallpaper_00.jpg",
    [Parameter(Position = 1, Mandatory = $false)] [string] $StoredUri = "$env:SystemRoot\Windex\Wallpapers\Wallpaper_00.jpg",
    [Parameter(Position = 2, Mandatory = $false)] [switch] $Undo = $false
)

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
    Set-ItemProperty -Path "registry::$SID\Control Panel\Desktop\" -Name Wallpaper -Value $StoredUri
}

# This value is typically replaced by the default theme, but we'll set it here just in case.
REG LOAD HKU\UserSkel "$env:SystemDrive\Users\Default\NTUSER.DAT"
Set-ItemProperty -Path "registry::HKU\UserSkel\Control Panel\Desktop\" -Name Wallpaper -Value $StoredUri
REG UNLOAD HKU\UserSkel

# Changing the wallpaper used by the default aero theme
takeown /f $env:SystemRoot\Resources\Themes\aero.theme
icacls --% %SystemRoot%\Resources\Themes\aero.theme /grant "Administrators":m
if ($Undo){
    (Get-Content $env:SystemRoot\Resources\Themes\aero.theme).Replace('\Windex\Wallpapers\Wallpaper_00.jpg', '\web\wallpaper\Windows\img0.jpg') `
    | Set-Content $env:SystemRoot\Resources\Themes\aero.theme
} else {
    (Get-Content $env:SystemRoot\Resources\Themes\aero.theme).Replace('\web\wallpaper\Windows\img0.jpg', '\Windex\Wallpapers\Wallpaper_00.jpg') `
    | Set-Content $env:SystemRoot\Resources\Themes\aero.theme
}
icacls --% %SystemRoot%\Resources\Themes\aero.theme /setowner "NT SERVICE\TrustedInstaller"
icacls --% %SystemRoot%\Resources\Themes\aero.theme /grant:r "Administrators":rx

Write-Host "Changes made to the active user will be reflected in the next session."