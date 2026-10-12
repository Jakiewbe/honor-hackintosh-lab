# RISK_ASSESSMENT｜1401 / NullMoth 路线对主力机的风险

> 当前模式：**`READ_ONLY_RESEARCH`**。下表每一项都需要用户**单独、明确**批准后才可执行；
> “1401 默认会这样做”不构成授权。依据为 v1.14.2 源码阅读（路径见 [SOURCES](SOURCES.md)）。

## 1. 风险清单

| ID | 动作 | 触发位置（v1.14.2） | 需要管理员 | 影响 | 严重度 | 本轮处理 |
|---|---|---|---|---|---|---|
| R-01 | 以管理员身份运行 `1401.exe` | `windows/App/app.manifest` `requireAdministrator` | 是 | 进程获得全部系统权限 | 高 | **未运行** |
| R-02 | 擦除并重新分区 U 盘（raw 写入 / diskpart 回退） | `p1401/usbwriter.py`、`rawdisk.py`、`windows/App/Disks.cs` | 是 | 选错盘即毁数据；本机只有一块 NVMe，筛选逻辑是唯一保护 | **极高** | **未运行**；`usbwriter` 文档串仍写“NOT TESTED ON WINDOWS YET”（可能过时） |
| R-03 | 上传扫描证据与日志到 `https://nullmothsystems.com/api/upload` | `MainForm.cs`（约 520–650 行） | 否 | 硬件指纹、ACPI、日志离开本机；会去除用户名/计算机名，但确认框**默认按钮为“发送”（Enter 即发送）** | 高（隐私） | **未运行**；`p1401/__init__.py` 声称“Nothing about your machine leaves it”，与上传功能并存，属文案冲突 |
| R-04 | 程序自更新：下载新版并用 `swap.cmd` 替换自身目录 | `MainForm.cs`（约 160–200 行）、`nullmoth.app_update` | 视目录 | 执行新下载的二进制（有 SHA256SUMS 校验） | 中 | **未运行** |
| R-05 | 运行 Hardware-Sniffer / `hwcapture` / `acpidump.exe` 扫描 | `p1401/scan.py` | 部分 | 读取硬件与 ACPI；`acpidump.exe` 按 SHA256 固定下载并执行 | 中 | **未运行**；本项目已有独立只读调查结果替代 |
| R-06 | 从 Apple 下载恢复镜像 | `p1401/apple.py` | 否 | 大流量下载；校验细节未审 | 低 | **未运行** |
| R-07 | 下载并执行**未固定版本/哈希**的 iasl | OCS `Scripts/dsdt.py:check_iasl`（DSDT 处理初始化时触发） | 否 | 执行来源未锁定的可执行文件，违反“未经审查不得执行”约束 | 高 | **阻止 `plan`/`build` 运行的主因之一**。2026-10-13 补充：OCS 抓取 acpica 最新 release 找 `iasl*.zip`，而最新的 20260930 只发布 Unix 资产（API 核对，未直接验证 OCS 的 HTML 抓取），故当前在 Windows 上自动下载**预计会失败**并报 “Could not locate or download iasl!”；预置固定哈希的 `iasl.exe` 是唯一可行做法（Q-16） |
| R-08 | 生成的 OpenCore 配置削弱 macOS 安全：SIP `0x0A43`、`amfi_get_out_of_my_way=0x1`、`amfi=0x80`、`SecureBootModel` 关闭（社区配置可见） | `p1401/nullmoth.py`、`policy.py` | — | macOS 代码签名与系统完整性保护被关闭 | 高 | 只记录，不生成 |
| R-09 | Mac companion 安装非 Apple 签名 kext，修改 OpenCore `config.plist`（BAR、IONDRVSupport 排除等） | 驱动仓库 `nullmoth-setup.sh`（未逐行审） | 是（macOS） | 内核级代码；#119 机制会让本机内屏失去帧缓冲 | 高 | 不适用（无 macOS） |
| R-10 | 将 EFI 写入内置磁盘 ESP、修改 NVRAM 启动项、BIOS 设置（Secure Boot 关闭、VMD 等） | 社区安装流程、1401 BIOS 指引 | 是 | 可导致 Windows 无法启动；BitLocker 可能要求恢复密钥 | **极高** | **禁止** |
| R-11 | NVRAM 残留：1401 故意**不删除** `boot-args`（仅删 `csr-active-config`） | `nullmoth.apply` 注释 | — | 旧 boot-args 会覆盖新配置（1401#26 日志 `boot-args - ignored, exists`），导致排障结论失真 | 中 | 记录 |
| R-12 | `tests/corpus/fetch.py` 下载公开报告语料；`scan --selftest` 下载 acpidump；`apple --selftest` 向 Apple 恢复服务器发 POST 并下载约 10 MB | 上游测试 | 否 | 网络下载并执行 | 中 | **未运行** |
| R-13 | OCS 构造时 `utils.clean_temporary_dir()` **删除 `%TEMP%\ocs_*` 下所有目录**；多个 `ocs_*`、`1401-plan-*` 临时目录遗留 | OCS `Scripts/utils.py:17-29`、`OpCore-Simplify.py:24`；`p1401/__main__.py:43-44` | 否 | 沙箱外文件被删除/遗留 | 中 | 记录；运行时必须重定向 TEMP/TMP/TMPDIR |
| R-14 | 扫描导出 ACPI 时**可能包含 MSDM（Windows OEM 产品密钥）**：1401 用 `GetSystemFirmwareTable` 补齐 acpidump 漏掉的表 | `p1401/scan.py:104-146` | 部分 | 产品密钥落盘，若随报告上传则泄露 | 高（隐私） | 本仓库已核对：现有证据**不含** MSDM（2026-10-12 调查主动跳过），所有分支历史也无 MSDM/SLIC 文件。**2026-10-13 沙箱扫描实测确实导出了 `msdm.aml`（85 字节）**，已立即删除并复查 0 残留；以后任何 1401 扫描都必须带这一步 |
| R-15 | Hardware-Sniffer 在进程内用 `VirtualAlloc` 分配 RWX 内存执行 CPUID 机器码 | `Hardware-Sniffer/.../cpuid.py:110-117` | 否 | 可能触发杀毒/漏洞防护拦截 | 低 | 记录 |
| R-16 | Mac 端 setup 把 `SecureBootModel` 改为 `Disabled`、SIP OR `0x0A43`、写 `nvram boot-args`；卸载后 `com.nullmoth.wsreset`（每次开机在登录窗口杀一次 WindowServer）与 `com.nullmoth.displaytrace` 两个 LaunchDaemon **不会被删除** | 驱动 `app/Resources/nullmoth-setup.sh:987-991, 1359-1369, 1433-1445, 430-545` | 是（macOS） | 卸载不彻底 | 中 | 不适用（无 macOS） |
| R-17 | 驱动 Mac App 的“更新”走 GitHub `releases/latest`，版本不固定（有 SHA256SUMS 校验） | 驱动 `app/Sources/main.swift:528-549` | — | 自动获取未审阅的新版本 | 中 | 记录 |
| R-19 | 生成的 EFI 在引导期加载 1401 仓库中**只有二进制**的 `NullMothLogo.efi`（默认开启） | `p1401/policy.py:359-372`，提交 `d94f056` | 是（引导期） | 未审源码的 UEFI 代码在固件环境执行 | 中 | 记录（Q-19）。2026-10-13 读源码（驱动仓库 `app/efi-logo/src/main.rs`，95 行）：替换 GOP `Blt` 函数指针绘制 logo，并**每次启动向固件 NVRAM 写非易失变量 `nm-logo`**（GUID `4e4d4f54-484c-4f47-8000-6e6d6c6f676f`，值 `armed`/`replaced`/`off (-nmlogooff)` 等）。`-nmlogooff` 仍会写入；**只有从 `UEFI.Drivers` 移除才不写 NVRAM** |
| R-20 | build 实际下载的 OpenCore 版本（1.0.9）与发布固定值（1.0.8）不同 | 2026-10-13 C3 实测 | 否 | 同一 1401 版本在不同日期产出不同 EFI，复现性差 | 中 | 记录；如需复现必须保存整份 EFI 与 kext 版本清单 |
| R-21 | v1.14.3 起 1401 **启动即查询 GitHub 新版本并提示一键自更新**（在构建/写盘之前） | 1401 v1.14.3 `nullmoth.py:_cli_appcheck`、`MainForm.cs` | 是 | 运行时版本可能偏离本项目审计的固定版本 | 中 | 记录；若将来运行 GUI，应断网或拒绝更新，并重新审计新版本 |
| R-22 | Windows 发布包的二进制基线（1.0.21 ZIP）已从 GitHub 删除 | 2026-10-13 API 与下载 404 | 否 | 发布包中继承自基线的文件无法再从公开源复现 | 中 | 记录；只能依赖发布包内 `BUILD-MANIFEST.json` 的哈希 |
| R-18 | 实验性 NMXGPU（i915）若启用，会重置驱动内屏的 Intel 显示引擎 | 驱动 `gpu-port/README.md:61-62`、`nullmoth-setup.sh:726-858` | 是（macOS） | 内屏黑屏 | 高 | 记录 |

