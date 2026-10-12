# HONOR GLO-FX6P 只读硬件调查报告（Intel + NVIDIA macOS 适配研究用实机证据）

- 采集时间：2026-10-12（UTC+8），最终一轮采集 22:47:25 开始、22:48 结束，详见 `evidence/_index.json` 中每项的 `started_local`
- 输出位置：`桌面\HONOR-Hardware-Report-20261012-221835`（分享副本中用户目录已去除）
- 执行权限：普通用户（未提权），Windows PowerShell 5.1
- 采集项共 26 项：成功 22、部分成功 1、失败 3。失败均为"需要管理员权限"，未自动提权
- 标记约定：**【实测】** 本次查询直接得到；**【背景】** 用户或项目已提供、本次未重新测量；**【未知】** 接口无法可靠给出；**【未测】** 条件不具备（例如没有外屏）；**【需要用户确认】** 只读查询无法证实的事项

> 本报告只代表"只读调查材料已经生成并自检"，**不代表** macOS 安装、EFI、驱动或任何 GPU 在 macOS 下的运行已经通过验证。

---

## 0. 关键结果与对后续研究的限制

1. **【实测】当前唯一活动显示路径**：`\\.\DISPLAY1` 由 Intel `8086:46A6`（`00:02.0`，`\_SB.PC00.GFX0`）扫描输出到内屏，输出技术 `INTERNAL`。这与已确认的背景一致，本次只是在路径枚举中顺带记录，没有把它当作待确认问题。
2. **【实测】在当前 Windows 模式下，RTX 2050 没有暴露任何显示输出**：WDDM 适配器类型为 `HybridDiscrete`、`RenderSupported=true`、`DisplaySupported=false`、`NumOfSources=0`；`QueryDisplayConfig(QDC_ALL_PATHS)` 中 NVIDIA 的显示目标数为 0；nvidia-smi 的 `display_mode` 和 `display_active` 均为 `Disabled`。与此同时，Intel 驱动暴露了 1 个 `INTERNAL`、2 个 `HDMI` 和 14 个 `DISPLAYPORT_EXTERNAL` 目标（DP 目标中可能包含 MST 虚拟目标）。
   - **限制**：以上只证明本次启动、当前显卡模式下的状态。它**不能证明**主板上没有 MUX，也不能证明某个物理接口的电气走线，更不能证明永远无法切换到 NVIDIA。驱动暴露的连接器目标不等于物理端口映射。
3. **【未测】外接 1080p/200 Hz（USB-C 转 DP）屏的 GPU 归属**：采集期间没有连接外屏，设备注册表里也没有与该屏对应的记录，所以这一项未测。不过上面第 2 点说明，在当前模式下外接显示连接器全部由 Intel 驱动提供；接上外屏后，同一脚本可以直接给出实测归属。
4. **【实测】ACPI 混合显卡固件**：`NvdTable` SSDT 中包含 NVIDIA Optimus（NVOP）、JT/GC6、NBCI、GPS、MXM 的 `_DSM` GUID，以及 `MXDS`、`MXMX` 方法名。我手工逐字节查看后，`MXDS` 的方法体看上去是两个空 `If` 分支加 `Return 0`，`MXMX` 开头是 `P8XH` 调试端口写入。这只是**未经反汇编器确认的初步解读**（原始字节见 `evidence/P42_acpi_context.json`），**不能**据此判断 MUX 或 Advanced Optimus 存在与否 →【未知】。
5. **【实测】内屏**：BOE 产品码 `0x0893`，EDID 文本描述符为 `BOE XS` / `TV140WTM-NH0`，原生模式 2160x1440 @ 60.001 Hz（像素时钟 206.02 MHz，总时序 2320x1480），8 bpc，EDID 接口类型为 DisplayPort，图像尺寸 296x197 mm。Windows 枚举到的所有模式都只有 60 Hz。ACPI 节点为 `\_SB.PC00.GFX0.DD1F`。
6. **【未取得】L1 目标最关键的底层证据**：VBT、OpRegion 内容、eDP 链路参数（lane 数、链路速率、PSR、背光、DPCD）、DDI 端口与 AUX 映射，都无法通过 Windows 支持的只读接口获得。ACPI 只声明了 OpRegion（`IgfxSsdt`：`OperationRegion IGDM, SystemMemory, ASLB, 0x2000`），它的内容位于物理内存中，本次没有读取。这对应项目的 `P0-SCANOUT` 阻塞，本次调查无法解除。
7. **【未知 / 需要用户确认】恢复条件**：普通权限下无法确认 BitLocker 的加密和保护状态（Shell 属性返回 0，含义有歧义；`manage-bde` 需要管理员权限）。恢复密钥是否已外部保存、ESP 是否有独立备份、是否做过回退演练，均为【需要用户确认】，**不能推断已经具备恢复条件**。另外，C: 只剩约 6.75 GiB 可用空间。
8. **【实测】与背景对照**：型号、主板、CPU、两块 GPU 的 PCI ID、内存、SSD、AX201、Realtek 音频均与背景一致。BIOS 仍为 3.09（2023-07-10），没有变化。

