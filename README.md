# Windex

Clean Windows of as much bloatware and telemetry as possible without impeding normal function.

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**
```powershell
# Confirm with Y or A
$priorPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy Unrestricted

# User will be presented with an interactive menu
# If presented with a security warning, press R to continue
. ./windex.ps1

# Confirm with Y or A
# Resetting your execution policy is critical to keep a secure system
Set-ExecutionPolicy $priorPolicy
```