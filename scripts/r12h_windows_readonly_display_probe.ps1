#requires -Version 5.1
<#
HONOR GLO-FX6P / R1.2-H: read-only Windows display topology preflight.
No administrator rights required. Makes NO changes to disk, partitions, EFI,
BIOS, registry, boot configuration, graphics settings or driver state.
No network requests and no file writes. Display-adapter/monitor PCI information
is printed without serial numbers. Output is NOT a proof of eDP/HDMI/USB-C
electrical routing or MUX hardware topology.
#>
$ErrorActionPreference = 'Stop'

function Section([string]$name) {
    Write-Output ''
    Write-Output ("==== " + $name + " ====")
}

Section 'Windows read-only graphics inventory'
try {
    Get-CimInstance -ClassName Win32_VideoController |
        ForEach-Object {
            $pci = 'UNKNOWN'
            if ($_.PNPDeviceID -match 'VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})') {
                $pci = ('{0}:{1}' -f $matches[1], $matches[2]).ToUpperInvariant()
            }
            [pscustomobject]@{
                Name          = $_.Name
                PCI_ID        = $pci
                DriverVersion = $_.DriverVersion
                Status        = $_.Status
            }
        } | Format-Table -AutoSize | Out-String | Write-Output
} catch {
    Write-Output ('BLOCKED: Win32_VideoController unavailable: ' + $_.Exception.Message)
}

Section 'Display adapter PCI location (bus location is NOT panel ownership)'
try {
    Get-PnpDevice -Class Display -PresentOnly | ForEach-Object {
        $d = $_
        $pci = 'UNKNOWN'
        if ($d.InstanceId -match 'VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})') {
            $pci = ('{0}:{1}' -f $matches[1], $matches[2]).ToUpperInvariant()
        }
        $location = ''
        try {
            $prop = Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_LocationPaths' -ErrorAction Stop
            if ($prop.Data) {
                # Location path can be useful for connecting PCI function to an
                # ACPI tree, but still does not prove display-output wiring.
                $location = (@($prop.Data) | Select-Object -First 1)
            }
        } catch { $location = 'UNAVAILABLE' }
        [pscustomobject]@{
            Adapter      = $d.FriendlyName
            PCI_ID       = $pci
            Status       = $d.Status
            LocationPath = $location
        }
    } | Format-List | Out-String | Write-Output
} catch {
    Write-Output ('BLOCKED: Get-PnpDevice unavailable: ' + $_.Exception.Message)
}

Section 'Active monitor connection technology (NOT GPU ownership)'
try {
    Get-CimInstance -Namespace 'root\wmi' -ClassName WmiMonitorConnectionParams -ErrorAction Stop |
        ForEach-Object {
            $code = [uint32]$_.VideoOutputTechnology
            $panel = 'UNKNOWN'
            if ($_.InstanceName -match 'DISPLAY\\([^\\]+)') {
                $panel = $matches[1].ToUpperInvariant()
            }
            [pscustomobject]@{
                MonitorModelCode     = $panel
                VideoOutputCodeHex   = ('0x{0:X8}' -f $code)
                Active               = $_.Active
            }
        } | Format-Table -AutoSize | Out-String | Write-Output
} catch {
    Write-Output ('BLOCKED: WmiMonitorConnectionParams unavailable: ' + $_.Exception.Message)
}

Section 'Evidence limits and next manual read-only checks'
Write-Output 'These results do NOT map the internal eDP, HDMI or USB-C port to a specific GPU.'
Write-Output 'Windows: Settings -> System -> Display -> Advanced display -> "Connected to" for EACH attached screen.'
Write-Output 'NVIDIA Control Panel -> Configure Surround, PhysX -> observe GPU-to-display diagram if available.'
Write-Output 'Check built-in panel and (if already connected) existing HDMI/USB-C displays separately.'
Write-Output 'Do not change PhysX, Optimus, GPU-only mode, BIOS, device driver, display settings or EFI.'
Write-Output 'If sharing screenshots, obscure account names, serials and other personal identifiers.'
