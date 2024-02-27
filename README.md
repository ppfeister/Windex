# Windex

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)

Use Windex to clean Windows of as much bloat and telemetry as possible without impeding normal function. Windex was built with virtualization in mind, but we're starting to use it on workstations as well.

> [!IMPORTANT]
> While Windex was designed with stability and usability in mind, caution should still be exercised outside of virtual environments. It's recommended that you read through the manifests and playbooks to understand what changes are being made.

## Available Actions

* AppX Debloat (to remove apps found on the [metro manifests](./defs/metro/))
* App Inst Debloat (to remove apps found on the [winget manifests](./defs/winget/))
* Prune system services from autorun
* Auto apply recommended tweaks (i.e. those found in [playbooks](./defs/general.yaml))
* Allow advanced users to apply a selection of additional tweaks

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**

When all modules are enabled **except** AppX OEM Debloat (which takes longer), Windex tends to have a runtime of about 3-5 minutes. The AppX OEM Debloat module is unnecessary on fresh Windows builds.
```powershell
Set-ExecutionPolicy Bypass -Scope Process # Confirm with Y or A

. ./windex.ps1 # User will be presented with an interactive menu
```

## Detailed documentation

- [Manifests and Playbooks](defs/README.md) documentation
- Further documentation in progress

## Planned development

- [x] Adopt playbooks for easier expansion and maintenance
- [ ] Remove additional telemetry **(in progress)**
- [ ] Create some sort of deployment pipeline for easier fetch and exec (possibly to one of the Windows package managers)
- [ ] Add normally-hidden tweak for the installation of hypervisor guest agents
