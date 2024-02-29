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
Debloats Windows 10 and Windows 11.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

#Requires -RunAsAdministrator

New-Variable -Scope Script -Name WindexRoot -Option Constant -Value "$(Split-Path -Parent $MyInvocation.MyCommand.Path)"
New-Variable -Scope Script -Name sysenv -Option Constant -Value "$([System.Environment]::OSVersion.Platform)"
New-Variable -Scope Script -Name distrib -Option Constant -Value "$((Get-WmiObject Win32_OperatingSystem).Caption)" -ErrorAction Ignore
New-Variable -Scope Script -Name scriptBanner -Option Constant -Value @"
	
      <><><><><><><><><><><><><><><><><><><><><><><><>
    <><>                                            <><>
    <>                     Windex                     <>
    <>     Windows bloat and telemetry mitigation     <>
    <>                                                <>
    <>     https://github.com/ppfeister/windex        <>
    <><>                                            <><>
      <><><><><><><><><><><><><><><><><><><><><><><><>



"@

. "$WindexRoot\modules\Guest Tools.ps1"

    ###################
  #######################
###########################
###########################
#### Windex Setup Menu ####

$menuItem_SetVerbosity = "Verbose"
$menuItem_MetroDebloatMS = "Module : Debloat Microsoft Metro apps (i.e. Skype)"
$menuItem_MetroDebloat3P = "Module : Debloat OEM Metro apps (i.e. LinkedIn) **Slow**"
$menuItem_AutoApplyTweaks = "Tweaks : Auto-apply preferred"
$menuItem_WingetDebloat = "Module : Debloat App Installer (requires winget)"
$menuItem_ShowAdvTweaks = "Tweaks : Show advanced tweaks"

$options = @{
    $menuItem_MetroDebloatMS = $true
    $menuItem_MetroDebloat3P = $false
    $menuItem_SetVerbosity = $false
    $menuItem_AutoApplyTweaks = $true
    $menuItem_WingetDebloat = $true
    $menuItem_ShowAdvTweaks = $false
}

function hasInternet {
    return (Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet)
}

$hv_type = if ( hasInternet ) { WhichVirtualEnvironment } else { $null }
if ($null -ne $hv_type) {
    $menuItem_GuestTools = "Module : Install $hv_type guest tools"
    $options[$menuItem_GuestTools] = $true
}

function DisplayMenu {
    $selectedIndex = 0
    $optionEntries = $options.GetEnumerator() | Sort-Object Name
    $buttonLabels = @("Begin", "Cancel")
    
    # Move cursor to the top of the console window
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, 0)
    
    while ($true) {
        # Clear console window (if not in debug mode)
        if($DebugPreference -eq "SilentlyContinue") {
            Clear-Host
        }

	[console]::CursorVisible = $false

	Write-Host "$scriptBanner"
	
	$menuOptionLeftPadding = "    "
        
	# Display menu
	for ($i = 0; $i -lt $optionEntries.Count; $i++) {
            $option = $optionEntries[$i].Key
            $isSelected = $options[$option] # Get the current state directly from the $options hashtable
            if ($i -eq $selectedIndex) {
                Write-Host -ForegroundColor Yellow ("$menuOptionLeftPadding[$(if ($isSelected) {'*'} else {' '})] $($option)")
            } else {
                Write-Host ("$menuOptionLeftPadding[$(if ($isSelected) {'*'} else {' '})] $($option)")
            }
        }

	Write-Host ""


        # Display buttons for Begin and Cancel
        for ($j = 0; $j -lt $buttonLabels.Count; $j++) {
            $buttonLabel = $buttonLabels[$j]
            if ($j -eq $selectedIndex - $optionEntries.Count) {
                Write-Host -ForegroundColor Yellow ("$menuOptionLeftPadding[$($buttonLabel)]")
            } else {
                Write-Host "$menuOptionLeftPadding[$($buttonLabel)]"
            }
        }

	Write-Host ""
        
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { # Up arrow
                if ($selectedIndex -gt 0) {
                    $selectedIndex--
                }
            }
            40 { # Down arrow
                if ($selectedIndex -lt ($optionEntries.Count + $buttonLabels.Count - 1)) {
                    $selectedIndex++
                }
            }
            32 { # Spacebar
                if ($selectedIndex -eq $optionEntries.Count) {
                    return "Begin"
                } elseif ($selectedIndex -eq ($optionEntries.Count + 1)) {
                    return "Cancel"
                } else {
                    $options[$optionEntries[$selectedIndex].Key] = !$options[$optionEntries[$selectedIndex].Key]
                }
            }
            13 { # Enter
                if ($selectedIndex -eq $optionEntries.Count) {
                    return "Begin"
                } elseif ($selectedIndex -eq ($optionEntries.Count + 1)) {
                    return "Cancel"
                } else {
                    $options[$optionEntries[$selectedIndex].Key] = !$options[$optionEntries[$selectedIndex].Key]
                }
            }
        }
    }
}

#### Windex Setup Menu ####
###########################
###########################
  #######################
    ###################

if ($sysenv -ne "Win32NT") {
    Write-Host $scriptBanner
    prinErr("This script is intended to run on Windows only. Exiting.")
}

$result = DisplayMenu

# less than ideal arg handling, but it works

if ($result -eq "Cancel")   { return "User cancelled. Exiting." }
if ($result -ne "Begin")    { return "Somehow, an invalid result was returned from the menu. Exiting." }

Write-Host "Beginning cleanup..."

if ($options[$menuItem_SetVerbosity])   { $VerbosePreference = "Continue" }

# Advanced Tweak Selection Screen
if ($options[$menuItem_ShowAdvTweaks]) {
    $selectedTweaks =. "$WindexRoot\modules\submodules\Tweak Select.ps1" -PlaybookUri "$WindexRoot\defs\general.yaml" -Category "Advanced"
}

# Modules
if ($options[$menuItem_GuestTools])     { InstallAgent -hv_type $hv_type }
if ($options[$menuItem_MetroDebloatMS]) { . "$WindexRoot\modules\Debloat AppX.ps1" -ManifestDirectory "$WindexRoot\defs" -ManifestCategory "metro\microsoft" }
if ($options[$menuItem_MetroDebloat3P]) { . "$WindexRoot\modules\Debloat AppX.ps1" -ManifestDirectory "$WindexRoot\defs" -ManifestCategory "metro\thirdparty" }
if ($options[$menuItem_WingetDebloat])  { . "$WindexRoot\modules\Debloat AppInst.ps1" -ManifestDirectory "$WindexRoot\defs\winget" -ManifestCategory "generalized-by-name" }
if ($options[$menuItem_AutoApplyTweaks]){ . "$WindexRoot\modules\Legacy Tweaks.ps1" }

. "$WindexRoot\modules\Playbook Handler.ps1" -PlaybookUri "$WindexRoot\defs\general.yaml" -Optionals $selectedTweaks -ApplyPreferred:$options[$menuItem_AutoApplyTweaks]

Get-Process Explorer | Stop-Process # just for good measure

Write-Host "Reboot is recommended."