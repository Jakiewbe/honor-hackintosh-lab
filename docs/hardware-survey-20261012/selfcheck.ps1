#requires -Version 5.1
<#
  Self-check for the read-only survey output.
  - Consistency: hardware.json vs evidence vs REPORT.md.
  - Unknowns: fields that must stay null are null and REPORT.md marks them as unknown / needs confirmation.
  - Leak scan: sensitive identifiers are read into memory ONLY to be searched for in the output files.
    They are never written; results contain category names, file names and hit counts only.
  - EDID: share copies are compared byte-wise with the registry values in memory; only offsets are reported.
  - Boundary: static scan of the scripts for state-changing commands.
  Writes evidence/selfcheck.json. Exit code 0 = all checks passed.
#>
param([Parameter(Mandatory = $true)][string]$OutDir)
$ErrorActionPreference = 'Stop'
$Evidence = Join-Path $OutDir 'evidence'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$results = New-Object System.Collections.ArrayList
function Add-Check([string]$id, [bool]$pass, [string]$detail) { [void]$results.Add([ordered]@{ check = $id; pass = $pass; detail = $detail }) }
function Load([string]$id) { return (Get-Content -LiteralPath (Join-Path $Evidence "$id.json") -Raw -Encoding UTF8 | ConvertFrom-Json) }

$h = $null
try { $h = Get-Content -LiteralPath (Join-Path $OutDir 'hardware.json') -Raw -Encoding UTF8 | ConvertFrom-Json; Add-Check 'hardware_json_parses' $true 'ok' } catch { Add-Check 'hardware_json_parses' $false $_.Exception.Message }
$report = ''
if (Test-Path -LiteralPath (Join-Path $OutDir 'REPORT.md')) { $report = Get-Content -LiteralPath (Join-Path $OutDir 'REPORT.md') -Raw -Encoding UTF8; Add-Check 'report_exists' $true 'ok' } else { Add-Check 'report_exists' $false 'REPORT.md missing' }
$idx = Load '_index'

# ---------- 1. hardware.json vs evidence
$p02 = Load 'P02_system'; $p03 = Load 'P03_cpu'; $p12 = Load 'P12_d3dkmt_adapters'; $p13 = Load 'P13_displayconfig_active'; $p17 = Load 'P17_edid'; $p19 = Load 'P19_nvidia_smi'; $p30 = Load 'P30_disks'; $p31 = Load 'P31_partitions'
$pairs = @(
    @('model', $h.platform.system_model, $p02.data.computer_system.Model),
    @('baseboard', $h.platform.baseboard_product, $p02.data.baseboard.Product),
    @('bios_version', $h.platform.bios_version, $p02.data.bios.SMBIOSBIOSVersion),
    @('bios_date', $h.platform.bios_release_date, $p02.data.bios.ReleaseDate),
    @('cpu', $h.cpu.name, $p03.data.win32_processor.Name),
    @('threads', [string]$h.cpu.threads, [string]$p03.data.total_logical),
    @('active_path_adapter', $h.displays.active_paths[0].display_adapter_instance, $p13.data.paths[0].target_adapter_instance_id),
    @('active_resolution', $h.displays.active_paths[0].resolution, $p13.data.paths[0].target_mode.active),
    @('active_refresh', [string]$h.displays.active_paths[0].refresh_hz, [string]$p13.data.paths[0].refresh_rate_hz),
    @('nvidia_sources', [string]$h.hybrid_graphics.nvidia_num_display_sources, [string](($p12.data | Where-Object { $_.registry_info -and $_.registry_info.adapter_string -match 'NVIDIA' }).num_of_sources)),
    @('disk_model', $h.storage.disks[0].model, $p30.data.get_disk[0].Model),
    @('disk_fw', $h.storage.disks[0].firmware, $p30.data.get_disk[0].FirmwareVersion),
    @('esp_size', [string]$h.storage.esp.size_bytes, [string](($p31.data.partitions | Where-Object { $_.gpt_type_name -eq 'EFI System Partition' }).size)),
    @('probe_ok', [string]$h.collection.ok, [string]$idx.ok),
    @('probe_error', [string]$h.collection.error, [string]$idx.error)
)
foreach ($p in $pairs) { Add-Check ('json_vs_evidence:' + $p[0]) ([string]$p[1] -eq [string]$p[2] -and $null -ne $p[1]) ("json='$($p[1])' evidence='$($p[2])'") }