## 2. 主力机自身的风险条件（实测）

- **只有一块磁盘**（Samsung NVMe），Windows、恢复分区、ESP 都在上面；任何磁盘写工具的误判都直接命中系统盘。
- C: 剩余约 10.2 GiB；Secure Boot 开启（两来源一致）；BitLocker **未加密**（2026-10-13 实测，因此误改引导不会触发恢复密钥，但也意味着磁盘数据无加密保护）；WinRE 已启用；ESP 仅约 94 MiB 剩余；没有已验证的 ESP 备份、恢复介质或恢复演练（`hardware.json` → `recovery_readiness = needs_user_confirmation`）。
- 结论：在恢复能力被证明前，**任何引导/磁盘/固件层面的操作都不具备回退保证**。

## 3. 本轮实际执行过的操作及其副作用

| 操作 | 副作用 |
|---|---|
| `git clone --filter=blob:none` 两个上游仓库到 `upstream/`，切换 1401 到 v1.14.2 | 仅写入项目目录 |
| GitHub REST API 只读 GET（Issue/PR 正文与评论）、下载 1401#26 公开 OpenCore 日志文本、抓取 Dortania 网页 | 网络读取；文件写入 `%TEMP%` |
| 只读 PowerShell 查询（版本、注册表、`Get-Disk/Get-Partition/Get-Volume`，不含序列号） | 无 |
| 1401 选定的 8 个单元测试模块，在 `%TEMP%\hk-1401-sandbox-20261013-001159` 中运行（源码副本、独立 venv、HOME/TEMP/APPDATA 重定向、代理指向不可达地址） | 仅沙箱 `tmp/` 下生成测试用 `config.plist` 与空 kext 目录 |
| 本项目 `tests/test_1401_static_audit.py` | 无写入（`git rev-parse` 只读） |

## 4. 若将来要推进，最低安全前提（建议，非授权）

1. 独立的非主力测试机或独立整块磁盘；主力机 ESP/分区表备份与恢复演练完成。
2. BitLocker 恢复密钥由用户自行确认已离线保存（本项目不读取、不导出）。
3. 用 U 盘引导而不写内置 ESP；首次启动前在隔离环境运行 `ocvalidate`。
4. 1401 只在断网或审查后的离线模式下运行；上传功能必须确认不会触发。
5. 所有删除 SIP/AMFI 保护的设置只在专用测试系统中使用。