---

## 1. 方法与只读边界

| 项目 | 做法 |
|---|---|
| 接口 | CIM/WMI、PnP 设备属性（`Get-PnpDeviceProperty`，白名单键）、注册表只读、`user32!QueryDisplayConfig` / `DisplayConfigGetDeviceInfo` / `EnumDisplayDevices` / `EnumDisplaySettingsEx`、`gdi32!D3DKMTEnumAdapters2` / `D3DKMTQueryAdapterInfo`（只查询）、`kernel32!GetSystemFirmwareTable` / `GetFirmwareType` / `GetLogicalProcessorInformationEx`、存储模块 `Get-Disk/Get-Partition/Get-Volume` |
| 驱动自带工具 | `nvidia-smi --query-gpu=`，只请求列出的字段，没有请求 UUID 或序列号；它随 NVIDIA 驱动安装，不是下载来的 |
| 未使用 | 第三方检测工具、dxdiag、`Get-BitLockerVolume`（其对象可能带有恢复密码）、`manage-bde -protectors`、bcdedit、任何挂载、写注册表、驱动加载、内核或物理内存访问 |
| 未读取的表 | ACPI `MSDM`（可能含 OEM 产品密钥）、`FACS`（硬件签名，本研究不需要） |
| 写入位置 | 仅限本输出文件夹 |
| 副作用说明 | ① `Add-Type` 编译查询用的 C# 辅助类时，.NET 会在用户 `%TEMP%` 中生成并清理临时编译文件；② `-ExecutionPolicy Bypass` 只作用于本次进程，没有改动系统策略；③ nvidia-smi 查询可能短暂唤醒独显（观测到 P5 状态），不改变任何设置 |
| 过程说明 | 因为修正了脚本缺陷，采集共运行 4 次，每次运行前只清空本文件夹下的 `evidence/`；所有证据都来自最后一次运行 |

脚本：`collect.ps1`（采集）、`build_hardware_json.ps1`（只根据 evidence 生成 `hardware.json`）、`selfcheck.ps1`（自检）。

---

## 2. 平台与系统【实测】

| 项目 | 值 | 来源 |
|---|---|---|
| 整机 | HONOR `GLO-FX6P`，系列 HONOR MagicBook，SKU C233，版本 M2080 | Win32_ComputerSystem / ComputerSystemProduct |
| 主板 | `GLO-FX6P-PCB`，版本 `M2080` | Win32_BaseBoard |
| BIOS | HONOR `3.09`，发布日期 `2023-07-10`；BIOSVersion 字符串 `HONOR - 2` / `3.09` / `QUANTA - 30009`；SMBIOS 3.3 | Win32_BIOS 与注册表 HARDWARE\DESCRIPTION 一致 |
| EC 固件 | 3.9 | Win32_BIOS EmbeddedController* |
| ACPI OEM | `HONOR` / `ADL-P-M` | ACPI 表头 |
| CPU | 12th Gen Intel Core `i5-12500H`，CPUID Family 6 Model 154 Stepping 3；12 核 16 线程 = **4 个 P 核（带超线程）+ 8 个 E 核**；L2 9 MB，L3 18 MB；微码修订 `0x41C` | Win32_Processor + GetLogicalProcessorInformationEx（EfficiencyClass）+ 注册表 Update Revision |
| 内存 | 共 16 GiB（系统可见 15.73 GiB）；SMBIOS 报告 8 个 2 GiB 条目（Controller0/1 × Channel A–D），类型 `LPDDR5`（SMBIOS 类型 35），Samsung `K3LKBKB@BM-MGCP`（SMBIOS 原文就含 `@`），额定 6400 MT/s，**当前配置 4800 MT/s** | Win32_PhysicalMemory |
| 是否板载 | 【未知】FormFactor=0。LPDDR5 一般是板载的，但这只是推断 | — |
| Windows | Windows 11 家庭版 中文版，25H2，Build `26200.9457`，64 位；系统检测到 Hypervisor（Hyper-V/VBS 类） | Win32_OperatingSystem + CurrentVersion |
| 启动模式 | `UEFI` | GetFirmwareType = 2 |
| Secure Boot | 开启（注册表 `UEFISecureBootEnabled=1`）；用 `Confirm-SecureBootUEFI` 交叉验证失败，因为需要管理员权限 | 注册表 SecureBoot\State |

