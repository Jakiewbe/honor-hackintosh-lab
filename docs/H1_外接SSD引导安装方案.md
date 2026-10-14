# H1｜外接 SSD 引导与安装 macOS 15 方案（2026-10-13，决策 D-17）

**状态**：方案，未执行。每个标 🔒 的步骤都需要用户针对该步骤单独批准。
**不变的边界**：内置 NVMe（`SAMSUNG MZVL2512HCJQ`，磁盘 0）、Windows、其 EFI 分区、BCD、固件启动顺序**全程不改**。

## 0. 使用的 EFI

位置：`D:\Hactk\efi-candidates\GLO-FX6P-1401-20261013\`（仓库外，含生成的 Mac 序列号）。

| 变体 | 内容 | 何时用 |
|---|---|---|
| `H1-A` | 1401 原样 − `NullMothLogo.efi` + 下表四项安全调整 | 首选 |
| `H1-B` | `H1-A` + `ForceExitBootServices=true` | H1-A 停在 `EXITBS:START` 时的单变量对照 |

H1 安全调整（相对 1401 输出，均通过 ocvalidate 1.0.9）：

| 设置 | 原值 → 新值 | 目的 |
|---|---|---|
| `DeviceProperties` 给内置 NVMe `PciRoot(0x0)/Pci(0x6,0x2)/Pci(0x0,0x0)` 加 `class-code=FFFFFFFF` | 无 → 有 | 让 macOS 不加载内置 NVMe 驱动，磁盘工具里看不到它，避免误抹 Windows。**未实机验证**，第一次进安装器必须确认 |
| `NVRAM.WriteFlash` | `true` → `false` | OpenCore 注入的 boot-args 等变量只在本次开机有效，不持久写入固件 |
| `ResetNvramEntry.efi` 参数 | 空 → `--preserve-boot` | 万一执行“Reset NVRAM”，保留固件启动项（含 Windows Boot Manager） |
| ~~`Misc.Boot.HideAuxiliary`~~ | ~~`false` → `true`~~ | **已撤销（10-14）**：它也隐藏 macOS 恢复项，见附录“S3 第一轮”。现为 `false`，菜单直接显示恢复项和 Reset NVRAM（后者带 `--preserve-boot`，但仍不要选） |

已有的有利设置：`LauncherOption=Disabled`（OpenCore 不把自己登记到固件启动列表）、`RequestBootVarRouting=true`（macOS 设置启动磁盘时写到 OpenCore 专用命名空间，不改 Windows 启动项）、`Misc.Debug.Target=67`（日志写到 U 盘根目录）。

## 1. 器材

- U 盘 ≥16 GB：**会被清空**。
- 外接 SSD ≥128 GB：**会被清空**。
- USB 鼠标（触控板在 macOS 中预计不可用）。
- 安装需要联网：恢复镜像在线下载约 13 GB。Wi-Fi 驱动 itlwm 在安装器里不可用，计划用现有的 Realtek USB 网卡扩展坞（`0BDA:8153`，macOS 大概率自带驱动，需实测）；或 iPhone USB 共享网络。

## 2. 步骤

### S0 识别外接设备（只读，无需批准）
插上 U 盘与外接 SSD，我运行 `Get-Disk` 只读列出磁盘编号、总线类型、容量、型号，写入本文附录。之后所有写盘步骤**只接受总线类型为 USB、且不是启动盘/系统盘的磁盘编号**。

### S1 🔒 制作 U 盘（需要管理员，写 U 盘）
1. 我先给出脚本全文供你审阅。脚本会断言目标磁盘 `BusType=USB`、`IsBoot=False`、`IsSystem=False`、容量与 S0 记录一致，否则退出。然后清空该 U 盘，建 GPT + 一个 16 GB FAT32 分区。
2. 用 OpenCore 1.0.9 自带的 `macrecovery.py`（已核对只访问 `osrecovery.apple.com`，主板序号为全零占位）下载 macOS 15 恢复镜像：`-b Mac-7BA5B2D9E42DDD94 -m 00000000000000000 download`，放入 U 盘 `com.apple.recovery.boot\`。
3. 复制 `H1-A\EFI` 到 U 盘根目录，并在 U 盘上额外放一份 `H1-B` 的 `config.plist`，命名为 `config-B.plist`，便于切换。

回滚：U 盘重新格式化即可，内置盘不受影响。

### S2 🔒 BIOS 关闭 Secure Boot（你手动操作）
开机按 `F2` → Security Setting → Secure Boot → Disabled → `F10` 保存。
- 影响：Windows 照常启动；BitLocker 未加密，不会要求恢复密钥。少数依赖 Secure Boot 的反作弊游戏会受影响。
- 回滚：同一位置改回 Enabled。

### S3 🔒 首次从 U 盘引导（你手动操作）
开机按 `F12`，在一次性启动菜单里选 U 盘（这**不改**固件启动顺序）。OpenCore 菜单出现后（5 秒倒计时，超时会进 Windows）用方向键选恢复项（名称类似 “macOS Base System / Recovery”）回车。屏幕会滚动 verbose 文字。

可能结果与处理：

| 现象 | 处理 |
|---|---|
| 进入恢复界面（语言选择/实用工具） | 成功，进 S4 |
| 停在 `EXITBS:START` 或 `[EB|...]` 字样不动 > 3 分钟 | 长按电源关机 → 进 Windows → 把 U 盘根目录 `opencore-*.txt` 交给我；把 U 盘上 `config.plist` 换成 `config-B.plist` 再试一次 |
| 内核 panic / 重启循环 | 拍照屏幕最后几行，关机，同上收集日志 |
| 文字停在 `loginwindow` 附近但图形界面不出现（同 1401 Issue 7） | 拍照，收集日志，停止，等分析 |

每次失败后都先正常启动一次 Windows（不按 F12），确认 Windows 完好。

### S4 🔒 安装到外接 SSD
1. 恢复界面 → 磁盘工具 → 显示 → 显示所有设备。
2. **确认列表里没有 512 GB 的 Samsung 内置盘**（class-code 隐藏生效）。如果看得到它，**立即停止**，不抹任何盘，回报。
3. 选外接 SSD（核对型号和容量与 S0 一致）→ 抹掉 → APFS / GUID 分区图。
4. 退出磁盘工具 → 重新安装 macOS Sequoia → 目标选外接 SSD。
5. 安装中会多次重启：每次按 `F12` → U 盘 → OpenCore 菜单选 “macOS Installer”（在外接 SSD 上），直到出现设置助理。

建议：先不要登录 Apple ID / iCloud。

### S5 🔒 首次进入桌面后的记录
保存 `ioreg`、`kextstat`、`system_profiler SPDisplaysDataType`、`log show --last boot` 的关键段到 U 盘，回到 Windows 交给我。这是 H2/H3 的起点。

### S6 （以后）把 EFI 放到外接 SSD 的 EFI 分区，脱离 U 盘启动
单独批准；仍只写外接 SSD。

## 3. 停止条件
- 磁盘工具里能看到内置 Samsung 盘 → 停止。
- 任何一次之后 Windows 无法正常启动、BIOS 设置被重置、固件启动项消失 → 停止，先恢复 Windows（Windows 启动项在内置盘 EFI 分区未动，F12 菜单可选 Windows Boot Manager；WinRE 已启用）。
- 出现无法解释的硬件行为（风扇狂转不止、屏幕异常闪烁）→ 长按关机，停止。

## 4. 已知不确定性
- Q-18：同 CPU 的 1401 Issue 26 停在 `EXITBS:START`，所以准备了 H1-B 对照。
- 固件帧缓冲能否显示安装器 GUI 未知（1401 Issue 7 的 11 代机型未出 GUI）。
- `class-code` 隐藏 NVMe 是社区做法，本机未验证，所以 S4 第 2 步必须目视确认。
- USB 网卡在恢复环境是否免驱未知。

## 附录：用户确认（2026-10-13）
- 方案已审阅通过；联网方式选 USB 扩展坞网口（`0BDA:8153`）。
- S0 等用户插好 U 盘与外接 SSD 后执行。

## 附录：S0 磁盘识别记录

2026-10-14 13:33，`Get-Disk`/`Get-Partition`/`Get-Volume` 只读（未取序列号）：

| 磁盘 | 型号 | BusType | 容量 | 分区表 | IsBoot/IsSystem | 结论 |
|---|---|---|---|---|---|---|
| 0 | SAMSUNG MZVL2512HCJQ-00B00 | NVMe | 476.9 GB | GPT，7 个分区 | True/True | 内置盘，永不碰 |
| 1 | KIOXIA TransMemory | USB | 28.9 GB | MBR，2 个分区 | False/False | 用户 U 盘，**含个人数据，不可直接用于 S1** |

- 磁盘 1：分区 1 exFAT 卷标 `System`（E:，28.24 GB，已用 25.42 GB）+ 分区 2 约 0.29 GB（类型未知），布局与微PE（WEPE）启动盘一致。根目录有个人项目文件夹/文档、Windows 与 Office 安装文件、旧 OpenCore 0.8.4 EFI 等（只看文件名，未打开文件）。
- 根目录有 `System Volume Information.exe`（伪装成系统文件夹名的可执行文件，疑似 U 盘蠕虫），已提醒用户勿运行并查杀，未触碰。
- 外接 SSD 本次未插入。
- 卷空间：C: 剩 8.8 GB，D: 剩 104.3 GB。
- **决定**：S1 暂停，待用户选择：换空 U 盘 / 先备份本 U 盘 / 改用外接 SSD 兼做安装盘。
- **用户选择先备份**（13:34）：`robocopy E:\ D:\USB-backup-KIOXIA-20261014 /E /COPY:DAT`，排除 `System Volume Information` 文件夹与疑似蠕虫 `System Volume Information.exe`；1221 文件 / 25.42 GB，失败 0。逐文件 SHA256 比对：缺失 0、多余 0、不一致 0；1 个文件（`HEU_KMS_Activator_v63.1.0.exe`）在 U 盘侧被系统拒绝读取（errno 22，推测为 Defender 拦截），大小一致。WEPE 启动分区（0.29 GB）未备份。日志 `%TEMP%\hk-usb-backup-20261014.log`。
- S1 脚本：[`scripts/h1_s1_prepare_usb.ps1`](../scripts/h1_s1_prepare_usb.ps1)，七项断言（非磁盘 0、USB、型号、精确容量 30979129344、非启动/系统盘、在线可写）全部通过才清空；GPT + 16 GB FAT32 `OCINSTALL`。
- **S1 执行（13:46，用户批准 + UAC）**：第一次运行七项断言全过，`Clear-Disk` 成功（U 盘 0 分区，仍为 MBR），随后 `Initialize-Disk` 报“已初始化”终止。日志中另有 13:46:43 的第二次运行记录（非本代理启动），断言同样全过，作用于已清空的 U 盘。修正脚本（清空后 MBR 用 `Set-Disk -PartitionStyle GPT`，已无分区则跳过清空）后再次 UAC 运行，退出 0：磁盘 1 为 GPT、1 个分区，E: `OCINSTALL` FAT32 15.99 GB。磁盘 0 仍为 GPT、7 个分区。
- 复制 `H1-A\EFI` → `E:\EFI`（142 文件，SHA256 全一致），`H1-B` 的 config 另存为 `E:\EFI\OC\config-B.plist`（一致）。
- 恢复镜像（13:51 用户批准）：OpenCore 1.0.9 `macrecovery.py -b Mac-7BA5B2D9E42DDD94 -m 00000000000000000 download`，在沙箱 `dl\recovery-sequoia` 下载并按 chunklist 校验通过（86 块）。`BaseSystem.dmg` 884317790 字节 SHA256 `7314EB40…`，`BaseSystem.chunklist` 3352 字节 `DBF262B8…`；复制到 `E:\com.apple.recovery.boot\`，哈希一致。U 盘剩余 15.13 GB。**S1 完成**；下一步 S2（用户手动关 Secure Boot）、S3（F12 引导）。

## 附录：S3 第一轮（2026-10-14 17:03、17:05）

- 用户已关 Secure Boot（日志 `OCSB: Secure boot is disabled`），F12 从 U 盘引导两次，OpenCore 菜单只有两个 Windows 项，没有恢复项。第一次超时启动内置盘 ESP 的 Windows，第二次用户选了内置盘分区 5 的 `\EFI\BOOT\BOOTX64.EFI`。两次都回到 Windows，无异常。
- 日志（U 盘根目录 `opencore-2026-10-14-170304.txt`、`-170546.txt`，含 OC 生成的序列号/MLB/ROM，**不入库**）：`OCB: Adding fs … (aux hidden)`、`OCB: Not adding hidden auxiliary entry Reset NVRAM`；U 盘分区只查了 blessed/预定义路径，没有 recovery 条目。`class-code` 设备属性写入成功；GOP 2160x1440。
- 原因（对照 OpenCorePkg master `81ecf1a` 源码）：`BootEntryManagement.c` 的 `AddBootEntryFromSelfRecovery` 在 `HideAuxiliary` 为真时直接返回，不加 `com.apple.recovery.boot` 条目；`BuiltinPicker.c` 中空格键（`OC_INPUT_MORE`）把 `HideAuxiliary` 置假并重建菜单。即 H1-A 自己加的 `HideAuxiliary=true` 导致恢复项被隐藏，U 盘文件与镜像无问题（`BaseSystem.dmg`/`.chunklist` 大小与校验时一致）。
- 处理：先建议菜单内按空格；用户（17:15）回复“你先改，我不会按的”，即批准改 U 盘。H1-A、H1-B 的 `config.plist` 只把 `HideAuxiliary` 改为 `false`（plist 逐键 diff 仅此一键，ocvalidate 均无问题），原文件备份在沙箱 `config-bak-before-hideaux\`，候选目录 `SHA256SUMS.txt` 同步更新。写入前核对 E: 属于磁盘 1（KIOXIA、USB），写入后 U 盘与候选哈希一致：`config.plist` `30A3AA4F…`、`config-B.plist` `99C1F42C…`。其余 U 盘文件未动。

## 附录：S3 第二轮（2026-10-14 17:21）

- 菜单出现恢复项（`OCINSTALL [AppleRecv:Apple]`），用户选中。OpenCore 加载 `BaseSystem.dmg`（chunklist 校验通过），`boot.efi` 读入内核 24.4.0（macOS 15.4 恢复），29 个 kext 全部注入成功，CPU 补丁全部成功，`OCABC: MAT support is 1`，MMIO devirt 3 段，可用 slide 0–217。日志止于 `EB|LOG:EXITBS:START`（17:22:46）。
- 用户描述：屏幕停在一屏文字，最后一行为 `EXITBS:START`，完全卡死，手动关机。即内核零输出。
- 同类案例：1401 Issue 26（i5-12500H，同样卡点）10-13 新增评论“禁用 VT-d 可以解决这个问题”；Issue 46（i5-12450H + RTX 4050，Alder Lake-H 笔记本）标题为 “freezes at EXITBS:START, zero kernel output”，已应报告者要求清空。Issue 26 的 Ryzen 台式机用户靠 `ForceExitBootServices`+`SetupVirtualMap` 解决（本机 `SetupVirtualMap` 已为 true）。
- 本机日志 ACPI 有 `DMAR`（136 字节），即 VT-d 开启；BIOS 无此选项。OpenCore `Configuration.tex`：`DisableIoMapper`（已开）是删除 DMAR / 固件关 VT-d 的替代；对照 Dortania “Stuck on EXITBS:START” 一节，本机 Booter 组合符合 MAT 固件建议。
- 用户选择组合试验（17:3x）：新变体 `H1-C` = `H1-A` + `ForceExitBootServices=true` + `ACPI.Delete`（`All=true`、`TableSignature=DMAR`）。plist 逐键 diff 仅这 7 个键，ocvalidate 无问题。U 盘：原 `config.plist` 另存为 `config-A.plist`（`30A3AA4F…`），`config.plist` 换为 H1-C（`84DD29CB…`），`config-B.plist` 不变。这两项只作用于经 OpenCore 引导的那一次开机。

## 附录：S3 第三轮（2026-10-14 17:32，H1-C）

- 日志确认 `OCABC: FEXITBS 1`、`OCA: Deleting table DMAR … at index 21`；仍止于 `EXITBS:START`（17:33:07）。用户照片（17:22、17:33 两张）均为 `boot.efi` 输出停在 `EB|LOG:EXITBS:START`，之后无内核输出。结论：单开 `ForceExitBootServices` 加删 DMAR 不足以通过。
- 检索：社区 Alder Lake 配置指南（alyxferrari/OpenCore-Install-Guide `alderlake` 分支 `config.plist/alder-lake.md`）的 Booter 推荐与本机配置逐项一致，唯独 `SetupVirtualMap` 为 NO（本机 YES）；Cpuid1Data 同为 `55060A00`。Dortania 排错页：2020 年后的许多固件开启 `SetupVirtualMap` 会在此处卡死。本机固件为 Insyde（ACPI 有 `$H2O` 表）。同指南另注 `RebuildAppleMemoryMap` 在部分笔记本 OEM 固件上会导致早期失败（下一候选：旧固件组合）。
- 用户选择在 H1-C 上叠加（17:4x）：`H1-D` = `H1-C` + `SetupVirtualMap=false`（逐键 diff 仅此一键，ocvalidate 无问题）。U 盘：H1-C 另存 `config-C.plist`（`84DD29CB…`），`config.plist` = H1-D（`C8B4C0B4…`）。
- 附加观察请求：卡住时按 Caps Lock 看指示灯是否切换，用来区分内核死锁与“在跑但不显示”。

## 附录：H1-D 首次尝试未进入测试（2026-10-14 17:45–17:46）

- 用户报告“OC 引导都失败了”。Windows 事件日志（只读）：17:44:59 关机后 17:45:08 直接启动 Windows（无对应 OpenCore 日志，未进 U 盘）；17:46:21 OpenCore 正常启动，菜单列出恢复项，5 秒内无按键，按默认项启动 Windows，17:46:40 Windows 正常开机，无 Kernel-Power 41 / 蓝屏记录。用户描述“没看到菜单，很快跳了代码后进入了 Windows”：屏幕调试输出（`Target=67`）与菜单混在一起，5 秒倒计时内难以辨认。H1-D 本身尚未被测试。
- 用户批准把菜单倒计时去掉：H1-D `Misc.Boot.Timeout` 5 → 0（逐键 diff 仅此一键，ocvalidate 无问题），U 盘 `config.plist` 更新为 `450F501C…`。`config-A/B/C.plist` 备份未改，仍为 5 秒。

## 附录：S3 第四轮（2026-10-14 17:51，H1-D）与 12500H 拓扑问题

- 日志 `OCABC: … VMAP 0`、`FEXITBS 1`、DMAR 已删，仍止于 `EXITBS:START`（17:52:33）。用户：卡死，按 Caps Lock 指示灯无反应（内核未跑到键盘驱动，倾向真挂死而非仅无显示），无 `panic-*.txt`。
- **检索到同 CPU 根因线索**：Dortania bugtracker 336《12500H Efficiency Core Issue》（open）：Erying i5-12500H 主板稳定卡 `EB|LOG:EXITBS:START`，`ProvideCurrentCpuInfo` 已开；套用 12700H/12900HK 的成品 EFI 也一样；BIOS 关 E 核（4C8T）或关超线程（12C12T）即可通过。评论中“跳过 EB 的内核补丁”仅对 macOS 13.3 之前有效。作者仓库 hykilpikonna/Erying-ITX-12500H-OpenCore（OpenCore 1.0.3、macOS 15.3）仍要求 BIOS 关超线程。本机 BIOS 无此两项。
- 推断（未验证）：本机卡点与此同源（12500H 16 线程拓扑），前几轮内存类 Booter quirk 均无效与此一致。软件近似：XNU 启动参数 `cpus=N` 限制启用的逻辑 CPU 数；更彻底的替代是改写 MADT 去掉部分 Local APIC（未做）。
- 用户批准 `H1-E` = `H1-A` + boot-args 末尾追加 `cpus=8` + `Timeout=0`（逐键 diff 仅这两键，ocvalidate 无问题）。U 盘：H1-D 另存 `config-D.plist`（`450F501C…`），`config.plist` = H1-E（`C46EE405…`）。

## 附录：S3 第五轮（2026-10-14 18:00，H1-E）与暂停结论

- 日志 `EB|MBA:OUT` 含 `cpus=8`（及 boot.efi 自加的 `slide=176`），Booter 组合回到 H1-A，仍止于 `EXITBS:START`（18:01:13），用户：依旧卡死。说明限制启动的逻辑 CPU 数不足以绕过，卡点更早（BSP 读取 CPU 拓扑阶段的推断，未证实）。
- MADT 只读读取（`GetSystemFirmwareTable`，表另存沙箱 `h1-logs\APIC.aml`）：OEM `HONOR`/`ADL-P-M`，启用的 16 个 LAPIC 依次为 APIC ID 0、1、8、9、16、17、24、25（性能核+超线程）与 32–46 偶数（能效核），其后 16 个禁用占位。CpuTopologyRebuild issue 24 的“能效核排在前被当主核”假设在本机不成立。
- OpenCore 源码核对：`ProvideCurrentCpuInfo` 在混合架构上把 MSR 35h 设为 线程=线程（本机 `00100010`），核心/包补丁写 128，拓扑校验 `_x86_validate_topology` 置 `ret`；内核 quirk 先于用户 `Kernel.Patch` 应用。1401 另有 3 条用户补丁 “force HT enabled …”（`_cpu_thread_alloc`，Sequoia 版 `418b8694010000`→`b8ff0000009090`）。
- 远景论坛帖（12500H/12700H/12900H 卡 EB）：把“核心/包”改为 16 可 8 核 16 线程启动，但 bugtracker 336 评论称仅对 macOS 13.3 之前有效。本机无 DMG/APFS 读取工具，未能在内核中核实补丁落点，故未试。
- **结论（10-14 18:2x，用户决定暂停）**：5 轮引导中 OpenCore 阶段全部成功，失败点固定为内核交接后零输出卡死；已排除 `ForceExitBootServices`、删 DMAR、`SetupVirtualMap=false`、`cpus=8`。与 Dortania bugtracker 336 的 12500H 现象一致，公开有效解法只有 BIOS 关超线程/能效核。可见菜单里没有这些项。H1 置为 blocked。未尝试的方向：关 1401 的 force-HT 补丁；核心/包 128→16；改隐藏设置（高风险，见下一附录，尚未批准）。
- 现状：Windows 正常；内置盘/ESP/BCD/固件启动项未改；Secure Boot 仍为关闭（用户可在 BIOS 改回）；U 盘保留 H1-E 与各备份配置。

## 附录：BIOS 3.09 隐藏 CPU 项（2026-10-14，只读，未改任何变量）

用户选择“只读研究 Insyde 隐藏超线程设置”。本机荣耀目录没有缓存 BIOS 包。从官网驱动页按机型「MagicBook 14 2022 独显 RTX 2050 i5 16GB+512GB (GLO-F56)」下载官方包 `BIOS_1.13&3.09_05017MAC&05017MJJ_Firmware`（标注 20230720，2023-11-13 上架）。外层 zip SHA256 `0D7FB6F87B003546A8E9CBE6CDB8EF7023846A133DB6399B3BC2CBBADB2CAAD8`，签名者为 Honor Device Co., Ltd.。包内选择脚本：机型名含 `GLO-FX6P` 走 3.09，否则走 1.13。3.09 的 `SystemFirmware.inf` 为 `DriverVer = 07/10/2023,0.3.0.9`，与本机 SMBIOS BIOS 3.09（2023/7/10）一致。固件镜像 `SystemFirmware.bin`（21600240 字节）SHA256 `f0b6da3a712564bdb7c8c3e19e21da6e9ca4f685a6a8932897081e61e16a0abf`。全程只在沙箱用纯 Python 解开 NSIS 并解析 HII 菜单，没有运行刷写程序，没有读、写 UEFI 变量。

菜单在 Intel 的 Advanced 表单集（标题 “Advanced”，其下 “CPU Configuration”）里，不在荣耀普通设置页引用的 Main 表单集里。CPU Configuration 这一条在 Advanced 里没有被隐藏条件包住；荣耀的可见菜单根本不挂这个 Advanced 页，所以开机按键进的 BIOS 里看不到。

| 菜单项 | 变量 | 偏移 | 取值 | 菜单里何时不显示 |
| --- | --- | --- | --- | --- |
| Hyper-Threading | `CpuSetup` | `0x05`（1 字节） | 0=Disabled，1=Enabled，出厂默认 1 | 仅当 `SetupCpuFeatures` 偏移 `0x04` 为 0（CPU 上报不支持超线程）。12500H 支持超线程，这项在 Advanced 页里应可见。TXT（`CpuSetup+0xC1`，默认关）打开时该项变灰 |
| Active Performance-cores | `CpuSetup` | `0x06` | `0xFF`=All（默认），或具体核数 | 隐藏计数 `CpuSetup+0x2AC` 为 0 时隐藏；Per Core Disable 打开或 TXT 打开时变灰 |
| Active Efficient-cores | `CpuSetup` | `0x22F` | `0xFF`=All（默认），或具体核数 | 隐藏计数 `CpuSetup+0x2AB` 为 0 时隐藏；变灰条件同上 |
| Per Core Disable Configuration | `CpuSetup` | `0x34C` | 0=Disabled（默认），1=Enabled | 在 Processor 子页 |

`CpuSetup` 的 GUID 是 `{B08F97FF-E6E8-4193-A997-5E9E9B0ADB32}`，长度 `0x379`，菜单声明的属性是非易失 + 启动服务 + 运行时（`0x07`），不是认证写变量。这只说明菜单如此声明；固件仍可能在进入系统前锁住它。没有读过本机当前值。机器现在以 16 线程运行，与默认“超线程开”一致。

未做、且未批准：读取或改写该变量。写错偏移可能无法开机；关超线程后 Windows 也会变成 12 线程（4 个性能核不再带超线程，8 个能效核还在）。能进 BIOS 时，“恢复默认”会把这些项打回上表的默认值。进不了系统时没有已验证的恢复步骤。
