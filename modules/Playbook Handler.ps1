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
Parse yaml tweak manifests and apply them to the system.
.PARAMETER PlaybookUri
The relative or absolute path to the YAML playbook.
.PARAMETER ApplyPreferred
Defaults to false. Automatically applies Windex-preferred tweaks.
.PARAMETER Optionals
List of manually selected tweaks to apply, whether or not they are Windex-preferred.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

#Requires -RunAsAdministrator

param (
    [Parameter(Position = 0, Mandatory = $true)] [string] $PlaybookUri,
    [Parameter(Position = 1, Mandatory = $false)] [switch] $ApplyPreferred = $false,
    [Parameter(Position = 2, Mandatory = $false)] $Optionals = $null
)

$WindexRootUri = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\.."

Get-ChildItem -Path "$WindexRootUri\modules\submodules\psyaml" -Recurse | Unblock-File
#Invoke-Command { & "powershell.exe" } -NoNewScope # sometimes the current session may need to be refreshed after unblocking
Import-Module -Name "$WindexRootUri\modules\submodules\psyaml\powershell-yaml.psd1" -Verbose:$false

$tweakPlaybook = Get-Content -Path "$PlaybookUri" -Raw 
$tweaksParsed = ConvertFrom-Yaml $tweakPlaybook

Write-Verbose "Found $($tweaksParsed.Count) tweaks to apply in playbook $([io.path]::GetFileNameWithoutExtension($PlaybookUri))"

function UpdateAllUserHives {
    # HCKU/NTUSER.DAT TWEAKS APPLIED HERE
    param (
        [Parameter(Position = 0, Mandatory = $true)] [string] $Key,
        [Parameter(Position = 1, Mandatory = $true)] [string] $Subkey,
        [Parameter(Position = 2, Mandatory = $true)] [string] $Value,
        [Parameter(Position = 3, Mandatory = $true)] [string] $Type
    )

    $userProfiles = Get-ChildItem "$env:SystemDrive\Users" `
    | Where-Object { $_.PSIsContainer } `
    | Where-Object { $_.Name -ne "Public" }

    foreach ($profile in $userProfiles) {
        $ntuserPath = Join-Path $profile.FullName "NTUSER.DAT"
        $regLoadOut = Invoke-Expression 'REG LOAD "HKU\IdleUser" "$ntuserPath" 2>&1'
    
        if ($regLoadOut -match "ERROR: The process cannot access the file because it is being used by another process.") {
            continue
        }

        if (!(Test-Path "registry::HKU\IdleUser\$($Key -replace "<USERS>")")) {
            New-Item -Path "registry::HKU\IdleUser\$($Key -replace "<USERS>")" -Type $Type -Force | Out-Null
            New-ItemProperty -Path "registry::HKU\IdleUser\$($Key -replace "<USERS>")" -Name $Subkey -Type $Type -Force | Out-Null
        }
        
        Set-ItemProperty -Path "registry::HKU\IdleUser\$($Key -replace "<USERS>")" -Name $Subkey -Value $Value -Type $Type -Force -ErrorAction Continue | Out-Null
        Invoke-Expression 'reg unload "HKU\IdleUser" 2>&1' | Out-Null
    }
    
    $KnownSIDs = Get-ChildItem registry::HKEY_USERS\ `
    | Select-Object -ExpandProperty Name `
    | Select-String -Pattern '^HKEY_USERS\\S-1-5-21-[\d-]+?$'
    
    foreach ($SID in $KnownSIDs) {
        if (!(Test-Path "registry::$SID\$($Key -replace "<USERS>")")) {
            New-Item -Path "registry::$SID\$($Key -replace "<USERS>")" -Type $Type -Force | Out-Null
            New-ItemProperty -Path "registry::$SID\$($Key -replace "<USERS>")" -Name $Subkey -Type $Type -Force | Out-Null
        }
        Set-ItemProperty -Path "registry::$SID\$($Key -replace "<USERS>")" -Name $Subkey -Value $Value -Type $Type -Force -ErrorAction Continue | Out-Null
    }
}

$global:skipped = 0
$tweaksParsed | ForEach-Object {
    $tweak = $_

    if (-not (($tweak.category -eq $null -and $ApplyPreferred -eq $true) -or ($Optionals -Contains $tweak.Name))) {
        $global:skipped++
        return
    }


    Write-Verbose "$($tweak.Name)"
    $tweak.Actions | ForEach-Object {
        $action = $_

        ## REGISTRY SETTERS
        if ($action.regset -ne $null) {
            $action.subkey | ForEach-Object {
                $subkey = $_
                if ($action.regset.StartsWith("<USERS>")) {
                    # HKU/NTUSER.DAT TWEAKS APPLIED IN F(X) UpdateAllUserHives
                    UpdateAllUserHives -Key $action.regset -Subkey $subkey -Value $action.value.Split(':')[1] -Type $action.value.Split(':')[0]
                } else {
                    # HKLM TWEAKS APPLIED HERE
                    if (!(Test-Path "registry::$($action.regset)")) {
                        New-Item -Path "registry::$($action.regset)" -Type $($action.value.Split(':')[0]) -Force | Out-Null
                        New-ItemProperty -Path "registry::$($action.regset)" -Name $subkey -Type $($action.value.Split(':')[0]) -Force | Out-Null
                    }
                    Set-ItemProperty -Path "registry::$($action.regset)" -Name $subkey -Value $($action.value.Split(':')[1]) -Type $($action.value.Split(':')[0]) -Force  | Out-Null
                }
            }
        }

        ElseIf ($action.pwsh -ne $null) {
            # ARBITRARY POWERSHELL COMMANDS / SCRIPT BLOCKS
            $execblock = [scriptblock]::Create($action.pwsh)
            . $execblock
        }

        ElseIf ($action.svcset -ne $null) {
            # SET-SERVICE ACTIONS
            if ($action.svcset -eq "disabled") {
                $action.service | ForEach-Object {
                    $service = $_
                    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                        try {
                            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                        } catch {
                            Write-Error "Failed to stop or disable system service $service."
                        }
                    }
                }
            }
        }
    }
}

Write-Verbose "Skipped $skipped tweaks from playbook $([io.path]::GetFileNameWithoutExtension($PlaybookUri))"
Remove-Variable -Name skipped -Scope global

Remove-Module powershell-yaml -Verbose:$false