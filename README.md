# Windex

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white) ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)

Clean Windows of as much bloatware and telemetry as possible without impeding normal function.

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**
```powershell
Set-ExecutionPolicy Bypass -Scope Process # Confirm with Y or A

. ./windex.ps1 # User will be presented with an interactive menu
```