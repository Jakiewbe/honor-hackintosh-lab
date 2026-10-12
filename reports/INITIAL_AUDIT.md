# INITIAL_AUDIT｜HONOR GLO-FX6P × NullMoth 1401 初始审计报告

**日期**：2026-10-13　**模式**：`READ_ONLY_RESEARCH`　**决策依据**：[D-16](../knowledge/07_DECISIONS.md)
**审计对象**：[`nullmoth/1401@46d9fee`](https://github.com/nullmoth/1401/tree/46d9fee308bbb8e373807d59773823e6a93c1f63)（v1.14.2）、[`nullmoth/nvidia-macos-driver@1083a98`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403)（v1.14.2）

## 结论摘要

1. **本机走 1401 路线得不到有加速的内屏显示**（E 级）。内屏只接 Intel Iris Xe 46A6，Apple 没有 Gen12 核显驱动；RTX 2050 的 PCI 类码是 `0x0302`（3D 控制器），Windows 下没有任何显示源或连接目标，强烈指向 muxless 拓扑（推断）。
2. **1401 把 RTX 2050 标为 “macOS 15 可用”只因为 `25A9` 在 NVIDIA GSP 设备表里**（C 级），1401 的已测设备列表只有 `2D05`；驱动文档对 Ampere 物理验证写 “Pending”。
3. **1401 对本机拓扑同时给出两条相反提示**：`mux_help` 称“内屏在 macOS 中保持黑屏”，`panel_guard.KEEP_NOTE` 称“内屏通过固件显示工作（无加速）”。已用本项目测试在代码层面复现。
4. **装上 NullMoth 驱动后，Intel 内屏很可能失去帧缓冲**：`NVRMFBClaim` 会占用 Intel 核显的 IOFramebuffer 匹配类别（[driver#119](https://github.com/nullmoth/nvidia-macos-driver/issues/119)，与本机同构的 GA107M/0x0302/无 MUX 机型），修复 [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131)、[PR #133](https://github.com/nullmoth/nvidia-macos-driver/pull/133) 在审计时均未合并。
5. **最接近本机的公开案例是 [`nullmoth/1401#26`](https://github.com/nullmoth/1401/issues/26)**（同为 i5-12500H、Iris Xe 接内屏、无 MUX），停在 `EXITBS:START`。旧知识库曾把它误判为“误引”（当时核对的是另一个仓库的 #26），已追加更正。
6. **未能生成候选 EFI**：缺 Hardware-Sniffer 格式的 `Report.json`，且 OpCore-Simplify 会在缺少 iasl 时下载并执行未固定版本的 iasl。

---

## 1. 已完成的项目初始化工作

工作区 `D:\Hactk\honor-hackintosh-lab` 是已有的研究仓库（`main`，审计开始时 `195e465`，工作区干净）。**按要求未覆盖任何既有研究**，只新增文件或在既有文件末尾追加带日期的章节。

| 项 | 路径 | 动作 |
|---|---|---|
| 代理规则 | `AGENTS.md` | 追加“1401 审计研究线”章节（目标、安全边界、证据标准、阶段进度、断点续做流程） |
| 项目说明 | `README.md` | 追加审计摘要与链接 |
| Cursor 规则 | `.cursor/rules/read-only-research.mdc`、`evidence-standard.mdc`（均 alwaysApply）、`upstream-readonly.mdc`（`upstream/**`） | 新建；工作区根另建 `D:\Hactk\.cursor\rules\honor-lab-pointer.mdc` 指向仓库（工作区根 ≠ 仓库根） |
| 上游源码 | `upstream/1401`、`upstream/nvidia-macos-driver`、`upstream/README.md` | 只读部分克隆；`.gitignore` 排除克隆目录，只入库 SHA 说明 |
| 研究文件 | `research/{HARDWARE,SOURCES,COMPATIBILITY,RISK_ASSESSMENT,OPEN_QUESTIONS}.md` | 新建 |
| 报告 | `reports/INITIAL_AUDIT.md` | 本文件 |
| 日志 | `logs/RESEARCH_LOG.md` | 新建，含当前断点 |
| 测试 | `tests/test_1401_static_audit.py` | 新建（11 项断言） |
| 知识库 | `knowledge/02`、`07`（D-16）、`10`、`11`（第 5 节更正） | 追加 |

Cursor 规则格式：`.mdc` + YAML 头（`description`、`globs`、`alwaysApply`），每条保持简短（< 30 行）。

## 2. 当前源码版本与依赖关系

详见 [SOURCES](../research/SOURCES.md)。要点：

- 1401 的发布线（v1.14.2，分支 `support-fixes-1008`，2026-10-11）**领先于 `main`**（`b211981`，2026-10-08）；旧知识库引用的是 `main`。
- 1401 = C# WinForms 前端（`requireAdministrator`）+ 内嵌 Python 3.12 引擎 `p1401` + 固定 commit 的 OpCore-Simplify（`e5d8a9f`）与 Hardware-Sniffer（`6570f91`）副本。
- **Windows 发布包不是完全由源码构建**：以 SHA256 固定的 **1401-Windows-1.0.21.zip 二进制基线**为底，替换新编译的 `1401.exe` 和 `p1401/`，再下载经三重校验的驱动包与 Mac companion。内嵌 Python 运行时等继承自基线，无法用本仓库源码复现。
- 有哈希固定：驱动包（`7c7f7ac9…`）、Mac companion、`acpidump.exe`、OpenCore 1.0.8 测试夹具。**无哈希固定**：OCS 运行时下载的 iasl。OCS 仓库自带 `macserial.exe`（随 commit 固定，会被执行以生成 SMBIOS 序列号）。
- 许可：1401 与驱动均为 PolyForm Noncommercial 1.0.0，NullMoth 名称/标志不在许可内；OCS/Hardware-Sniffer 为 BSD-3-Clause。

## 3. 本地环境检测结果

全部为非管理员只读查询（2026-10-13），不含序列号与 BitLocker 信息。

| 项 | 结果 |
|---|---|
| 权限 | 当前会话**非管理员** |
| 系统 | Windows 11 家庭中文版 10.0.26200，64 位；VBS 运行中；Smart App Control 关闭（策略值 0） |
| 固件 | UEFI（`GetFirmwareType`=2）；Secure Boot 开启（注册表，未交叉验证） |
| 磁盘 | 仅 1 块 NVMe（476.9 GiB，GPT，7 个分区）；**无 U 盘**；C: 剩余 10.17 GiB，D: 剩余 105.5 GiB |
| BitLocker / WinRE | **未知**（需管理员只读命令，未执行） |
| 工具 | Git 2.52.0、Python 3.12.2（pip 24.0、venv 可用）、uv 0.11.8（含 CPython 3.14.4）、PowerShell 5.1、.NET Framework 4.8（release 533509）、Rust（cargo/rustc） |
| 缺失 | .NET SDK（`dotnet`）、Visual Studio/MSBuild、GitHub CLI（`gh`）、PowerShell 7、7-Zip、iasl、ocvalidate、QEMU |
| 网络 | 系统代理关闭（存在未启用的 `127.0.0.1:7897` 配置）；GitHub API 可直连 |

影响：无法本地编译 `1401.exe`（缺 .NET SDK，但本研究也不需要）；缺 iasl/ocvalidate 意味着离线候选 EFI 校验需先获取并哈希核对这两个工具。

## 4. 1401 自动构建 EFI 的技术流程（含 Phase 2 十个问题的回答）

```
1401.exe（管理员）→ 扫描：Hardware-Sniffer + hwcapture/devicemap + acpidump.exe
   → engine.build()：加载 OCS，按 PROMPT_RULES 自动回答约 40 个交互提示
   → OCS 生成 config.plist / ACPI / kext 选择（1401 运行时打补丁修正）
   → nullmoth.mark()/apply()、panel_guard、policy pass（SIP、BAR、日志、已知机型）
   → validate（ocvalidate 等）→ 写 U 盘（rawdisk 擦除 / diskpart 回退）→ 下载 Apple 恢复镜像
   → 启动失败后：读 U 盘日志，可选上传 nullmothsystems.com；Mac companion 安装驱动
```

| # | 问题 | 回答（依据：v1.14.2 路径） |
|---|---|---|
| 1 | 如何识别 CPU/GPU/主板/ACPI？ | Hardware-Sniffer（WMI/SetupAPI）生成 `Report.json`；`p1401/hwcapture.py`、`devicemap.py` 用 ctypes 调 Windows API（含 QueryDisplayConfig 判断内屏归属）；ACPI 表由按 SHA256 固定下载的 `acpidump.exe` 导出（`p1401/scan.py`） |
| 2 | 如何调用 OpCore-Simplify？ | 以库方式加载 OCS，替换其 `request_input`，用 `engine.PROMPT_RULES`（首个匹配规则生效）自动应答；未知提示抛 `UnknownPrompt` 停止；同一提示连续 3 次视为不接受并停止（`p1401/engine.py` 文件头与 `request_input`） |
| 3 | SMBIOS/SSDT/kext/quirk 规则？ | SMBIOS：OCS `smbios.py`（笔记本默认 `MacBookPro16,2`）；SSDT：OCS `acpi_guru.py` + `dsdt.py`（本轮未逐行审）及 1401 `dsdt_pass1.py`；kext：OCS `kext_maestro.select_required_kexts`；quirk：OCS `config_prodigy.py`（约 620–685 行）+ 1401 `policy.py`、`known_machines.json`、`bootfix.py` |
| 4 | 遇到未知硬件？ | OCS `compatibility_checker` 标为不支持 → 禁用（`disable-gpu`）或排除；没有受支持 GPU 时 `engine.STOP_LEADS` 停止，或 `nullmoth.basic_display` 保留一块卡走固件帧缓冲；`_unsupported_igpu_fix` 防止无属性核显导致 KeyError；`panel_guard` 保留驱动内屏的不支持核显 |
| 5 | RTX 2050 是否命中规则？ | **命中**：`25A9` 在 `p1401/nvidia_gsp_ids.json`（235 个 ID），`mark()` 设为仅 macOS 15；不在 `tested`；`mux_help` 会给“内屏黑屏”提示（已用本项目测试验证） |
| 6 | SIP/boot-args/ReBAR 变更？ | SIP `430A0000`（0x0A43）；boot-args 追加 `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0`；NVRAM Delete 只含 `csr-active-config`（故意不删 boot-args）；安装阶段 `ResizeAppleGpuBars=0`、`ResizeGpuBars=-1`；笔记本独显加 `acpi-wake-type=1`；U 盘日志 `Target |= 0x41` |
| 7 | 哪些步骤需要管理员？ | 整个 `1401.exe`（manifest `requireAdministrator`）；原始磁盘访问与分区（`rawdisk`/`diskpart`）；部分扫描（ACPI/固件表） |
| 8 | 磁盘写入/系统修改/上传/删除风险？ | U 盘擦除与分区（R-02）；自更新替换程序目录（R-04）；上传扫描证据与日志（R-03，确认框默认“发送”）；生成的配置削弱 SIP/AMFI（R-08）；Mac companion 安装 kext（R-09）。完整表见 [RISK_ASSESSMENT](../research/RISK_ASSESSMENT.md) |
| 9 | 能否不写盘、不改系统就生成候选 EFI？ | **原则上能**：`python -m p1401 plan <Report.json> <ACPI 目录>` 调用 `engine.build(download=False)`，输出到 `tempfile.mkdtemp("1401-plan-")`。**本轮未执行**，原因：没有 Hardware-Sniffer `Report.json`；OCS `dsdt.py:check_iasl` 会下载执行未固定 iasl；`scan_evidence`/`panel_guard` 需要配套采集数据。**会话 2 更正**：`plan` 只输出决策，**不生成 config.plist**，也不运行 macserial/ocvalidate；要得到候选 EFI 必须走联网的 `build`（同样不写 U 盘），见附录 A |
| 10 | 测试覆盖？ | 约 70 个 Python 单元/回归测试（大量使用 mock 与夹具）、`tests/native/*.c|cs`、公开报告语料回归（`tests/corpus`，需下载）、Rust loader 的 QEMU 测试；CI `windows-candidate.yml` 对打包产物在 Optiplex 5050 夹具上验证。**没有任何真实机型的引导/安装测试** |

## 5. GLO-FX6P 硬件兼容性矩阵

完整矩阵与证据见 [COMPATIBILITY](../research/COMPATIBILITY.md)；硬件事实见 [HARDWARE](../research/HARDWARE.md)。

| 模块 | 等级 | 一句话结论 |
|---|---|---|
| CPU i5-12500H 引导 | D | 1401/OCS 有完整的 Alder Lake 伪装与拓扑补丁；同代机型成功与失败并存 |
| Iris Xe 46A6 加速/原生帧缓冲 | E | Apple 无 Gen12 驱动 |
| Iris Xe 46A6 固件帧缓冲内屏（未装驱动） | D | 1401 源码自相矛盾；Tiger Lake 同类案例未出 GUI |
| 同上（装 NullMoth 驱动后） | E | driver#119 机制；修复未合并 |
| RTX 2050 列入设备表 | C | 表中有、从未实测 |
| RTX 2050 显示输出 | E | 类码 0x0302、无显示源 |
| RTX 2050 无头 Metal | D | 仅 Turing 有单例报告 |
| Wi-Fi AX201 | B | itlwm 支持表内，同系列社区可用 |
| 蓝牙 | C | — |
| 音频 ALC256 / SST 麦克风 | C / E | 通用 layout 存在；SST 麦克风不支持 |
| NVMe PM9A1 | C | 无已知问题记录 |
| 触控板 ELAN2616 | D → **E（原版）/ D（手工补丁）** | 会话 2 已核实原版 VoodooI2C `IOPCIMatch` 不含 `0x51E8` |
| 键盘 / 电池 | C | 通用方案 |
| USB / 摄像头 | D | 需本机映射/实测 |
| 指纹 | E | 不支持 |

## 6. 已确认风险和未解决问题

- 风险（详见 [RISK_ASSESSMENT](../research/RISK_ASSESSMENT.md)）：**本机只有一块磁盘**且恢复能力未验证；1401 的 U 盘写入、管理员权限、默认“发送”的上传确认框、自更新、未固定 iasl、SIP/AMFI 削弱、NVRAM `boot-args` 残留。
- 上游文案冲突：`p1401/__init__.py` 写 “Nothing about your machine leaves it”，但存在上传功能（需用户确认）。
- 未解决问题（详见 [OPEN_QUESTIONS](../research/OPEN_QUESTIONS.md)）：MUX/BIOS 选项、外接口归属、CFG Lock、BitLocker/WinRE、1401 真实生成的配置、ocvalidate 结果、PR #131/#133 状态、Gen12 固件帧缓冲能否出 GUI、未审阅模块、1.0.21 基线内容、同机型案例（检索未找到）。

## 7. 已运行测试、结果及未运行原因

| 测试 | 层级 | 结果 | 说明 |
|---|---|---|---|
| 本项目 `tests/test_1401_static_audit.py`（11 项） | 代码测试 | **11/11 通过** | 用实测硬件事实调用 1401 真实规则函数；含 SHA 固定检查 |
| 1401 上游 8 个测试模块（24 项）：`test_intel_panel_keep`、`test_laptop_display_notes`、`test_laptop_gpu_awake`、`test_unsupported_igpu`、`test_nullmoth_amfipass`、`test_known_machines`、`test_excluded_kexts`、`test_boot_security` | 代码测试 | **24/24 通过**（0.503 s） | 沙箱 `%TEMP%\hk-1401-sandbox-20261013-001159`：源码副本、独立 venv（无第三方包）、HOME/TEMP/APPDATA 重定向、代理指向 `127.0.0.1:9`；产物仅为沙箱 `tmp/` 下的测试 `config.plist` 与空 kext 目录；有 `ResourceWarning`（上游测试未关闭文件，不影响结果） |

未运行及原因：

| 项 | 原因 |
|---|---|
| 其余约 62 个上游测试 | 涉及 subprocess/网络/磁盘或 Windows API（如 `test_system_tools`、`test_downloads`、`test_apple_doh`、`test_rawdisk_lock`、`test_usb_*`），未逐个审查副作用前不运行 |
| `test_kernel_patches` | 实例化 OCS `gatheringFiles`，可能联网 |
| `p1401.nullmoth` / `usbwriter --selftest`、`scan --selftest` | `scan` 自测会下载 acpidump；`usbwriter` 自测会调用 PowerShell 枚举磁盘；未取得批准 |
| `tests/corpus/fetch.py` | 下载公开报告语料 |
| `python -m p1401 plan` / 候选 EFI | 缺 `Report.json`；iasl 未固定下载（R-07） |
| `ocvalidate` | 无候选 config，也未获取 ocvalidate |
| UEFI 引导、macOS 安装、GPU 加速 | 超出 `READ_ONLY_RESEARCH` 范围，且无独立测试硬件 |

## 8. 进入 EFI 构建阶段还需要的资料

1. Hardware-Sniffer 格式的 `Report.json`（需审查并在沙箱运行 Hardware-Sniffer，或在用户批准下运行 1401 扫描且禁止上传）。
2. 与 `Report.json` 同一次采集的 ACPI 表（现有调查的 ACPI 导出可作参考，但 1401 期望自己的格式与绑定）。
3. 经哈希核对的 iasl 与 ocvalidate（固定版本，预先放入沙箱，阻止 OCS 自动下载）。
4. 用户对 BIOS 显示模式/MUX 选项的目视确认（只看不改）。
5. CFG Lock 状态（只能在将来的 U 盘引导环境中只读查看）。
6. BitLocker/WinRE/ESP 状态（管理员只读）和用户自行确认的恢复密钥离线保存情况（本项目不读取）。
7. driver PR #131/#133 的合并状态与包含它们的版本号。

## 9. 是否满足下一阶段前置条件

| 下一阶段 | 前置条件 | 是否满足 |
|---|---|---|
| 沙箱内生成候选 EFI（不写盘） | `Report.json`、固定 iasl、用户批准运行扫描 | **否** |
| `ocvalidate` 配置校验 | 候选 config.plist、固定 ocvalidate | **否** |
| U 盘引导实验 | 用户批准的空白 U 盘、主力机恢复能力验证、BitLocker 状态已知 | **否** |
| macOS 安装 / 驱动安装 | 独立测试硬件或独立磁盘；SIP/AMFI 削弱获批 | **否**（且显示路径评级为 E/D，收益很低） |

**结论：不满足任何写入或引导类阶段的前置条件。** 可继续的只有只读工作（见第 10 节）。

## 10. 下一阶段具体行动建议及回滚要求

建议按顺序（每一步都需要用户的单独批准）：

1. **只读补充（无需管理员）**：继续审阅 Q-12 列出的模块与驱动 `nullmoth-setup.sh`；跟踪 PR #131/#133 与 1401#26；查阅 VoodooI2C 固定版本 `Info.plist`（Q-14）。回滚：无需。
2. **用户目视确认**（Q-01/Q-02）：进入 BIOS 只看显示模式选项；接外接显示器时重跑只读显示探针。回滚：不修改任何设置。
3. **管理员只读查询**（Q-04/Q-05）：`manage-bde -status`、`reagentc /info`、`Confirm-SecureBootUEFI`。不执行任何带 `-protectors`、`/disable`、`/enable` 的命令。回滚：无需（只读）。
4. **沙箱候选 EFI**（Q-06/Q-07）：审查 Hardware-Sniffer 后在断网沙箱运行，产出 `Report.json`；预置固定哈希的 iasl/ocvalidate；运行 `python -m p1401 plan`，再 `ocvalidate`。回滚：删除沙箱目录即可；不得触及 ESP。
5. **任何引导实验之前**必须先完成：ESP 与分区表备份、恢复介质、恢复演练、BitLocker 恢复密钥由用户自行确认离线可用；优先使用独立测试机或独立磁盘。回滚要求：能在不依赖 macOS 的情况下恢复 Windows 启动（Windows 恢复 U 盘 + `bcdboot` 演练过）。

鉴于显示路径评级（加速内屏 E），**建议用户先决定是否值得为“无加速固件帧缓冲 + 不装 NVIDIA 驱动”的结果继续投入**；L1 主线（自研 Intel 46A6 显示）仍是本仓库的长期目标。

---

## 任务完成情况

| Phase / 任务 | 状态 | 说明 |
|---|---|---|
| P1 检查工作区、保留既有研究 | DONE | 已有仓库，未覆盖 |
| P1 目录与文件结构 | DONE | 见第 1 节 |
| P1 Cursor 规则格式核对与规则文件 | DONE | 仓库 3 条 + 工作区根指针 1 条 |
| P1 AGENTS.md（目标/证据/安全/进度/续做） | DONE | 追加章节 |
| P2 获取上游源码并固定 SHA | DONE | 部分克隆，SHA 见 SOURCES |
| P2 维护状态、release↔源码关系、许可 | DONE | 含 1.0.21 基线发现 |
| P2 审阅指定模块 | DONE（会话 2） | 会话 1 为 PARTIAL；会话 2 补审其余模块与驱动 Mac 端脚本（Q-12 DONE，附录 A） |
| P2 十个问题 | DONE | 第 4 节；第 3 问的 SSDT 部分未逐行审 |
| P3 只读环境检测 | DONE（会话 2） | 会话 1 为 PARTIAL；会话 2 经用户批准以 UAC 运行 `scripts/readonly_admin_status.ps1`：BitLocker 未加密、WinRE 启用、Secure Boot 开启（交叉验证）、ESP FAT32 剩 94 MiB。CFG Lock 仍无法在 Windows 只读获取 |
| P4 静态检查与测试审查 | PARTIAL | 8 个上游模块 + 本项目测试已跑；其余未审查不运行 |
| P4 隔离候选 EFI + ocvalidate | DONE（会话 2） | 会话 1 为 BLOCKED。会话 2：沙箱 C1 扫描、C2 plan、C3 build 全部完成，OpenCore 1.0.9 ocvalidate 0 问题（附录 B） |
| P4 缺失硬件报告的只读收集方案 | DONE | OPEN_QUESTIONS + 第 8、10 节 |
| P5 模块兼容性分析与 A–E 分级 | DONE | 无任何一项经本机实测 |
| P5 同代真实案例检索 | DONE | 1401/驱动 Issue 12 条 + PR 2 条；同机型检索无结果 |
| P6 研究文件、报告、日志、断点 | DONE | — |

---

## 附录 A｜会话 2 补充（2026-10-13，仍为 READ_ONLY_RESEARCH）

本节只追加，不改写上文结论；上文中被更正处已就地标注“会话 2”。

**已执行（全部只读或在仓库内写文档）**

| 项 | 结果 |
|---|---|
| 本地提交 | `8869796 docs(1401): read-only audit of 1401 v1.14.2 against GLO-FX6P`（main，未 push） |
| 补审 1401 其余模块、Hardware-Sniffer、OCS iasl/macserial 路径、驱动 Mac 端脚本与 App | 完成；新增风险 R-13～R-18，见 RISK_ASSESSMENT |
| PR #131/#133 状态 | 仍为 open/未合并；v1.14.2 源码中 `NVRMFBClaim` 仍无厂商过滤 |
| VoodooI2C `0x51E8` | 原版 v2.9.1 与 master 均不含，触控板原版评级 E |
| 仓库 MSDM 检查 | 现有证据与所有分支历史均不含 MSDM/SLIC |
| 本项目静态测试 | 扩展到 **13 项，13/13 通过**（新增驱动 SHA 固定检查与 `NVRMFBClaim` 匹配条件检查） |
| 新文件 | `research/NEXT_STEPS_PLAN.md`（BIOS/外接口目视清单、管理员只读查询、沙箱 C1–C3 分步方案与回滚）；`scripts/readonly_admin_status.ps1` |
| 管理员只读查询（用户批准，UAC） | BitLocker C:/D: 完全解密、无保护器；WinRE 启用；Secure Boot = True；ESP FAT32 约 196 MiB、剩 94 MiB；固件启动顺序 Windows Boot Manager 优先 |
| iasl 版本（Q-16） | acpica 20260930 无 Windows 资产 → OCS 自动下载预计失败；候选固定 20260408 `iasl.exe`（SHA256 `739c597b…`），**未下载** |

**关键更正与新事实**

1. `plan` 不生成 config.plist；候选 EFI 只能经联网的 `build` 产出。`build` 会运行 macserial 与 ocvalidate，本身不写 U 盘。
2. ocvalidate 哈希来自运行时 Dortania 数据，非静态固定；本项目若要复现须自行固定 OpenCore 1.0.8 RELEASE（SHA256 `2011e8b7…`，见 SOURCES）。
3. 核显保持开启依赖与 `Report.json` 哈希一致的 `scan-evidence.json`；缺少时很可能被 `disable-gpu`（重现 1401#26 旧行为）。
4. 驱动 release 1.12.0 声称“11 代以后 Intel 内屏机型可无加速显示 + NVIDIA 无头 Metal”，与 #119 的 `NVRMFBClaim` 缺陷互相冲突；评级保持 D，不裁决。
5. OCS 启动时会删除 `%TEMP%\ocs_*`；扫描可能导出 MSDM（产品密钥）；Mac 端卸载会残留两个 LaunchDaemon。

**结论不变**：本机没有 NVIDIA 显示路径（E），内屏只能寄望于 Iris Xe 固件帧缓冲（D，装驱动后 E），整体仍**不满足**进入 EFI 构建或引导实验的前置条件。下一步全部需要用户逐条批准，见 [NEXT_STEPS_PLAN](../research/NEXT_STEPS_PLAN.md)。

## 附录 B｜沙箱 C1 扫描 + C2 离线 plan（2026-10-13）

用户回复“你自己继续收”后执行；非管理员、子进程内全部用户目录重定向到沙箱、代理指向空端口，沙箱外无写入。详见 [docs/1401-plan-run-20261013/SUMMARY.md](../docs/1401-plan-run-20261013/SUMMARY.md)。

| 测试 | 层级 | 结果 |
|---|---|---|
| `python -m p1401.scan` | 真实本机扫描（只读） | 通过；导出的 MSDM 已立即删除并复查 0 残留 |
| `python -m p1401 plan --json` | 1401 决策层（无 config） | `ok=true`：macOS 15、MacBookPro16,2、保留核显、禁用指纹、要求关闭 Secure Boot、24 个 kext |
| iasl 20260408 合并反编译 | 工具 | **失败**（ACPI 重名对象），1401 跳过预补丁反编译继续（Q-17） |
| `build`（C3，只走 GitHub，镜像回退被拦截且未触发） | 生成 EFI | 通过；OpenCore **1.0.9**（非发布固定的 1.0.8）、23 个 kext、9 个通用 SSDT |
| ocvalidate | 配置验证 | **No issues found**（仅结构校验，不代表能启动） |
| 产物静态审阅 | 配置审阅 | 核显无属性、SIP 0x0A43、`SecureBootModel=Disabled`；无 SSDT-PNLF；未启用 `ForceExitBootServices`；加载仅有二进制的 `NullMothLogo.efi`；VoodooI2C 2.9.1 不匹配 `0x51E8` |

实测确认了此前的代码层推断：OCS 原生检查器判定本机“没有受支持的 GPU”；1401 输出同时包含“内屏在 macOS 中黑屏”和“内屏可通过固件显示工作”两条矛盾提示。**结论不变。**

## 附录 C｜上游 v1.14.3 与发布包追溯（2026-10-13）

- 1401 与驱动已发布 v1.14.3。逐文件核对：本机相关的决策模块（`engine`/`panel_guard`/`policy`/GSP 表）与驱动 `NVRMFBClaim` 均未改；PR #131/#133 仍未合并。**本报告所有本机结论适用于 v1.14.3。** 新增风险：启动时自动检查并提示自更新（R-21）。
- 1.0.21 基线 ZIP 已从 GitHub 删除（R-22）。改用 HTTP Range 只读 v1.14.3 发布包的目录与清单：自带 iasl = ACPICA R2024_12_12（哈希一致），`NullMothLogo.efi` 与源码树一致。
- 用 R2024_12_12 iasl 重跑离线 plan：结果与 20260408 完全相同，ACPI 合并反编译失败源于本机表间重名对象（与主线 `research/acpi-static-20261012` 一致），与 iasl 版本无关。
- 本地 `main` 已合并 `origin/main`（PR #2 等 9 个提交），冲突仅三处追加段落，双方原文全部保留。