---

## 3. 显卡【实测】

| 项目 | Intel Iris Xe | NVIDIA GeForce RTX 2050 |
|---|---|---|
| PCI ID | `8086:46A6` | `10DE:25A9` |
| 子系统 ID | `20271EE7`（1EE7:2027） | `20271EE7`（1EE7:2027） |
| 修订号 | `REV_0C` | `REV_A1` |
| PCI 位置 | `00:02.0`，`PCIROOT(0)#PCI(0200)` | `01:00.0`，`PCIROOT(0)#PCI(0600)#PCI(0000)`，上游根端口 PEG60 `8086:464D` |
| ACPI 路径 | `\_SB.PC00.GFX0` | `\_SB.PC00.PEG0.PEGP` |
| 设备状态 | OK，问题码 0 | OK，问题码 0 |
| 驱动 | `31.0.101.3358`，2022-08-04，Intel，`oem44.inf` | `32.0.15.7283`（NVIDIA 572.83），2025-03-14，`oem7.inf` |
| WDDM | 3.1（枚举值 3100） | 3.2（枚举值 3200） |
| 适配器类型 | `HybridIntegrated`、`DisplaySupported`、`RenderSupported`、`PostDevice` | `HybridDiscrete`、`RenderSupported`、**`DisplaySupported=false`**、`NumOfSources=0` |
| 固件字符串 | `Intel Video BIOS`（只是通用字符串，不是 GOP/VBT 版本） | VBIOS `94.07.69.00.22`（nvidia-smi）；注册表为 `Version94.7.69.0.22` |
| PCIe 链路 | 不适用（集成） | 当前 Gen4 x4；设备能力 Gen4 x16（快照，可能随电源状态变化；x4 是否为板上实际布线【未知】） |
| 显存 | **没有独立显存（UMA）**。D3DKMT 报告的"专用"128 MiB 和注册表 / Win32 的 1 GiB 都是驱动报告的预算值；**DVMT/stolen memory 大小【未知】** | **4 GiB**：注册表 `qwMemorySize` = 4294967296，与 nvidia-smi `4096 MiB` 一致；D3DKMT 可用专用段约 3.87 GiB；Win32 `AdapterRAM` 是 32 位字段，有上限，不能单独采信 |

---

## 4. 显示链路

### 4.1 当前活动路径【实测，QueryDisplayConfig】

| GDI 源 | 扫描输出适配器 | 输出技术 | 当前模式 | 首选模式 | 显示器 |
|---|---|---|---|---|---|
| `\\.\DISPLAY1`（主显示） | Intel `8086:46A6`（LUID 00000000:00010EF5） | `INTERNAL`（base 也是 `INTERNAL`） | 2160x1440 @ 60.001 Hz（206020000/3433600），总时序 2320x1480，像素率 206.02 MHz，32 bpp | 2160x1440 @ 60.001 Hz | `DISPLAY\BOE0893`，ACPI `\_SB.PC00.GFX0.DD1F`，总线描述 "Integrated Monitor" |

- 只有 1 条活动路径，【实测】当前没有外接显示器。
- 渲染源适配器与扫描输出适配器是同一个 Intel LUID。
- Advanced Color：支持，未启用，8 bpc。
- Intel 驱动把内屏报告为 `INTERNAL`，而不是 `DISPLAYPORT_EMBEDDED`。"内屏走 eDP"这一判断来自 EDID 中接口类型为 DisplayPort，以及 ACPI 的 `DD1F` 节点，**并非 Windows 直接报告**。

### 4.2 驱动暴露的连接器目标【实测，QDC_ALL_PATHS，按适配器+目标去重】

| 适配器 | INTERNAL | HDMI | DISPLAYPORT_EXTERNAL | 当前可用（targetAvailable） |
|---|---|---|---|---|
| Intel 46A6 | 1 | 2 | 14 | 只有 INTERNAL |
| NVIDIA 25A9 | 0 | 0 | 0 | — |
| 软件间接显示适配器（3 个，`INDIRECT_WIRED`） | — | — | — | 全部不可用 |

GDI 层面（`EnumDisplayDevices`）也一样：只有 Intel 拥有 `\\.\DISPLAY1`–`DISPLAY4` 这 4 个源，NVIDIA 没有出现。软件虚拟显示设备包括 GameViewer Virtual Display Adapter、IddDesk（Honor）、Honor Virtual Display Device（当前状态为错误码 22 = 已禁用，这是采集前就存在的状态，不是本次造成的），以及 "Lebo Virtual USB Monitor"。它们都不是硬件输出。

