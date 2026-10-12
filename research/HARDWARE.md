# HARDWARE｜HONOR GLO-FX6P 硬件事实表（1401 审计视角）

> 维护规则：只写有证据的事实；推断必须标【推断】，未测必须标【未知】。原始证据在
> [`docs/hardware-survey-20261012/`](../docs/hardware-survey-20261012/REPORT.md)（2026-10-12 非管理员只读采集），
> 本文件不复制序列号、UUID、BitLocker 信息或个人身份信息。
> 2026-10-13 补充：只读环境检查（见 [`logs/RESEARCH_LOG.md`](../logs/RESEARCH_LOG.md) 第 2 节）。

## 1. 平台

| 项 | 值 | 证据 | 状态 |
|---|---|---|---|
| 机型 | HONOR MagicBook，型号 GLO-FX6P，SKU C233，版本 M2080 | `hardware.json` → `platform` | 实测 |
| 主板 | GLO-FX6P-PCB（M2080） | 同上 | 实测 |
| BIOS | HONOR 3.09（2023-07-10），EC 3.9，SMBIOS 3.3 | 同上 | 实测 |
| ACPI OEM | `HONOR` / `ADL-P-M` | 同上 | 实测 |
| 启动模式 | UEFI（`GetFirmwareType`=2，2026-10-13 复核） | `logs/RESEARCH_LOG.md` | 实测 |
| Secure Boot | 已开启（注册表 `UEFISecureBootEnabled=1`；2026-10-13 管理员 `Confirm-SecureBootUEFI` = `True`，两来源一致） | 同上；`scripts/readonly_admin_status.ps1` | 实测 |
| CFG Lock | 【未知】Windows 下无法只读获得；1401/Hardware-Sniffer 会探测，但未运行 | — | 未知 |
| VMD/RST | 【推断】未启用：NVMe 以 `144D:A80A` 直接枚举，未被 VMD 控制器遮蔽 | P20 PnP | 推断 |
| 操作系统 | Windows 11 家庭中文版 25H2，build 26200；Hyper-V/VBS 运行中（VBS status=2） | 同上 | 实测 |

## 2. CPU / 内存

| 项 | 值 | 状态 |
|---|---|---|
| CPU | 12th Gen Intel Core i5-12500H，Family 6 Model 154 (0x9A) Stepping 3，Alder Lake-H/P 混合架构 | 实测 |
| 核心 | 4 P 核 + 8 E 核 = 12 核 / 16 线程（只有 P 核超线程） | 实测 |
| 微码 | 0x41C | 实测 |
| 内存 | 16 GiB LPDDR5，配置速率 4800 MT/s；【推断】板载焊接 | 实测/推断 |

## 3. 图形与显示（审计关键）

| 项 | Intel 核显 | NVIDIA 独显 |
|---|---|---|
| 名称 | Iris Xe Graphics | GeForce RTX 2050 Laptop（**不是 3050**） |
| PCI ID | `8086:46A6` REV 0C，SUBSYS `20271EE7` | `10DE:25A9` REV A1，SUBSYS `20271EE7` |
| **PCI 类码** | **`0x0300`（VGA 兼容控制器）** | **`0x0302`（3D 控制器）** |
| 位置 | 00:02.0，`\_SB.PC00.GFX0` | 01:00.0，`\_SB.PC00.PEG0.PEGP`，PCIe Gen4 x4（最大 x16） |
| 显存 / VBIOS | 共享 | 4 GiB；VBIOS 94.07.69.00.22 |
| WDDM 角色 | HybridIntegrated，DisplaySupported=true | HybridDiscrete，**DisplaySupported=false，显示源 0** |
| 驱动暴露的连接目标 | INTERNAL 1、HDMI 2、DISPLAYPORT_EXTERNAL 14 | **0** |
| nvidia-smi | — | display_mode=Disabled，display_active=Disabled |

