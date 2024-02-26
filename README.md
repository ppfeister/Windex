# Windex

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)

Clean Windows of as much bloatware and telemetry as possible without impeding normal function.

## Available Actions

* AppX Debloat (to remove apps found on the [metro manifests](./defs/metro/))
* App Inst Debloat (to remove apps found on the [winget manifests](./defs/winget/))
* Prune system services from autorun
* Auto apply recommended tweaks (i.e. those found in [playbooks](./defs/tweaks.yaml))
* Allow advanced users to apply a selection of additional tweaks

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**

When all modules are enabled **except** AppX OEM Debloat (which takes longer), Windex tends to have a runtime of about 3-5 minutes. The AppX OEM Debloat module is unnecessary on fresh Windows builds.
```powershell
Set-ExecutionPolicy Bypass -Scope Process # Confirm with Y or A

. ./windex.ps1 # User will be presented with an interactive menu
```

## Detailed documentation

__Work in progress__

## Planned development

- [x] Adopt playbooks for easier expansion and maintenance
- [ ] Remove additional telemetry **(in progress)**
- [ ] Create some sort of deployment pipeline for easier fetch and exec (possibly to one of the Windows package managers)
- [ ] Create some sort of executable with GUI
- [ ] Add normally-hidden tweak for the installation of hypervisor guest agents