### 4.3 内屏型号与 EDID【实测】

| 字段 | 值 |
|---|---|
| PnP 厂商 / 产品码 | `BOE` / `0x0893` |
| 型号文本 | 0xFE 描述符：`BOE XS`、`TV140WTM-NH0`（面板料号来自 EDID 文本，没有其他交叉来源） |
| EDID | 1.4，数字输入，8 bpc，接口 DisplayPort；注册表值 256 字节，扩展块数为 0，后 128 字节全为 0（填充） |
| 原生模式 | 2160x1440 @ 60.001 Hz。EDID 第一个详细时序（206.02 MHz；H 2160+160，同步偏移 48、宽 32；V 1440+40，同步偏移 3、宽 10）与 DisplayConfig 首选模式一致 |
| 物理尺寸 | 296x197 mm（约 14.0 英寸，3:2） |
| 范围限制描述符 | 无 |
| 生产日期字段 | 2019 年第 20 周（EDID 字段原值） |
| Windows 可枚举刷新率 | 只有 60 Hz（共 24 个分辨率） |

**EDID 分享副本**：`evidence/edid/BOE0893_present.sanitized.bin` / `.hex.txt`。去敏规则如下：ID 序列号字段（字节 12–15）置 0，标签为 0xFF 的序列号描述符清空，然后重新计算块校验和。内屏 EDID 本身没有序列号字段，也没有 0xFF 描述符，所以处理后的字节与注册表原值相同（自检中做了逐字节比对）。即便如此，它仍是"经过去敏流程的分享副本"，不称为未经处理的原始数据。

### 4.4 外接显示【未测】

- 当前没有外屏。软件无法区分物理 HDMI 和 USB-C 转 DP，因此物理接口类型【未知】，外接接口的 GPU 归属【未测】。
- 注册表中还有一条**已不存在**的显示器记录：Dell `S2719DGF`（DEL `0xD0E6`，EDID 首个时序 2560x1440 @ 144.48 Hz，范围 40–155 Hz）。它的父设备已无法追溯；实例前缀 `1&` 和 `UID256` 与软件间接显示目标的模式一致。因此它**不能**作为物理外接口或 GPU 归属的证据，也与背景中的 1080p/200 Hz 外屏不符。这条记录的 EDID 副本已去除序列号（字节 12–15 及偏移 72 处的 0xFF 描述符）。
- 背景中的 1080p/200 Hz 外屏没有在设备记录中找到。

### 4.5 MUX / Optimus / Advanced Optimus

| 证据 | 结果 | 能说明什么 |
|---|---|---|
| WDDM 适配器类型 | Intel `HybridIntegrated`，NVIDIA `HybridDiscrete` 且没有显示源 | 【实测】当前是混合（Optimus 式）模式 |
| nvidia-smi | `display_mode=Disabled`，`display_active=Disabled`，P5 | 【实测】当前没有显示器挂在 NVIDIA 上 |
| ACPI `NvdTable` | 含 NVOP / JT(GC6) / NBCI / GPS / MXM GUID；`MXDS`×1、`MXMX`×1、`MXM_`×2；`PEGP._DOD` 返回一个常量 ID `0x80087330`（手工字节解读） | 固件声明了 Optimus 相关 `_DSM`。`MXDS/MXMX` 方法体的初步解读看起来是空实现，必须用 iasl 复核 |
| `NVDA0820`（NVIDIA Platform Controllers and Framework，`\_SB.NPCF`） | 存在，驱动 32.0.15.7081 | 平台功耗框架（Dynamic Boost 类），与 MUX 无直接关系 |
| MUX 是否存在 | 【未知】 | — |
| Advanced Optimus | 【未知】 | — |
| 外接口电气走线 | 【未知】 | — |

---

## 5. 其他设备【实测】

