# 1401 v1.14.2 在本机的沙箱扫描与离线 plan（2026-10-13）

> 对应 [NEXT_STEPS_PLAN](../../research/NEXT_STEPS_PLAN.md) C1、C2。用户在会话中回复“你自己继续收”，视为对 C1/C2 与固定 iasl 的批准；C3（联网 build）未执行。
> 本目录只入库脱敏摘录 [`plan_excerpt.json`](plan_excerpt.json)。原始 `Report.json`、`scan-evidence.json`、ACPI 表、完整 plan 输出只留在 `%TEMP%\hk-1401-scan-20261013-004439`，不入库、不上传。

## 1. 环境与隔离

| 项 | 值 |
|---|---|
| 源码 | `upstream/1401` v1.14.2 `46d9fee3` 的副本（robocopy，排除 `.git`） |
| Python | 系统 3.12.2 建独立 venv；依赖按 1401 `windows/release-inputs.json` 固定：pywin32 312、WMI 1.5.1、certifi 2026.7.22，`pip --require-hashes --only-binary :all: --no-deps --no-cache-dir`（哈希取自 PyPI） |
| acpidump | ACPICA R2024_12_12 `acpidump.exe`，预置到沙箱 `home\.cache\1401`，SHA256 与 1401 固定值 `9f54227f…` 一致 |
| iasl | ACPICA 20260408 `iasl.exe`，SHA256 `739c597b…f9`、1035776 字节，与 GitHub 资产 digest 一致；未签名（ACPICA 官方 exe 均未签名）；放入副本的 `upstream/OpCore-Simplify/Scripts/` |
| 进程环境 | 子 PowerShell 进程内 `USERPROFILE/HOME/TEMP/TMP/TMPDIR/APPDATA/LOCALAPPDATA` 指向沙箱；`HTTP(S)_PROXY/ALL_PROXY=http://127.0.0.1:9`（扫描与 plan 均无网络）；`PYTHONDONTWRITEBYTECODE=1` |
| 权限 | **非管理员**。扫描无需提权即成功 |

