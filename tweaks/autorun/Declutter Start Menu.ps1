# Windex
# https://github.com/ppfeister/windex
#
# MAINTAINER : Paul Pfeister ( https://github.com/ppfeister : https://pfeister.dev )
#            :
# PURPOSE    : Eliminate much of the crapware that comes with Windows 10 and Windows 11, and disable or otherwise
#            : mitigate certain baked-in telemetry items, to the greatest extent possible without breaking Windows.
#            :
# LICENSE    : GNU General Public License v3.0 : https://github.com/ppfeister/windex/blob/master/LICENSE

<#
.SYNOPSIS
Declutter the Start Menu. Removes all live tiles and sets the Start Menu to a single column (viewing the All Apps list).
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
.PARAMETER Undo
Does nothing for this tweak. Enjoy. (it will still skip the tweak though)
#>

param (
    [Parameter(Position = 0, Mandatory = $false)] [switch] $Undo = $false
)

$WindexRootUri = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\.."

if ($Undo) {
    Write-Host "This tweak does not yet support undo, but it will skip"
    exit 0
}

$userProfiles = Get-ChildItem "$env:SystemDrive\Users" `
| Where-Object { $_.PSIsContainer } `
| Where-Object { $_.Name -ne "Public" } `
| Where-Object { $_.Name -ne "Default" }

Write-Verbose "Users found for Start Menu override: $($userProfiles.Name -join ', ')"

##### Apply Template

$layoutSourceUri = "$WindexRootUri\defs\markup\Start Menu Layout Override.xml"

# Applies templace to default
Import-StartLayout -LayoutPath "$layoutSourceUri" -MountPath "$env:SystemDrive\"

# Applies template to each existing user
foreach ($profile in $userProfiles) {
    $ntuserPath = $profile.FullName
    Write-Verbose "Copying Start Menu override to $($profile.Name)"
    Copy-Item -Path "$layoutSourceUri" -Destination "$ntuserPath\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Force
}


##### Cache Reg Key Removal

$regKey = 'Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\*$start.tilegrid$windows.data.curatedtilecollection.tilecollection'

foreach ($profile in $userProfiles) {
    $ntuserPath = Join-Path $profile.FullName "NTUSER.DAT"

    $regLoadOut = Invoke-Expression 'REG LOAD "HKU\IdleUser" "$ntuserPath" 2>&1'

    if ($regLoadOut -match "ERROR: The process cannot access the file because it is being used by another process.") {
        continue
    }

    if (Test-Path "HKU\IdleUser\$regKey") {
        Remove-Item "registry::HKU\IdleUser\$regKey"  -Force -Recurse -Verbose:$true
        Write-Verbose "Registry key deleted to reset $($profile.Name)'s Start Menu cache."
    } else {
        Write-Verbose "Registry key not found for $($profile.Name). Their cache may not exist. Skipping."
    }
    Invoke-Expression 'reg unload "HKU\IdleUser" 2>&1' | Out-Null
}

$KnownSIDs = Get-ChildItem registry::HKEY_USERS\ `
| Select-Object -ExpandProperty Name `
| Select-String -Pattern '^HKEY_USERS\\S-1-5-21-[\d-]+?$'

foreach ($SID in $KnownSIDs) {
    try {
        Write-Verbose "Removing Start Layout cache from SID $(($SID -split '\\')[1])"
        Remove-Item "registry::$SID\$regKey" -Recurse -Force
    } catch {
        Write-Error "Failed to remove Start Layout cache from $SID"
    }
}

####             ####
##  Clean up menu  ##
####             ####

$globalStartMenuPaths = @(
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\System Tools',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Math Input Panel',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Quick Assist',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Steps Recorder',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessibility',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Maintenance',
    'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Settings'
)

$typicalUserStartMenuPaths = @(
    'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Maintenance',
    'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup',
    'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories',
    'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility'
)

foreach ($path in $globalStartMenuPaths) {
        Remove-Item -Path "$path" -Force -Recurse -ErrorAction SilentlyContinue
}

foreach ($path in $typicalUserStartMenuPaths) {
    Remove-Item -Path "$path" -Force -Recurse -ErrorAction SilentlyContinue # for default profile first
    foreach ($profile in $userProfiles) {
        $path.replace("Default", $profile.Name) | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }    
}

#### Finish ####

Write-Verbose "Restarting Explorer to rebuild current user's Start Layout cache"
Get-Process Explorer | Stop-Process