- **内屏**：BOE `0x0893`（EDID 文本 TV140WTM-NH0），2160×1440@60.001 Hz，EDID 1.4、接口 DisplayPort（eDP 为推断），ACPI `\_SB.PC00.GFX0.DD1F`；当前唯一活动显示路径由 Intel 46A6 输出（QueryDisplayConfig）。**实测**。
- **独显类码 0x0302 的含义**（2026-10-13 从 P20 PnP 证据中提取）：PCI 3D 控制器通常表示该 GPU 不承担显示输出。与 WDDM 显示源 0、驱动暴露连接目标 0 三者一致，强烈指向 **muxless（Optimus）拓扑：NVIDIA 没有物理连接任何显示接口**。【推断，强】——Windows 驱动暴露的连接目标不是物理接线图，仍需厂商资料或实机外接显示测试确认 HDMI/USB-C 归属。
- ACPI `NvdTable` SSDT 含 NVOP/JT/NBCI/GPS/MXM `_DSM`，以及 `MXDS`/`MXMX`/`MXM_` 名称：仅说明固件有 Optimus/MXM 方法，**不能证明存在硬件 MUX**。`mux_present=null`。
- Intel VBT、OpRegion 内容、eDP 链路参数、DDI 端口映射：**均未取得**（Windows 无受支持的用户态接口）。

## 4. 存储

| 项 | 值 | 状态 |
|---|---|---|
| 磁盘 | 1 块 Samsung MZVL2512HCJQ-00B00（PM9A1 系 OEM），NVMe `144D:A80A`，Gen4 x4，476.9 GiB，GPT | 实测 |
| 分区 | ESP 200 MiB、MSR 16 MiB、C: 120 GiB（剩余约 10.2 GiB，2026-10-13）、D: 343.2 GiB（剩余约 105.5 GiB）、3 个恢复类分区（0.5/12/1 GiB） | 实测 |
| 其他磁盘 | 2026-10-13 检查时**没有 U 盘或第二块磁盘** | 实测 |
| BitLocker | C:、D: 均为“完全解密 / 保护关闭 / 无密钥保护器”（2026-10-13 管理员 `manage-bde -status`；未读取任何密钥） | 实测 |
| WinRE | 已启用，位于磁盘 0 第 7 分区（`reagentc /info`，版本 10.0.26100.9168） | 实测 |
| ESP | FAT32，卷标 `SYSTEM`，约 196 MiB，剩余约 94 MiB，健康（`Get-Volume`，未挂载） | 实测 |
| 固件启动项 | 顺序：Windows Boot Manager → EFI USB Device → EFI DVD/CDROM → EFI Network；固件菜单超时 2 s（`bcdedit /enum firmware`；完整输出仅留在 `%TEMP%`，标识符 GUID 不入库） | 实测 |

## 5. 外设

| 设备 | ID / 路径 | 备注 | 状态 |
|---|---|---|---|
| Wi-Fi | Intel AX201 `8086:51F0`（CNVi） | — | 实测 |
| 蓝牙 | USB `8087:0026` | — | 实测 |
| 音频 | Intel SST 总线 `8086:51C8`（00:1F.3，`\_SB.PC00.HDAS`）；Realtek codec `10EC:0256` SUBSYS `1EE72029` | ALC256 为按编号【推断】；codec 挂在 SST DSP 之下 | 实测/推断 |
| USB | PCH xHCI `8086:51ED`；TCSS xHCI `8086:461E` | 无 TBT/USB4 PCI 设备 | 实测 |
| 触控板 | ELAN `ELAN2616`，I2C HID，`\_SB.PC00.I2C0.TPD0`；I2C 控制器 `8086:51E8` | — | 实测 |
| 键盘 | PS/2（经 EC），`\_SB.PC00.LPCB.PS2K` | — | 实测 |
| 摄像头 | USB `3277:0003` | — | 实测 |
| 指纹 | FPC USB `10A5:A921` | macOS 不可用（Dortania） | 实测 |
| 有线网 | 无内置；调查时存在 1 个 USB 外置网卡 | — | 实测 |

## 6. 本机仍缺的硬件事实（详见 [OPEN_QUESTIONS](OPEN_QUESTIONS.md)）

1. 是否存在 BIOS 级独显直连/MUX 选项（需用户在 BIOS 界面目视确认，不修改）。
2. HDMI、USB-C DP Alt Mode 物理连接到哪块 GPU（需厂商资料或外接显示器只读观察）。
3. CFG Lock 状态（BitLocker、WinRE、ESP 已于 2026-10-13 经批准的管理员只读查询补齐，见上表）。
4. Hardware-Sniffer 格式的 `Report.json`（1401 `plan` 模式的输入），从未生成。
