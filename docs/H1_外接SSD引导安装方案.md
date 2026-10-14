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
| `Misc.Boot.HideAuxiliary` | `false` → `true` | 开机菜单默认隐藏“Reset NVRAM”等辅助项（按空格才显示） |

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
开机按 `F12`，在一次性启动菜单里选 U 盘（这**不改**固件启动顺序）。OpenCore 菜单出现后选 “macOS Base System / Recovery”。屏幕会滚动 verbose 文字。

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
- **恢复镜像下载：用户暂未批准**，`com.apple.recovery.boot` 尚未放入。
