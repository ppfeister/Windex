# Windex

Clean Windows of as much bloatware and telemetry as possible without impeding normal function.

## Basic use

Must be ran in an **elevated** PowerShell instance. **Reboot when complete.**
```powershell
Set-ExecutionPolicy Unrestricted  # Confirm with Y or A

# User will be presented with an interactive menu
# If presented with a security warning, press R to continue (this may happen never, or a ton)
. ./windex.ps1

# After starting your new session, this step is critical to maintain a secure system.
Set-ExecutionPolicy Restricted  # Confirm with Y or A
```