沙箱外写入核对：真实 `%LOCALAPPDATA%\NullMoth`、`%USERPROFILE%\.cache\1401` 不存在；真实 `%TEMP%` 无新增 `ocs_*`/`1401-plan-*`。OCS 的 `ocs_*` 临时目录与 pywin32 的 `gen_py` 缓存都落在沙箱 `tmp\`。

## 2. C1 扫描（`python -m p1401.scan`）

- 退出码 0，约 20 秒。产出 `Report.json`（16 KB）、`scan-evidence.json`（145 KB）、`scan-partial.json`、ACPI 34 个文件。
- **MSDM 确实被导出**（`msdm.aml`，85 字节），扫描结束后立即删除；随后对沙箱内全部 json/log/txt 检索 MSDM 与产品密钥格式，0 命中。删除为普通删除，未做安全擦除。
- ACPI：DSDT（`HONOR ADL-P-M`，307077 字节）+ 15 个 SSDT（`DptfTabl`、`Pmax_Dev`、`CpuSsdt`、`SaSsdt`、`IgfxSsdt`、`TcssSsdt`、`Tpm2Tabl`、`WmiTable`、`PtidDevc`、`ADL-P-M`、`NvdTable`、`xh_adlLP`、`SocGpe`、`SocCmn`、`PcdTabl`）+ APIC/BGRT/DBG2/DBGP/DMAR/FACP/FPDT/HPET/LPIT/MCFG/NHLT/PHAT/TPM2/UEFI/WSMT/XSDT，另有 0 字节的 `$h2o.aml`（Insyde 占位）。
- `cpu_native` 不可用：源码副本没有 `nm_cpuinfo.exe`（发布包才有），因此 CPUID 只来自 Hardware-Sniffer。
- `bios_settings` 不可观测（无 Lenovo/HP/Dell 的 WMI BIOS 提供程序）。
- 报告的 Input 中没有单列 ELAN I2C 触控板（只见 ACPI 下的“HID 供应商定义设备”与外接 USB 设备）。

## 3. C2 离线 plan（`python -m p1401 plan Report.json ACPI --json`）

退出码 0，`ok=true`；plan 输出目录**为空**（实机证实 plan 不生成 config.plist）。

| 决策 | 值 |
|---|---|
| macOS | `24.99.99`（Sequoia 15，NullMoth `mark()` 限定；提示中只列出 15） |
| SMBIOS | `MacBookPro16,2` |
| 禁用设备 | 仅指纹 `10A5-A921`；**核显 46A6 保持开启**（`scan-evidence.json` 绑定生效） |
| BIOS 要求 | `Disable Secure Boot` |
| kext（24） | Lilu、VirtualSMC、SMCBatteryManager、SMCLightSensor、SMCProcessor、SMCSuperIO、WhateverGreen、AppleALC、itlwm、BlueToolFixup、IntelBluetoothFirmware、IntelBTPatcher、USBToolBox、UTBDefault、XHCI-unsupported、VoodooPS2Controller、VoodooI2C、VoodooI2CHID、NVMeFix、AMFIPass、BrightnessKeys、CpuTopologyRebuild、ECEnabler、RestrictEvents |
| 自动应答 | macOS 版本、Wi-Fi kext 两个提示均取默认（Sequoia 15、itlwm） |
| ocvalidate | 未运行（`validation={}`，plan 本就不运行） |

**plan 实际输出中的关键现象**

1. **OCS 自己的兼容性检查器判定 “NVIDIA GeForce RTX 2050: Unsupported / Intel Iris Xe: Unsupported … You cannot install macOS without a supported GPU”**，1401 随后用 NullMoth 规则继续。
2. **两条相互矛盾的内屏提示同时出现**（此前只在代码层面验证）：
   - “Without a MUX … the built-in screen stays dark in macOS.”
   - “1401 keeps that GPU on, so the built-in screen works in macOS through the firmware display (no graphics acceleration on it yet).”
3. 另有提示 “NVIDIA GeForce RTX 2050 selected for macOS 15 Sequoia. This card is in NVIDIA's supported list but has not been tested with the driver yet.”
4. **iasl 对本机 ACPI 失败**（exit `0xFFFFFFFF`，1401 记为 crash），保留 `dsdt.aml.crash` 并“不做预补丁反编译继续”。原因是重名对象：`\_SB.PC00.PEG1.PEGP._S0W`、`\_SB.PC00.RP06.BRST`、`\_SB.PC00.XHCI.RHUB.HS10.SADX`（`xh_adlLP` SSDT 与其他表重复）。单表反编译大多成功。
5. VoodooI2C 仍被选入，但原版不匹配本机 I2C 控制器 `0x51E8`（见 COMPATIBILITY）。

**解读边界**：以上只是 1401 对本机的**决策**，不是可启动性的证据；没有 config.plist、没有 ocvalidate、没有引导。

## 4. C3 联网 build + ocvalidate（用户选择“只走 GitHub，镜像回退即中止”）

- 运行方式：沙箱包装脚本 `run_build.py` 把 `p1401.mirror.fetch/fetch_once/prefer/preferred` 替换为“报错并拒绝”，再调用 `p1401.__main__.main(["build", Report.json, ACPI, out, "--json"])`；用户目录同样重定向到沙箱，未设代理拦截（需要联网）。
- 结果：约 100 秒，退出码 0，stderr 为空（**未触发任何镜像回退**），`ok=true`。
- **ocvalidate：No issues found（0 issues）**。注意下载的是 **OpenCore 1.0.9**（ocvalidate 自述“only compatible with OpenCore version 1.0.9”），而非 `release-inputs.json` 固定的 1.0.8，证实 build 版本由运行时 Dortania 数据决定。
- 产物：`EFI/BOOT/BOOTx64.efi`、`EFI/OC/{OpenCore.efi, config.plist, ACPI(9), Drivers(4), Kexts(23)}`，`Tools/` 为空；另有 `.machine-profile.json`。全部留在沙箱，不入库。脱敏摘要见 [`build_config_summary.txt`](build_config_summary.txt)。

**config.plist 要点（静态审阅）**

| 区域 | 内容 | 评注 |
|---|---|---|
| ACPI | SSDT-EC/GPI0/MCHC/PLUG-ALT/RTCAWAC/SBUS/USB-Reset/USBX/XOSI；补丁 GPI0 `_STA→XSTA`、`_OSI→XOSI` | 都是通用模板 SSDT；**没有 SSDT-PNLF**（内屏背光控制大概率不可用，推断） |
| DeviceProperties | 仅 `PciRoot(0x0)/Pci(0x1f,0x3)` `layout-id=97`、`PciRoot(0x0)/Pci(0x6,0x0)/Pci(0x0,0x0)` `acpi-wake-type=1` | **核显无任何属性、未 disable**（与源码推断一致）；独显未禁用 |
| Booter | `AllowRelocationBlock`、`DevirtualiseMmio`、`SetupVirtualMap`、`RebuildAppleMemoryMap`、`SyncRuntimePermissions`、`ProtectUefiServices`、`ProvideCustomSlide` 等；`ResizeAppleGpuBars=0` | **未启用 `ForceExitBootServices`**（1401#26 台式机用户靠它解决 EXITBS 卡住，对本机是否需要未知） |
| Kernel | `Cpuid1Data 55060a00…`（Comet Lake 伪装）、`ProvideCurrentCpuInfo`、`AppleXcpmCfgLock`、`DisableIoMapper`；3 条“force HT” 补丁 | 与源码推断一致；CFG Lock 未知时按锁定处理 |
| Misc | `SecureBootModel=Disabled`、`Vault=Optional`、`ScanPolicy=0`、`Target=67`、`AppleDebug/ApplePanic`、`HideAuxiliary=False` | 日志写到 U 盘，便于失败后在 Windows 读取 |
| NVRAM | `csr-active-config=430a0000`；boot-args：`-v debug=0x100 keepsyms=1 -vi2c-force-polling ctrsmt=full nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0`；Delete 不含 boot-args | 与源码推断一致 |
| UEFI | Drivers：HfsPlus、OpenRuntime、ResetNvramEntry、**NullMothLogo.efi**；`ProvideConsoleGop`；`ReleaseUsbOwnership`、`RequestBootVarRouting` | `NullMothLogo.efi`（539648 字节）在 1401 仓库中**只有二进制**（提交 `d94f056`），源码在驱动仓库 `app/efi-logo`（Rust），二者对应关系未验证 |
| PlatformInfo | `MacBookPro16,2`、`UpdateSMBIOSMode=Custom`、`SpoofVendor`；序列号由 macserial 生成 | 序列号已脱敏，不入库 |

**实际打包的 VoodooI2C 是 2.9.1**，其 7 个 `IOPCIMatch`（带掩码 `0xfffcffff`）经掩码计算**均不匹配 `0x51e88086`**——在真实产物上确认触控板原版不可用（E）。

**仍然不是启动证据**：ocvalidate 只校验配置结构与 OpenCore 版本一致性。
