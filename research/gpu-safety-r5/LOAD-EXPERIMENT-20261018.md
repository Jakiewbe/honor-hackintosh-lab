# A. 一次性 KEXT-LOAD 取证协议（2026-10-18，用户已授权）

**授权范围**：一次隔离的 kext 加载取证。**不含**：EFI/BIOS/SIP/AMFI 改动、安装或替换驱动文件、改 boot-args、
重启以外的持久化操作、内屏桥接实验。

**执行者**：你（我无法进入那块外接 SSD 的 macOS）。我负责给出判定表，并把带回的日志翻译成结论。

**只回答一个问题**：NVRM（RM/GSP）在本机能不能初始化成功。不回答"桌面会不会变快"。

> 为什么只加载 NVRM、不加载 NVRMFB/NVAccel：
> `NVRMFB::start()` 需要 boot-arg `nvfb=1` 才启动（`nvrm-fb.cpp:1984`），那是 EFI 改动，不在本次授权内；
> 而 `NVAccel` 会在有 framebuffer 时接管加速。本次只想知道 GPU 能不能起来，最少的变量就是只加载 NVRM。

---

## 0. 开始前（Windows 侧也要做）

1. 确认**当前 macOS 能正常启动到桌面**（这是唯一的回退基线）。
2. 记下你现在能进桌面的那套 OpenCore 配置（U 盘 / 外接 SSD 的 ESP）。不修改，只是知道它在哪。
3. 确认本次实验**不会**碰内置 NVMe、Windows、EFI。

## 1. 采集基线（macOS 里，普通用户）

把 `tools/gpu-forensics/collect.sh` 拷到 macOS（U 盘/网盘都行），然后：

```bash
bash collect.sh before
```

产物在 `~/Desktop/gpu-forensics/<时间>-before/`。**这一步不改任何东西。**

先自己看一眼 `06-bootargs.txt`：

- 如果里面有 `nvfb=1`，说明 NVRMFB 本来就会启动——那本次实验要额外小心，先告诉我再继续。
- 如果有 `-nvrmnogo`，NVRM 会直接拒绝初始化——先告诉我。

## 2. 加载取证（macOS 里，root）

```bash
sudo bash load-nvrm-once.sh
```

脚本自己会做这些拒绝（不满足就退出，不"尽力而为"）：

| 检查 | 不满足时 |
|---|---|
| 是 macOS | 退出码 2 |
| 是 root | 退出码 2 |
| `/Library/Extensions/NVRM.kext` 存在 | 退出码 3（说明驱动没装，实验做不了） |
| NVRM **当前未加载** | 退出码 4（要求从干净状态开始） |
| `kextload` / `kmutil load -p` 成功 | 退出码 5，并明确提示"不要为此关 SIP" |
| 卸载后模块列表回到基线 | 退出码 6，提示重启可回到实验前状态 |

它会：记基线 → 加载 → 等 30 秒 → 采日志（`NVRM-xnu:` / `NVKMS rm:` / `gsp` 行）→ **立即卸载** → 再记一次模块列表。
**没有安装任何文件，没有写 nvram，没有改 SIP/EFI。**

## 3. 带回什么

两个目录打包，一起给我：

```bash
cd ~/Desktop/gpu-forensics
tar czf gpu-forensics-$(date +%Y%m%d).tar.gz *-before *-load
```

如果不方便传文件，至少把这两个文件的内容贴给我：

- `*-load/22-key-lines.txt`（脚本自动摘出的关键行）
- `*-load/load-session.log`

## 4. 判定表（我看到日志后按这个下结论）

| 日志特征 | 含义 | 等级 |
|---|---|---|
| `NVRM-xnu: ... rm_init_adapter ...` 成功，且出现 `allocateDevice ... ok` 或后续 ALLOC status 0x0 | RM 起来了 | `GPU-RUNTIME` 的**必要**条件之一 |
| 只有 `allocateDevice failed` / `getDeviceResourcesInfo failed` | RM 没起来 | 关键失败点，看上一行 |
| `NVRM-xnu: ... GSP ...` 或 `FSP` 相关报错/超时 | GSP 固件或初始化问题 | 通常是止损信号 |
| `NVKMS rm: ALLOC ... -> status 0x...`（非 0） | RM 分配失败，记录 status | 按 status 查含义 |
| 完全没有 `NVRM-xnu:` 行 | 驱动没运行（可能没匹配到设备） | 先看 `24-iopci-nvidia.txt` |
| 内核 panic / 卡死 | RM 把机器搞挂了 | 重启，记录为"不可加载" |

## 5. 停止条件（任一命中就停，不继续）

- 加载命令返回失败（SIP/签名/依赖）→ 不做任何绕过，停。
- 加载后 30 秒内系统卡死或 panic → 断电重启，记录现象，停。
- 卸载失败、状态未回基线 → 重启后确认恢复正常，再把日志给我。
- 出现任何"为了让它加载而关 SIP/改 boot-args"的冲动 → 那需要**新的单独授权**，现在不做。

## 6. 回退

本次实验不产生持久化修改：

- 没有安装/替换/删除任何文件；
- 没有写 `nvram`；
- 没有改 SIP / AMFI / EFI；
- 加载只对**当前会话**有效，重启即回到实验前状态。

若出现异常且无法卸载：长按电源关机，正常启动 macOS（或从备份的 OpenCore 配置启动），确认回到桌面后告诉我。

---

## 7. 我已经知道的、会影响结果的两件事（先说清楚，免得误判）

1. **NVRMFB 本次不会启动**（缺 `nvfb=1`），所以日志里不该出现 display/head 相关行，那是预期的。
2. **NVRM.kext 是上游预编译件**，我们没有它的构建证据（R13：公开源码只能覆盖约 2% 符号）。
   本次实验本质上是在验证"这个二进制在这块 GPU 上能不能起来"，不是在验证我们的补丁。
   我们的 NVAccel/NVRMFB 补丁要等各自能构建出二进制之后才有机会参与。