# ---------- 2. REPORT.md contains key measured values
$intel = $h.gpus | Where-Object { $_.role -eq 'integrated' }; $nv = $h.gpus | Where-Object { $_.role -eq 'discrete' }
$tokens = @(
    $h.platform.system_model, $h.platform.baseboard_product, $h.platform.baseboard_version, $h.platform.bios_version, $h.platform.bios_release_date, $h.cpu.microcode_revision,
    "$($intel.ids.vendor_id):$($intel.ids.device_id)", "$($nv.ids.vendor_id):$($nv.ids.device_id)", $intel.ids.subsystem_id, $nv.ids.subsystem_id, "REV_$($intel.ids.revision)", "REV_$($nv.ids.revision)",
    $intel.driver.version, $nv.driver.version, $nv.nvidia_smi.vbios_version, $intel.acpi_path, $nv.acpi_path, $intel.pci_bdf, $nv.pci_bdf,
    $h.displays.internal_panel.panel_model_from_edid_text[1], $h.displays.active_paths[0].resolution, [string]$h.displays.active_paths[0].refresh_hz, $h.displays.internal_panel.acpi_path,
    $h.storage.disks[0].firmware, $h.storage.disks[0].model, $h.memory.part_number, $h.memory.type, $h.firmware.boot_mode,
    "$($h.os.build).$($h.os.ubr)", 'ELAN2616', '8087:0026', '3277:0003', '144D:A80A', '8086:51F0', 'DEV_0256', '8086:51C8', '8086:461E', '8086:51ED', 'NvdTable', 'IgfxSsdt'
)
$missing = @($tokens | Where-Object { $_ -and $report.IndexOf([string]$_, [StringComparison]::OrdinalIgnoreCase) -lt 0 })
Add-Check 'report_contains_key_values' ($missing.Count -eq 0) $(if ($missing.Count) { 'missing: ' + ($missing -join ', ') } else { "all $($tokens.Count) tokens present" })
$countPhrase = "共 $($idx.probe_count) 项：成功 $($idx.ok)、部分成功 $($idx.partial)、失败 $($idx.error)"
Add-Check 'report_probe_counts' ($report.Contains($countPhrase)) "expected phrase: $countPhrase"
$failIds = @($idx.probes | Where-Object { $_.status -ne 'ok' } | ForEach-Object { $_.probe_id })
$missFail = @($failIds | Where-Object { -not $report.Contains($_) })
Add-Check 'report_lists_every_failed_or_partial_probe' ($missFail.Count -eq 0) $(if ($missFail.Count) { 'missing: ' + ($missFail -join ', ') } else { ($failIds -join ', ') })

# ---------- 3. unknowns stay unknown
$mustBeNull = [ordered]@{
    'hybrid_graphics.mux_present' = $h.hybrid_graphics.mux_present
    'hybrid_graphics.advanced_optimus_present' = $h.hybrid_graphics.advanced_optimus_present
    'hybrid_graphics.external_port_wiring' = $h.hybrid_graphics.external_port_wiring
    'displays.external_display_usb_c_dp_1080p_200hz.gpu_owner' = $h.displays.external_display_usb_c_dp_1080p_200hz.gpu_owner
    'storage.bitlocker.encryption_status' = $h.storage.bitlocker.encryption_status
    'storage.bitlocker.protection_status' = $h.storage.bitlocker.protection_status
    'storage.recovery_readiness.bitlocker_recovery_key_saved_externally' = $h.storage.recovery_readiness.bitlocker_recovery_key_saved_externally
    'storage.recovery_readiness.esp_independent_backup_exists' = $h.storage.recovery_readiness.esp_independent_backup_exists
    'storage.recovery_readiness.recovery_drill_performed' = $h.storage.recovery_readiness.recovery_drill_performed
    'memory.soldered' = $h.memory.soldered
    'intel physical_vram_bytes' = $intel.memory.physical_vram_bytes
}
foreach ($k in $mustBeNull.Keys) { Add-Check ('unknown_is_null:' + $k) ($null -eq $mustBeNull[$k]) ("value='" + $mustBeNull[$k] + "'") }
Add-Check 'vbt_not_claimed' ($h.firmware_evidence.vbt.obtained -eq $false -and $h.firmware_evidence.opregion.obtained -eq $false) 'vbt/opregion obtained=false'
foreach ($phrase in @('需要用户确认', '未取得', '未测', '未知')) { Add-Check "report_uses_marker:$phrase" ($report.Contains($phrase)) '' }
$overclaim = @('MUX 已确认', '确认存在 MUX', '确认没有 MUX', '已具备恢复能力', 'macOS 已可用', 'RTX 2050 在 macOS 下可用')
$found = @($overclaim | Where-Object { $report.Contains($_) })
Add-Check 'report_no_overclaim_phrases' ($found.Count -eq 0) $(if ($found.Count) { 'found: ' + ($found -join ', ') } else { 'none of: ' + ($overclaim -join ' / ') })

