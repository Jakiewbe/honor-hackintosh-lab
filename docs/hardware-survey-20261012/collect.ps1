#requires -Version 5.1
<#
  HONOR GLO-FX6P read-only hardware survey (collection stage).

  Boundaries enforced by this script:
  - Only query APIs are called (CIM/WMI, PnP properties, registry reads, user32
    QueryDisplayConfig/DisplayConfigGetDeviceInfo, gdi32 D3DKMT query thunks,
    kernel32 GetSystemFirmwareTable). Nothing is set, enabled, disabled or installed.
  - All files are written below -OutDir only.
  - No serial numbers, UUIDs, MAC/IP addresses, product keys or BitLocker secrets are
    selected. Get-BitLockerVolume is intentionally NOT used (its KeyProtector objects can
    carry recovery passwords). MSDM/SLIC ACPI tables are never read (they hold product keys).
  - Every evidence file is passed through Protect-Text before it is written.
#>
param([Parameter(Mandatory = $true)][string]$OutDir)

$ErrorActionPreference = 'Stop'
$Evidence = Join-Path $OutDir 'evidence'
$AcpiDir = Join-Path $Evidence 'acpi'
$EdidDir = Join-Path $Evidence 'edid'
foreach ($d in @($Evidence, $AcpiDir, $EdidDir)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null } }
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# ---------------------------------------------------------------- redaction
$script:LiteralRules = New-Object System.Collections.ArrayList
if ($env:USERNAME) {
    $u = [regex]::Escape($env:USERNAME)
    [void]$script:LiteralRules.Add(@("(?i)([A-Z]:(?:\\{1,2}|/)Users(?:\\{1,2}|/))$u(?![A-Za-z0-9])", '$1<REDACTED_USER>'))
    [void]$script:LiteralRules.Add(@("(?i)(?<![A-Za-z0-9])$u(?![A-Za-z0-9])", '<REDACTED_USER>'))
}
if ($env:COMPUTERNAME) {
    [void]$script:LiteralRules.Add(@("(?i)(?<![A-Za-z0-9])$([regex]::Escape($env:COMPUTERNAME))(?![A-Za-z0-9])", '<REDACTED_COMPUTERNAME>'))
}
if ($env:USERDOMAIN -and $env:USERDOMAIN -ne $env:COMPUTERNAME) {
    [void]$script:LiteralRules.Add(@("(?i)(?<![A-Za-z0-9])$([regex]::Escape($env:USERDOMAIN))(?![A-Za-z0-9])", '<REDACTED_DOMAIN>'))
}
$script:BusPrefix = 'USB|USBSTOR|HID|SCSI|STORAGE|BTHENUM|BTHLE|BTHLEDEVICE|BTHHFENUM|BTH|SWD|DISPLAY|MONITOR|PCI|ACPI|HDAUDIO|INTELAUDIO|UEFI|ROOT|WPDBUSENUM|NVME|USB4|INTELI2C'
# Last segment of a device instance path without '&' and >= 8 chars is a device-reported unique id (serial).
$script:InstanceRe = "(?i)((?:$($script:BusPrefix))(?:\\{1,2}|#)[^\\#\s`"]+(?:\\{1,2}|#))([^&\\#\s`"{}<>]{8,}(?:&\d{1,2})?)(?=$|[\\#\s`",}\]])"

function Protect-Text([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return $s }
    foreach ($r in $script:LiteralRules) { $s = [regex]::Replace($s, $r[0], $r[1]) }
    $s = [regex]::Replace($s, '(?i)(?<![0-9a-f:-])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![0-9a-f:-])', '<REDACTED_MAC>')
    $s = [regex]::Replace($s, '(?i)(&0&)[0-9a-f]{12}(_)', '$1<REDACTED_MAC>$2')
    $s = [regex]::Replace($s, $script:InstanceRe, '$1<REDACTED_UNIQUE_ID>')
    return $s
}

function Save-Text([string]$Path, [string]$Text) { [IO.File]::WriteAllText($Path, (Protect-Text $Text), $Utf8) }

function ConvertTo-SafeJson($Obj) {
    $json = ConvertTo-Json -InputObject $Obj -Depth 14
    $json = $json.Replace('\u0026', '&').Replace('\u003c', '<').Replace('\u003e', '>').Replace('\u0027', "'")
    return (Protect-Text $json)
}
function Save-Json([string]$Path, $Obj) { [IO.File]::WriteAllText($Path, (ConvertTo-SafeJson $Obj), $Utf8) }

function Format-Date($d) {
    if ($null -eq $d) { return $null }
    if ($d -is [datetime]) { return $d.ToString('yyyy-MM-dd') }
    return [string]$d
}

# ---------------------------------------------------------------- probe runner
$script:Index = New-Object System.Collections.ArrayList
$script:ProbeErrors = $null

function Add-ProbeError([string]$msg) { [void]$script:ProbeErrors.Add($msg) }

function Invoke-Probe {
    param(
        [string]$Id, [string]$Title, [string]$Source, [scriptblock]$Script,
        [switch]$Native
    )
    $script:ProbeErrors = New-Object System.Collections.ArrayList
    $started = Get-Date
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $status = 'ok'; $data = $null; $exitCode = $null
    try {
        $global:LASTEXITCODE = $null
        $data = & $Script
        if ($Native) {
            $exitCode = $global:LASTEXITCODE
            if ($null -ne $exitCode -and $exitCode -ne 0) { $status = 'error' }
        }
        if ($status -eq 'ok' -and $script:ProbeErrors.Count -gt 0) { $status = 'partial' }
    } catch {
        $status = 'error'
        Add-ProbeError ($_.Exception.GetType().FullName + ': ' + $_.Exception.Message)
    }
    $sw.Stop()
    $rec = [ordered]@{
        probe_id         = $Id
        title            = $Title
        source_interface = $Source
        command          = $Script.ToString().Trim()
        started_local    = $started.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')
        duration_ms      = [int]$sw.ElapsedMilliseconds
        status           = $status
        native_exit_code = $exitCode
        errors           = @($script:ProbeErrors)
        data             = $data
    }
    $file = "$Id.json"
    Save-Json (Join-Path $Evidence $file) $rec
    [void]$script:Index.Add([ordered]@{ probe_id = $Id; title = $Title; source_interface = $Source; status = $status; native_exit_code = $exitCode; error_count = $script:ProbeErrors.Count; first_error = $(if ($script:ProbeErrors.Count) { $script:ProbeErrors[0] } else { $null }); file = "evidence/$file"; started_local = $rec.started_local })
    Write-Host ("[{0}] {1} -> {2}" -f $Id, $Title, $status)
}

# ---------------------------------------------------------------- native helpers (query-only)
$cs = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace HonorSurvey {
  [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint LowPart; public int HighPart; }
  [StructLayout(LayoutKind.Sequential)] public struct DC_RATIONAL { public uint Numerator; public uint Denominator; }
  [StructLayout(LayoutKind.Sequential)] public struct DC_PATH_SOURCE_INFO { public LUID adapterId; public uint id; public uint modeInfoIdx; public uint statusFlags; }
  [StructLayout(LayoutKind.Sequential)] public struct DC_PATH_TARGET_INFO {
    public LUID adapterId; public uint id; public uint modeInfoIdx; public uint outputTechnology; public uint rotation; public uint scaling;
    public DC_RATIONAL refreshRate; public uint scanLineOrdering; public int targetAvailable; public uint statusFlags; }
  [StructLayout(LayoutKind.Sequential)] public struct DC_PATH_INFO { public DC_PATH_SOURCE_INFO sourceInfo; public DC_PATH_TARGET_INFO targetInfo; public uint flags; }
  [StructLayout(LayoutKind.Explicit, Size = 64)] public struct DC_MODE_INFO {
    [FieldOffset(0)] public uint infoType; [FieldOffset(4)] public uint id; [FieldOffset(8)] public LUID adapterId;
    [FieldOffset(16)] public ulong pixelRate;
    [FieldOffset(24)] public uint hSyncNum; [FieldOffset(28)] public uint hSyncDen;
    [FieldOffset(32)] public uint vSyncNum; [FieldOffset(36)] public uint vSyncDen;
    [FieldOffset(40)] public uint activeCx; [FieldOffset(44)] public uint activeCy;
    [FieldOffset(48)] public uint totalCx; [FieldOffset(52)] public uint totalCy;
    [FieldOffset(56)] public uint videoStandard; [FieldOffset(60)] public uint scanLineOrdering;
    [FieldOffset(16)] public uint srcWidth; [FieldOffset(20)] public uint srcHeight; [FieldOffset(24)] public uint srcPixelFormat;
    [FieldOffset(28)] public int srcPosX; [FieldOffset(32)] public int srcPosY; }

  public class DcQuery { public int Status; public DC_PATH_INFO[] Paths; public DC_MODE_INFO[] Modes; }
  public class TargetName { public int Status; public uint Flags; public uint OutputTechnology; public ushort EdidManufactureId; public ushort EdidProductCodeId; public uint ConnectorInstance; public string FriendlyName; public string MonitorDevicePath; }
  public class PreferredMode { public int Status; public uint Width; public uint Height; public ulong PixelRate; public uint VSyncNum; public uint VSyncDen; public uint HSyncNum; public uint HSyncDen; public uint ActiveCx; public uint ActiveCy; public uint TotalCx; public uint TotalCy; public uint VideoStandard; public uint ScanLineOrdering; }
  public class AdvColor { public int Status; public uint Value; public uint ColorEncoding; public uint BitsPerColorChannel; }
  public class StrResult { public int Status; public string Value; }
  public class UIntResult { public int Status; public uint Value; }

  public static class DisplayCfg {
    [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint flags, out uint numPath, out uint numMode);
    [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint flags, ref uint numPath, [Out] DC_PATH_INFO[] paths, ref uint numMode, [Out] DC_MODE_INFO[] modes, IntPtr topology);
    [DllImport("user32.dll")] static extern int DisplayConfigGetDeviceInfo(IntPtr packet);

    public static DcQuery Query(uint flags) {
      DcQuery r = new DcQuery();
      for (int attempt = 0; attempt < 5; attempt++) {
        uint np, nm;
        int st = GetDisplayConfigBufferSizes(flags, out np, out nm);
        if (st != 0) { r.Status = st; return r; }
        DC_PATH_INFO[] p = new DC_PATH_INFO[np];
        DC_MODE_INFO[] m = new DC_MODE_INFO[nm];
        st = QueryDisplayConfig(flags, ref np, p, ref nm, m, IntPtr.Zero);
        if (st == 122) continue;
        r.Status = st;
        if (st == 0) { Array.Resize(ref p, (int)np); Array.Resize(ref m, (int)nm); r.Paths = p; r.Modes = m; }
        return r;
      }
      r.Status = 122; return r;
    }

    static IntPtr Packet(uint type, int size, LUID a, uint id) {
      IntPtr buf = Marshal.AllocHGlobal(size);
      for (int i = 0; i < size; i++) Marshal.WriteByte(buf, i, 0);
      Marshal.WriteInt32(buf, 0, (int)type);
      Marshal.WriteInt32(buf, 4, size);
      Marshal.WriteInt32(buf, 8, (int)a.LowPart);
      Marshal.WriteInt32(buf, 12, a.HighPart);
      Marshal.WriteInt32(buf, 16, (int)id);
      return buf;
    }

    public static StrResult SourceName(LUID a, uint id) {
      IntPtr b = Packet(1, 84, a, id);
      try { StrResult r = new StrResult(); r.Status = DisplayConfigGetDeviceInfo(b); if (r.Status == 0) r.Value = Marshal.PtrToStringUni(new IntPtr(b.ToInt64() + 20)); return r; }
      finally { Marshal.FreeHGlobal(b); }
    }
    public static TargetName Target(LUID a, uint id) {
      IntPtr b = Packet(2, 420, a, id);
      try {
        TargetName t = new TargetName(); t.Status = DisplayConfigGetDeviceInfo(b);
        if (t.Status == 0) {
          t.Flags = (uint)Marshal.ReadInt32(b, 20); t.OutputTechnology = (uint)Marshal.ReadInt32(b, 24);
          t.EdidManufactureId = (ushort)Marshal.ReadInt16(b, 28); t.EdidProductCodeId = (ushort)Marshal.ReadInt16(b, 30);
          t.ConnectorInstance = (uint)Marshal.ReadInt32(b, 32);
          t.FriendlyName = Marshal.PtrToStringUni(new IntPtr(b.ToInt64() + 36));
          t.MonitorDevicePath = Marshal.PtrToStringUni(new IntPtr(b.ToInt64() + 164));
        }
        return t;
      } finally { Marshal.FreeHGlobal(b); }
    }
    public static PreferredMode Preferred(LUID a, uint id) {
      IntPtr b = Packet(3, 80, a, id);
      try {
        PreferredMode p = new PreferredMode(); p.Status = DisplayConfigGetDeviceInfo(b);
        if (p.Status == 0) {
          p.Width = (uint)Marshal.ReadInt32(b, 20); p.Height = (uint)Marshal.ReadInt32(b, 24);
          p.PixelRate = (ulong)Marshal.ReadInt64(b, 32);
          p.HSyncNum = (uint)Marshal.ReadInt32(b, 40); p.HSyncDen = (uint)Marshal.ReadInt32(b, 44);
          p.VSyncNum = (uint)Marshal.ReadInt32(b, 48); p.VSyncDen = (uint)Marshal.ReadInt32(b, 52);
          p.ActiveCx = (uint)Marshal.ReadInt32(b, 56); p.ActiveCy = (uint)Marshal.ReadInt32(b, 60);
          p.TotalCx = (uint)Marshal.ReadInt32(b, 64); p.TotalCy = (uint)Marshal.ReadInt32(b, 68);
          p.VideoStandard = (uint)Marshal.ReadInt32(b, 72); p.ScanLineOrdering = (uint)Marshal.ReadInt32(b, 76);
        }
        return p;
      } finally { Marshal.FreeHGlobal(b); }
    }
    public static StrResult AdapterName(LUID a) {
      IntPtr b = Packet(4, 276, a, 0);
      try { StrResult r = new StrResult(); r.Status = DisplayConfigGetDeviceInfo(b); if (r.Status == 0) r.Value = Marshal.PtrToStringUni(new IntPtr(b.ToInt64() + 20)); return r; }
      finally { Marshal.FreeHGlobal(b); }
    }
    public static UIntResult BaseType(LUID a, uint id) {
      IntPtr b = Packet(6, 24, a, id);
      try { UIntResult r = new UIntResult(); r.Status = DisplayConfigGetDeviceInfo(b); if (r.Status == 0) r.Value = (uint)Marshal.ReadInt32(b, 20); return r; }
      finally { Marshal.FreeHGlobal(b); }
    }
    public static AdvColor AdvancedColor(LUID a, uint id) {
      IntPtr b = Packet(9, 32, a, id);
      try {
        AdvColor c = new AdvColor(); c.Status = DisplayConfigGetDeviceInfo(b);
        if (c.Status == 0) { c.Value = (uint)Marshal.ReadInt32(b, 20); c.ColorEncoding = (uint)Marshal.ReadInt32(b, 24); c.BitsPerColorChannel = (uint)Marshal.ReadInt32(b, 28); }
        return c;
      } finally { Marshal.FreeHGlobal(b); }
    }
  }

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct DISPLAY_DEVICE {
    public int cb;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
    public int StateFlags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
  }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
    public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra; public int dmFields;
    public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
    public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
    public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency;
    public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight;
  }
  public static class Gdi {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE dd, uint flags);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool EnumDisplaySettingsEx(string name, int mode, ref DEVMODE dm, uint flags);
    public static DISPLAY_DEVICE NewDD() { DISPLAY_DEVICE d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE)); return d; }
    public static DEVMODE NewDM() { DEVMODE d = new DEVMODE(); d.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return d; }
  }

  [StructLayout(LayoutKind.Sequential)] public struct KMT_ADAPTERINFO { public uint hAdapter; public LUID AdapterLuid; public uint NumOfSources; public int bPrecisePresentRegionsPreferred; }
  [StructLayout(LayoutKind.Sequential)] public struct KMT_ENUMADAPTERS2 { public uint NumAdapters; public IntPtr pAdapters; }
  [StructLayout(LayoutKind.Sequential)] public struct KMT_QUERYADAPTERINFO { public uint hAdapter; public int Type; public IntPtr pData; public uint DataSize; }
  [StructLayout(LayoutKind.Sequential)] public struct KMT_CLOSEADAPTER { public uint hAdapter; }

  public class KmtAdapter {
    public uint LuidLow; public int LuidHigh; public uint NumOfSources;
    public int AddrStatus; public uint BusNumber; public uint DeviceNumber; public uint FunctionNumber;
    public int TypeStatus; public uint TypeFlags;
    public int VersionStatus; public int DriverVersion;
    public int SegStatus; public ulong DedicatedVideoMemory; public ulong DedicatedSystemMemory; public ulong SharedSystemMemory;
    public int RegStatus; public string AdapterString; public string BiosString; public string DacType; public string ChipType;
  }
  public static class Kmt {
    [DllImport("gdi32.dll")] static extern int D3DKMTEnumAdapters2(ref KMT_ENUMADAPTERS2 p);
    [DllImport("gdi32.dll")] static extern int D3DKMTQueryAdapterInfo(ref KMT_QUERYADAPTERINFO p);
    [DllImport("gdi32.dll")] static extern int D3DKMTCloseAdapter(ref KMT_CLOSEADAPTER p);

    static int Q(uint h, int type, IntPtr buf, int size) {
      KMT_QUERYADAPTERINFO q = new KMT_QUERYADAPTERINFO(); q.hAdapter = h; q.Type = type; q.pData = buf; q.DataSize = (uint)size;
      return D3DKMTQueryAdapterInfo(ref q);
    }
    public static int LastEnumStatus;
    public static List<KmtAdapter> Enumerate() {
      List<KmtAdapter> list = new List<KmtAdapter>();
      KMT_ENUMADAPTERS2 e = new KMT_ENUMADAPTERS2();
      LastEnumStatus = D3DKMTEnumAdapters2(ref e);
      if (LastEnumStatus != 0) return list;
      int sz = Marshal.SizeOf(typeof(KMT_ADAPTERINFO));
      e.pAdapters = Marshal.AllocHGlobal(sz * (int)Math.Max(1, e.NumAdapters));
      try {
        LastEnumStatus = D3DKMTEnumAdapters2(ref e);
        if (LastEnumStatus != 0) return list;
        IntPtr buf = Marshal.AllocHGlobal(4096);
        try {
          for (int i = 0; i < e.NumAdapters; i++) {
            KMT_ADAPTERINFO ai = (KMT_ADAPTERINFO)Marshal.PtrToStructure(new IntPtr(e.pAdapters.ToInt64() + i * sz), typeof(KMT_ADAPTERINFO));
            KmtAdapter a = new KmtAdapter();
            a.LuidLow = ai.AdapterLuid.LowPart; a.LuidHigh = ai.AdapterLuid.HighPart; a.NumOfSources = ai.NumOfSources;
            Zero(buf, 4096); a.AddrStatus = Q(ai.hAdapter, 6, buf, 12);
            if (a.AddrStatus == 0) { a.BusNumber = (uint)Marshal.ReadInt32(buf, 0); a.DeviceNumber = (uint)Marshal.ReadInt32(buf, 4); a.FunctionNumber = (uint)Marshal.ReadInt32(buf, 8); }
            Zero(buf, 4096); a.TypeStatus = Q(ai.hAdapter, 15, buf, 4);
            if (a.TypeStatus == 0) a.TypeFlags = (uint)Marshal.ReadInt32(buf, 0);
            Zero(buf, 4096); a.VersionStatus = Q(ai.hAdapter, 13, buf, 4);
            if (a.VersionStatus == 0) a.DriverVersion = Marshal.ReadInt32(buf, 0);
            Zero(buf, 4096); a.SegStatus = Q(ai.hAdapter, 3, buf, 24);
            if (a.SegStatus == 0) { a.DedicatedVideoMemory = (ulong)Marshal.ReadInt64(buf, 0); a.DedicatedSystemMemory = (ulong)Marshal.ReadInt64(buf, 8); a.SharedSystemMemory = (ulong)Marshal.ReadInt64(buf, 16); }
            Zero(buf, 4096); a.RegStatus = Q(ai.hAdapter, 8, buf, 2080);
            if (a.RegStatus == 0) {
              a.AdapterString = Marshal.PtrToStringUni(buf);
              a.BiosString = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + 520));
              a.DacType = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + 1040));
              a.ChipType = Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + 1560));
            }
            KMT_CLOSEADAPTER c = new KMT_CLOSEADAPTER(); c.hAdapter = ai.hAdapter; D3DKMTCloseAdapter(ref c);
            list.Add(a);
          }
        } finally { Marshal.FreeHGlobal(buf); }
      } finally { Marshal.FreeHGlobal(e.pAdapters); }
      return list;
    }
    static void Zero(IntPtr b, int n) { for (int i = 0; i < n; i++) Marshal.WriteByte(b, i, 0); }
  }

  public class CoreInfo { public int EfficiencyClass; public int Flags; public int LogicalCount; }
  public static class Fw {
    [DllImport("kernel32.dll", SetLastError = true)] public static extern uint EnumSystemFirmwareTables(uint provider, byte[] buffer, uint size);
    [DllImport("kernel32.dll", SetLastError = true)] public static extern uint GetSystemFirmwareTable(uint provider, uint id, byte[] buffer, uint size);
    [DllImport("kernel32.dll", SetLastError = true)] public static extern bool GetFirmwareType(out int type);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetLogicalProcessorInformationEx(int rel, IntPtr buf, ref uint len);

    public static int LastError;
    public static byte[] Enum(uint provider) {
      uint n = EnumSystemFirmwareTables(provider, null, 0);
      if (n == 0) { LastError = Marshal.GetLastWin32Error(); return null; }
      byte[] b = new byte[n];
      uint got = EnumSystemFirmwareTables(provider, b, n);
      if (got == 0) { LastError = Marshal.GetLastWin32Error(); return null; }
      return b;
    }
    public static byte[] Get(uint provider, uint id) {
      uint n = GetSystemFirmwareTable(provider, id, null, 0);
      if (n == 0) { LastError = Marshal.GetLastWin32Error(); return null; }
      byte[] b = new byte[n];
      uint got = GetSystemFirmwareTable(provider, id, b, n);
      if (got == 0) { LastError = Marshal.GetLastWin32Error(); return null; }
      return b;
    }
    public static List<CoreInfo> Cores() {
      List<CoreInfo> list = new List<CoreInfo>();
      uint len = 0;
      GetLogicalProcessorInformationEx(0, IntPtr.Zero, ref len);
      if (len == 0) { LastError = Marshal.GetLastWin32Error(); return list; }
      IntPtr buf = Marshal.AllocHGlobal((int)len);
      try {
        if (!GetLogicalProcessorInformationEx(0, buf, ref len)) { LastError = Marshal.GetLastWin32Error(); return list; }
        int off = 0;
        while (off < len) {
          IntPtr p = new IntPtr(buf.ToInt64() + off);
          int rel = Marshal.ReadInt32(p, 0); int size = Marshal.ReadInt32(p, 4);
          if (rel == 0) {
            CoreInfo c = new CoreInfo();
            c.Flags = Marshal.ReadByte(p, 8); c.EfficiencyClass = Marshal.ReadByte(p, 9);
            int groupCount = Marshal.ReadInt16(p, 30);
            int cnt = 0;
            for (int g = 0; g < groupCount; g++) {
              ulong mask = (ulong)Marshal.ReadInt64(p, 32 + g * 16);
              while (mask != 0) { cnt += (int)(mask & 1); mask >>= 1; }
            }
            c.LogicalCount = cnt; list.Add(c);
          }
          if (size <= 0) break;
          off += size;
        }
      } finally { Marshal.FreeHGlobal(buf); }
      return list;
    }
  }
}
'@
Add-Type -TypeDefinition $cs -Language CSharp

