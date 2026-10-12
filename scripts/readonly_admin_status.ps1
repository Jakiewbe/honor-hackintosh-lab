#requires -Version 5.1
<#
  Read-only status queries that need an elevated PowerShell (research/NEXT_STEPS_PLAN.md, section B).
  Run only after the user has approved this exact script. Output goes to the console only.

  Deliberately NOT used:
  - Get-BitLockerVolume: its KeyProtector objects can carry the recovery password.
  - manage-bde -protectors -get: prints recovery passwords.
  - Anything with -on/-off/-enable/-disable/-set/-delete/-create, bcdedit /set, mountvol, diskpart.
#>
$ErrorActionPreference = 'Continue'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Output 'Not elevated: open PowerShell as Administrator and run again.'; exit 1 }

Write-Output '== 1. Secure Boot (Confirm-SecureBootUEFI)'
try { Confirm-SecureBootUEFI } catch { Write-Output "error: $($_.Exception.Message)" }

Write-Output "`n== 2. BitLocker status per volume (manage-bde -status; protector TYPES only, no keys)"
& "$env:SystemRoot\System32\manage-bde.exe" -status

Write-Output "`n== 3. Windows Recovery Environment (reagentc /info)"
& "$env:SystemRoot\System32\ReAgentc.exe" /info

Write-Output "`n== 4. ESP file system and size (no mount, no drive letter assigned)"
Get-Partition -DiskNumber 0 | Where-Object GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' |
    Get-Volume | Select-Object FileSystem, FileSystemLabel, HealthStatus,
        @{n = 'SizeMiB'; e = { [math]::Round($_.Size / 1MB, 1) } },
        @{n = 'FreeMiB'; e = { [math]::Round($_.SizeRemaining / 1MB, 1) } } | Format-List

Write-Output "`n== 5. Firmware boot entries (bcdedit /enum firmware, read-only; baseline for rollback)"
& "$env:SystemRoot\System32\bcdedit.exe" /enum firmware
