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
If a virtual environment is detected, this module will attempt to install the correct guest tools.
.LINK
Official repository: https://github.com/ppfeister/Windex
.LINK
Latest release: https://github.com/ppfeister/Windex/releases/latest
#>

#Requires -RunAsAdministrator

if (-not (Test-Path variable:WindexRoot)) {
    $WindexRoot = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\.."
}

function WhichVirtualEnvironment {
    <#
    .SYNOPSIS
    Attempt to detect which hypervisor the virtual machine is running on. Returns $null if no known hypervisor is detected.
    Values returned here can be passed to InstallAgent.
    #>
    if (Get-WmiObject Win32_PnPEntity | Where-Object {$_.Description -like "*QEMU*"}) { return "KVM/QEMU" }
    return $null
}

function InstallAgent {
    <#
    .SYNOPSIS
    Passively install the guest agent for your hypervisor of choice.
    .PARAMETER hv_type
    The hypervisor type to install the guest agent for.
    When no value is provided, Windex will attempt to automatically identify the hypervisor. When a value is provided, Windex will attempt to verify the hypervisor.
    Currently supported values: "KVM/QEMU"
    #>
    param (
        [Parameter(Position = 0, Mandatory = $false)] [string] $hv_type = $null
    )

    # permalinks for guest tool installers -- stable preferred over latest
    $virtioUri = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-guest-tools.exe"

    if ($hv_type -eq $null) { $hv_type = WhichVirtualEnvironment }
    elseif ($hv_type -ne "$(WhichVirtualEnvironment)") { return "Hypervisor discrepancy. Skipping." }

    if ($hv_type -eq "KVM/QEMU") {
        # Qemu Guest Agent
        if (Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%QEMU Guest Agent%'" | Select-Object Name, Version) {
            Write-Verbose "QEMU Guest Agent already installed."
        } else {
            Write-Verbose "Installing QEMU Guest Agent..."
            New-Item -Path "$WindexRoot" -Name "remote-bin" -ItemType "directory" -Force | Out-Null
            Invoke-WebRequest -Uri $virtioUri -OutFile "$WindexRoot\remote-bin\virtio-win-guest-tools.exe" -Verbose:$false | Out-Null
            Start-Process -FilePath "$WindexRoot\remote-bin\virtio-win-guest-tools.exe" -ArgumentList "-install -passive -quiet -norestart" -Wait
            Write-Verbose "QEMU Guest Agent installed."
        }
    }
}

<# Problematic currently.

if ($MyInvocation.InvocationName -eq $null) { return } # early return if not interactive

$hv_type = WhichVirtualEnvironment

if ($hv_type -eq $null) {
    Write-Host "No known hypervisor detected."
    Write-Host "If you're running in a yet-to-be-supported hypervisor, you should let us know on GitHub."
    Write-Host "https://github.com/ppfeister/Windex/issues/new"
    return
}

$confirmation = Read-Host "$hv_type detected. Would you like to install the guest tools for this hypervisor? [Y/n]"
if (-not ($confirmation -eq "N" -or $confirmation -eq "n")) {
    Install-Agent -hv_type $hv_type
    Write-Host "$hv_type guest tools installed. Restart is recommended."
}

#>