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
Debloats Windows 10 and Windows 11 by removing and deprovisioning AppX packages from a given manifest.
.PARAMETER ManifestCategory
The category of AppX packages to remove. This is the name of the manifest file in the defs directory. Do not include the file extension.
.PARAMETER ManifestDirectory
The directory containing the manifest file. Defaults to the defs directory in the parent directory as this script.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

#Requires -RunAsAdministrator

param (
    [Parameter(Position = 0, Mandatory = $true)] [string] $ManifestCategory,
    [Parameter(Position = 1, Mandatory = $false)] [string] $ManifestDirectory = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\defs",
    [Parameter(Position = 2, Mandatory = $false)] [int] $MaxParallel = 4
)

function filterManifest {
    param (
        [Parameter(Position=0,Mandatory=$true)] $itemNames
    )
    return $itemNames `
    | Where-Object { $_ -notmatch "::" } `
    | Where-Object { $_ -notmatch "set" } `
    | Where-Object { $_ -notmatch "rem" } `
    | Where-Object { $_ -notmatch "#" } `
    | Where-Object { $_ -notmatch "^\s*$" } # blank lines/whitespace lines
}

function loadManifest {
    param (
        [Parameter(Position=0,Mandatory=$true)] [string] $ManifestUri
    )

    try {
        $itemNames = Get-Content -Path "$ManifestUri" -ErrorAction Stop
    } catch {
        throw "Failed to load AppX manifest $ManifestUri."
    }

    $itemNames = filterManifest $itemNames
    return $itemNames
}

$itemNames = loadManifest -ManifestUri "$ManifestDirectory\$ManifestCategory.txt"

$PurgePackage = {
    param (
        [Parameter(Position = 0, Mandatory = $true)] [string] $PackageName
    )
    
    # REMOVING PACKAGES
    try {
        $installed = Get-AppxPackage -AllUsers -ErrorAction Stop | Select-Object PackageFullName,Name `
        | Where-Object Name -eq $PackageName `
        | Select-Object -ExpandProperty PackageFullName
    } catch {
        throw "Failed to query installed AppX packages for $PackageName. Try a lower parallelization value?"
    }

    if ($installed) {
        try {
            Remove-AppxPackage -Verbose:$false -Package $installed -ErrorAction Stop
            Write-Verbose "Removed AppX package $PackageName."
        } catch {
            Write-Error("Failed to remove AppX package $PackageName.")
        }
        Clear-Variable installed
    }



    # DEPROVISION
    try {
        $provisioned = Get-AppxProvisionedPackage -Online -Verbose:$false -ErrorAction Stop `
        | Where-Object DisplayName -eq $PackageName `
        | Select-Object -ExpandProperty PackageName
    } catch {
        throw "Failed to query provisioned AppX packages for $PackageName. Try a lower parallelization value?"
    }

    if ($provisioned) {
        try {
            Remove-AppxProvisionedPackage -Online -Verbose:$false -PackageName $provisioned -ErrorAction Stop | Out-Null
            Write-Verbose "Deprovisioned AppX package $PackageName."
        } catch {
            Write-Error("Failed to deprovision AppX package $PackageName.")
        }
        Clear-Variable provisioned
    }
}

$RemovalJobs = @()

ForEach ($pkg in $itemNames) {
    while (@($RemovalJobs | Where-Object { $_.State -eq 'Running' }).Count -ge $MaxParallel) {
        Start-Sleep -Milliseconds 100
    }
    $RemovalJobs += Start-Job -ScriptBlock $PurgePackage -ArgumentList $pkg
}

Wait-Job -Job $RemovalJobs | Out-Null
Receive-Job -Job $RemovalJobs
Remove-Job -Job $RemovalJobs