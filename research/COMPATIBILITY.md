# COMPATIBILITY｜GLO-FX6P × 1401 v1.14.2 模块级兼容性分析

> 审计对象：`nullmoth/1401@46d9fee`（v1.14.2）、`nullmoth/nvidia-macos-driver@1083a98`（v1.14.2）。
> **本文件没有任何一项经过本机实机验证**。“1401 会怎么做”来自源码阅读和 [`tests/test_1401_static_audit.py`](../tests/test_1401_static_audit.py)
> 对 1401 真实规则函数的调用（代码级）；“能否工作”来自上游文档和社区报告。

## 0. 证据等级（本项目统一口径）

| 等级 | 含义 |
|---|---|
| **A** | 同一设备 ID（最好同机型）经完整验证（有日志/可复核） |
| **B** | 同架构/同系列设备经验证（社区报告含日志或多人一致） |
| **C** | 仅源码、设备表或上游文档声称 |
| **D** | 推测、单一未复核社区说法 |
| **E** | 已知不支持或已知失败 |

验证层级必须分开：**代码测试 ≠ OpenCore 配置校验（ocvalidate）≠ UEFI 能引导 ≠ macOS 能安装 ≠ 完整 GPU 加速**。本轮最高只到“代码测试”。

## 1. 总表

| 模块 | 1401 v1.14.2 对本机的预期处理（源码） | 能否工作 | 等级 | 关键证据 |
|---|---|---|---|---|
| CPU i5-12500H 启动 | 伪装 Comet Lake `Cpuid1Data`、`ProvideCurrentCpuInfo`、`CpuTopologyRebuild` + `ctrsmt=full`、HT 补丁；CFG Lock 时加 `AppleXcpmCfgLock` | 同代机型结果互相矛盾，本机未知 | **D** | Dortania 笔记本只覆盖到 Ice Lake；[1401#26](https://github.com/nullmoth/1401/issues/26)、[driver#87](https://github.com/nullmoth/nvidia-macos-driver/issues/87)、[1401#5](https://github.com/nullmoth/1401/issues/5)、[driver#109](https://github.com/nullmoth/nvidia-macos-driver/issues/109) |
| Iris Xe 46A6 原生帧缓冲/加速 | 标记为不支持（Compatibility `(None, None)`），不注入 `ig-platform-id` | 不可能（Apple 无 Gen12 驱动） | **E** | 1401 `engine.STOP_LEADS`：“Intel UHD/Iris … up to 10th gen”；`panel_guard.py` 注释“Tiger Lake and newer” |
| Iris Xe 46A6 固件帧缓冲（无加速）内屏 | `panel_guard.intel_panel_keys` 保留核显开启（不 `disable-gpu`），显示 `KEEP_NOTE` | 未验证；且安装驱动后会被 `NVRMFBClaim` 抢占 | **D**（未装驱动）/ **E**（装驱动后，机制同 [driver#119](https://github.com/nullmoth/nvidia-macos-driver/issues/119)） | 见第 2.2 节 |
| RTX 2050 25A9 被选中 | `nvidia_gsp_ids.json` 含 `25A9`→`mark()` 标记“仅 macOS 15”，保留独显 | 表中列出 ≠ 验证；`tested` 只有 `2D05` | **C** | 本项目测试 `test_rtx_2050_is_in_the_gsp_table_but_never_hardware_tested` |
| RTX 2050 驱动内屏/外接显示 | 显示 `mux_help`（“内屏在 macOS 中保持黑屏”） | 本机 NVIDIA 很可能没有任何显示接口 | **E** | 类码 `0x0302`、显示源 0、连接目标 0；[driver#119](https://github.com/nullmoth/nvidia-macos-driver/issues/119)（GA107M、0x0302、`heads 0 connectors 0`） |
| RTX 2050 无头 Metal 加速 | 驱动包由 Mac companion 安装（需 SIP `0x0A43` + AMFI 放宽）；驱动 1.12 起有 headless 模式（开机约 60 s 无显示 head 时只做 Metal 设备） | 上游 release notes 声称 11 代以后 Intel 内屏机型“内屏无加速显示，应用可用 NVIDIA Metal”；仅 Turing 无 MUX 机型有单例报告；GA107 无 MUX 未见成功 | **C**（上游声称）/ **D**（本机） | 驱动 `docs/RELEASE-1.12.0.md:5-9`、`kexts/NVRM/accel/nvrm-accel.cpp:295-340`；[driver#104](https://github.com/nullmoth/nvidia-macos-driver/issues/104)、#119 中 #76 跟进（GTX 1650 Max-Q 无头 Metal 3） |
| Wi-Fi AX201 | `8086-51F0` 在 OCS itlwm 设备表；选 itlwm（HeliPort）或 AirportItlwm | 同系列社区普遍可用 | **B** | OCS `datasets/pci_data.py:549`；[driver#87](https://github.com/nullmoth/nvidia-macos-driver/issues/87)（AX210 + HeliPort 可用，WPA3 个人版不行） |
| 蓝牙 8087:0026 | IntelBluetoothFirmware + BlueToolFixup + IntelBTPatcher | 同系列社区可用 | **C** | 1401#26 日志中同组 kext 注入成功（仅注入，不代表可用） |
| 音频 ALC256（经 SST 51C8） | AppleALC，按 `codec_layouts["10EC-0256"]` 自动选 `alcid` | codec 有通用 layout；SST 连接的数字麦克风不可用 | **C**（扬声器/耳机）/ **E**（SST 麦克风） | OCS `datasets/codec_layouts.py:197`；Dortania “Intel SST … will not work” |
| NVMe Samsung PM9A1（MZVL2512HCJQ） | NVMeFix | 未见本型号已知问题；本机为唯一磁盘 | **C** | Dortania 只点名 PM981/PM991/2200S；[1401#5](https://github.com/nullmoth/1401/issues/5) 机器也有同系列盘（失败原因与盘无关联证据） |
| 触控板 ELAN2616（I2C 51E8） | VoodooI2C + VoodooI2CHID，加 `-vi2c-force-polling`；OCS 无任何 `51E8` 处理 | **原版 VoodooI2C 不匹配本机 I2C 控制器**（2026-10-13 已核实 v2.9.1 `e3ac3ed` 与 master `5c0c99c` 的 `IOPCIMatch` 只到 Ice Lake `0x34E8`）；社区做法是手工把 `0x51e88086` 加进 Info.plist 并用轮询 | **E**（原版）/ **D**（手工补丁） | [VoodooI2C Info.plist @v2.9.1](https://github.com/VoodooI2C/VoodooI2C/blob/e3ac3ed207170c39db88d6a67a76cc9fd3a1895a/VoodooI2C/VoodooI2C/Info.plist)；[driver#87](https://github.com/nullmoth/nvidia-macos-driver/issues/87) 评论（补丁做法未复核） |
| 键盘（PS/2 经 EC） | VoodooPS2Controller | 通用方案 | **C** | — |
| USB（xHCI 51ED + TCSS 461E） | USB 映射 kext；15 端口限制 | 需本机端口映射，Type-C 热插拔未知 | **D** | — |
| 摄像头 USB 3277:0003 | 无需 kext（UVC） | 未知 | **D** | — |
| 指纹 FPC | — | 不支持 | **E** | Dortania |
| 电池/EC | ECEnabler + SMCBatteryManager | 通用方案 | **C** | 1401#26 日志同组 kext 注入 |

## 2. 重点模块展开

### 2.1 CPU：Alder Lake-H 混合架构

- 1401 依赖 OpCore-Simplify：`config_prodigy.py` 的 `spoof_cpuid` 对 Alder Lake 写 Comet Lake CPUID（`55060A00`，掩码 `FFFFFFFF`），开启 `ProvideCurrentCpuInfo`；`kext_maestro` 对混合架构选 `CpuTopologyRebuild`，boot-args 加 `ctrsmt=full`。
- 1401#26（同款 i5-12500H）日志证实上述补丁全部生效：`Patch success CPUID release`、`force HT enabled for Sequoia`、`ProvideCurrentCpuInfoZeroMsrThreadCoreCount`、`XcpmCfgLock patch`，并进入 Apple `boot.efi` 至 `EXITBS:START`。**这只证明 OpenCore 阶段通过，不证明内核启动。**
- 同代对照：[driver#87](https://github.com/nullmoth/nvidia-macos-driver/issues/87)（i7-12700H + RTX 3060，独显直连屏）报告已进入桌面并日常使用 → CPU 平台**可以**启动的社区说法；[1401#5](https://github.com/nullmoth/1401/issues/5)（i7-12700H，独显模式）在 0.886 s 早期内核 panic；[driver#109](https://github.com/nullmoth/nvidia-macos-driver/issues/109)（i7-12700H，独显模式）EXITBS 后黑屏。**结论冲突，保留：B 级“Alder Lake-H 可以启动”与 E 级“同代多机失败”同时存在，本机为 D。**
- 本机特有未知：CFG Lock 状态、BIOS 是否提供相关选项。

### 2.2 显示路径（本机最关键的限制）

实测事实（[HARDWARE](HARDWARE.md) 第 3 节）：内屏只接在 Intel 46A6；RTX 2050 是 3D 控制器（`0x0302`），无显示源、无连接目标；Intel 驱动暴露全部 HDMI/DP 目标。**推断（强）：本机为 muxless Optimus，所有显示输出都走 Intel。**

1401 v1.14.2 对此拓扑的处理（代码级已测）：

1. `nullmoth.mark()` 仍把 RTX 2050 标为 macOS 15 可用（仅因 ID 在表中）。
2. `nullmoth.mux_help()` 返回提示：内屏在 macOS 中保持黑屏，需要 MUX 或接到 NVIDIA 的外接口。
3. `panel_guard.intel_panel_keys()` 保留 Intel 核显（不加 `disable-gpu`），`KEEP_NOTE` 称“内屏通过固件显示在 macOS 中工作（无加速）”。

**1401 对同一台机器同时给出两条相反提示**（第 2 条与第 3 条）。这是上游源码内部的证据冲突，本项目不替其裁决。

社区证据：

| 来源 | 机器 | 结果 | 对本机的意义 |
|---|---|---|---|
| [1401#26](https://github.com/nullmoth/1401/issues/26)（2026-10-10，开放） | Monster Abra A5 V19.2：**i5-12500H**、Iris Xe 接内屏、RTX 3050 Ti Laptop、无 MUX | 日志停在 `EXITBS:START`；日志显示 1401 给核显设了 `disable-gpu` | **最接近本机的案例（E，旧版本行为）**。`EXITBS:START` 是 OpenCore 能记录的最后一行，**不能区分内核挂死与内屏失去输出**。v1.14.2 的 `panel_guard` 正是为修复“禁用接内屏核显”而加，当前版本对该机的效果未知 |
| [1401#7](https://github.com/nullmoth/1401/issues/7) | HP Victus：i5-11400H（Tiger Lake）UHD 接内屏、RTX 3050 Ti 接 HDMI | 进入 verbose 并启动 loginwindow，但安装器 GUI 永不出现；改 `-igfxvesa` 无效 | Gen12 核显 + 固件帧缓冲路径在恢复环境中**未出 GUI**（E，旧版本 1.0.24） |
| [driver#119](https://github.com/nullmoth/nvidia-macos-driver/issues/119) | Dell Inspiron 16 7610：Tiger Lake UHD 接内屏、RTX 3050 Laptop GA107M（`0x0302`，无连接器）、无 MUX | 装驱动后 `NVRMFBClaim` 占用核显的 IOFramebuffer 类别，没有任何帧缓冲，WindowServer 只有虚拟显示 | **与本机拓扑同构（E）**；修复 [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131)、[PR #133](https://github.com/nullmoth/nvidia-macos-driver/pull/133) 在 2026-10-11 时**均未合并** |
| [driver#35](https://github.com/nullmoth/nvidia-macos-driver/issues/35) | 台式 i7-12700K：UHD 770（12 代，无 macOS 驱动） | 无驱动核显让 IOGraphics 启动多等约 60 s；用 `-wegnoigpu` 隐藏解决 | 本机若保留 46A6 也可能遇到；但本机不能隐藏它（内屏在它上面） |
| [driver#26](https://github.com/nullmoth/nvidia-macos-driver/issues/26) | Alienware 51MR2（独显直连屏 + UHD 630） | 约 90 s 后独显屏黑屏仅剩光标 | **与本机无关**；旧知识库曾把它与 1401#26 混淆（见 [OPEN_QUESTIONS](OPEN_QUESTIONS.md) Q-11） |

**驱动源码核实（2026-10-13，v1.14.2 `1083a98`）**：`kexts/NVRMFB/fb/Info.plist` 中 `NVRMFBClaim` 仅以 `IOProviderClass=IOPCIDevice`、`IONameMatch=display`、`IOMatchCategory=IOFramebuffer`、`IOProbeScore=30000` 匹配，**没有任何厂商或类码过滤**；`nvrm-fb.cpp:411-426` 也未重写 `probe()`。即 #119 的缺陷在当前发布版中仍然存在（本项目测试 `test_nvrmfbclaim_matches_any_display_named_pci_device` 固定了这一点）。同时 Mac 端 `nullmoth-setup.sh:1061-1076` 在检测到“Intel VGA 且无 `ig-platform-id`”时特意**不屏蔽** IONDRVSupport 以点亮 Intel 内屏——而这正是 `NVRMFBClaim` 会挡掉的那条路径。**上游声称（release 1.12.0）与上游缺陷（#119）互相冲突，保留不裁决。**

另外两条驱动侧信息：驱动仓库的 `NMIntelFB` 设备表含 `{0x46a6, 13}`，但**不在 `install.sh` 的安装列表中**；实验性 NMXGPU（i915）路径默认关闭，上游写明“尚未在任何 Intel GPU 上运行过”，并警告接管驱动启动显示的 GPU 会**重置其显示引擎**（`gpu-port/README.md:61-62`），在本机即内屏。

**本机显示结论**：经 1401 路线获得“有加速的内屏”= **E**；“无加速固件帧缓冲内屏、未装驱动”= **D**（无同代成功案例，有 Gen12 失败案例）；“装 NullMoth 驱动后仍保持内屏”= **E**（#119 机制，PR 未合并）。

### 2.3 RTX 2050（10DE:25A9，GA107 系）

- 在 NVIDIA r610.57.04 GSP 支持表中（同表还有 `25A7`/`25AD`/`25ED` 等 RTX 2050 变体），1401 `tested` 只有 `2D05`。驱动 `docs/CARD-SUPPORT.md` 对 Ampere 物理验证写“Pending”，并说明笔记本需 NVIDIA 驱动的显示路径，PCI ID 不会实现 Optimus 切换。
- 同芯片族（GA107）成功：[driver#69](https://github.com/nullmoth/nvidia-macos-driver/issues/69)、[driver#15](https://github.com/nullmoth/nvidia-macos-driver/issues/15)（RTX 3050 Ti 25E0，**BIOS MUX 设为独显直连**，需改 PAT 补丁；1.10.0 起又回退）→ 对“有 MUX 的 GA107”是 B，对本机拓扑不适用。
- 同拓扑失败：#119（GA107M、`0x0302`、无连接器）→ E。
- 无 MUX 的“无头 Metal 加速”：仅 Turing（GTX 1650 Max-Q，#76 跟进）有报告；GA107 无头未见成功 → D。
- 驱动 v1.14.2 要求 SIP `0x0A43`、`amfi_get_out_of_my_way=0x1 amfi=0x80`、AMFIPass，均**削弱系统安全**（见 [RISK_ASSESSMENT](RISK_ASSESSMENT.md)）。

### 2.4 1401 v1.14.2 预计为本机生成的配置（代码推断，未生成）

| 项 | 预计值 | 来源 |
|---|---|---|
| SMBIOS | `MacBookPro16,2` | OCS `smbios.py` 笔记本默认 |
| macOS 版本 | 15（Sequoia，受 NullMoth 标记限制） | `nullmoth.SEQUOIA` |
| SIP `csr-active-config` | `430A0000`（0x0A43） | `nullmoth.SIP_DRIVER` |
| boot-args 追加 | `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0` | `nullmoth.BOOT_ARGS` |
| 安装阶段 BAR | `ResizeAppleGpuBars=0`、`ResizeGpuBars=-1`（Mac 端 setup 之后改为 13/-1，PR #133 指出对 Intel 内屏机型有害） | `policy.py`；PR #133 |
| 独显 DeviceProperties | `acpi-wake-type=1`，写在独显 PCI 路径上；本机实测位置 `PCIROOT(0)#PCI(0600)#PCI(0000)`，即 `PciRoot(0x0)/Pci(0x6,0x0)/Pci(0x0,0x0)` | `nullmoth.laptop_gpu_awake`；`hardware.json` |
| 核显 | 保持开启、不加属性——**前提是**有与 `Report.json` 同次扫描、`report_sha256` 一致的 `scan-evidence.json`；缺少它时按引擎默认处理，很可能被设 `disable-gpu`（即 1401#26 的旧行为） | `panel_guard`、`engine._unsupported_igpu_fix`、`engine.py:629-636`、`scan_evidence.py:129-160` |
| CPU | Comet Lake CPUID 伪装、ProvideCurrentCpuInfo、CpuTopologyRebuild、`ctrsmt=full` | OCS |
| 日志 | `Target |= 0x41` 写 U 盘日志 | `policy.py` |

**2026-10-13 实测 plan（沙箱、离线）**：上表决策与源码推断一致（macOS 15、MacBookPro16,2、保留核显、禁用指纹、24 个 kext），另有三点新事实：OCS 兼容性检查器原文判定“没有受支持的 GPU，无法安装 macOS”后被 1401 规则绕过；两条矛盾内屏提示在输出中同时出现；iasl 因本机 ACPI 重名对象合并反编译失败，1401 跳过预补丁反编译。详见 [docs/1401-plan-run-20261013](../docs/1401-plan-run-20261013/SUMMARY.md)。

**未生成真实候选 EFI**：缺 Hardware-Sniffer `Report.json`，且 OCS 会在缺 iasl 时下载并执行未固定版本的 iasl（见 RISK_ASSESSMENT R-07）。会话 2 进一步确认：`plan` 只输出决策、不生成 `config.plist`；要得到 EFI 必须走联网的 `build`。方案见 [NEXT_STEPS_PLAN](NEXT_STEPS_PLAN.md) 第 C 节。