| 类别 | 型号 / 名称 | 硬件 ID | 位置 / ACPI | 驱动 | 状态 |
|---|---|---|---|---|---|
| NVMe 控制器 | Samsung NVMe（系统用通用 stornvme 驱动） | `144D:A80A`，子系统 A801144D，REV 00 | CPU PEG62 根端口 `8086:463D` 之下，`\_SB.PC00.PEG2.PEGP`，Gen4 x4（当前 / 最大一致） | 10.0.26100.9278（Microsoft） | OK |
| SSD | `SAMSUNG MZVL2512HCJQ-00B00`，固件 `GXA7601Q`，512110190592 字节（约 476.9 GiB），逻辑扇区 512 / 物理扇区 4096 | `SCSI\DISK&VEN_NVME&PROD_SAMSUNG_MZVL2512` | 磁盘 0 | — | Healthy |
| Wi-Fi | Intel Wi-Fi 6 AX201 160MHz（CNVi） | `8086:51F0`，子系统 00748086，REV 01 | `\_SB.PC00.CNVW`（00:14.3） | 23.70.0.6，2024-07-17 | OK |
| 蓝牙 | 英特尔无线 Bluetooth | USB `8087:0026` | PCH xHCI HS10，`\_SB.PC00.XHCI.RHUB.HS10` | 23.70.0.2 | OK |
| 音频控制器 | Intel 智音技术（SST）总线 | `8086:51C8`，子系统 20271EE7 | `\_SB.PC00.HDAS`（00:1F.3） | 10.29.0.7082 | OK |
| 音频 DSP 功能 | Intel SST OED | `INTELAUDIO\DSP_CTLR_DEV_51C8&VEN_8086&DEV_0222` | `\_SB.PC00.HDAS.IDA` | 10.29.0.7082 | OK |
| 音频编解码器 | Realtek(R) Audio | `INTELAUDIO\FUNC_01&VEN_10EC&DEV_0256&SUBSYS_1EE72029&REV_1000` | 挂在 SST DSP 之下 | 6.0.9334.1，2022-03-31 | OK |
| 编解码器型号 | 按 Realtek 编号惯例，`10EC:0256` 对应 ALC256（**推断**，驱动没有直接报告型号名） | — | — | — | — |
| HDMI/DP 显示音频功能 | 【实测】当前未枚举到（Intel 或 NVIDIA 的显示音频 codec 均未出现） | — | — | — | — |
| 有线网卡（机身内置） | 【实测】未枚举到 PCI 有线网卡 | — | — | — | — |
| 外接有线网卡 | Realtek USB GbE Family Controller（外接扩展坞 / 集线器上，非机身部件） | USB `0BDA:8153`（实例序列号已去除） | PCH xHCI SS03 → Genesys `05E3:0626` USB3 集线器 | 11.19.602.2025 | OK |
| USB 控制器 1 | Intel USB 3.10 xHCI（PCH） | `8086:51ED` | `\_SB.PC00.XHCI`（00:14.0） | 10.0.26100.9444（Microsoft） | OK |
| USB 控制器 2 | Intel USB 3.20 xHCI（CPU TCSS / Type-C 子系统） | `8086:461E` | `\_SB.PC00.TXHC`（00:0D.0），当前无下游设备 | 10.0.26100.9444 | OK |
| Thunderbolt / USB4 主机 | 【实测】未枚举到 TBT DMA/NHI 或 USB4 PCI 设备。`TcssSsdt` 中有 `TDM0` 名称，但没有对应的 PCI 设备；是固件禁用还是没有实现【未知】 | — | — | — | — |
| 触控板 | ELAN I2C HID 触控板 | ACPI `ELAN2616`（`ACPI\VEN_ELAN&DEV_2616`，兼容 `PNP0C50`）；HID `VID_04F3`，Col03 = 触摸板 | `\_SB.PC00.I2C0.TPD0`，服务 hidi2c | 10.0.26100.8972（Microsoft） | OK |
| 内置键盘 | PS/2 标准键盘（经 EC/LPC） | ACPI `MSFT0001`，兼容 `PNP0303` | `\_SB.PC00.LPCB.PS2K`，服务 i8042prt | 10.0.26100.8972 | OK |
| I2C / Serial IO | Intel Serial IO I2C Host Controller | `8086:51E8`（I2C0） | `\_SB.PC00.I2C0`（00:15.0） | 30.100.2148.1，2021-11-22，iaLPSS2_I2C_ADL | OK |
| Serial IO GPIO | Intel Serial IO GPIO Host Controller | ACPI `INTC1055` | `\_SB.GPI0` | 30.100.2148.1 | OK |
| 读卡器 | 【实测】未枚举到 | — | — | — | — |
| 摄像头 | "HD Camera"（厂商名【未知】，只有 USB ID） | USB `3277:0003`，REV 0012 | PCH xHCI HS06，`\_SB.PC00.XHCI.RHUB.HS06.CAM0` | 10.0.26100.9444（系统 UVC） | OK |
| 指纹 | FPC Fingerprint Reader (Disum) | USB `10A5:A921` | HS08，`\_SB.PC00.XHCI.RHUB.HS08` | 24.26.0.26 | OK |
| 其他 PCI | 主机桥 `8086:4621`、PEG60 `8086:464D`、PEG62 `8086:463D`、SMBus `8086:51A3`、LPC `8086:5182`、SPI `8086:51A4`、HECI `8086:51E0`、Shared SRAM `8086:51EF`、PMT `8086:467D`、DPTF `8086:461D` | 见 `hardware.json` → `devices.other_pci` | — | — | OK |

