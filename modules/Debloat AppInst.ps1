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
Debloats Windows 10 and Windows 11 by removing and deprovisioning App Installer (winget) packages from a given manifest.
.PARAMETER ManifestCategory
The category of AppX packages to remove. This is the name of the manifest file in the defs directory. Do not include the file extension.
.PARAMETER ManifestDirectory
The directory containing the manifest file. Defaults to the defs directory in the parent directory as this script.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

param (
    [Parameter(Position = 0, Mandatory = $true)] [string] $ManifestCategory,
    [Parameter(Position = 1, Mandatory = $false)] [string] $ManifestDirectory = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\defs\winget",
    [Parameter(Position = 2, Mandatory = $false)] [string] $IdentifierType = "name", # only name or id currently supported by winget
    [Parameter(Position = 3, Mandatory = $false)] [int] $MaxParallel = 4
)

function doesWingetExist {
    try {
        winget --version | Out-Null
        return $true
    } catch {
        return $false
    }
    throw "check for winget failed for some reason"
}

function installWinget {
    <# PLACEHOLDER. UNATTENDED INSTALL WORK IN PROGRESS.
    if (Get-AppxPackage -Name Microsoft.DesktopAppInstaller) {
        $currentRoot = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)"
        
        $installerRawUri = "$currentRoot\submodules\Microsoft Store Install Helper.cs"
        $installerRaw = Get-Content -Path $installerRawUri -Raw
        Add-Type -TypeDefinition $installerRaw -Language CSharp
        [UpdateHelper]::BeginSimpleUpdate()
    }

    Write-Host "Microsoft.DesktopAppInstaller is detected whatsoever. Manual installation required."
    #>
    Write-Host "The Microsoft Store will open momentarily. Please install the App Installer."
    Start-Process 'ms-windows-store://pdp?hl=en-us&gl=us&productid=9NBLGGH4NNS1'

    while ($true) {
        Start-Sleep -Seconds 5
        if (doesWingetExist -SkipInstall) {
            break
        }
    }

    return doesWingetExist
}

function prepareWinget {
    if (-not (doesWingetExist)) {
        return installWinget
    }
    return $true
}

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
        throw "Failed to load winget manifest $ManifestUri."
    }

    $itemNames = filterManifest $itemNames
    return $itemNames
}

if (-not (prepareWinget)) {
    throw "Failed to install winget. Exiting."
}

$itemNames = loadManifest -ManifestUri "$ManifestDirectory\$ManifestCategory.txt"

$PurgePackage = {
    param (
        [Parameter(Position = 0, Mandatory = $true)] [string] $PackageName,
        [Parameter(Position = 1, Mandatory = $true)] [string] $PackageScope,
        [Parameter(Position = 2, Mandatory = $true)] [string] $PackageIDType # "Name" or "ID"
    )
    
    $installed = winget list --scope $PackageScope --accept-source-agreements --disable-interactivity | Select-String -Pattern "$PackageName" | Select-Object -ExpandProperty LineNumber
    if ($installed) {
        Write-Verbose "Found $PackageName in $PackageScope scope."
        try {
            if ($PackageIDType -like "Name") {
                $out = winget uninstall --name $PackageName --scope $PackageScope --silent --disable-interactivity --force --purge --accept-source-agreements --disable-interactivity
            } elseif ($PackageIDType -like "ID") {
                $out = winget uninstall --id $PackageName --scope $PackageScope --silent --disable-interactivity --force --purge --accept-source-agreements --disable-interactivity
            }
            if ($out -eq "No installed package found matching input criteria.") {
                throw "No installed package found matching input criteria."
            }
            Write-Verbose "Removed $PackageName from $PackageScope scope."
        } catch {
            Write-Error("Failed to remove $PackageName from $PackageScope scope.")
        }
        Clear-Variable installed
    } else {
        Write-Verbose "Did not find $PackageName in $PackageScope scope."
    }
}

$RemovalJobs = @()

ForEach ($scope in @("user", "machine")) {
    ForEach ($pkg in $itemNames) {
        $JobArgs = @(
            "$pkg"
            "$scope"
            "$IdentifierType"
        )
        while (@($RemovalJobs | Where-Object { $_.State -eq 'Running' }).Count -ge $MaxParallel) {
            Start-Sleep -Milliseconds 100
        }
        $RemovalJobs += Start-Job -ScriptBlock $PurgePackage -ArgumentList $JobArgs
    }
}

Wait-Job -Job $RemovalJobs | Out-Null
Receive-Job -Job $RemovalJobs
Remove-Job -Job $RemovalJobs