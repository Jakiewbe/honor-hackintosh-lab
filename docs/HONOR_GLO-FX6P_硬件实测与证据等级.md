# HONOR GLO-FX6P｜硬件实测与证据等级（研究基线）

**2026-10-12 更正：内屏当前 Windows 输出归属已经由用户明确确认，不能再写作 UNKNOWN，也不得让用户重复运行相同的内屏检查。**

## A. 已确定的硬件与观测

| 事项 | 已知事实 | 证据级别与边界 |
|---|---|---|
| 型号/平台 | HONOR `GLO-FX6P`，主板 `GLO-FX6P-PCB / M2080`；高度吻合 MagicBook 14 2022 | Windows PowerShell 实机硬件信息，用户先前报告 |
| CPU | Intel Core i5-12500H，Alder Lake-P/H | Windows 实机信息 |
| 内置 GPU | Intel Iris Xe，PCI `8086:46A6` | Windows 实机信息 |
| 独立 GPU | NVIDIA GeForce RTX 2050 Laptop，PCI `10DE:25A9`，**不是此前口述的 RTX 3050** | Windows 实机 PCI ID 结果优先 |
| 内屏“连接到” | **Intel 核显** | **用户此前已经在 Windows“高级显示”确认并再次明确重申**；可确认当时的活动输出归属，不自动证明永久 muxless 或电气电路图 |
| USB-C→DisplayPort | 用户报告曾外接 **1080p / 200 Hz** 显示器并正常使用 | 证明 USB-C 显示输出可用；**不能区分该接口由 NVIDIA 还是 Intel 扫描输出** |
| 内存与硬盘 | 约 16 GB；Samsung `MZVL2512HCJQ-00B00` 512 GB | Windows 实机信息 |
| 无线/音频 | Intel Wi-Fi 6 AX201、Realtek 音频 | Windows 实机信息 |
| BIOS | 3.09，2023-07-10 | Windows 实机信息 |

## B. 尚未确认的事实（不得代替已确认项）

- HDMI 接口与 USB-C DP Alt Mode 的**GPU 输出归属**未确认；高刷新率不等于 NVIDIA 直连。
- 硬件是否具有实体 MUX / Advanced Optimus、在其他模式下能否切换内屏扫描输出，没有足够实测证据。**当前连接 Intel**与**硬件永久只能连接 Intel**须严格区分。
- UEFI 启动模式、分区/BitLocker 具体状态、EFI 独立备份及回滚验证尚未完成。
- RTX 2050 `10DE:25A9` 的 macOS NVRM attach、NVAccel、Metal 真实渲染、GSP 初始化没有该机实机证据。
- Intel Xe `8086:46A6` 的 macOS framebuffer / scanout / Metal 是否可用，没有该机或匹配设备的充分实机证据。

## C. 后续决策与禁止重复工作

1. **内屏活动输出归属视为已知**：Intel Iris Xe；不再把它列为下一轮向用户索取的截图任务。
2. **内屏 macOS 可用性最小条件**：必须证明 Intel 扫描输出路径在 macOS 可行，或存在实际可用的 NVIDIA 渲染→Intel 扫描输出桥接链路。NVIDIA 设备表匹配、`Metal 3` 字样、单独 NVAccel 构建或 VBL 抽象模型均不足以证明内屏可用。
3. **外屏路线是可选分支**：若以后有直接 NVIDIA 扫描输出的可靠证据，再单独讨论外接显示器情形，不能将外屏推断套用于内屏。
4. **设备安全边界**：只读调查、仓库源代码与离线云端分析；在备份和回滚演练之前，不修改 Windows、BIOS、EFI、磁盘、Secure Boot/SIP，不签名/加载第三方驱动，不执行第三方一键安装器。
5. **立即研究重点**：Intel Xe 12 代驱动可行性、NMXGPU 独立实机报告、跨 GPU 复制与输出机制和 NVIDIA 2050 加速真实证据；R1.2-C～G 的 VBL 补丁研发保持冻结。

**档案更新依据：用户在原项目早先确认内屏连接 Intel，并在 2026-10-12 再次指出这一信息早已提供。**

状态：`INTERNAL_DISPLAY_ON_INTEL_CONFIRMED_BY_USER / MUX_UNVERIFIED / EXTERNAL_PORT_OWNER_UNVERIFIED / MACOS_GRAPHICS_RUNTIME_NO_GO`。
