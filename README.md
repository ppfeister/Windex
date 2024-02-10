# Windex

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)

Clean Windows of as much bloatware and telemetry as possible without impeding normal function.

## Available Actions

* AppX Debloat (to remove apps found on the [metro manifests](./defs/metro/))
* App Installer Debloat (to remove apps found on the [winget manifests](./defs/winget/))
* Apply Winex-recommended system tweaks (those found in the [autorun](./tweaks/autorun/) directory)
* Manually apply optional system tweaks (those found in the [optional](./tweaks/optional/) directory)

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**
```powershell
Set-ExecutionPolicy Bypass -Scope Process # Confirm with Y or A

. ./windex.ps1 # User will be presented with an interactive menu
```

## Detailed documentation

__Work in progress__

## Planned development

- [ ] Remove additional telemetry
- [ ] Create some sort of deployment pipeline for easier fetch and exec (possibly to one of the Windows package managers)
- [ ] Create some sort of executable with GUI
- [ ] Add normally-hidden tweak for the installation of hypervisor guest agents