补充说明：
- 当前插着外接 USB 集线器 / 扩展坞（Genesys `05E3:0610` 与 `05E3:0626`），以及两把外接键盘（`320F:505D`、`0C45:0500`）。它们挂在 PCH xHCI 的 HS03/SS03 上，**不是机身部件**。该端口物理上是 USB-A 还是 USB-C【未知】。
- 完整清单：`evidence/P20_pnp_inventory.json`（124 个设备节点；软件枚举器 ROOT/SWD、存储卷、远端蓝牙等 73 个节点只计数，不列出名称）和 `evidence/P21_pnp_properties.json`（位置路径、ACPI 名、父设备、PCIe 链路）。

---

## 6. 启动、存储与恢复条件

| 项目 | 结果 |
|---|---|
| 磁盘 0 | 【实测】`SAMSUNG MZVL2512HCJQ-00B00`，NVMe，**GPT**，7 个分区；同时是启动盘和系统盘 |
| 分区 1 | EFI 系统分区（ESP），200 MiB，偏移 1 MiB；**文件系统【未知】**（非管理员不可读，未挂载） |
| 分区 2 | Microsoft Reserved，16 MiB |
| 分区 3 | `C:`，Basic Data，NTFS，120 GiB，**可用约 6.75 GiB**，Windows 所在分区 |
| 分区 4 | `D:`，Basic Data，NTFS，约 343.2 GiB，可用约 23.5 GiB |
| 分区 5 | Recovery 类型，512 MiB，FAT32 |
| 分区 6 | Recovery 类型，12 GiB，NTFS |
| 分区 7 | Recovery 类型，约 1 GiB，NTFS |
| 当前系统所在磁盘 | 磁盘 0，分区 3 |
| BitLocker 加密状态 | **【未知】**。非管理员 Shell 属性 `System.Volume.BitLockerProtection` 对 C:、D: 都返回 0（含义有歧义，不能视为"未加密"）；`BitLockerStatus\BootStatus=0`（含义无官方文档）；`manage-bde -status` 被拒绝访问（需要管理员权限）。本次没有执行任何会显示恢复密钥或保护器的查询 |
| BitLocker 保护状态 | 【未知】 |
| WinRE 状态 | 【未知】，`reagentc /info` 需要提升权限 |
| 恢复密钥是否已外部保存 | 【需要用户确认】 |
| ESP 是否已有独立备份 | 【需要用户确认】 |
| 是否做过恢复 / 回退演练 | 【需要用户确认】 |
| 是否有独立恢复环境 | 【需要用户确认】。项目文档记录为"尚未完成"，本次无法改变这一结论 |

---

## 7. 底层显示与固件证据缺口

| 证据 | 状态 | 尝试过的接口 | 原因 |
|---|---|---|---|
| ACPI DSDT | **已取得**，307077 字节，校验和正确 | `GetSystemFirmwareTable('DSDT')` 与注册表 `HKLM\HARDWARE\ACPI\DSDT` 两路一致 | — |
| ACPI SSDT（15 个） | **全部已取得**，校验和正确：`DptfTabl`、`Pmax_Dev`、`CpuSsdt`、`SaSsdt`、`IgfxSsdt`、`TcssSsdt`、`Tpm2Tabl`、`WmiTable`、`PtidDevc`、`ADL-P-M`、`NvdTable`、`xh_adlLP`、`SocGpe`、`SocCmn`、`PcdTabl` | 注册表 `HKLM\HARDWARE\ACPI\SSD1..SSDE, SSDT` | 固件表 API 对同一签名只返回第一个 SSDT，所以其余 SSDT 改从注册表副本读取 |
| 其他 ACPI 表 | 已取得：FACP、APIC、MCFG、DMAR、HPET、FPDT、UEFI、TPM2、LPIT、WSMT、DBG2、NHLT、`$H2O`、BGRT、PHAT、DBGP、XSDT | `GetSystemFirmwareTable` | — |
| MSDM / FACS | 有意不读取 | — | 前者可能含产品密钥；后者本研究不需要 |
| **VBT** | **未取得** | 显示类注册表值名扫描、Intel 服务注册表扫描、D3DKMT `ADAPTERREGISTRYINFO`（只得到 "Intel Video BIOS" 字符串） | Windows 没有返回 VBT 的受支持用户态 API；VBT 位于 OpRegion（物理内存）或 GOP/固件镜像中，读取需要物理内存或 PCI 配置空间访问，超出本次边界 |
| **OpRegion 内容** | **未取得** | `IgfxSsdt` 字节扫描（P40/P42） | ACPI 只声明了 `OperationRegion IGDM, SystemMemory, ASLB, 0x2000`，基址是运行时变量，内容在物理内存中 |
| **eDP 链路参数**（lane 数、速率、PSR、背光、DPCD） | **未取得** | DisplayConfig、EDID | 没有受支持的只读接口；EDID 只给出时序 |
| **DDI 端口 / AUX / 物理走线映射** | **未取得** | QDC_ALL_PATHS 连接器枚举 | 连接器枚举不等于端口走线图，相应信息在 VBT 的 child device 表中 |
| Intel 驱动显示策略值 | 已读取（只读） | 显示类注册表 | 例如 `PSR2Disable=0`、`Psr2DrrsEnable=1`、`eDPFecDisable=1`、`NoFastLinkTrainingForeDP=1`、`LinkRateSupport=3`。这些是**驱动 / INF 配置值，不是面板实测能力** |
| DVMT / stolen memory 大小 | 【未知】 | D3DKMT、注册表 | 驱动报告的显存预算不等于 DVMT 预分配大小 |

