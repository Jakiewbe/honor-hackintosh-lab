# H1 S1: wipe the approved USB stick and create one FAT32 partition for OpenCore + macOS recovery.
# Must be run elevated. Refuses to touch anything that does not match every expected property.
param(
    [int]$DiskNumber = 1,
    [string]$ExpectedName = 'KIOXIA TransMemory',
    [long]$ExpectedSize = 30979129344,
    [string]$Label = 'OCINSTALL'
)
$ErrorActionPreference = 'Stop'
Start-Transcript -Path (Join-Path $env:TEMP 'hk-h1-s1-prepare-usb.log') -Append | Out-Null

$d = Get-Disk -Number $DiskNumber
$checks = [ordered]@{
    'not disk 0'       = ($d.Number -ne 0)
    'BusType USB'      = ($d.BusType -eq 'USB')
    'name matches'     = ($d.FriendlyName -eq $ExpectedName)
    'size matches'     = ($d.Size -eq $ExpectedSize)
    'not boot disk'    = (-not $d.IsBoot)
    'not system disk'  = (-not $d.IsSystem)
    'online, writable' = ((-not $d.IsOffline) -and (-not $d.IsReadOnly))
}
$checks.GetEnumerator() | ForEach-Object { '{0,-18} {1}' -f $_.Key, $_.Value }
if ($checks.Values -contains $false) { throw 'Safety check failed; nothing was changed.' }

$boot = Get-Disk | Where-Object { $_.IsBoot -or $_.IsSystem }
if ($boot.Number -contains $DiskNumber) { throw 'Target is a boot/system disk; nothing was changed.' }

if ((Get-Partition -DiskNumber $DiskNumber -ErrorAction SilentlyContinue).Count -gt 0) {
    Clear-Disk -Number $DiskNumber -RemoveData -RemoveOEM -Confirm:$false
}
switch ((Get-Disk -Number $DiskNumber).PartitionStyle) {
    'RAW' { Initialize-Disk -Number $DiskNumber -PartitionStyle GPT }
    'MBR' { Set-Disk -Number $DiskNumber -PartitionStyle GPT }
    'GPT' { }
}
$p = New-Partition -DiskNumber $DiskNumber -Size 16GB -AssignDriveLetter
Format-Volume -Partition $p -FileSystem FAT32 -NewFileSystemLabel $Label -Confirm:$false | Out-Null

Get-Disk -Number $DiskNumber | Select-Object Number, FriendlyName, BusType, PartitionStyle | Format-List
Get-Partition -DiskNumber $DiskNumber | Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, Size | Format-List
Stop-Transcript | Out-Null
Read-Host 'Done. Press Enter to close'
