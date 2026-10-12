# NEXT_STEPS_PLAN｜下一阶段四项工作的执行方案（2026-10-13）

> 用户已选择“四项都做”。本文件说明每项**怎么做、有什么副作用、需要哪一级批准**。
> 除第 A 项由用户本人操作外，B、C 两项中的每条命令执行前都要再次取得用户对**该条命令**的批准。
> 只读源码审查（第 D 项）已在会话 2 完成，结果见 `logs/RESEARCH_LOG.md`。

## A. 用户目视检查（Q-01 MUX / Q-02 外接口归属）

### A1. BIOS 只看不改

1. 关机后开机，按 `F2` 进入 BIOS（HONOR 常用键；若无效请查说明书）。
2. 逐页查看并拍照，重点找：
   - 显卡模式：如“独显直连 / Discrete / dGPU only / Hybrid / MSHybrid / Optimus”；
   - Secure Boot 状态；
   - VMD / Intel RST；
   - Above 4G Decoding、Resizable BAR；
   - CFG Lock（多数品牌机隐藏，看不到也是有效结果）；
   - 虚拟化（VT-x / VT-d）。
3. 离开时选 **“不保存退出 / Discard Changes and Exit”**。不要按 `F10`（通常是“保存并退出”）。
4. 若 HONOR 电脑管家里有“独显直连”一类开关，只截图记录，不切换。

**预期**：RTX 2050 类码为 `0x0302`，大概率**没有**独显直连选项；若有，会根本改变显示路径评级（见 COMPATIBILITY 第 2.2 节）。

### A2. 外接口归属（需要一台外接显示器）