需要注意的几组区别：EDID 不等于 VBT；PCI 枚举和 ACPI 路径不等于端口走线图；Windows 驱动工作正常不等于 macOS 可用；ACPI 中出现某个名称或 `_DSM` GUID，也不等于对应方法真正有功能。

---

## 8. 已有背景与本次实测对照

| 背景条目 | 本次实测 | 结论 |
|---|---|---|
| 型号 GLO-FX6P，主板 GLO-FX6P-PCB / M2080 | GLO-FX6P / GLO-FX6P-PCB / M2080 | 一致 |
| CPU i5-12500H | i5-12500H（4P+8E，16 线程） | 一致 |
| 核显 Iris Xe 8086:46A6 | 8086:46A6 | 一致 |
| 独显 RTX 2050 Laptop 10DE:25A9（不是 3050） | 10DE:25A9，"NVIDIA GeForce RTX 2050" | 一致 |
| 内屏在当前 Windows 下接 Intel | 活动路径的扫描输出适配器 = Intel 46A6 | 一致（未作为问题重新询问） |
| 曾用 USB-C 转 DP 接 1080p/200 Hz 外屏，GPU 归属未确认 | 当前无外屏，也无对应记录 | 【未测】 |
| 约 16 GB 内存 | 16 GiB LPDDR5 | 一致 |
| Samsung MZVL2512HCJQ-00B00 512 GB | 同型号，固件 GXA7601Q | 一致 |
| Intel AX201 | AX201 160MHz（8086:51F0） | 一致 |
| Realtek 音频 | Realtek codec 10EC:0256（接在 Intel SST 上） | 一致（ALC256 为推断） |
| BIOS 3.09 / 2023-07-10 | 3.09 / 2023-07-10 | 一致，没有变化 |
| 未完成独立恢复环境、EFI 备份、回退演练 | 只读查询无法证实 | 【需要用户确认】 |

---

## 9. 采集失败、部分成功与限制

| 采集项 | 状态 | 原因 |
|---|---|---|
| `P06_secureboot_cmdlet` | 失败 | `Confirm-SecureBootUEFI` 需要管理员权限（UnauthorizedAccessException）。已用注册表结果代替，Secure Boot 状态仍有来源 |
| `P12_d3dkmt_adapters` | 部分成功 | 4 个非 PCI 适配器（3 个间接显示 + Basic Render）的 `ADAPTERREGISTRYINFO` 返回 `0xC0000034`（对象不存在）。两块物理 GPU 的数据完整 |
| `P33_manage_bde_status` | 失败（退出码 -2147217405） | 需要管理员权限 |
| `P34_reagentc_info` | 失败（退出码 5） | 需要提升权限 |

其他限制：
- ESP 文件系统、BitLocker 和 WinRE 都受限于非管理员权限。按要求没有自动提权。
- `GetSystemFirmwareTable` 不能按序号读取重复签名的表，已改用注册表中 Windows 实际加载的表副本，两路结果中 DSDT 一致。
- ACPI 分析只做了字节模式匹配和少量手工解读，**没有使用反汇编器**。
- PCIe 链路宽度和速度都是瞬时快照。

---

## 10. 自检结果

