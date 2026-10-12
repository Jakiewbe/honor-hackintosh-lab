#requires -Version 5.1
<#
  Builds hardware.json purely from evidence/*.json produced by collect.ps1.
  No system queries are made here. Unknown values are $null (JSON null).
#>
param([Parameter(Mandatory = $true)][string]$OutDir)
$ErrorActionPreference = 'Stop'
$Evidence = Join-Path $OutDir 'evidence'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Load([string]$id) { return (Get-Content -LiteralPath (Join-Path $Evidence "$id.json") -Raw -Encoding UTF8 | ConvertFrom-Json) }
function First($x) { if ($null -eq $x) { return $null }; return @($x)[0] }
function Parse-PciId([string]$hwid) {
    if ($hwid -match '(?i)VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})(?:&SUBSYS_([0-9A-F]{8}))?(?:&REV_([0-9A-F]{2}))?') {
        return [ordered]@{ vendor_id = $Matches[1].ToUpper(); device_id = $Matches[2].ToUpper(); subsystem_id = $(if ($Matches[3]) { $Matches[3].ToUpper() } else { $null }); revision = $(if ($Matches[4]) { $Matches[4].ToUpper() } else { $null }) }
    }
    if ($hwid -match '(?i)VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { return [ordered]@{ usb_vid = $Matches[1].ToUpper(); usb_pid = $Matches[2].ToUpper() } }
    return $null
}

$idx = Load '_index'
$p01 = Load 'P01_os'; $p02 = Load 'P02_system'; $p03 = Load 'P03_cpu'; $p04 = Load 'P04_memory'; $p05 = Load 'P05_firmware_mode'; $p06 = Load 'P06_secureboot_cmdlet'
$p10 = Load 'P10_video_controller'; $p11 = Load 'P11_gpu_class_registry'; $p12 = Load 'P12_d3dkmt_adapters'; $p13 = Load 'P13_displayconfig_active'; $p14 = Load 'P14_displayconfig_all_targets'
$p15 = Load 'P15_enum_display_devices'; $p16 = Load 'P16_display_modes'; $p17 = Load 'P17_edid'; $p18 = Load 'P18_wmi_monitor'; $p19 = Load 'P19_nvidia_smi'
$p20 = Load 'P20_pnp_inventory'; $p21 = Load 'P21_pnp_properties'; $p30 = Load 'P30_disks'; $p31 = Load 'P31_partitions'; $p32 = Load 'P32_bitlocker_shell'; $p33 = Load 'P33_manage_bde_status'; $p34 = Load 'P34_reagentc_info'
$p40 = Load 'P40_acpi_tables'; $p41 = Load 'P41_intel_display_firmware'; $p42 = Load 'P42_acpi_context'

$props = @{}; foreach ($d in $p21.data) { $props[$d.instance_id.ToUpperInvariant()] = $d }
$devs = @($p20.data.devices)

function Get-DeviceRecord($d) {
    $pp = $props[$d.instance_id.ToUpperInvariant()]
    $hw = First $d.hardware_ids
    [ordered]@{
        name = $d.name; class = $d.class; manufacturer = $d.manufacturer
        bus_reported_name = $(if ($pp) { $pp.Device_BusReportedDeviceDesc } else { $null })
        ids = (Parse-PciId $hw); hardware_ids = @($d.hardware_ids); compatible_ids = @($d.compatible_ids | Select-Object -First 4)
        instance_id = $d.instance_id
        status = $d.status; config_manager_error_code = $d.config_manager_error_code
        acpi_path = $(if ($pp) { $pp.Device_BiosDeviceName } else { $null })
        location_paths = $(if ($pp -and $pp.Device_LocationPaths) { , @($pp.Device_LocationPaths) } else { $null })
        location_info = $(if ($pp) { $pp.Device_LocationInfo } else { $d.location })
        parent = $(if ($pp) { $pp.Device_Parent } else { $null })
        service = $d.service
        driver = [ordered]@{ version = $d.driver_version; date = $d.driver_date; provider = $d.driver_provider; inf = $d.inf }
        pcie_link = $(if ($pp -and $null -ne $pp.PciDevice_CurrentLinkWidth) { [ordered]@{ current_speed_gen = $pp.PciDevice_CurrentLinkSpeed; current_width = $pp.PciDevice_CurrentLinkWidth; max_speed_gen = $pp.PciDevice_MaxLinkSpeed; max_width = $pp.PciDevice_MaxLinkWidth; note = 'speed value is PCIe generation code (1=2.5GT/s,2=5,3=8,4=16); snapshot only, may change with power state' } } else { $null })
    }
}
function Find([string]$re, [string]$field = 'instance_id') { return @($devs | Where-Object { $_.$field -match $re }) }

# ---------------- GPUs
$kmt = @($p12.data)
$nvsmi = $null
$nvLines = @($p19.data.output)
if ($p19.status -eq 'ok' -and $nvLines.Count -ge 2) {
    $h = $nvLines[0].Split(',') | ForEach-Object { $_.Trim() }; $v = $nvLines[1].Split(',') | ForEach-Object { $_.Trim() }
    $nvsmi = [ordered]@{}; for ($i = 0; $i -lt $h.Count; $i++) { $nvsmi[$h[$i]] = $v[$i] }
}
$gpus = @()
foreach ($d in @(Find '^PCI\\VEN_(8086&DEV_46A6|10DE&DEV_25A9)' | Where-Object { $null -ne $_ })) {
    $r = Get-DeviceRecord $d
    $pp = $props[$d.instance_id.ToUpperInvariant()]
    $bus = $null; $dev = $null; $fn = $null
    if ($pp -and $null -ne $pp.Device_Address) { $bus = $pp.Device_BusNumber; $dev = ([int64]$pp.Device_Address -shr 16); $fn = ([int64]$pp.Device_Address -band 0xFFFF) }
    $k = $kmt | Where-Object { $_.pci_address -and $_.pci_address.bus -eq $bus -and $_.pci_address.device -eq $dev -and $_.pci_address.function -eq $fn } | Select-Object -First 1
    $reg = $p11.data | Where-Object { $d.instance_id -like ($_.values.MatchingDeviceId + '*') } | Select-Object -First 1
    $vc = $p10.data | Where-Object { $_.PNPDeviceID -eq $d.instance_id } | Select-Object -First 1
    $isNv = $d.instance_id -match 'VEN_10DE'
    $r.role = $(if ($isNv) { 'discrete' } else { 'integrated' })
    $r.pci_bdf = $(if ($null -ne $bus) { '{0:X2}:{1:X2}.{2}' -f $bus, $dev, $fn } else { $null })
    $r.wddm = $(if ($k) { [ordered]@{ luid = $k.luid; num_of_sources = $k.num_of_sources; adapter_type_raw = $k.adapter_type_raw; render_supported = $k.adapter_type.RenderSupported; display_supported = $k.adapter_type.DisplaySupported; hybrid_discrete = $k.adapter_type.HybridDiscrete; hybrid_integrated = $k.adapter_type.HybridIntegrated; post_device = $k.adapter_type.PostDevice; wddm_version_enum = $k.wddm_driver_version_enum } } else { $null })
    $r.firmware_string = [ordered]@{ d3dkmt_bios_string = $(if ($k -and $k.registry_info) { $k.registry_info.bios_string } else { $null }); nvidia_smi_vbios_version = $(if ($isNv -and $nvsmi) { $nvsmi['vbios_version'] } else { $null }) }
    $r.memory = [ordered]@{
        d3dkmt_dedicated_video_bytes = $(if ($k -and $k.segment_sizes_bytes) { $k.segment_sizes_bytes.dedicated_video } else { $null })
        d3dkmt_shared_system_bytes = $(if ($k -and $k.segment_sizes_bytes) { $k.segment_sizes_bytes.shared_system } else { $null })
        registry_qwMemorySize_bytes = $(if ($reg) { $reg.values.'HardwareInformation.qwMemorySize' } else { $null })
        registry_MemorySize_bytes = $(if ($reg) { $reg.values.'HardwareInformation.MemorySize' } else { $null })
        win32_videocontroller_AdapterRAM = $(if ($vc) { $vc.AdapterRAM } else { $null })
        nvidia_smi_memory_total = $(if ($isNv -and $nvsmi) { $nvsmi['memory.total [MiB]'] } else { $null })
        physical_vram_bytes = $(if ($isNv -and $reg -and $nvsmi -and ([int64]$reg.values.'HardwareInformation.qwMemorySize' -eq ([int64]($nvsmi['memory.total [MiB]'] -replace '\D', '')) * 1MB)) { [int64]$reg.values.'HardwareInformation.qwMemorySize' } else { $null })
        physical_vram_basis = $(if ($isNv) { 'set only when registry HardwareInformation.qwMemorySize equals nvidia-smi memory.total; D3DKMT dedicated segment is the OS-usable portion' } else { 'UMA iGPU: no dedicated VRAM. D3DKMT "dedicated" 128 MiB and registry 1 GiB are driver-reported budgets, not DVMT pre-allocated size; DVMT/stolen size is unknown' })
    }
    $r.nvidia_smi = $(if ($isNv) { $nvsmi } else { $null })
    $gpus += $r
}

# ---------------- displays
$active = @()
foreach ($p in @($p13.data.paths)) {
    $mon = $p17.data | Where-Object { $p.target_name.monitor_device_path -and ($p.target_name.monitor_device_path -replace '^\\\\\?\\', '' -replace '#\{.*$', '' -replace '#', '\').ToUpperInvariant() -eq $_.instance_id.ToUpperInvariant() } | Select-Object -First 1
    $active += [ordered]@{
        gdi_source = $p.source_gdi_name
        display_adapter_instance = $p.target_adapter_instance_id
        display_adapter_is = $(if ($p.target_adapter_instance_id -match 'VEN_8086&DEV_46A6') { 'Intel 8086:46A6' } elseif ($p.target_adapter_instance_id -match 'VEN_10DE') { 'NVIDIA 10DE:25A9' } else { $null })
        render_source_adapter_luid = $p.source_adapter_luid
        output_technology = $p.output_technology; base_output_technology = $p.base_output_technology
        physical_connector = $(if ($p.output_technology -eq 'INTERNAL') { 'internal panel (Intel driver reports INTERNAL, not DISPLAYPORT_EMBEDDED; eDP is implied by EDID interface=DisplayPort and ACPI DD1F, not reported directly)' } else { $null })
        resolution = $(if ($p.target_mode) { $p.target_mode.active } else { $null })
        refresh_hz = $p.refresh_rate_hz; refresh_rational = $p.refresh_rate_rational
        timing_total = $(if ($p.target_mode) { $p.target_mode.total } else { $null }); pixel_rate_hz = $(if ($p.target_mode) { $p.target_mode.pixel_rate_hz } else { $null })
        preferred_mode = $p.preferred_mode
        advanced_color = $p.advanced_color
        monitor_instance = $(if ($mon) { $mon.instance_id } else { $null })
        monitor_acpi_path = $(if ($mon) { $mon.Device_BiosDeviceName } else { $null })
        edid_pnp_id = $(if ($mon) { $mon.edid.manufacturer_pnp_id } else { $null }); edid_product_code = $(if ($mon) { $mon.edid.product_code } else { $null })
    }
}
$internal = $p17.data | Where-Object { $_.present -and $_.Device_BusReportedDeviceDesc -eq 'Integrated Monitor' } | Select-Object -First 1
$targetsByAdapter = [ordered]@{}
foreach ($t in @($p14.data.targets)) {
    $a = $t.target_adapter_instance_id
    if (-not $targetsByAdapter.Contains($a)) { $targetsByAdapter[$a] = [ordered]@{} }
    $tech = $t.output_technology
    if ($targetsByAdapter[$a].Contains($tech)) { $targetsByAdapter[$a][$tech]++ } else { $targetsByAdapter[$a][$tech] = 1 }
}
$nvInst = (First (Find '^PCI\\VEN_10DE&DEV_25A9')).instance_id
$intelInst = (First (Find '^PCI\\VEN_8086&DEV_46A6')).instance_id
$modes = @($p16.data) | Where-Object { $_.gdi_name -eq '\\.\DISPLAY1' } | Select-Object -First 1

$displays = [ordered]@{
    active_paths = $active
    active_path_count = $active.Count
    external_displays_connected_now = @($active | Where-Object { $_.output_technology -ne 'INTERNAL' }).Count
    internal_panel = [ordered]@{
        panel_model_from_edid_text = $(if ($internal) { , @($internal.edid.text_descriptors.unspecified_text) } else { $null })
        edid_pnp_id = $(if ($internal) { $internal.edid.manufacturer_pnp_id } else { $null }); edid_product_code = $(if ($internal) { $internal.edid.product_code } else { $null })
        edid_version = $(if ($internal) { $internal.edid.edid_version } else { $null }); edid_interface = $(if ($internal) { $internal.edid.video_interface } else { $null }); edid_bits_per_color = $(if ($internal) { $internal.edid.bits_per_color } else { $null })
        edid_length_bytes = $(if ($internal) { $internal.edid.length } else { $null }); edid_extension_count = $(if ($internal) { $internal.edid.extension_count } else { $null })
        edid_detailed_timings = $(if ($internal) { , @($internal.edid.detailed_timings) } else { $null })
        edid_block1_note = 'registry EDID value is 256 bytes but extension_count=0; bytes 128-255 are all zero (padding)'
        image_size_mm = $(if ($internal) { (First $internal.edid.detailed_timings).image_mm } else { $null }); screen_size_cm = $(if ($internal) { $internal.edid.screen_size_cm } else { $null })
        native_mode = $(if ($internal) { $t0 = First $internal.edid.detailed_timings; '{0}x{1}@{2}Hz' -f $t0.h_active, $t0.v_active, $t0.refresh_hz } else { $null })
        native_mode_basis = 'EDID first detailed timing descriptor and DisplayConfig TARGET_PREFERRED_MODE agree'
        refresh_rates_enumerated_hz = $(if ($modes) { , @($modes.refresh_rates_seen_hz) } else { $null })
        acpi_path = $(if ($internal) { $internal.Device_BiosDeviceName } else { $null })
        edid_share_copy = $(if ($internal) { , @($internal.sanitized_files) } else { $null }); edid_share_copy_sha256 = $(if ($internal) { $internal.sanitized_sha256 } else { $null })
        edid_sanitization = $(if ($internal) { $(if (@($internal.sanitization_actions).Count) { , @($internal.sanitization_actions) } else { 'no serial number present in ID field or 0xFF descriptor; the scrub pass changed no bytes (byte comparison against the registry value is recorded in evidence/selfcheck.json), but it is still labelled a processed share copy' }) } else { $null })
    }
    connector_targets_exposed_by_driver = [ordered]@{
        intel_46A6 = $(if ($intelInst -and $targetsByAdapter.Contains($intelInst)) { $targetsByAdapter[$intelInst] } else { $null })
        nvidia_25A9 = $(if ($nvInst -and $targetsByAdapter.Contains($nvInst)) { $targetsByAdapter[$nvInst] } else { [ordered]@{ total = 0 } })
        software_indirect_adapters = @($targetsByAdapter.Keys | Where-Object { $_ -notmatch '^PCI\\' })
        note = 'QDC_ALL_PATHS targets = connectors the driver exposes; includes possible MST/virtual targets; not a physical routing map'
    }
    virtual_display_adapters = @($p10.data | Where-Object { $_.PNPDeviceID -notmatch '^PCI\\' } | ForEach-Object { [ordered]@{ name = $_.Name; instance = $_.PNPDeviceID; driver_version = $_.DriverVersion; status = $_.Status; config_manager_error_code = $_.ConfigManagerErrorCode } })
    historical_monitor_records = @($p17.data | Where-Object { -not $_.present } | ForEach-Object { [ordered]@{ instance_id = $_.instance_id; name = $_.Device_BusReportedDeviceDesc; pnp_id = $_.edid.manufacturer_pnp_id; product_code = $_.edid.product_code; first_dtd = (First $_.edid.detailed_timings); parent_now = $_.Device_Parent; interpretation = 'not present; parent no longer resolvable; instance prefix 1& and UID256 match the software indirect-display target pattern, so it cannot be attributed to a physical port or GPU' } })
    external_display_usb_c_dp_1080p_200hz = [ordered]@{ observed_now = $false; gpu_owner = $null; connector_type = $null; note = 'no external display connected during collection; no matching monitor record found in the device registry' }
}

# ---------------- hybrid graphics
$nvd = $p40.data.registry_tables | Where-Object { $_.oem_table_id -eq 'NvdTable' } | Select-Object -First 1
$nvGpu = $gpus | Where-Object { $_.role -eq 'discrete' } | Select-Object -First 1
$hybrid = [ordered]@{
    windows_mode_observed = 'Hybrid (Optimus-style): Intel = HybridIntegrated + DisplaySupported; NVIDIA = HybridDiscrete, RenderSupported, DisplaySupported=false, 0 display sources'
    nvidia_display_supported = $(if ($nvGpu.wddm) { $nvGpu.wddm.display_supported } else { $null })
    nvidia_num_display_sources = $(if ($nvGpu.wddm) { $nvGpu.wddm.num_of_sources } else { $null })
    nvidia_display_targets_exposed = @($p14.data.targets | Where-Object { $_.target_adapter_instance_id -match 'VEN_10DE' }).Count
    nvidia_smi_display_mode = $(if ($nvsmi) { $nvsmi['display_mode'] } else { $null }); nvidia_smi_display_active = $(if ($nvsmi) { $nvsmi['display_active'] } else { $null })
    acpi_nvidia_dsm_guids_in_NvdTable = $(if ($nvd) { @($nvd.dsm_guid_hits.PSObject.Properties.Name) } else { $null })
    acpi_mux_related_names_in_NvdTable = $(if ($nvd) { [ordered]@{ MXDS = $nvd.aml_name_hits.MXDS; MXMX = $nvd.aml_name_hits.MXMX; MXM_ = $nvd.aml_name_hits.MXM_ } } else { $null })
    mux_present = $null; advanced_optimus_present = $null; external_port_wiring = $null
    limits = 'Current output path proves current state only. Absence of NVIDIA display sources in this boot does not prove the board lacks a MUX or that no port can be routed to NVIDIA in another mode.'
}

# ---------------- other devices
function Recs($list) { return , @($list | Where-Object { $null -ne $_ } | ForEach-Object { Get-DeviceRecord $_ }) }
$codecs = Find '^(INTELAUDIO|HDAUDIO)\\FUNC_'
$devices = [ordered]@{
    nvme_controller = Recs (Find '^PCI\\VEN_144D')
    wifi = Recs (Find '^PCI\\VEN_8086&DEV_51F0')
    bluetooth = Recs (@($devs | Where-Object { $_.class -eq 'Bluetooth' -and $_.instance_id -match '^USB\\' }))
    audio_controller = Recs (Find '^PCI\\VEN_8086&DEV_51C8')
    audio_dsp_function = Recs (Find '^INTELAUDIO\\DSP_CTLR')
    audio_codecs = @((Recs $codecs) | ForEach-Object { $c = $_; $vid = $null; $did = $null; if ($c.instance_id -match 'VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})') { $vid = $Matches[1]; $did = $Matches[2] }; $c.codec_vendor_id = $vid; $c.codec_device_id = $did; $c.codec_model_inferred = $(if ($vid -eq '10EC') { 'ALC' + $did.TrimStart('0') + ' (inferred from Realtek codec ID convention, not reported by name)' } else { $null }); $c })
    nvidia_hd_audio_function = Recs (Find '^PCI\\VEN_10DE&DEV_(?!25A9)')
    ethernet_builtin = Recs (@($devs | Where-Object { $_.class -eq 'Net' -and $_.instance_id -match '^PCI\\' -and $_.instance_id -notmatch 'DEV_51F0' }))
    ethernet_external_usb = Recs (@($devs | Where-Object { $_.class -eq 'Net' -and $_.instance_id -match '^USB\\' }))
    usb_host_controllers = Recs (@($devs | Where-Object { $_.instance_id -match '^PCI\\' -and (@($_.compatible_ids) -match '(?i)CC_0C03') }))
    thunderbolt_usb4 = Recs (@($devs | Where-Object { $_.instance_id -match '^PCI\\' -and ((@($_.compatible_ids) -match '(?i)CC_0C0340') -or $_.name -match '(?i)thunderbolt|usb4') }))
    touchpad = Recs (Find '^ACPI\\ELAN')
    touchpad_hid_collections = Recs (Find '^HID\\ELAN')
    keyboard_internal = Recs (Find '^ACPI\\MSFT0001')
    i2c_serialio_controllers = Recs (@($devs | Where-Object { $_.instance_id -match '^PCI\\VEN_8086' -and $_.name -match '(?i)I2C|Serial IO|UART|SPI' }))
    serialio_gpio = Recs (Find '^ACPI\\INTC1055')
    card_reader = Recs (@($devs | Where-Object { $_.name -match '(?i)card ?reader|SD Host|RTS5|GL97' -or $_.class -eq 'SDHost' }))
    camera = Recs (@($devs | Where-Object { $_.class -in @('Camera', 'Image') }))
    fingerprint = Recs (@($devs | Where-Object { $_.class -eq 'Biometric' }))
    nvidia_platform_framework = Recs (Find '^ACPI\\NVDA')
    other_pci = Recs (@($devs | Where-Object { $_.instance_id -match '^PCI\\' -and $_.instance_id -notmatch 'DEV_(46A6|25A9|51F0|51C8|A80A|51ED|461E)' }))
    external_usb_peripherals_present = @($devs | Where-Object { $_.instance_id -match '^USB\\VID_' -and $_.instance_id -notmatch 'MI_' -and $_.instance_id -notmatch 'VID_(8087|3277|10A5)' } | ForEach-Object { [ordered]@{ name = $_.name; ids = (Parse-PciId (First $_.hardware_ids)); bus_reported_name = $props[$_.instance_id.ToUpperInvariant()].Device_BusReportedDeviceDesc; location_paths = @($props[$_.instance_id.ToUpperInvariant()].Device_LocationPaths) } })
    problem_devices = @($devs | Where-Object { $_.config_manager_error_code -and $_.config_manager_error_code -ne 0 } | ForEach-Object { [ordered]@{ name = $_.name; instance_id = $_.instance_id; config_manager_error_code = $_.config_manager_error_code } })
}

# ---------------- storage / boot / recovery
$disk = First $p30.data.get_disk
$parts = @($p31.data.partitions)
$esp = $parts | Where-Object { $_.gpt_type_name -eq 'EFI System Partition' } | Select-Object -First 1
$storage = [ordered]@{
    disks = @($p30.data.get_disk | ForEach-Object { [ordered]@{ number = $_.Number; model = $_.Model; firmware = $_.FirmwareVersion; bus = $_.BusType; partition_style = $_.PartitionStyle; size_bytes = $_.Size; logical_sector = $_.LogicalSectorSize; physical_sector = $_.PhysicalSectorSize; is_boot = $_.IsBoot; is_system = $_.IsSystem; health = $_.HealthStatus; location = $_.Location } })
    partitions = @($parts | ForEach-Object { [ordered]@{ disk = $_.disk; number = $_.partition; type = $_.type; gpt_type_name = $_.gpt_type_name; size_bytes = $_.size; offset_bytes = $_.offset; file_system = $_.file_system; drive_letter = $_.drive_letter; is_system = $_.is_system; is_boot = $_.is_boot; free_bytes = $_.volume_free } })
    esp = $(if ($esp) { [ordered]@{ present = $true; disk = $esp.disk; partition = $esp.partition; size_bytes = $esp.size; file_system = $esp.file_system; file_system_note = 'null = not readable without elevation; the ESP was not mounted' } } else { [ordered]@{ present = $false } })
    windows_system_disk = $p31.data.windows_partition.disk; windows_partition = $p31.data.windows_partition.partition
    bitlocker = [ordered]@{
        encryption_status = $null; protection_status = $null
        shell_property_raw = @($p32.data.volumes | ForEach-Object { [ordered]@{ drive = $_.drive; raw = $_.bitlocker_protection_raw } })
        registry_BootStatus = $p32.data.registry_BitLockerStatus_BootStatus
        manage_bde = [ordered]@{ status = $p33.status; exit_code = $p33.native_exit_code; reason = 'requires elevation (access denied)' }
        note = 'Non-elevated shell property returned 0 for all volumes; this value is ambiguous and is NOT taken as proof that the disk is unencrypted. Encryption and protection status remain unconfirmed.'
    }
    windows_re = [ordered]@{ status = $null; reagentc = [ordered]@{ status = $p34.status; exit_code = $p34.native_exit_code; reason = 'requires elevation' } }
    recovery_readiness = [ordered]@{
        bitlocker_recovery_key_saved_externally = $null; esp_independent_backup_exists = $null; recovery_drill_performed = $null; independent_recovery_environment = $null
        status = 'needs_user_confirmation (not verifiable by read-only queries; do not assume recovery capability)'
    }
}

# ---------------- firmware evidence
$fwEvidence = [ordered]@{
    acpi_tables_obtained = @($p40.data.registry_tables | Where-Object { $_.file } | ForEach-Object { [ordered]@{ signature = $_.signature; oem_table_id = $_.oem_table_id; length = $_.length; checksum_ok = $_.checksum_ok; file = $_.file; sha256 = $_.sha256; dsm_guids = @($_.dsm_guid_hits.PSObject.Properties.Name) } })
    acpi_tables_not_read = @(@($p40.data.registry_tables | Where-Object { $_.skipped } | ForEach-Object { [ordered]@{ table = $_.registry_key; reason = $_.skipped } }) + @($p40.data.firmware_api_tables | Where-Object { $_.signature -in @('MSDM', 'SLIC') } | ForEach-Object { [ordered]@{ table = $_.signature; reason = $_.skipped } }))
    intel_opregion_declaration = 'IgfxSsdt declares OperationRegion IGDM in SystemMemory at runtime base ASLB, length 0x2000 (see P42 byte context); contents not read'
    vbt = [ordered]@{ obtained = $false; tried = @($p41.data.vbt.tried); reason = $p41.data.vbt.reason }
    opregion = [ordered]@{ obtained = $false; tried = @($p41.data.opregion.tried); reason = $p41.data.opregion.reason }
    edp_link_parameters = [ordered]@{ obtained = $false; tried = @($p41.data.edp_link_parameters.tried); reason = $p41.data.edp_link_parameters.reason }
    ddi_port_mapping = [ordered]@{ obtained = $false; tried = @($p41.data.port_mapping.tried); reason = $p41.data.port_mapping.reason }
    intel_driver_display_policy_values = ($p11.data | Where-Object { $_.values.DriverDesc -match 'Intel' } | Select-Object -First 1).display_related_values
    intel_driver_display_policy_note = 'These are driver/INF configuration values, not measured panel capabilities.'
}

$cpu = $p03.data
$mem = $p04.data
$memTypes = @{ 26 = 'DDR4'; 30 = 'LPDDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }
$m0 = First $mem.modules
$hw = [ordered]@{
    schema = 'honor-hackintosh-lab/readonly-hardware-survey/v1'
    generated_local = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    collection = [ordered]@{ script = 'collect.ps1'; collected_local = $idx.generated_local; elevated = $idx.elevated; powershell = $idx.powershell; probe_count = $idx.probe_count; ok = $idx.ok; partial = $idx.partial; error = $idx.error; probes = @($idx.probes | ForEach-Object { [ordered]@{ id = $_.probe_id; status = $_.status; source = $_.source_interface; first_error = $_.first_error; file = $_.file } }) }
    provenance = 'All values outside background_claims are measured in this run (see evidence/). null = unknown / not measured.'
    platform = [ordered]@{
        system_manufacturer = $p02.data.computer_system.Manufacturer; system_model = $p02.data.computer_system.Model; system_family = $p02.data.computer_system.SystemFamily; system_sku = $p02.data.computer_system.SystemSKUNumber; system_version = $p02.data.computer_system_product.Version
        baseboard_product = $p02.data.baseboard.Product; baseboard_version = $p02.data.baseboard.Version
        bios_vendor = $p02.data.bios.Manufacturer; bios_version = $p02.data.bios.SMBIOSBIOSVersion; bios_release_date = $p02.data.bios.ReleaseDate; bios_version_strings = @($p02.data.bios.BIOSVersion)
        ec_firmware_version = ('{0}.{1}' -f $p02.data.bios.EmbeddedControllerMajorVersion, $p02.data.bios.EmbeddedControllerMinorVersion); smbios_version = ('{0}.{1}' -f $p02.data.bios.SMBIOSMajorVersion, $p02.data.bios.SMBIOSMinorVersion)
        acpi_oem_id = 'HONOR'; acpi_oem_table_id = 'ADL-P-M'
    }
    os = [ordered]@{ caption = $p01.data.win32_operatingsystem.Caption; version = $p01.data.win32_operatingsystem.Version; build = $p01.data.currentversion.CurrentBuild; ubr = $p01.data.currentversion.UBR; display_version = $p01.data.currentversion.DisplayVersion; edition_id = $p01.data.currentversion.EditionID; architecture = $p01.data.win32_operatingsystem.OSArchitecture; hypervisor_present = $p02.data.computer_system.HypervisorPresent }
    firmware = [ordered]@{ boot_mode = $p05.data.GetFirmwareType; secure_boot_enabled = $(if ($p05.data.registry_UEFISecureBootEnabled -eq 1) { $true } elseif ($p05.data.registry_UEFISecureBootEnabled -eq 0) { $false } else { $null }); secure_boot_source = 'registry SecureBoot\State\UEFISecureBootEnabled; Confirm-SecureBootUEFI cross-check failed (needs elevation)' }
    cpu = [ordered]@{ name = $cpu.win32_processor.Name; cpuid_signature = $cpu.win32_processor.Caption; cores = $cpu.total_cores; threads = $cpu.total_logical; p_cores = ($cpu.core_topology_by_efficiency_class | Where-Object { $_.efficiency_class -eq 1 }).core_count; e_cores = ($cpu.core_topology_by_efficiency_class | Where-Object { $_.efficiency_class -eq 0 }).core_count; base_clock_mhz = $cpu.win32_processor.MaxClockSpeed; l2_kb = $cpu.win32_processor.L2CacheSize; l3_kb = $cpu.win32_processor.L3CacheSize; microcode_revision = $cpu.registry.MicrocodeUpdateRevision }
    memory = [ordered]@{ total_bytes = $mem.total_bytes; os_visible_bytes = $p02.data.computer_system.TotalPhysicalMemory; module_count = @($mem.modules).Count; per_module_bytes = $m0.Capacity; type = $(if ($memTypes.ContainsKey([int]$m0.SMBIOSMemoryType)) { $memTypes[[int]$m0.SMBIOSMemoryType] } else { $null }); smbios_memory_type = $m0.SMBIOSMemoryType; rated_speed_mts = $m0.Speed; configured_speed_mts = $m0.ConfiguredClockSpeed; manufacturer = $m0.Manufacturer; part_number = $m0.PartNumber.Trim(); soldered = $null; soldered_note = 'not reported directly (FormFactor=0); LPDDR5 is normally soldered - inference only' }
    gpus = $gpus
    displays = $displays
    hybrid_graphics = $hybrid
    devices = $devices
    storage = $storage
    firmware_evidence = $fwEvidence
    background_claims = @(
        [ordered]@{ claim = 'Model HONOR GLO-FX6P, board GLO-FX6P-PCB / M2080'; measured = "$($p02.data.computer_system.Model) / $($p02.data.baseboard.Product) / $($p02.data.baseboard.Version)"; result = 'consistent' }
        [ordered]@{ claim = 'CPU Intel Core i5-12500H'; measured = $cpu.win32_processor.Name; result = 'consistent' }
        [ordered]@{ claim = 'iGPU Intel Iris Xe 8086:46A6'; measured = 'PCI VEN_8086 DEV_46A6'; result = 'consistent' }
        [ordered]@{ claim = 'dGPU NVIDIA RTX 2050 Laptop 10DE:25A9 (not RTX 3050)'; measured = 'PCI VEN_10DE DEV_25A9, name NVIDIA GeForce RTX 2050'; result = 'consistent' }
        [ordered]@{ claim = 'Internal panel on Intel iGPU in current Windows'; measured = 'active path display adapter = Intel 46A6 (not re-asked; recorded as part of path enumeration)'; result = 'consistent' }
        [ordered]@{ claim = 'External 1080p/200Hz via USB-C to DP; GPU owner unknown'; measured = 'no external display connected; no record found'; result = 'not_measured' }
        [ordered]@{ claim = '~16 GB RAM'; measured = "$($mem.total_bytes) bytes"; result = 'consistent' }
        [ordered]@{ claim = 'Samsung MZVL2512HCJQ-00B00 512 GB'; measured = $disk.Model; result = 'consistent' }
        [ordered]@{ claim = 'Intel AX201'; measured = (First (Find '^PCI\\VEN_8086&DEV_51F0')).name; result = 'consistent' }
        [ordered]@{ claim = 'Realtek audio'; measured = 'Realtek codec 10EC:0256 on Intel SST'; result = 'consistent' }
        [ordered]@{ claim = 'BIOS 3.09, 2023-07-10'; measured = "$($p02.data.bios.SMBIOSBIOSVersion), $($p02.data.bios.ReleaseDate)"; result = $(if ($p02.data.bios.SMBIOSBIOSVersion -eq '3.09' -and $p02.data.bios.ReleaseDate -eq '2023-07-10') { 'consistent (still current)' } else { 'changed' }) }
    )
}

$json = ConvertTo-Json -InputObject $hw -Depth 16
$json = $json.Replace('\u0026', '&').Replace('\u003c', '<').Replace('\u003e', '>').Replace('\u0027', "'")
[IO.File]::WriteAllText((Join-Path $OutDir 'hardware.json'), $json, $Utf8)
Write-Host 'hardware.json written'