1. 分别只用 HDMI、只用 USB-C（DP Alt Mode）接上显示器，各做一次。
2. 每次运行既有只读采集脚本，输出到 `%TEMP%`，**不写入仓库**：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs\hardware-survey-20261012\collect.ps1 -OutDir "$env:TEMP\hk-survey-hdmi"
```

3. 看 `evidence\P13_*`（活动显示路径）中外接显示器属于 Intel `46A6` 还是 NVIDIA `25A9`。
   - `collect.ps1` 已审查：只调用查询 API，跳过 MSDM 与 BitLocker 密钥，输出经脱敏，只写 `-OutDir`。
   - 它也会导出 ACPI 表，与第一次调查重复，可忽略。

**预期**：Intel 驱动已暴露全部 HDMI/DP 目标、NVIDIA 为 0，外接口大概率全部接在 Intel 上。

## B. 管理员只读查询（Q-04 / Q-05）

脚本：[`scripts/readonly_admin_status.ps1`](../scripts/readonly_admin_status.ps1)。**2026-10-13 已完成**：用户批准后以 UAC 运行一次，退出码 0；结论已写入 HARDWARE（BitLocker 未加密、WinRE 启用、ESP FAT32 剩 94 MiB、Secure Boot 交叉验证为开启）。原始输出 `%TEMP%\hk-admin-status-20261013.txt` 不入库。

| 步骤 | 命令 | 读取什么 | 风险 |
|---|---|---|---|
| 1 | `Confirm-SecureBootUEFI` | Secure Boot 开关 | 无（只读） |
| 2 | `manage-bde -status` | 各卷加密/保护状态、保护器**类型** | 不显示恢复密钥；**刻意不用** `Get-BitLockerVolume`（其对象可能含恢复密码） |
| 3 | `reagentc /info` | WinRE 是否启用及位置 | 无 |
| 4 | `Get-Partition` + `Get-Volume`（ESP） | ESP 文件系统、大小、剩余空间 | 不挂载、不分配盘符 |
| 5 | `bcdedit /enum firmware` | 固件启动项列表，作为回滚基线 | 只读；输出含启动项 GUID 与描述，不含个人信息 |

执行方式：用户在“以管理员身份运行”的 PowerShell 中执行，再把输出贴回；或批准我用 `Start-Process -Verb RunAs` 触发 UAC 弹窗后运行。结果只写进 `research/HARDWARE.md` 的结论字段，原始输出不入库。

## C. 沙箱生成候选 EFI（Q-06 / Q-07）

源码审查结论（会话 2）改变了原计划：

- **`python -m p1401 plan` 不生成 `config.plist`**。它只输出决策文本（macOS 版本、SMBIOS、kext 列表、禁用设备、提示），不运行 ocvalidate。
- 生成 EFI 必须走 `build`（`download=True`），会联网下载 OpenCore、kext（哈希来自运行时的 Dortania `latest.json`，不是静态固定），并执行 `macserial.exe` 与 `ocvalidate.exe`。**`build` 本身不写 U 盘**，写盘是 1401 GUI 的另一步。
- `plan` 和 `build` 都需要：Hardware-Sniffer 格式的 `Report.json` + ACPI 目录（恰好一个 DSDT）；`scan-evidence.json` 可选，但必须与 `Report.json` 同一次扫描、逐字节未改，**否则核显 46A6 很可能被设为 `disable-gpu`**（即 1401#26 的旧行为）。

分三步，每步单独批准。**状态（2026-10-13）**：C1、C2、C3 均已在沙箱完成（C1/C2 非管理员、离线、MSDM 已删除；C3 只走 GitHub、镜像回退被拦截且未触发），ocvalidate 0 问题。结果见 [docs/1401-plan-run-20261013](../docs/1401-plan-run-20261013/SUMMARY.md)。**本节已无待办**；下一层（U 盘引导）超出 `READ_ONLY_RESEARCH`。

### C1. 产生扫描输入（副作用最大的一步）

用 `python -m p1401.scan <沙箱目录>` 运行（不直接运行 Hardware-Sniffer 原版，因为原版会下载未校验的 acpidump）。已审查到的副作用：

| 副作用 | 说明 |
|---|---|
| 执行 `acpidump.exe` | 有 SHA256 固定（`9f54227f…`）；缺失时从 GitHub 或 `nullmothsystems.com` 镜像下载到 `~\.cache\1401` |
| 管理员权限 | 1401 文档称 acpidump 需要管理员（Windows 版是否必须，源码中不确定） |
| 进程内执行 RWX 机器码 | Hardware-Sniffer `cpuid.py` 用 `VirtualAlloc` 执行 CPUID 指令片段，可能触发杀毒软件 |
| 加载 NVIDIA DLL | `nvml.dll`、`nvcuda.dll`（先做 Authenticode 校验） |
| PowerShell CIM 查询 | 只读，白名单过滤 |
| **MSDM 产品密钥** | 1401 会用 `GetSystemFirmwareTable` 补齐 acpidump 漏掉的表，**可能导出 MSDM**。必须在扫描后立即删除沙箱中的 MSDM 文件，且永不入库、不上传 |
| 不上传 | `scan` 模块本身没有上传代码（上传只在 GUI `MainForm.cs`） |

### C2. 离线 `plan`（低风险）

前提：预置 `upstream/OpCore-Simplify/Scripts/iasl.exe`（在沙箱副本中）。2026-10-13 核对 acpica 官方 release：1401 注释中的 20260930 **没有 Windows 资产**，候选为 **20260408 `iasl.exe`**（SHA256 `739c597bcee4563f18d13e73b2051bb661707713e6154cf5712a1b7eef4a5df9`，见 Q-16）。下载后先比对哈希与 Authenticode 签名信息，不一致即中止。不预置时 OCS 的自动下载按当前 release 情况预计会失败（R-07）。环境：

```powershell
$sb = "$env:TEMP\hk-1401-plan-<时间戳>"   # 沙箱根：src\（1401 副本）、venv\、tmp\、localappdata\、home\
foreach ($v in 'TEMP', 'TMP', 'TMPDIR') { Set-Item "Env:$v" "$sb\tmp" }
$env:LOCALAPPDATA = "$sb\localappdata"; $env:USERPROFILE = "$sb\home"
$env:HTTP_PROXY = 'http://127.0.0.1:9'; $env:HTTPS_PROXY = 'http://127.0.0.1:9'   # 兜底断网
Set-Location "$sb\src"
& "$sb\venv\Scripts\python.exe" -B -m p1401 plan "<scan 目录>\Report.json" "<scan 目录>\ACPI" --json
```

已知副作用：OCS 的 `clean_temporary_dir()` 会**删除 `%TEMP%\ocs_*`**（因此必须重定向 TEMP）；创建 `%LOCALAPPDATA%\NullMoth\1401\OCK_Files`（重定向后落在沙箱）；以子进程执行 iasl 反汇编 ACPI 副本。

### C3. 沙箱 `build` + ocvalidate（需联网）

会下载 OpenCore DEBUG 包与 kext（GitHub/Dortania），执行 `macserial.exe -g --model MacBookPro16,2`（生成随机序列号）与 `ocvalidate.exe`。输出完整 `EFI/` 到沙箱。**不写 U 盘、不碰 ESP**。产出只用于静态审阅与 ocvalidate，**不等于能启动**。

补充核对（2026-10-13）：OCS 下载主机为 `github.com`、`raw.githubusercontent.com`（含 Dortania 数据）；GitHub 失败时 1401 `downloads.py`/`validate.py` 回退到 `nullmothsystems.com/mirror/<sha256>`（只发 GET，按哈希取文件，不携带硬件信息）。build 路径无上传代码。若要完全避免第三方镜像，可在运行时让 GitHub 可达，并在日志中检查有无 `mirror` 字样。执行的二进制：OpenCorePkg 包内的 `macserial.exe`、`ocvalidate.exe`（来自下载包，哈希由运行时 Dortania 数据校验）。

## D. 只读源码审查（已完成，会话 2）

结论已并入 `COMPATIBILITY.md`、`RISK_ASSESSMENT.md`、`SOURCES.md`、`OPEN_QUESTIONS.md`。

## 回滚要求

- A：BIOS 不保存退出；采集输出在 `%TEMP%`，删除目录即可。
- B：纯只读，无需回滚。
- C：删除整个沙箱目录；确认 `%TEMP%\ocs_*` 与 `%LOCALAPPDATA%\NullMoth` 未在沙箱外出现；MSDM 文件删除后再做任何归档。