# ---------------------------------------------------------------- lookup tables
$OutTech = @{
    '4294967295' = 'OTHER'; '0' = 'HD15'; '1' = 'SVIDEO'; '2' = 'COMPOSITE_VIDEO'; '3' = 'COMPONENT_VIDEO'; '4' = 'DVI'; '5' = 'HDMI'; '6' = 'LVDS';
    '8' = 'D_JPN'; '9' = 'SDI'; '10' = 'DISPLAYPORT_EXTERNAL'; '11' = 'DISPLAYPORT_EMBEDDED'; '12' = 'UDI_EXTERNAL'; '13' = 'UDI_EMBEDDED';
    '14' = 'SDTVDONGLE'; '15' = 'MIRACAST'; '16' = 'INDIRECT_WIRED'; '17' = 'INDIRECT_VIRTUAL'; '18' = 'DISPLAYPORT_USB_TUNNEL'; '2147483648' = 'INTERNAL'
}
function Get-OutTechName($v) { $k = [string]$v; if ($OutTech.ContainsKey($k)) { return $OutTech[$k] } return "UNKNOWN($k)" }
function Format-Luid($low, $high) { return ('{0:X8}:{1:X8}' -f [uint32]$high, [uint32]$low) }
function Convert-AdapterPathToInstance([string]$p) {
    if (-not $p) { return $null }
    $t = $p -replace '^\\\\\?\\', ''
    $parts = $t.Split('#')
    if ($parts.Count -ge 3) { return ($parts[0] + '\' + $parts[1] + '\' + $parts[2]).ToUpperInvariant() }
    return $null
}
function Get-RegValues([string]$Path, [string[]]$Names) {
    $o = [ordered]@{}
    $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
    foreach ($n in $Names) {
        $v = $item.$n
        if ($v -is [byte[]]) {
            if ($n -like 'HardwareInformation.*String' -or $n -like 'HardwareInformation.ChipType' -or $n -like 'HardwareInformation.DacType') {
                $v = ([Text.Encoding]::Unicode.GetString($v)).TrimEnd([char]0)
            } elseif ($v.Length -le 8) {
                $pad = New-Object byte[] 8; [Array]::Copy($v, $pad, $v.Length); $v = [BitConverter]::ToUInt64($pad, 0)
            } else { $v = 'binary(' + $v.Length + ' bytes)' }
        }
        $o[$n] = $v
    }
    return $o
}

# ================================================================ PROBES
# ---- 1. platform and OS
Invoke-Probe -Id 'P01_os' -Title 'Windows version and build' -Source 'CIM Win32_OperatingSystem + registry HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Script {
    $os = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, MUILanguages
    $cv = Get-RegValues 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' @('ProductName', 'DisplayVersion', 'EditionID', 'CurrentBuild', 'UBR', 'InstallationType')
    [ordered]@{ win32_operatingsystem = $os; currentversion = $cv }
}

Invoke-Probe -Id 'P02_system' -Title 'System model, baseboard, BIOS' -Source 'CIM Win32_ComputerSystem / Win32_ComputerSystemProduct / Win32_BaseBoard / Win32_BIOS (serial/UUID fields not selected)' -Script {
    $csys = Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, SystemFamily, SystemSKUNumber, SystemType, PCSystemType, NumberOfProcessors, NumberOfLogicalProcessors, TotalPhysicalMemory, HypervisorPresent
    $prod = Get-CimInstance Win32_ComputerSystemProduct | Select-Object Vendor, Name, Version
    $bb = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, Version
    $bios = Get-CimInstance Win32_BIOS | Select-Object Manufacturer, Name, SMBIOSBIOSVersion, BIOSVersion, SMBIOSMajorVersion, SMBIOSMinorVersion, SystemBiosMajorVersion, SystemBiosMinorVersion, EmbeddedControllerMajorVersion, EmbeddedControllerMinorVersion, @{n = 'ReleaseDate'; e = { Format-Date $_.ReleaseDate } }
    $hwbios = $null
    try { $hwbios = Get-RegValues 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' @('BIOSVendor', 'BIOSVersion', 'BIOSReleaseDate', 'SystemManufacturer', 'SystemProductName', 'SystemFamily', 'SystemVersion', 'SystemSKU', 'BaseBoardManufacturer', 'BaseBoardProduct', 'BaseBoardVersion', 'BiosMajorRelease', 'BiosMinorRelease', 'ECFirmwareMajorRelease', 'ECFirmwareMinorRelease') } catch { Add-ProbeError ('registry HARDWARE\DESCRIPTION\System\BIOS: ' + $_.Exception.Message) }
    [ordered]@{ computer_system = $csys; computer_system_product = $prod; baseboard = $bb; bios = $bios; registry_hardware_description_bios = $hwbios }
}

Invoke-Probe -Id 'P03_cpu' -Title 'CPU model, cores, threads, P/E topology' -Source 'CIM Win32_Processor + kernel32 GetLogicalProcessorInformationEx(RelationProcessorCore) + registry CentralProcessor\0' -Script {
    $p = Get-CimInstance Win32_Processor | Select-Object Name, Manufacturer, Caption, NumberOfCores, NumberOfEnabledCore, NumberOfLogicalProcessors, MaxClockSpeed, L2CacheSize, L3CacheSize, SocketDesignation, VirtualizationFirmwareEnabled, VMMonitorModeExtensions, SecondLevelAddressTranslationExtensions
    $cores = [HonorSurvey.Fw]::Cores()
    if ($cores.Count -eq 0) { Add-ProbeError ('GetLogicalProcessorInformationEx failed, Win32 error ' + [HonorSurvey.Fw]::LastError) }
    $groups = $cores | Group-Object EfficiencyClass | ForEach-Object { [ordered]@{ efficiency_class = [int]$_.Name; core_count = $_.Count; logical_processors = ($_.Group | Measure-Object LogicalCount -Sum).Sum; smt_cores = @($_.Group | Where-Object { $_.Flags -band 1 }).Count } }
    $reg = $null
    try {
        $r = Get-ItemProperty -LiteralPath 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0'
        $ucode = $null
        $ur = $r.'Update Revision'
        if ($ur -is [byte[]]) { $ucode = '0x' + [BitConverter]::ToUInt32($ur, $(if ($ur.Length -ge 8) { 4 } else { 0 })).ToString('X'); $ucodeRaw = ($ur | ForEach-Object { $_.ToString('X2') }) -join ' ' }
        $reg = [ordered]@{ ProcessorNameString = $r.ProcessorNameString; Identifier = $r.Identifier; VendorIdentifier = $r.VendorIdentifier; MHz = $r.'~MHz'; MicrocodeUpdateRevision = $ucode; UpdateRevisionRawBytes = $ucodeRaw }
    } catch { Add-ProbeError ('registry CentralProcessor\0: ' + $_.Exception.Message) }
    [ordered]@{ win32_processor = $p; core_topology_by_efficiency_class = @($groups); total_cores = $cores.Count; total_logical = ($cores | Measure-Object LogicalCount -Sum).Sum; registry = $reg; note = 'On Intel hybrid CPUs Windows reports P-cores with the higher EfficiencyClass value.' }
}

Invoke-Probe -Id 'P04_memory' -Title 'Physical memory modules' -Source 'CIM Win32_PhysicalMemory / Win32_PhysicalMemoryArray (SerialNumber not selected)' -Script {
    $m = Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, DeviceLocator, Capacity, Speed, ConfiguredClockSpeed, ConfiguredVoltage, Manufacturer, PartNumber, SMBIOSMemoryType, MemoryType, FormFactor, DataWidth, TotalWidth
    $a = Get-CimInstance Win32_PhysicalMemoryArray | Select-Object MaxCapacity, MaxCapacityEx, MemoryDevices, MemoryErrorCorrection
    [ordered]@{ modules = @($m); arrays = @($a); total_bytes = ($m | Measure-Object Capacity -Sum).Sum }
}

Invoke-Probe -Id 'P05_firmware_mode' -Title 'Boot firmware type and Secure Boot state (registry)' -Source 'kernel32 GetFirmwareType + registry Control\PEFirmwareType + Control\SecureBoot\State' -Script {
    $t = 0; $ok = [HonorSurvey.Fw]::GetFirmwareType([ref]$t)
    if (-not $ok) { Add-ProbeError ('GetFirmwareType failed, Win32 error ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error()) }
    $names = @{ 1 = 'BIOS (Legacy)'; 2 = 'UEFI' }
    $pe = $null; try { $pe = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control').PEFirmwareType } catch { Add-ProbeError ('PEFirmwareType: ' + $_.Exception.Message) }
    $sb = $null; try { $sb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction Stop).UEFISecureBootEnabled } catch { Add-ProbeError ('SecureBoot\State: ' + $_.Exception.Message) }
    [ordered]@{ GetFirmwareType_raw = $t; GetFirmwareType = $(if ($names.ContainsKey($t)) { $names[$t] } else { 'Unknown' }); registry_PEFirmwareType = $pe; registry_UEFISecureBootEnabled = $sb }
}

Invoke-Probe -Id 'P06_secureboot_cmdlet' -Title 'Confirm-SecureBootUEFI (cmdlet cross-check)' -Source 'PowerShell SecureBoot module Confirm-SecureBootUEFI (read-only; requires elevation)' -Script {
    [ordered]@{ Confirm_SecureBootUEFI = (Confirm-SecureBootUEFI) }
}

# ---- 2. GPU / display
Invoke-Probe -Id 'P10_video_controller' -Title 'Win32_VideoController' -Source 'CIM Win32_VideoController' -Script {
    @(Get-CimInstance Win32_VideoController | Select-Object Name, PNPDeviceID, AdapterCompatibility, VideoProcessor, AdapterRAM, AdapterDACType, DriverVersion, @{n = 'DriverDate'; e = { Format-Date $_.DriverDate } }, InfSection, Status, ConfigManagerErrorCode, Availability, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate, CurrentBitsPerPixel, VideoModeDescription)
}

Invoke-Probe -Id 'P11_gpu_class_registry' -Title 'Display class registry keys (driver, HardwareInformation.*)' -Source 'registry HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\NNNN (read-only)' -Script {
    $rel = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    $root = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($rel, $false)
    if ($null -eq $root) { throw 'display class key not readable' }
    $subs = @($root.GetSubKeyNames() | Where-Object { $_ -match '^\d{4}$' })
    $root.Close()
    $out = @()
    foreach ($sub in $subs) {
        $k = [pscustomobject]@{ PSChildName = $sub; PSPath = "HKLM:\$rel\$sub" }
        try {
            $vals = Get-RegValues $k.PSPath @('DriverDesc', 'ProviderName', 'DriverVersion', 'DriverDate', 'MatchingDeviceId', 'InfPath', 'InfSection', 'HardwareInformation.qwMemorySize', 'HardwareInformation.MemorySize', 'HardwareInformation.AdapterString', 'HardwareInformation.BiosString', 'HardwareInformation.ChipType', 'HardwareInformation.DacType')
            $names = @((Get-Item -LiteralPath $k.PSPath).GetValueNames())
            $interesting = @($names | Where-Object { $_ -match '(?i)vbt|opregion|edp|panel|mux|optimus|hybrid|dds|psr|lane|linkrate|backlight|dmc' })
            $ivals = [ordered]@{}
            if ($interesting.Count) {
                $ip = Get-ItemProperty -LiteralPath $k.PSPath
                foreach ($n in $interesting) {
                    $v = $ip.$n
                    if ($v -is [byte[]]) { $v = $(if ($v.Length -le 16) { 'hex:' + (($v | ForEach-Object { $_.ToString('X2') }) -join '') } else { 'binary(' + $v.Length + ' bytes)' }) }
                    elseif ($v -is [string] -and $v.Length -gt 64) { $v = $v.Substring(0, 64) + '...' }
                    $ivals[$n] = $v
                }
            }
            $out += [ordered]@{ key = $k.PSChildName; values = $vals; value_name_count = $names.Count; display_related_values = $ivals }
        } catch { Add-ProbeError ("$($k.PSChildName): " + $_.Exception.Message) }
    }
    $out
}

Invoke-Probe -Id 'P12_d3dkmt_adapters' -Title 'WDDM adapters: LUID, PCI address, sources, hybrid flags, memory segments, BIOS string' -Source 'gdi32 D3DKMTEnumAdapters2 + D3DKMTQueryAdapterInfo(ADAPTERADDRESS, ADAPTERTYPE, DRIVERVERSION, GETSEGMENTSIZE, ADAPTERREGISTRYINFO)' -Script {
    $list = [HonorSurvey.Kmt]::Enumerate()
    if ([HonorSurvey.Kmt]::LastEnumStatus -ne 0) { Add-ProbeError ('D3DKMTEnumAdapters2 NTSTATUS 0x' + ('{0:X8}' -f [HonorSurvey.Kmt]::LastEnumStatus)) }
    $bits = @('RenderSupported', 'DisplaySupported', 'SoftwareDevice', 'PostDevice', 'HybridDiscrete', 'HybridIntegrated', 'IndirectDisplayDevice', 'Paravirtualized', 'ACGSupported', 'SupportSetTimingsFromVidPn', 'Detachable', 'ComputeOnly', 'Prototype', 'RuntimePowerManagement')
    foreach ($a in $list) {
        $flags = [ordered]@{}
        for ($i = 0; $i -lt $bits.Count; $i++) { $flags[$bits[$i]] = [bool]($a.TypeFlags -band (1 -shl $i)) }
        foreach ($s in 'AddrStatus', 'TypeStatus', 'VersionStatus', 'SegStatus', 'RegStatus') { if ($a.$s -ne 0) { Add-ProbeError ("LUID $(Format-Luid $a.LuidLow $a.LuidHigh) $s NTSTATUS 0x" + ('{0:X8}' -f $a.$s)) } }
        [ordered]@{
            luid = (Format-Luid $a.LuidLow $a.LuidHigh); num_of_sources = $a.NumOfSources
            pci_address = $(if ($a.AddrStatus -eq 0) { [ordered]@{ bus = $a.BusNumber; device = $a.DeviceNumber; function = $a.FunctionNumber } } else { $null })
            adapter_type_raw = $(if ($a.TypeStatus -eq 0) { '0x' + $a.TypeFlags.ToString('X') } else { $null }); adapter_type = $(if ($a.TypeStatus -eq 0) { $flags } else { $null })
            wddm_driver_version_enum = $(if ($a.VersionStatus -eq 0) { $a.DriverVersion } else { $null })
            segment_sizes_bytes = $(if ($a.SegStatus -eq 0) { [ordered]@{ dedicated_video = $a.DedicatedVideoMemory; dedicated_system = $a.DedicatedSystemMemory; shared_system = $a.SharedSystemMemory } } else { $null })
            registry_info = $(if ($a.RegStatus -eq 0) { [ordered]@{ adapter_string = $a.AdapterString; bios_string = $a.BiosString; dac_type = $a.DacType; chip_type = $a.ChipType } } else { $null })
        }
    }
}

function Get-DisplayPathRecord($path, $modes, [switch]$Full) {
    $s = $path.sourceInfo; $t = $path.targetInfo
    $an = [HonorSurvey.DisplayCfg]::AdapterName($t.adapterId)
    $tn = [HonorSurvey.DisplayCfg]::Target($t.adapterId, $t.id)
    $rec = [ordered]@{
        source_adapter_luid = (Format-Luid $s.adapterId.LowPart $s.adapterId.HighPart); source_id = $s.id
        target_adapter_luid = (Format-Luid $t.adapterId.LowPart $t.adapterId.HighPart); target_id = $t.id
        target_adapter_device_path = $(if ($an.Status -eq 0) { $an.Value } else { "error $($an.Status)" })
        target_adapter_instance_id = $(if ($an.Status -eq 0) { Convert-AdapterPathToInstance $an.Value } else { $null })
        output_technology_raw = $t.outputTechnology; output_technology = (Get-OutTechName $t.outputTechnology)
        target_available = [bool]$t.targetAvailable; path_flags = $path.flags; target_status_flags = $t.statusFlags
        target_name = $(if ($tn.Status -eq 0) { [ordered]@{ friendly_name = $tn.FriendlyName; monitor_device_path = $tn.MonitorDevicePath; connector_instance = $tn.ConnectorInstance; edid_ids_valid = [bool]($tn.Flags -band 4); friendly_name_from_edid = [bool]($tn.Flags -band 1); edid_manufacture_id_raw = $tn.EdidManufactureId; edid_product_code_id = ('0x{0:X4}' -f $tn.EdidProductCodeId); output_technology = (Get-OutTechName $tn.OutputTechnology) } } else { [ordered]@{ error = $tn.Status } })
    }
    if ($Full) {
        $src = [HonorSurvey.DisplayCfg]::SourceName($s.adapterId, $s.id)
        $pm = [HonorSurvey.DisplayCfg]::Preferred($t.adapterId, $t.id)
        $bt = [HonorSurvey.DisplayCfg]::BaseType($t.adapterId, $t.id)
        $ac = [HonorSurvey.DisplayCfg]::AdvancedColor($t.adapterId, $t.id)
        $rec.source_gdi_name = $(if ($src.Status -eq 0) { $src.Value } else { "error $($src.Status)" })
        $rec.refresh_rate_hz = $(if ($t.refreshRate.Denominator) { [math]::Round($t.refreshRate.Numerator / $t.refreshRate.Denominator, 3) } else { $null })
        $rec.refresh_rate_rational = "$($t.refreshRate.Numerator)/$($t.refreshRate.Denominator)"
        $rec.base_output_technology = $(if ($bt.Status -eq 0) { Get-OutTechName $bt.Value } else { "error $($bt.Status)" })
        $sm = $null; $tm = $null
        if ($s.modeInfoIdx -ne [uint32]::MaxValue -and $s.modeInfoIdx -lt $modes.Count) { $m = $modes[$s.modeInfoIdx]; if ($m.infoType -eq 1) { $sm = [ordered]@{ width = $m.srcWidth; height = $m.srcHeight; pixel_format = $m.srcPixelFormat; position = "$($m.srcPosX),$($m.srcPosY)" } } }
        if ($t.modeInfoIdx -ne [uint32]::MaxValue -and $t.modeInfoIdx -lt $modes.Count) { $m = $modes[$t.modeInfoIdx]; if ($m.infoType -eq 2) { $tm = [ordered]@{ active = "$($m.activeCx)x$($m.activeCy)"; total = "$($m.totalCx)x$($m.totalCy)"; pixel_rate_hz = $m.pixelRate; vsync_hz = $(if ($m.vSyncDen) { [math]::Round($m.vSyncNum / $m.vSyncDen, 3) } else { $null }); hsync_hz = $(if ($m.hSyncDen) { [math]::Round($m.hSyncNum / $m.hSyncDen, 1) } else { $null }); video_standard = $m.videoStandard; scanline_ordering = $m.scanLineOrdering } } }
        $rec.source_mode = $sm; $rec.target_mode = $tm
        $rec.preferred_mode = $(if ($pm.Status -eq 0) { [ordered]@{ width = $pm.Width; height = $pm.Height; active = "$($pm.ActiveCx)x$($pm.ActiveCy)"; total = "$($pm.TotalCx)x$($pm.TotalCy)"; pixel_rate_hz = $pm.PixelRate; vsync_hz = $(if ($pm.VSyncDen) { [math]::Round($pm.VSyncNum / $pm.VSyncDen, 3) } else { $null }) } } else { [ordered]@{ error = $pm.Status } })
        $rec.advanced_color = $(if ($ac.Status -eq 0) { [ordered]@{ supported = [bool]($ac.Value -band 1); enabled = [bool]($ac.Value -band 2); bits_per_color_channel = $ac.BitsPerColorChannel; color_encoding = $ac.ColorEncoding } } else { [ordered]@{ error = $ac.Status } })
    }
    return $rec
}

Invoke-Probe -Id 'P13_displayconfig_active' -Title 'Active display paths (QueryDisplayConfig QDC_ONLY_ACTIVE_PATHS)' -Source 'user32 QueryDisplayConfig + DisplayConfigGetDeviceInfo (SOURCE_NAME, TARGET_NAME, TARGET_PREFERRED_MODE, ADAPTER_NAME, TARGET_BASE_TYPE, ADVANCED_COLOR_INFO)' -Script {
    $q = [HonorSurvey.DisplayCfg]::Query(2)
    if ($q.Status -ne 0) { throw "QueryDisplayConfig returned $($q.Status)" }
    [ordered]@{ path_count = $q.Paths.Count; mode_count = $q.Modes.Count; paths = @(foreach ($p in $q.Paths) { Get-DisplayPathRecord $p $q.Modes -Full }) }
}

Invoke-Probe -Id 'P14_displayconfig_all_targets' -Title 'All possible display targets per adapter (QueryDisplayConfig QDC_ALL_PATHS, deduplicated by adapter+target)' -Source 'user32 QueryDisplayConfig(QDC_ALL_PATHS) + DisplayConfigGetDeviceInfo (TARGET_NAME, ADAPTER_NAME)' -Script {
    $q = [HonorSurvey.DisplayCfg]::Query(1)
    if ($q.Status -ne 0) { throw "QueryDisplayConfig returned $($q.Status)" }
    $seen = @{}; $targets = @()
    foreach ($p in $q.Paths) {
        $key = (Format-Luid $p.targetInfo.adapterId.LowPart $p.targetInfo.adapterId.HighPart) + '/' + $p.targetInfo.id
        if ($seen.ContainsKey($key)) { if ($p.targetInfo.targetAvailable) { $seen[$key].target_available = $true }; continue }
        $r = Get-DisplayPathRecord $p $q.Modes
        $r.Remove('source_adapter_luid'); $r.Remove('source_id'); $r.Remove('path_flags')
        $seen[$key] = $r; $targets += $r
    }
    [ordered]@{ raw_path_count = $q.Paths.Count; unique_target_count = $targets.Count; targets = $targets; note = 'Targets are connectors the driver exposes to the OS. Exposure is not proof of physical wiring; target_available=true means the OS currently considers something attached.' }
}

Invoke-Probe -Id 'P15_enum_display_devices' -Title 'GDI display devices and attached monitors' -Source 'user32 EnumDisplayDevices (adapters and monitors)' -Script {
    $out = @()
    for ($i = 0; $i -lt 64; $i++) {
        $dd = [HonorSurvey.Gdi]::NewDD()
        if (-not [HonorSurvey.Gdi]::EnumDisplayDevices([NullString]::Value, [uint32]$i, [ref]$dd, 0)) { break }
        $mons = @()
        for ($j = 0; $j -lt 16; $j++) {
            $md = [HonorSurvey.Gdi]::NewDD()
            if (-not [HonorSurvey.Gdi]::EnumDisplayDevices($dd.DeviceName, [uint32]$j, [ref]$md, 0)) { break }
            $mons += [ordered]@{ device_name = $md.DeviceName; device_string = $md.DeviceString; state_flags = ('0x{0:X}' -f $md.StateFlags); active = [bool]($md.StateFlags -band 1); attached = [bool]($md.StateFlags -band 2); device_id = $md.DeviceID }
        }
        $out += [ordered]@{ device_name = $dd.DeviceName; device_string = $dd.DeviceString; state_flags = ('0x{0:X}' -f $dd.StateFlags); attached_to_desktop = [bool]($dd.StateFlags -band 1); primary = [bool]($dd.StateFlags -band 4); device_id = $dd.DeviceID; monitors = $mons }
    }
    $out
}

Invoke-Probe -Id 'P16_display_modes' -Title 'Current and enumerable display modes per active GDI source' -Source 'user32 EnumDisplaySettingsEx (ENUM_CURRENT_SETTINGS and mode index enumeration)' -Script {
    $out = @()
    for ($i = 0; $i -lt 64; $i++) {
        $dd = [HonorSurvey.Gdi]::NewDD()
        if (-not [HonorSurvey.Gdi]::EnumDisplayDevices([NullString]::Value, [uint32]$i, [ref]$dd, 0)) { break }
        if (-not ($dd.StateFlags -band 1)) { continue }
        $cur = [HonorSurvey.Gdi]::NewDM()
        $ok = [HonorSurvey.Gdi]::EnumDisplaySettingsEx($dd.DeviceName, -1, [ref]$cur, 0)
        $modes = New-Object System.Collections.Generic.HashSet[string]
        for ($m = 0; $m -lt 5000; $m++) {
            $dm = [HonorSurvey.Gdi]::NewDM()
            if (-not [HonorSurvey.Gdi]::EnumDisplaySettingsEx($dd.DeviceName, $m, [ref]$dm, 0)) { break }
            [void]$modes.Add(('{0}x{1}@{2}Hz/{3}bpp' -f $dm.dmPelsWidth, $dm.dmPelsHeight, $dm.dmDisplayFrequency, $dm.dmBitsPerPel))
        }
        $sorted = @($modes) | Sort-Object { [int](($_ -split 'x')[0]) }, { [int](($_ -split '[x@]')[1]) }, { [int](($_ -split '[@H]')[1]) } -Descending
        $rates = @($modes | ForEach-Object { [int](($_ -split '[@H]')[1]) } | Sort-Object -Unique)
        $out += [ordered]@{ gdi_name = $dd.DeviceName; adapter = $dd.DeviceString; current = $(if ($ok) { [ordered]@{ width = $cur.dmPelsWidth; height = $cur.dmPelsHeight; frequency_hz = $cur.dmDisplayFrequency; bpp = $cur.dmBitsPerPel } } else { $null }); enumerated_mode_count = $modes.Count; refresh_rates_seen_hz = $rates; modes = $sorted }
    }
    $out
}

function Get-EdidDescriptorText([byte[]]$b, [int]$o) { return ([Text.Encoding]::ASCII.GetString($b, $o + 5, 13) -replace "`n.*$", '').Trim() }
function Get-EdidDtd([byte[]]$raw, [int]$o) {
    $b = [int[]]$raw
    $pc = [BitConverter]::ToUInt16($raw, $o) * 10000
    if ($pc -eq 0) { return $null }
    $ha = $b[$o + 2] + (($b[$o + 4] -shr 4) -shl 8); $hb = $b[$o + 3] + (($b[$o + 4] -band 0xF) -shl 8)
    $va = $b[$o + 5] + (($b[$o + 7] -shr 4) -shl 8); $vb = $b[$o + 6] + (($b[$o + 7] -band 0xF) -shl 8)
    $hso = $b[$o + 8] + ((($b[$o + 11] -shr 6) -band 3) -shl 8); $hsw = $b[$o + 9] + ((($b[$o + 11] -shr 4) -band 3) -shl 8)
    $vso = ($b[$o + 10] -shr 4) + ((($b[$o + 11] -shr 2) -band 3) -shl 4); $vsw = ($b[$o + 10] -band 0xF) + (($b[$o + 11] -band 3) -shl 4)
    $hmm = $b[$o + 12] + (($b[$o + 14] -shr 4) -shl 8); $vmm = $b[$o + 13] + (($b[$o + 14] -band 0xF) -shl 8)
    $refresh = [math]::Round($pc / (($ha + $hb) * ($va + $vb)), 3)
    return [ordered]@{ pixel_clock_khz = $pc / 1000; h_active = $ha; h_blank = $hb; h_sync_offset = $hso; h_sync_width = $hsw; v_active = $va; v_blank = $vb; v_sync_offset = $vso; v_sync_width = $vsw; image_mm = "${hmm}x${vmm}"; interlaced = [bool]($b[$o + 17] -band 0x80); flags_raw = ('0x{0:X2}' -f $b[$o + 17]); refresh_hz = $refresh }
}
function Set-BlockChecksum([byte[]]$b, [int]$start, [int]$len) {
    $sum = 0; for ($i = $start; $i -lt $start + $len - 1; $i++) { $sum += $b[$i] }
    $b[$start + $len - 1] = [byte]((256 - ($sum % 256)) % 256)
}
function Read-Edid([byte[]]$raw) {
    $b = [byte[]]$raw.Clone()
    $actions = @()
    $info = [ordered]@{ length = $b.Length }
    if ($b.Length -lt 128 -or $b[0] -ne 0 -or $b[1] -ne 0xFF) { $info.valid_header = $false; return @{ info = $info; sanitized = $null; actions = @('not an EDID 1.x block; not shared') } }
    $info.valid_header = $true
    $mid = ([int]$b[8] -shl 8) -bor $b[9]
    $info.manufacturer_pnp_id = [string]([char](64 + (($mid -shr 10) -band 31))) + [char](64 + (($mid -shr 5) -band 31)) + [char](64 + ($mid -band 31))
    $info.product_code = ('0x{0:X4}' -f [BitConverter]::ToUInt16($b, 10))
    $info.serial_number_field_present = ([BitConverter]::ToUInt32($b, 12) -ne 0)
    $info.manufacture_week = $b[16]; $info.manufacture_year = 1990 + $b[17]
    $info.edid_version = "$($b[18]).$($b[19])"
    $info.digital_input = [bool]($b[20] -band 0x80)
    if ($b[20] -band 0x80) {
        $bpcMap = @{ 0 = 'undefined'; 1 = '6'; 2 = '8'; 3 = '10'; 4 = '12'; 5 = '14'; 6 = '16'; 7 = 'reserved' }
        $ifMap = @{ 0 = 'undefined'; 1 = 'DVI'; 2 = 'HDMI-a'; 3 = 'HDMI-b'; 4 = 'MDDI'; 5 = 'DisplayPort' }
        $info.bits_per_color = $bpcMap[[int](($b[20] -shr 4) -band 7)]
        $iv = [int]($b[20] -band 0xF); $info.video_interface = $(if ($ifMap.ContainsKey($iv)) { $ifMap[$iv] } else { "reserved($iv)" })
    }
    $info.screen_size_cm = "$($b[21])x$($b[22])"
    $info.extension_count = $b[126]
    $dtds = @(); $texts = [ordered]@{}; $range = $null
    foreach ($o in 54, 72, 90, 108) {
        if ($b[$o] -ne 0 -or $b[$o + 1] -ne 0) { $d = Get-EdidDtd $b $o; if ($d) { $dtds += $d }; continue }
        $tag = $b[$o + 3]
        switch ($tag) {
            0xFC { $texts['monitor_name'] = Get-EdidDescriptorText $b $o }
            0xFE { if (-not $texts.Contains('unspecified_text')) { $texts['unspecified_text'] = @() }; $texts['unspecified_text'] += (Get-EdidDescriptorText $b $o) }
            0xFF { for ($i = $o + 5; $i -lt $o + 18; $i++) { $b[$i] = 0x20 }; $b[$o + 5] = 0x0A; $actions += "base block descriptor at offset $o (tag 0xFF serial string) blanked" }
            0xFD { $range = [ordered]@{ v_min_hz = $b[$o + 5]; v_max_hz = $b[$o + 6]; h_min_khz = $b[$o + 7]; h_max_khz = $b[$o + 8]; max_pixel_clock_mhz = $b[$o + 9] * 10 } }
            default { }
        }
    }
    $info.detailed_timings = $dtds; $info.text_descriptors = $texts; $info.range_limits = $range
    if ($info.serial_number_field_present) { for ($i = 12; $i -le 15; $i++) { $b[$i] = 0 }; $actions += 'base block bytes 12-15 (ID serial number) zeroed' }
    Set-BlockChecksum $b 0 128
    $exts = @()
    for ($e = 1; $e -le $b[126] -and (($e + 1) * 128) -le $b.Length; $e++) {
        $o = $e * 128; $tag = $b[$o]
        $ext = [ordered]@{ index = $e; tag = ('0x{0:X2}' -f $tag) }
        if ($tag -eq 0x02) {
            $ext.type = 'CTA-861'; $ext.revision = $b[$o + 1]
            $dtdStart = $b[$o + 2]; $cd = @()
            if ($dtdStart -ge 4) { for ($p = $o + $dtdStart; $p + 18 -le $o + 127; $p += 18) { $d = Get-EdidDtd $b $p; if ($d) { $cd += $d } else { break } } }
            $ext.detailed_timings = $cd
        } elseif ($tag -eq 0x70) {
            $ext.type = 'DisplayID'; $ext.version = ('0x{0:X2}' -f $b[$o + 1])
            $secLen = $b[$o + 2]; $p = $o + 5; $end = $o + 5 + $secLen; $blocks = @(); $timings = @()
            while ($p + 3 -le $end -and $p + 3 -le $o + 127) {
                $btag = $b[$p]; $blen = $b[$p + 2]
                if ($btag -eq 0 -and $blen -eq 0) { break }
                $blocks += ('0x{0:X2}(len {1})' -f $btag, $blen)
                if (($btag -eq 0x00 -or $btag -eq 0x20) -and $blen -ge 9) {
                    for ($i = $p + 3 + 5; $i -le $p + 3 + 8; $i++) { $b[$i] = 0 }
                    $actions += "DisplayID extension $e product-identification block serial bytes zeroed"
                }
                if (($btag -eq 0x03 -or $btag -eq 0x22) -and $blen -ge 20) {
                    for ($q = $p + 3; $q + 20 -le $p + 3 + $blen; $q += 20) {
                        $pc = ([int]$b[$q] -bor ([int]$b[$q + 1] -shl 8) -bor ([int]$b[$q + 2] -shl 16)) + 1
                        $ha = [BitConverter]::ToUInt16($b, $q + 4) + 1; $hb = [BitConverter]::ToUInt16($b, $q + 6) + 1
                        $va = [BitConverter]::ToUInt16($b, $q + 12) + 1; $vb = [BitConverter]::ToUInt16($b, $q + 14) + 1
                        $timings += [ordered]@{ pixel_clock_khz = $pc * 10; h_active = $ha; h_blank = $hb; v_active = $va; v_blank = $vb; refresh_hz = [math]::Round(($pc * 10000) / (($ha + $hb) * ($va + $vb)), 3); preferred = [bool]($b[$q + 3] -band 0x80) }
                    }
                }
                $p += 3 + $blen
            }
            $ext.data_blocks = $blocks; $ext.type1_or_type7_timings = $timings
            Set-BlockChecksum $b ($o + 1) ($secLen + 5)
        } else { $ext.type = 'other' }
        Set-BlockChecksum $b $o 128
        $exts += $ext
    }
    $info.extensions = $exts
    return @{ info = $info; sanitized = $b; actions = $actions }
}

Invoke-Probe -Id 'P17_edid' -Title 'Monitor EDID (registry copy), decoded and serial-scrubbed' -Source 'registry HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\<model>\<instance>\Device Parameters\EDID (read-only) + Get-PnpDevice -Class Monitor' -Script {
    $mons = @(Get-PnpDevice -Class Monitor -ErrorAction Stop)
    $out = @()
    foreach ($m in $mons) {
        $rec = [ordered]@{ instance_id = $m.InstanceId; friendly_name = $m.FriendlyName; present = $m.Present; status = [string]$m.Status }
        try {
            $pp = Get-PnpDeviceProperty -InstanceId $m.InstanceId -KeyName 'DEVPKEY_Device_Parent', 'DEVPKEY_Device_BiosDeviceName', 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction Stop
            foreach ($x in $pp) { $rec[$x.KeyName -replace '^DEVPKEY_', ''] = $x.Data }
        } catch { Add-ProbeError ("$($m.InstanceId) properties: " + $_.Exception.Message) }
        try {
            $raw = (Get-ItemProperty -LiteralPath ("HKLM:\SYSTEM\CurrentControlSet\Enum\" + $m.InstanceId + "\Device Parameters") -ErrorAction Stop).EDID
            if ($raw -isnot [byte[]]) { throw 'EDID value missing' }
            $r = Read-Edid $raw
            $rec.edid = $r.info; $rec.sanitization_actions = $r.actions
            if ($r.sanitized) {
                $safeName = ($m.InstanceId -split '\\')[1] + '_' + $(if ($m.Present) { 'present' } else { 'not_present' })
                $binPath = Join-Path $EdidDir ($safeName + '.sanitized.bin')
                [IO.File]::WriteAllBytes($binPath, $r.sanitized)
                $hex = (($r.sanitized | ForEach-Object { $_.ToString('X2') }) -join ' ')
                $lines = for ($i = 0; $i -lt $r.sanitized.Length; $i += 16) { ('{0:X4}: ' -f $i) + (($r.sanitized[$i..([Math]::Min($i + 15, $r.sanitized.Length - 1))] | ForEach-Object { $_.ToString('X2') }) -join ' ') }
                [IO.File]::WriteAllText((Join-Path $EdidDir ($safeName + '.sanitized.hex.txt')), ("SANITIZED EDID COPY - not the unmodified original. Actions: " + ($r.actions -join '; ') + "; block checksums recomputed.`r`n" + ($lines -join "`r`n")), $Utf8)
                $rec.sanitized_files = @("evidence/edid/$safeName.sanitized.bin", "evidence/edid/$safeName.sanitized.hex.txt")
                $rec.sanitized_sha256 = (Get-FileHash -LiteralPath $binPath -Algorithm SHA256).Hash
            }
        } catch { $rec.edid_error = $_.Exception.Message; Add-ProbeError ("$($m.InstanceId): " + $_.Exception.Message) }
        $out += $rec
    }
    $out
}

Invoke-Probe -Id 'P18_wmi_monitor' -Title 'WMI monitor classes (supplementary only, not used for GPU ownership)' -Source 'CIM root\wmi WmiMonitorConnectionParams / WmiMonitorBasicDisplayParams / WmiMonitorID (SerialNumberID not selected)' -Script {
    $res = [ordered]@{}
    try { $res.connection_params = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorConnectionParams -ErrorAction Stop | Select-Object InstanceName, Active, VideoOutputTechnology) } catch { Add-ProbeError ('WmiMonitorConnectionParams: ' + $_.Exception.Message) }
    try { $res.basic_display_params = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction Stop | Select-Object InstanceName, Active, MaxHorizontalImageSize, MaxVerticalImageSize, VideoInputType, DisplayTransferCharacteristic) } catch { Add-ProbeError ('WmiMonitorBasicDisplayParams: ' + $_.Exception.Message) }
    try { $res.monitor_id = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop | ForEach-Object { [ordered]@{ InstanceName = $_.InstanceName; Active = $_.Active; ManufacturerName = (-join ($_.ManufacturerName | Where-Object { $_ } | ForEach-Object { [char]$_ })); ProductCodeID = (-join ($_.ProductCodeID | Where-Object { $_ } | ForEach-Object { [char]$_ })); UserFriendlyName = (-join ($_.UserFriendlyName | Where-Object { $_ } | ForEach-Object { [char]$_ })); YearOfManufacture = $_.YearOfManufacture; WeekOfManufacture = $_.WeekOfManufacture } }) } catch { Add-ProbeError ('WmiMonitorID: ' + $_.Exception.Message) }
    $res
}

Invoke-Probe -Id 'P19_nvidia_smi' -Title 'nvidia-smi limited field query (driver-bundled tool; no serial/UUID fields requested)' -Source 'nvidia-smi --query-gpu (installed with NVIDIA driver; not downloaded)' -Native -Script {
    $ErrorActionPreference = 'Continue'
    $exe = @("$env:SystemRoot\System32\nvidia-smi.exe", "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { throw 'nvidia-smi.exe not found in System32 or NVSMI' }
    $fields = 'name,pci.bus_id,pci.device_id,pci.sub_device_id,driver_version,vbios_version,memory.total,display_mode,display_active,pstate,driver_model.current,pcie.link.gen.max,pcie.link.width.max'
    $o = & $exe "--query-gpu=$fields" '--format=csv' 2>&1
    [ordered]@{ executable = ($exe -replace [regex]::Escape($env:SystemRoot), '%SystemRoot%'); fields = $fields; output = @($o | ForEach-Object { [string]$_ }) }
}

# ---- 3. PnP inventory
$script:Excluded = [ordered]@{}
$exclusionRe = '^(SWD|BTHENUM|BTHLE|BTHLEDEVICE|BTHHFENUM|BTHAVCTP|BTHA2DP|WPDBUSENUM|UMB|ROOT|TS_USB_HUB_ENUMERATOR|TERMINPUT_BUS|STORAGE\\VOLUME|STORAGE\\VOLUMESNAPSHOT)\\'
$exclusionClass = @('AudioEndpoint', 'WPD', 'PrintQueue', 'Printer', 'Volume', 'VolumeSnapshot')

Invoke-Probe -Id 'P20_pnp_inventory' -Title 'Present PnP devices with hardware IDs, status and signed-driver info' -Source 'CIM Win32_PnPEntity + Win32_PnPSignedDriver (software/remote-Bluetooth/volume/printer/WPD nodes excluded, counts kept)' -Script {
    $drivers = @{}
    foreach ($d in (Get-CimInstance Win32_PnPSignedDriver | Select-Object DeviceID, DriverVersion, DriverDate, DriverProviderName, InfName, IsSigned, Location)) { if ($d.DeviceID) { $drivers[$d.DeviceID.ToUpperInvariant()] = $d } }
    $all = Get-CimInstance Win32_PnPEntity | Select-Object Name, PNPClass, ClassGuid, Manufacturer, PNPDeviceID, HardwareID, CompatibleID, Status, ConfigManagerErrorCode, Present, Service
    $kept = @()
    foreach ($e in $all) {
        $id = [string]$e.PNPDeviceID
        $reason = $null
        if ($id -match $exclusionRe) { $reason = 'enumerator:' + ($id -split '\\')[0] } elseif ($exclusionClass -contains $e.PNPClass) { $reason = 'class:' + $e.PNPClass }
        if ($reason) { if ($script:Excluded.Contains($reason)) { $script:Excluded[$reason]++ } else { $script:Excluded[$reason] = 1 }; continue }
        $drv = $drivers[$id.ToUpperInvariant()]
        $kept += [ordered]@{ name = $e.Name; class = $e.PNPClass; manufacturer = $e.Manufacturer; instance_id = $id; hardware_ids = @($e.HardwareID); compatible_ids = @($e.CompatibleID); status = $e.Status; config_manager_error_code = $e.ConfigManagerErrorCode; service = $e.Service
            driver_version = $(if ($drv) { $drv.DriverVersion } else { $null }); driver_date = $(if ($drv) { Format-Date $drv.DriverDate } else { $null }); driver_provider = $(if ($drv) { $drv.DriverProviderName } else { $null }); inf = $(if ($drv) { $drv.InfName } else { $null }); location = $(if ($drv) { $drv.Location } else { $null }) }
    }
    [ordered]@{ total_present_entities = @($all).Count; kept_count = $kept.Count; excluded_counts = $script:Excluded; devices = $kept }
}

Invoke-Probe -Id 'P21_pnp_properties' -Title 'Location paths, ACPI names, parents and PCIe link state for hardware devices' -Source 'Get-PnpDeviceProperty (whitelisted DEVPKEYs only)' -Script {
    $want = @('DEVPKEY_Device_LocationPaths', 'DEVPKEY_Device_LocationInfo', 'DEVPKEY_Device_BiosDeviceName', 'DEVPKEY_Device_Parent', 'DEVPKEY_Device_BusReportedDeviceDesc', 'DEVPKEY_Device_DriverVersion', 'DEVPKEY_Device_DriverDate', 'DEVPKEY_Device_DriverProvider', 'DEVPKEY_Device_Service', 'DEVPKEY_Device_ProblemCode', 'DEVPKEY_Device_DevNodeStatus', 'DEVPKEY_Device_Address', 'DEVPKEY_Device_BusNumber', 'DEVPKEY_PciDevice_CurrentLinkSpeed', 'DEVPKEY_PciDevice_CurrentLinkWidth', 'DEVPKEY_PciDevice_MaxLinkSpeed', 'DEVPKEY_PciDevice_MaxLinkWidth', 'DEVPKEY_PciDevice_BaseClass', 'DEVPKEY_PciDevice_SubClass', 'DEVPKEY_PciDevice_ProgIf', 'DEVPKEY_Device_FirmwareRevision')
    $devs = @(Get-PnpDevice -PresentOnly -ErrorAction Stop | Where-Object { $_.InstanceId -notmatch $exclusionRe -and $_.InstanceId -match '^(PCI|USB|HID|ACPI|HDAUDIO|INTELAUDIO|DISPLAY|SCSI|NVME|USB4|INTELI2C|BTH\\MS_|BTH\\)' -and ($exclusionClass -notcontains $_.Class) })
    $out = @()
    foreach ($d in $devs) {
        try {
            $props = Get-PnpDeviceProperty -InstanceId $d.InstanceId -ErrorAction Stop | Where-Object { $want -contains $_.KeyName }
            $o = [ordered]@{ instance_id = $d.InstanceId; name = $d.FriendlyName; class = $d.Class }
            foreach ($p in $props) {
                $v = $p.Data
                if ($v -is [datetime]) { $v = $v.ToString('yyyy-MM-dd') }
                $o[$p.KeyName -replace '^DEVPKEY_', ''] = $v
            }
            $out += $o
        } catch { Add-ProbeError ("$($d.InstanceId): " + $_.Exception.Message) }
    }
    $out
}

# ---- 4. storage / boot / recovery
Invoke-Probe -Id 'P30_disks' -Title 'Disks (model, firmware, bus, partition style)' -Source 'Storage module Get-Disk / Get-PhysicalDisk + CIM Win32_DiskDrive (serial/UniqueId/Guid not selected)' -Script {
    $res = [ordered]@{}
    $res.get_disk = @(Get-Disk -ErrorAction Stop | Select-Object Number, FriendlyName, Model, Manufacturer, FirmwareVersion, BusType, PartitionStyle, Size, AllocatedSize, NumberOfPartitions, IsBoot, IsSystem, IsOffline, IsReadOnly, OperationalStatus, HealthStatus, LogicalSectorSize, PhysicalSectorSize, Location)
    try { $res.get_physicaldisk = @(Get-PhysicalDisk -ErrorAction Stop | Select-Object DeviceId, FriendlyName, Model, FirmwareVersion, MediaType, BusType, Size, HealthStatus, SpindleSpeed) } catch { Add-ProbeError ('Get-PhysicalDisk: ' + $_.Exception.Message) }
    try { $res.win32_diskdrive = @(Get-CimInstance Win32_DiskDrive -ErrorAction Stop | Select-Object Index, Model, FirmwareRevision, InterfaceType, MediaType, Size, Partitions, PNPDeviceID) } catch { Add-ProbeError ('Win32_DiskDrive: ' + $_.Exception.Message) }
    $res
}

Invoke-Probe -Id 'P31_partitions' -Title 'Partitions (type, size, file system), ESP presence, system disk' -Source 'Storage module Get-Partition / Get-Volume -Partition (no mount, Guid/AccessPaths/labels not selected)' -Script {
    $gptNames = @{ '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' = 'EFI System Partition'; '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' = 'Microsoft Reserved'; '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' = 'Basic Data'; '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' = 'Windows Recovery'; '{5808c8aa-7e8f-42e0-85d2-e1e90434cfb3}' = 'LDM Metadata'; '{af9b60a0-1431-4f62-bc68-3311714a69ad}' = 'LDM Data'; '{7c3457ef-0000-11aa-aa11-00306543ecac}' = 'Apple APFS'; '{48465300-0000-11aa-aa11-00306543ecac}' = 'Apple HFS+'; '{0fc63daf-8483-4772-8e79-3d69d8477de4}' = 'Linux filesystem' }
    $parts = @()
    foreach ($p in (Get-Partition -ErrorAction Stop)) {
        $fs = $null; $volSize = $null; $free = $null
        try { $v = Get-Volume -Partition $p -ErrorAction Stop; $fs = $v.FileSystemType; $volSize = $v.Size; $free = $v.SizeRemaining } catch { }
        $gt = $(if ($p.GptType) { $p.GptType.ToLowerInvariant() } else { $null })
        $parts += [ordered]@{ disk = $p.DiskNumber; partition = $p.PartitionNumber; drive_letter = $(if ($p.DriveLetter -and [int][char]$p.DriveLetter -ne 0) { [string]$p.DriveLetter } else { $null }); offset = $p.Offset; size = $p.Size; type = [string]$p.Type; gpt_type = $gt; gpt_type_name = $(if ($gt -and $gptNames.ContainsKey($gt)) { $gptNames[$gt] } else { $null }); mbr_type = $p.MbrType; is_system = $p.IsSystem; is_boot = $p.IsBoot; is_hidden = $p.IsHidden; is_active = $p.IsActive; file_system = $fs; volume_size = $volSize; volume_free = $free }
    }
    $sysLetter = $env:SystemDrive.TrimEnd(':')
    $sysPart = Get-Partition -DriveLetter $sysLetter -ErrorAction Stop
    [ordered]@{ windows_system_drive = $env:SystemDrive; windows_partition = [ordered]@{ disk = $sysPart.DiskNumber; partition = $sysPart.PartitionNumber }; esp_count = @($parts | Where-Object { $_.gpt_type -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' }).Count; partitions = $parts }
}

Invoke-Probe -Id 'P32_bitlocker_shell' -Title 'BitLocker protection status per fixed drive letter (no key material)' -Source 'Shell.Application ExtendedProperty System.Volume.BitLockerProtection (non-elevated; status code only)' -Script {
    $map = @{ 0 = 'not BitLocker-capable / no value'; 1 = 'On (encrypted, protection on)'; 2 = 'Off (not encrypted)'; 3 = 'Encrypting'; 4 = 'Decrypting'; 5 = 'Suspended (encrypted, protection off)'; 6 = 'On (locked)'; 8 = 'Waiting for activation (encrypted with clear key, protection off)' }
    $sh = New-Object -ComObject Shell.Application
    $out = @()
    foreach ($v in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID, FileSystem, Size)) {
        $val = $null
        try { $val = $sh.NameSpace($v.DeviceID + '\').Self.ExtendedProperty('System.Volume.BitLockerProtection') } catch { Add-ProbeError ("$($v.DeviceID): " + $_.Exception.Message) }
        $out += [ordered]@{ drive = $v.DeviceID; file_system = $v.FileSystem; size = $v.Size; bitlocker_protection_raw = $val; interpretation = $(if ($null -ne $val -and $map.ContainsKey([int]$val)) { $map[[int]$val] } else { $null }) }
    }
    [Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
    $boot = $null; try { $boot = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLockerStatus' -ErrorAction Stop).BootStatus } catch { Add-ProbeError ('BitLockerStatus: ' + $_.Exception.Message) }
    [ordered]@{ volumes = $out; registry_BitLockerStatus_BootStatus = $boot; interpretation_source = 'Community-documented mapping of the shell property; not an official Microsoft table. Raw 0 is ambiguous and does not by itself prove the volume is unencrypted. BootStatus meaning is undocumented.' }
}

Invoke-Probe -Id 'P33_manage_bde_status' -Title 'manage-bde -status C: (status only; never -protectors)' -Source 'manage-bde.exe -status (read-only; requires elevation)' -Native -Script {
    $ErrorActionPreference = 'Continue'
    $o = & "$env:SystemRoot\System32\manage-bde.exe" -status $env:SystemDrive 2>&1
    @($o | ForEach-Object { [string]$_ } | Where-Object { $_ -notmatch '(?i)password|recovery key|\d{6}-\d{6}-\d{6}' })
}

Invoke-Probe -Id 'P34_reagentc_info' -Title 'Windows RE status (reagentc /info)' -Source 'reagentc.exe /info (read-only; requires elevation)' -Native -Script {
    $ErrorActionPreference = 'Continue'
    $o = & "$env:SystemRoot\System32\ReAgentc.exe" /info 2>&1
    @($o | ForEach-Object { [string]$_ })
}

# ---- 5. firmware / ACPI evidence
$script:AcpiNames = @('GFX0', 'IGPU', 'PEG0', 'PEG1', 'PEG2', 'PEGP', 'PXSX', 'RP05', 'RP09', 'RP12', '_DOD', '_DOS', '_DSM', '_DDC', '_BCL', '_BCM', '_BQC', '_DGS', '_DCS', '_DSS', 'DD1F', 'IGDO', 'ASLS', 'ASLB', 'OPRG', 'IGDM', 'NVHG', 'NVOP', 'NBCI', 'NVJT', 'GPS_', 'MXDS', 'MXMX', 'MXM_', 'DDSS', 'HGOF', 'HGON', 'SGOF', 'SGON', '_PR3', 'GC6I', 'GC6O', 'NVPO', 'DGPS', 'NPCF', 'NVDA0820', 'TBTS', 'TCSS', 'TXHC', 'TDM0', 'XHCI', 'I2C0', 'I2C1', 'TPD0', 'ELAN2616', 'HDAS', 'CNVW', 'PS2K', 'PNP0C14', 'INTC1043', 'NVDA', 'IOS0')
$script:AcpiGuids = [ordered]@{ 'NVIDIA_Optimus_NVOP_a486d8f8-0bda-471b-a72b-6042a6b5bee0' = 'a486d8f8-0bda-471b-a72b-6042a6b5bee0'; 'NVIDIA_JT_GC6_cbeca351-067b-4924-9cbd-b46b00b86f34' = 'cbeca351-067b-4924-9cbd-b46b00b86f34'; 'NVIDIA_NBCI_d4a50b75-65c7-46f7-bfb7-41514cea0244' = 'd4a50b75-65c7-46f7-bfb7-41514cea0244'; 'NVIDIA_GPS_a3132d01-8cda-49ba-a52e-bc9d46df6b81' = 'a3132d01-8cda-49ba-a52e-bc9d46df6b81'; 'Intel_IGD_DSM_3e5b41c6-eb1d-4260-9d15-c71fbadae414' = '3e5b41c6-eb1d-4260-9d15-c71fbadae414'; 'NVIDIA_MXM_4004a400-917d-4cf2-b89c-79b62fd55665' = '4004a400-917d-4cf2-b89c-79b62fd55665'; 'NVIDIA_NVHG_9d95a0a0-0060-4d48-b34d-7e5fea129fd4' = '9d95a0a0-0060-4d48-b34d-7e5fea129fd4' }

function Get-AcpiTableInfo([byte[]]$data, [string]$file) {
    $latin = [Text.Encoding]::GetEncoding(28591)
    $t = [ordered]@{ signature = $null; length = $data.Length }
    if ($data.Length -ge 36) {
        $t.signature = [Text.Encoding]::ASCII.GetString($data, 0, 4)
        $t.header_length = [BitConverter]::ToUInt32($data, 4); $t.revision = $data[8]
        $t.oem_id = [Text.Encoding]::ASCII.GetString($data, 10, 6).Trim([char]0, ' '); $t.oem_table_id = [Text.Encoding]::ASCII.GetString($data, 16, 8).Trim([char]0, ' ')
        $t.oem_revision = ('0x{0:X8}' -f [BitConverter]::ToUInt32($data, 24)); $t.creator_id = [Text.Encoding]::ASCII.GetString($data, 28, 4).Trim([char]0, ' '); $t.creator_revision = ('0x{0:X8}' -f [BitConverter]::ToUInt32($data, 32))
        $sum = 0; foreach ($x in $data) { $sum = ($sum + $x) % 256 }; $t.checksum_ok = ($sum -eq 0)
    }
    $str = $latin.GetString($data)
    $hits = [ordered]@{}; foreach ($n in $script:AcpiNames) { $c = ([regex]::Matches($str, [regex]::Escape($n))).Count; if ($c) { $hits[$n] = $c } }
    $ghits = [ordered]@{}; foreach ($k in $script:AcpiGuids.Keys) { $gs = $latin.GetString(([guid]$script:AcpiGuids[$k]).ToByteArray()); $c = ([regex]::Matches($str, [regex]::Escape($gs))).Count; if ($c) { $ghits[$k] = $c } }
    $t.aml_name_hits = $hits; $t.dsm_guid_hits = $ghits
    $full = Join-Path $Evidence $file
    [IO.File]::WriteAllBytes($full, $data)
    $t.file = "evidence/$file"; $t.sha256 = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    return $t
}

Invoke-Probe -Id 'P40_acpi_tables' -Title 'ACPI tables (firmware-table API + HKLM\HARDWARE\ACPI registry copies incl. DSDT and all SSDTs); MSDM/SLIC/FACS not read; AML name/GUID byte scan' -Source 'kernel32 EnumSystemFirmwareTables/GetSystemFirmwareTable(provider ACPI); registry HKLM\HARDWARE\ACPI\<sig>\<oem>\<table>\<rev> value 00000000 (read-only)' -Script {
    $ACPI = [uint32]0x41435049
    $list = [HonorSurvey.Fw]::Enum($ACPI)
    $sigs = @()
    if ($null -eq $list) { Add-ProbeError ('EnumSystemFirmwareTables(ACPI) failed, Win32 error ' + [HonorSurvey.Fw]::LastError) }
    else { for ($i = 0; $i + 4 -le $list.Length; $i += 4) { $sigs += , ([byte[]]$list[$i..($i + 3)]) } }
    $fw = @(); $seenSig = @{}
    foreach ($sb in $sigs) {
        $sig = [Text.Encoding]::ASCII.GetString($sb)
        $occ = 1; if ($seenSig.ContainsKey($sig)) { $seenSig[$sig]++; $occ = $seenSig[$sig] } else { $seenSig[$sig] = 1 }
        if ($sig -in @('MSDM', 'SLIC')) { $fw += [ordered]@{ signature = $sig; enumeration_occurrence = $occ; skipped = 'not read: may contain an OEM product key' }; continue }
        if ($occ -gt 1) { $fw += [ordered]@{ signature = $sig; enumeration_occurrence = $occ; skipped = 'GetSystemFirmwareTable returns only the first table of a signature; see registry copies below' }; continue }
        $data = [HonorSurvey.Fw]::Get($ACPI, [BitConverter]::ToUInt32($sb, 0))
        if ($null -eq $data) { $err = 'GetSystemFirmwareTable failed, Win32 error ' + [HonorSurvey.Fw]::LastError; Add-ProbeError "$sig : $err"; $fw += [ordered]@{ signature = $sig; error = $err }; continue }
        $t = Get-AcpiTableInfo $data ("acpi/fw_$sig.bin"); $t.Insert(0, 'enumeration_occurrence', $occ); $fw += $t
    }
    $dsdtFw = [HonorSurvey.Fw]::Get($ACPI, [BitConverter]::ToUInt32([Text.Encoding]::ASCII.GetBytes('DSDT'), 0))
    $dsdtNote = $(if ($null -eq $dsdtFw) { 'explicit GetSystemFirmwareTable(DSDT) failed, Win32 error ' + [HonorSurvey.Fw]::LastError } else { 'explicit GetSystemFirmwareTable(DSDT) ok, length ' + $dsdtFw.Length })
    if ($dsdtFw) { $t = Get-AcpiTableInfo $dsdtFw 'acpi/fw_DSDT.bin'; $t.Insert(0, 'enumeration_occurrence', 'explicit'); $fw += $t }
    $reg = @()
    foreach ($top in (Get-ChildItem -LiteralPath 'HKLM:\HARDWARE\ACPI' -ErrorAction Stop)) {
        $key = $top.PSChildName
        if ($key -in @('FACS', 'MSDM', 'SLIC')) { $reg += [ordered]@{ registry_key = "HKLM\HARDWARE\ACPI\$key"; skipped = $(if ($key -eq 'FACS') { 'not read: FACS holds a hardware signature/waking vector, not needed' } else { 'not read: may contain an OEM product key' }) }; continue }
        foreach ($leaf in (@(Get-Item -LiteralPath $top.PSPath) + @(Get-ChildItem -LiteralPath $top.PSPath -Recurse))) {
            if (-not ($leaf.GetValueNames() -contains '00000000')) { continue }
            $rel = $leaf.Name -replace '^HKEY_LOCAL_MACHINE\\HARDWARE\\ACPI\\', ''
            try {
                $data = [byte[]]$leaf.GetValue('00000000')
                $t = Get-AcpiTableInfo $data ('acpi/reg_' + ($rel -replace '[\\/:*?"<>| ]', '_') + '.bin')
                $t.Insert(0, 'registry_key', "HKLM\HARDWARE\ACPI\$rel"); $reg += $t
            } catch { Add-ProbeError ("$rel : " + $_.Exception.Message) }
        }
    }
    [ordered]@{ enumerated_signatures = @($sigs | ForEach-Object { [Text.Encoding]::ASCII.GetString($_) }); dsdt_firmware_api = $dsdtNote; firmware_api_tables = $fw; registry_tables = $reg; note = 'String hits are byte-pattern matches inside AML, not a disassembly. Presence of a name or _DSM GUID does not prove the method is functional.' }
}

Invoke-Probe -Id 'P42_acpi_context' -Title 'Byte context around selected AML names in saved tables (no disassembler)' -Source 'Reads evidence/acpi/reg_*.bin written by P40; no system access' -Script {
    $targets = [ordered]@{
        'reg_SSDA_HONOR_NvdTable_00001000.bin' = @('_DOD', 'MXDS', 'MXMX', 'MXM_', 'NVOP', 'NBCI', 'NVJT', 'GPS_')
        'reg_SSD4_HONOR_IgfxSsdt_00003000.bin' = @('_DOD', 'DD1F', 'IGDM', '_DSM')
        'reg_DSDT_HONOR_ADL-P-M_00000002.bin'  = @('DD1F', 'ASLB', 'NPCF')
    }
    $latin = [Text.Encoding]::GetEncoding(28591)
    $out = [ordered]@{}
    foreach ($f in $targets.Keys) {
        $path = Join-Path $AcpiDir $f
        if (-not (Test-Path -LiteralPath $path)) { Add-ProbeError "$f not found"; continue }
        $b = [IO.File]::ReadAllBytes($path); $s = $latin.GetString($b)
        $perName = [ordered]@{}
        foreach ($n in $targets[$f]) {
            $hits = @(); $i = 0
            while (($i = $s.IndexOf($n, $i, [StringComparison]::Ordinal)) -ge 0 -and $hits.Count -lt 8) {
                $st = [Math]::Max(0, $i - 8); $en = [Math]::Min($b.Length - 1, $i + 40)
                $seg = $b[$st..$en]
                $hits += [ordered]@{ offset = ('0x{0:X}' -f $i); preceding_byte = ('0x{0:X2}' -f $(if ($i -gt 0) { $b[$i - 1] } else { 0 })); hex = (($seg | ForEach-Object { $_.ToString('X2') }) -join ' '); ascii = (-join ($seg | ForEach-Object { if ($_ -ge 32 -and $_ -lt 127) { [char]$_ } else { '.' } })) }
                $i++
            }
            $perName[$n] = $hits
        }
        $out[$f] = $perName
    }
    [ordered]@{ contexts = $out; note = 'Raw bytes only. Any reading of AML opcodes in REPORT.md is a manual decode and must be confirmed with a disassembler (iasl) offline.' }
}

Invoke-Probe -Id 'P41_intel_display_firmware' -Title 'Intel VBT / OpRegion / eDP parameter availability via supported read-only interfaces' -Source 'Summary of: display class registry value names (P11), D3DKMT ADAPTERREGISTRYINFO (P12), ACPI DSDT/SSDT scan (P40), Intel driver service registry key names' -Script {
    $svc = @()
    foreach ($s in 'igfxn', 'igfx', 'igfxnd', 'iigd_dch') {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$s"
        if (Test-Path -LiteralPath $p) {
            try {
                $keys = @(Get-ChildItem -LiteralPath $p -Recurse -ErrorAction Stop | ForEach-Object { $_.Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM' })
                $vn = @(); foreach ($k in (@(Get-Item -LiteralPath $p) + @(Get-ChildItem -LiteralPath $p -Recurse))) { $vn += @($k.GetValueNames() | Where-Object { $_ -match '(?i)vbt|opregion|edp|panel|psr|dmc|lane|link' } | ForEach-Object { ($k.Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM') + ' :: ' + $_ }) }
                $svc += [ordered]@{ service = $s; subkeys = $keys; display_related_value_names = $vn }
            } catch { Add-ProbeError ("$s : " + $_.Exception.Message) }
        }
    }
    [ordered]@{
        intel_service_keys = $svc
        vbt = [ordered]@{ obtained = $false; tried = @('display class registry value-name scan (P11)', 'Intel service registry value-name scan', 'D3DKMT ADAPTERREGISTRYINFO BiosString (P12, gives a version string only)'); reason = 'Windows exposes no supported user-mode API that returns the VBT. The VBT lives in the IGD OpRegion (system memory at the address in PCI config register ASLS) or inside the GOP/firmware image; reading either needs physical-memory or PCI-config access, which is out of scope.' }
        opregion = [ordered]@{ obtained = $false; tried = @('ACPI DSDT/SSDT byte scan for IGDO/ASLS/ASLB/OPRG (P40)'); reason = 'ACPI tables only declare the OperationRegion; its base address is a runtime value and its contents are in physical memory. Not read.' }
        edp_link_parameters = [ordered]@{ obtained = $false; tried = @('DisplayConfig target info (P13)', 'EDID decode (P17)'); reason = 'Lane count, link rate, PSR, backlight control and DPCD are not exposed by any supported read-only Windows API; EDID gives timings only.' }
        port_mapping = [ordered]@{ obtained = $false; tried = @('DisplayConfig QDC_ALL_PATHS connector enumeration (P14)'); reason = 'Connector enumeration lists driver-exposed targets and output technology, not DDI port numbers / AUX channels / physical routing (that data is in the VBT child-device table).' }
    }
}

# ---------------------------------------------------------------- index
$summary = [ordered]@{
    generated_local = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    powershell = $PSVersionTable.PSVersion.ToString()
    elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    probe_count = $script:Index.Count
    ok = @($script:Index | Where-Object { $_.status -eq 'ok' }).Count
    partial = @($script:Index | Where-Object { $_.status -eq 'partial' }).Count
    error = @($script:Index | Where-Object { $_.status -eq 'error' }).Count
    probes = $script:Index
}
Save-Json (Join-Path $Evidence '_index.json') $summary
Write-Host ("Done: {0} probes, ok={1} partial={2} error={3}" -f $summary.probe_count, $summary.ok, $summary.partial, $summary.error)