`selfcheck.ps1` 输出 `evidence/selfcheck.json`：**共 41 项检查，41 项通过，0 项失败**。

- **报告与 JSON 一致性**：`hardware.json` 能正常解析；型号、主板、BIOS 版本和日期、CPU、线程数、活动路径适配器、分辨率、刷新率、NVIDIA 源数、磁盘型号和固件、ESP 大小、成功数和失败数共 15 个字段，与 evidence 原值一致；报告中出现了全部 40 个关键实测值，包含采集计数原句，并列出了全部 4 个失败或部分成功的采集项。
- **未知项没有被写成已确认**：MUX、Advanced Optimus、外接口走线、外屏 GPU 归属、BitLocker 加密和保护状态、恢复密钥外部保存、ESP 备份、恢复演练、内存是否板载、核显物理显存，这 11 个字段在 JSON 中都是 null；VBT 和 OpRegion 标为 `obtained=false`；报告使用了"需要用户确认 / 未取得 / 未测 / 未知"标记，并且不含把 MUX、恢复能力或 macOS 可用性写成已确认的越界表述（禁用短语清单见 `selfcheck.ps1`）。
- **EDID 分享副本**：在内存中与注册表原值逐字节比较。BOE0893 与原值完全相同（原 EDID 没有序列号）；DELD0E6 只改动了偏移 12–15、77–84（0xFF 序列号描述符的内容）和 127（校验和）。
- **敏感信息泄漏扫描**：扫描了 73 个文件，每个文件分别按 Latin-1、UTF-8 和 UTF-16 解读，**命中 0 次**。检查的类别有计算机名、用户名（3 个字符，按完整词边界匹配）、用户目录及目录名、BIOS 序列号、主板序列号、系统 IdentifyingNumber、系统 UUID（含二进制大小端形式）、磁盘序列号、Windows 产品 ID、注册所有者、本机 4 个 MAC 地址（三种写法）和 6 个 IP 地址，另外还按通用格式查找 MAC、BitLocker 恢复密码、产品密钥和未去敏的用户目录路径。内存条序列号在 SMBIOS 中全为 0，当前连接的显示器也没有序列号，所以这两类没有可匹配的值。敏感值只在内存中用于匹配，不写入任何文件。
- **只读边界静态扫描**：去掉注释后，`collect.ps1` 和 `build_hardware_json.ps1` 中没有注册表写入、bcdedit、mountvol、diskpart、分区修改、设备启用或禁用、pnputil、BitLocker 保护器或密钥相关命令、重启、Secure Boot 设置、驱动安装、下载、提权、物理内存访问等调用；所有文件写入都指向输出文件夹的 `evidence/` 或根目录。

---

## 11. 需要用户补充的最少信息（全部可选；不涉及内屏归属）

1. BitLocker / 设备加密是否开启，恢复密钥是否已离线保存。只需回答"是 / 否"，**不要提供密钥本身**。
2. 是否已有 ESP/EFI 的独立备份、可用的独立恢复介质，以及做过回退演练（是 / 否）。
3. 当初接 1080p/200 Hz 外屏时用的是机身上的哪个物理接口（USB-C 还是 HDMI，位于哪一侧）。以后方便接外屏时，用同一个 `collect.ps1` 再跑一次，即可实测外接口的 GPU 归属，不需要切换模式。
4. （可选）是否允许以管理员身份运行同一脚本，用于补齐 Secure Boot 交叉验证、BitLocker 状态（只读 `-status`）、WinRE 状态和 ESP 文件系统。不同意也不影响本报告的其他结论。

---

## 12. 文件清单

| 路径 | 内容 |
|---|---|
| `REPORT.md` | 本报告 |
| `hardware.json` | 结构化结果，未知值为 null |
| `collect.ps1` | 实际执行的采集脚本 |
| `build_hardware_json.ps1` | 根据 evidence 生成 hardware.json（不查询系统） |
| `selfcheck.ps1` | 自检脚本 |
| `evidence/_index.json` | 26 个采集项的状态、来源接口、首个错误 |
| `evidence/Pxx_*.json` | 每项采集的命令原文、执行时间、来源接口、状态、原生退出码、错误和数据（已去敏） |
| `evidence/acpi/` | ACPI 表二进制（`fw_*` 来自固件表 API，`reg_*` 来自注册表副本） |
| `evidence/edid/` | 去敏 EDID 分享副本（.bin 和带说明的 .hex.txt） |
| `evidence/selfcheck.json` | 自检结果 |
| `evidence/_collect_console.log` | 最后一次采集的控制台输出 |
| `FILES_SHA256.txt` | 以上文件的 SHA-256（不含清单自身） |