# ---------- 4. EDID share copies vs registry (in memory, offsets only)
$edidRes = @()
foreach ($m in @($p17.data)) {
    if (-not $m.sanitized_files) { continue }
    $bin = Join-Path $OutDir ($m.sanitized_files[0] -replace '/', '\')
    $orig = (Get-ItemProperty -LiteralPath ("HKLM:\SYSTEM\CurrentControlSet\Enum\" + $m.instance_id + "\Device Parameters")).EDID
    $san = [IO.File]::ReadAllBytes($bin)
    $diff = @(); for ($i = 0; $i -lt [Math]::Min($orig.Length, $san.Length); $i++) { if ($orig[$i] -ne $san[$i]) { $diff += $i } }
    $serialZero = ($san[12] -eq 0 -and $san[13] -eq 0 -and $san[14] -eq 0 -and $san[15] -eq 0)
    $ffClean = $true; foreach ($o in 54, 72, 90, 108) { if ($san[$o] -eq 0 -and $san[$o + 1] -eq 0 -and $san[$o + 3] -eq 0xFF) { if (@($san[($o + 6)..($o + 17)] | Where-Object { $_ -ne 0x20 }).Count -gt 0) { $ffClean = $false } } }
    $allowed = @(12, 13, 14, 15, 127) + (54..71) + (72..89) + (90..107) + (108..125)
    $unexpected = @($diff | Where-Object { $allowed -notcontains $_ -and $_ -lt 128 }) + @($diff | Where-Object { $_ -ge 128 })
    $edidRes += [ordered]@{ monitor = $m.instance_id; identical_to_registry = ($diff.Count -eq 0 -and $orig.Length -eq $san.Length); changed_offsets = ($diff -join ','); id_serial_zero = $serialZero; ff_descriptor_blank = $ffClean }
    Add-Check ("edid_share_copy:" + ($m.instance_id -split '\\')[1]) ($serialZero -and $ffClean -and $unexpected.Count -eq 0) ("changed offsets: " + $(if ($diff.Count) { $diff -join ',' } else { 'none (byte-identical)' }))
}

# ---------- 5. leak scan
$secrets = New-Object System.Collections.ArrayList
function Add-Secret([string]$cat, $val) {
    if ($null -eq $val) { return }
    $s = ([string]$val).Trim()
    $short = $cat -in @('user_name', 'user_profile_leaf')
    if ($s.Length -lt $(if ($short) { 2 } else { 4 })) { return }
    if ($s -match '^(0+|F+|Default string|To be filled by O\.E\.M\.|System Serial Number|None|N/A|Not Applicable|Not Specified|123456789|0000_0000.*)$') { return }
    if (($s.ToCharArray() | Select-Object -Unique).Count -le 1) { return }
    [void]$secrets.Add(@($cat, $s))
}
Add-Secret 'computer_name' $env:COMPUTERNAME; Add-Secret 'user_name' $env:USERNAME; Add-Secret 'user_profile_path' $env:USERPROFILE; Add-Secret 'user_profile_leaf' (Split-Path $env:USERPROFILE -Leaf)
if ($env:USERDOMAIN -ne $env:COMPUTERNAME) { Add-Secret 'user_domain' $env:USERDOMAIN }
try { Add-Secret 'bios_serial' (Get-CimInstance Win32_BIOS).SerialNumber } catch { }
try { Add-Secret 'baseboard_serial' (Get-CimInstance Win32_BaseBoard).SerialNumber } catch { }
$uuid = $null
try { $csp = Get-CimInstance Win32_ComputerSystemProduct; Add-Secret 'system_uuid' $csp.UUID; Add-Secret 'system_identifying_number' $csp.IdentifyingNumber; $uuid = $csp.UUID } catch { }
try { foreach ($x in Get-CimInstance Win32_DiskDrive) { Add-Secret 'disk_serial' $x.SerialNumber } } catch { }
try { foreach ($x in Get-PhysicalDisk) { Add-Secret 'disk_serial' $x.SerialNumber } } catch { }
try { foreach ($x in Get-CimInstance Win32_PhysicalMemory) { Add-Secret 'memory_serial' $x.SerialNumber } } catch { }
try { Add-Secret 'windows_product_id' (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductId } catch { }
try { Add-Secret 'registered_owner' (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').RegisteredOwner } catch { }
try { foreach ($x in Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID) { Add-Secret 'monitor_serial' (-join ($x.SerialNumberID | Where-Object { $_ } | ForEach-Object { [char]$_ })) } } catch { }
$macCount = 0
try { foreach ($x in Get-NetAdapter -IncludeHidden) { if ($x.MacAddress) { $raw = ($x.MacAddress -replace '[-:]', ''); if ($raw -match '^[0-9A-Fa-f]{12}$' -and $raw -notmatch '^0+$') { $macCount++; Add-Secret 'mac' $raw; Add-Secret 'mac' ($raw -replace '(..)(?!$)', '$1-'); Add-Secret 'mac' ($raw -replace '(..)(?!$)', '$1:') } } } } catch { }
$ipCount = 0
try { foreach ($x in Get-NetIPAddress) { if ($x.IPAddress -notmatch '^(127\.|::1$|169\.254\.)') { $ipCount++; Add-Secret 'ip' ($x.IPAddress -replace '%.*$', '') } } } catch { }
$binPatterns = New-Object System.Collections.ArrayList
if ($uuid) { try { $g = [guid]$uuid; [void]$binPatterns.Add(@('system_uuid_binary_le', $g.ToByteArray())); $be = [byte[]]@(); $hex = $g.ToString('N'); for ($i = 0; $i -lt 32; $i += 2) { $be += [Convert]::ToByte($hex.Substring($i, 2), 16) }; [void]$binPatterns.Add(@('system_uuid_binary_be', $be)) } catch { } }

$latin = [Text.Encoding]::GetEncoding(28591)
$hits = @(); $scanned = 0
$files = Get-ChildItem -LiteralPath $OutDir -Recurse -File | Where-Object { $_.Name -notin @('selfcheck.json', 'FILES_SHA256.txt') }
foreach ($f in $files) {
    $bytes = [IO.File]::ReadAllBytes($f.FullName); $scanned++
    $views = @($latin.GetString($bytes), [Text.Encoding]::UTF8.GetString($bytes), [Text.Encoding]::Unicode.GetString($bytes))
    $rel = $f.FullName.Substring($OutDir.Length).TrimStart('\')
    foreach ($s in $secrets) {
        $cat = $s[0]; $val = $s[1]
        $pattern = $(if ($cat -in @('user_name', 'user_profile_leaf')) { '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($val) + '(?![A-Za-z0-9])' } else { '(?i)' + [regex]::Escape($val) })
        $n = 0; foreach ($v in $views) { $n += [regex]::Matches($v, $pattern).Count }
        if ($n -gt 0) { $hits += [ordered]@{ category = $cat; file = $rel; count = $n } }
    }
    foreach ($bp in $binPatterns) { $n = [regex]::Matches($views[0], [regex]::Escape($latin.GetString($bp[1]))).Count; if ($n) { $hits += [ordered]@{ category = $bp[0]; file = $rel; count = $n } } }
    if ($f.Extension -in @('.json', '.md', '.txt', '.log', '.ps1')) {
        $t = $views[1]
        $n = [regex]::Matches($t, '(?i)[A-Z]:(\\{1,2}|/)Users(\\{1,2}|/)(?!<REDACTED_USER>|Public)[^\\/"\s]+').Count
        if ($n) { $hits += [ordered]@{ category = 'unredacted_user_profile_path_pattern'; file = $rel; count = $n } }
        $n = [regex]::Matches($t, '(?i)(?<![0-9a-f:-])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![0-9a-f:-])').Count
        if ($n) { $hits += [ordered]@{ category = 'mac_like_pattern'; file = $rel; count = $n } }
        $n = [regex]::Matches($t, '(?i)\b\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}\b').Count
        if ($n) { $hits += [ordered]@{ category = 'bitlocker_recovery_password_pattern'; file = $rel; count = $n } }
        $n = [regex]::Matches($t, '(?i)\b[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}\b').Count
        if ($n) { $hits += [ordered]@{ category = 'product_key_pattern'; file = $rel; count = $n } }
    }
}
$cats = @($secrets | ForEach-Object { $_[0] } | Sort-Object -Unique)
Add-Check 'leak_scan' ($hits.Count -eq 0) ("files scanned: $scanned; identifier categories checked: " + ($cats -join ', ') + "; MAC addresses checked: $macCount; IP addresses checked: $ipCount; hits: $($hits.Count)")

# ---------- 6. boundary: static scan of scripts
$forbidden = @('Set-ItemProperty', 'New-ItemProperty', 'Remove-ItemProperty', 'Set-Item ', 'reg add', 'reg delete', 'bcdedit', 'mountvol', 'diskpart', 'Format-Volume', 'Set-Partition', 'Resize-Partition', 'Disable-PnpDevice', 'Enable-PnpDevice', 'pnputil', 'devcon', 'Get-BitLockerVolume', 'Suspend-BitLocker', 'Disable-BitLocker', 'manage-bde.exe -protectors', 'manage-bde -protectors', 'Restart-Computer', 'Stop-Computer', 'Set-SecureBootUEFI', 'Install-', '-Verb RunAs', 'Invoke-WebRequest', 'DownloadFile', 'WriteProcessMemory', '\\.\PhysicalMemory', 'NtSystemDebugControl', 'Set-ExecutionPolicy', 'Start-Process')
$bnd = @()
foreach ($sf in @('collect.ps1', 'build_hardware_json.ps1')) {
    $txt = Get-Content -LiteralPath (Join-Path $OutDir $sf) -Raw
    $txt = [regex]::Replace($txt, '(?s)<#.*?#>', '')
    $txt = [regex]::Replace($txt, '(?m)^\s*#.*$', '')
    foreach ($fb in $forbidden) { if ($txt.IndexOf($fb, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $bnd += "$sf contains '$fb'" } }
    $writes = [regex]::Matches($txt, '(?i)(WriteAllBytes|WriteAllText|New-Item)[^\r\n]*') | ForEach-Object { $_.Value }
    foreach ($w in $writes) { if ($w -notmatch '(?i)\$Evidence|\$EdidDir|\$AcpiDir|\$binPath|\$full|\$OutDir|ItemType Directory -Path \$d|WriteAll(Text|Bytes)\(\$Path') { $bnd += "$sf write outside output dir? $w" } }
    $helperCalls = [regex]::Matches($txt, '(?im)^\s*Save-(Json|Text)\s+(\([^)]*\)|\S+)') | ForEach-Object { $_.Groups[2].Value }
    foreach ($c in $helperCalls) { if ($c -notmatch '^\(Join-Path\s+\$Evidence\s') { $bnd += "$sf Save-* call with non-evidence path: $c" } }
}
Add-Check 'readonly_boundary_static_scan' ($bnd.Count -eq 0) $(if ($bnd.Count) { $bnd -join ' | ' } else { 'no state-changing commands found; all file writes target the output folder' })

# ---------- summary
$pass = @($results | Where-Object { $_.pass }).Count; $fail = @($results | Where-Object { -not $_.pass }).Count
$out = [ordered]@{
    generated_local = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    checks_total = $results.Count; checks_passed = $pass; checks_failed = $fail
    checks = $results; edid_comparison = $edidRes; leak_hits = $hits
    note = 'Sensitive identifiers were read in memory only for matching and are not written here.'
}
$json = (ConvertTo-Json -InputObject $out -Depth 8).Replace('\u0026', '&').Replace('\u003c', '<').Replace('\u003e', '>').Replace('\u0027', "'")
[IO.File]::WriteAllText((Join-Path $Evidence 'selfcheck.json'), $json, $Utf8)
Write-Host "selfcheck: $pass passed, $fail failed"
foreach ($r in $results | Where-Object { -not $_.pass }) { Write-Host ("FAIL " + $r.check + " :: " + $r.detail) }
if ($fail -gt 0) { exit 1 } else { exit 0 }
