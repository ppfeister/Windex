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

$packages = @(
    'Browser.InternetExplorer~~~~0.0.11.0'
    'Microsoft.Windows.MSPaint~~~~0.0.1.0'
    'App.StepsRecorder~~~~0.0.1.0'
    'MathRecognizer~~~~0.0.1.0'
    'Microsoft.Windows.WordPad~~~~0.0.1.0' # nobody uses wordpad anymore
    'OneCoreUAP.OneSync~~~~0.0.1.0' # EXPERIMENTAL - Supposed to handle syncing for things like contacts, email, etc.
    'App.Support.QuickAssist~~~~0.0.1.0'
    'Print.Fax.Scan~~~~0.0.1.0' # EXPERIMENTAL - Monitor for issues with the print service
)

if ($Undo) {
    ForEach ($package in $packages) {
        Add-WindowsCapability -Name $package -Online -ErrorAction Continue
    }
    return 0
}

ForEach ($package in $packages) {
    Remove-WindowsCapability -Name $package -Online -ErrorAction Continue
}
return 0