# Windex

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)

Use Windex to clean Windows of as much bloat and telemetry as possible without impeding normal function. Windex was built with virtualization in mind, but we're starting to use it on workstations as well.

Windex currently has varying degrees of support for debloating AppX packages, debloating AppInst packages, pruning system services, disabling various telemetry items, and more via advanced tweaks. Windex will attempt to detect virtual environments as well, offering to install the detected hypervisor's guest tools when available (i.e. QEMU Guest Agent).

The debloat manifests are easily updated, allowing users to add or remove packages at will, and with recently added support for playbooks, users can add more advanced tweaks in just a few lines.

The general consensus is that endpoints running Windex feel snapier and are much less intrusive.

![Windex Desktop](./assets/demo/start.png)

## Basic use

> [!WARNING]
> While Windex was designed with stability and usability in mind, not everyone's environments and workflows are the same. Taking a snapshot or backup before running is considered best practice.

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**

When all modules are enabled **except** AppX OEM Debloat (which takes longer), Windex tends to have a runtime of about 3-5 minutes. The AppX OEM Debloat module is unnecessary on fresh Windows builds.
```powershell
Set-ExecutionPolicy Bypass -Scope Process # Confirm with Y or A

. ./windex.ps1 # User will be presented with an interactive menu
```

If you experience some sort of error or hangup, just restart and try again. We're working on optimization and parallelization so it's probably related to that. Reports are encouraged.

## Detailed documentation

- [Manifests and Playbooks](defs/README.md) documentation
- Further documentation in progress

## Planned development

- [x] Adopt playbooks for easier expansion and maintenance
- [ ] Remove additional telemetry **(in progress)**
- [ ] Escalate to SYSTEM or TI without triggering UAC and without psexec to disable certain protected services
- [ ] Create some sort of deployment pipeline for easier fetch and exec (possibly to one of the Windows package managers)
- [x] Add normally-hidden tweak for the installation of hypervisor guest agents **(KVM/QEMU support added!)**