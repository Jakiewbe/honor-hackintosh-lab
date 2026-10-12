# 01｜HONOR 实测硬件与证据级别

主要根据 [硬件原始登记](../docs/HONOR_GLO-FX6P_硬件实测与证据等级.md)；**2026-10-12 更正**：RTX 是 **2050**，不是早期口述的 3050；内屏归属已知，**不要再要求用户检查“连接到”**。

| 组件 | 已知结果 | 证据 |
|---|---|---|
| 机器型号 | HONOR `GLO-FX6P`，主板 `GLO-FX6P-PCB` / M2080；高度吻合 MagicBook 14 2022 独显版 | Windows PowerShell 实机枚举 + 对照公开机型 |
| CPU | Intel Core **i5-12500H**，12th Gen Alder Lake-P/H，P/E 混合架构 | Windows 实机 |
| 内置 GPU | **Intel Iris Xe PCI `8086:46A6`**，Alder Lake-P GT2 | Windows 实机 |
| 独立 GPU | **NVIDIA RTX 2050 Laptop PCI `10DE:25A9`**，Ampere；不是 RTX3050 | Windows PCI 实机 |
| 内置显示屏 | Windows“高级显示→连接到”**明确为 Intel 核显** | 用户早已提供、再次确认；只代表当前激活链路，不证明 MUX 物理不存在 |
| 外接屏 | 用户曾用 USB-C→DP 带动 **1080p / 200 Hz** | 用户报告；**不能证明 USB-C 与 NVIDIA 直连** |
| 内存 | 约 16GB | Windows 实机 |
| 存储 | Samsung `MZVL2512HCJQ-00B00` 512 GB SSD | Windows 实机 |
| Wi-Fi | Intel AX201（Wi-Fi 6） | Windows 实机 |
| 音频 | Realtek | Windows 实机 |
| BIOS | 3.09，日期 2023-07-10 | Windows 实机 |

### 2026-10-12 Windows 只读硬件调查补充（本机实测，非管理员）

完整材料见 [`docs/hardware-survey-20261012/REPORT.md`](../docs/hardware-survey-20261012/REPORT.md)，结构化结果见 `hardware.json`，原始证据在 `evidence/`；26 项采集：成功 22、部分成功 1、失败 3（均因需管理员权限）。只用 CIM/WMI、PnP 属性、注册表只读、QueryDisplayConfig、D3DKMT 查询与 `GetSystemFirmwareTable`；未改系统、未提权、未访问物理内存。

| 项目 | 新增实测 | 不能推出 |
|---|---|---|
| CPU / 内存 | 4P(HT)+8E 共 16 线程，微码 `0x41C`；16 GiB LPDDR5（Samsung `K3LKBKB@BM-MGCP`），额定 6400、当前 4800 MT/s | 内存是否板载（推断板载，未证实） |
| Intel 46A6 | `00:02.0`、`\_SB.PC00.GFX0`，SUBSYS `20271EE7` REV `0C`，驱动 31.0.101.3358，WDDM 3.1 `HybridIntegrated` | DVMT/stolen 大小（驱动报告的 128 MiB/1 GiB 只是预算） |
| RTX 2050 25A9 | `01:00.0`、`\_SB.PC00.PEG0.PEGP`，REV `A1`，VBIOS 94.07.69.00.22，4 GiB，当前链路 Gen4 x4；WDDM `HybridDiscrete`、`DisplaySupported=false`、0 源 0 目标 | 主板没有 MUX；永远不能直连 |
| 显示连接器 | 当前模式下 Intel 驱动暴露 1 INTERNAL + 2 HDMI + 14 DP_EXTERNAL 目标，NVIDIA 为 0 | 物理端口走线、外接口 GPU 归属（外屏未接，**未测**） |
| 内屏 | BOE `0x0893` / EDID 文本 `TV140WTM-NH0`，2160x1440 @ 60.001 Hz，8 bpc，EDID 接口 DisplayPort，ACPI `\_SB.PC00.GFX0.DD1F`；Windows 只枚举到 60 Hz | eDP lane/速率/PSR/背光参数 |
| ACPI | DSDT+15 SSDT经哈希/长度/校验核对；单表iasl16份通过，联合namespace冲突仍阻塞。MXDS为空；MXMX为调试路径；MXM读取NVS；IGD另有经EDMX的位读写路径。ASLB是SANV首个32bit字段，IGDM声明0x2000。详见[静态证据](../research/acpi-static-20261012/README.md) | MUX结论：无法判断；NVS/OpRegion运行值、赋值者及实际GPIO含义UNKNOWN；非运行时证据 |
| VBT / OpRegion 内容 / DDI 映射 | **未取得**：没有受支持的 Windows 只读接口 | — |
| 存储 / 启动 | UEFI，Secure Boot 开（注册表）；GPT，ESP 200 MiB；C: 剩约 6.75 GiB | BitLocker、WinRE 状态（需管理员）；恢复条件仍**需要用户确认** |

### 待查而不臆测

- HDMI/USB-C 端口的 GPU 实际扫描输出归属；有无 MUX/Advanced Optimus、其他模式能否切换，**未验证**。无需重复调查内屏当前接 Intel。
- macOS 15.x 启动与 Alder Lake P/E 核、ACPI、EC、NVMe、Wi-Fi/音频的功能边界没有完整同配置实物证据。
- UEFI/磁盘分区/BitLocker/恢复密钥/EFI 独立备份与回退演练**未完成**，此时不进行任何磁盘或固件写入。
- Intel `46A6` 的真实 macOS eDP 初始化、IOFramebuffer、Metal；NVIDIA `25A9` 的 macOS GSP/NVAccel/Metal **都未证明**。
- 同配置 Notebookcheck 评测确认 Optimus 混合图形背景，但**没有提供本机可验证的电气走线图**：[2022 评测](https://www.notebookcheck.net/Honor-MagicBook-14-2022-review-Multimedia-laptop-with-RTX-2050.647183.0.html)。

### 技术后果

在目前 Intel 负责内屏的条件下，**仅证明 NVIDIA Metal/虚拟头可用，并不足以点亮本机内屏**。必须先证明 Intel 扫描输出本身能在 macOS 维持，或者另有真实的 NVIDIA→Intel 合法同步/复制路径。对“内屏永远只能 Intel”要区分用户当前连接的事实与缺乏 MUX 电路证据的未知。

用户电脑是主力生产设备；所有原生硬件实验必须延后到可恢复、明确批准的独立测试环境。
