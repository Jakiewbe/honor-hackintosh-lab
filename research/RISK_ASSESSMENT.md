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
| R-07 | 下载并执行**未固定版本/哈希**的 iasl | OCS `Scripts/dsdt.py:check_iasl`（DSDT 处理初始化时触发） | 否 | 执行来源未锁定的可执行文件，违反“未经审查不得执行”约束 | 高 | **阻止 `plan`/`build` 运行的主因之一** |
| R-08 | 生成的 OpenCore 配置削弱 macOS 安全：SIP `0x0A43`、`amfi_get_out_of_my_way=0x1`、`amfi=0x80`、`SecureBootModel` 关闭（社区配置可见） | `p1401/nullmoth.py`、`policy.py` | — | macOS 代码签名与系统完整性保护被关闭 | 高 | 只记录，不生成 |
| R-09 | Mac companion 安装非 Apple 签名 kext，修改 OpenCore `config.plist`（BAR、IONDRVSupport 排除等） | 驱动仓库 `nullmoth-setup.sh`（未逐行审） | 是（macOS） | 内核级代码；#119 机制会让本机内屏失去帧缓冲 | 高 | 不适用（无 macOS） |
| R-10 | 将 EFI 写入内置磁盘 ESP、修改 NVRAM 启动项、BIOS 设置（Secure Boot 关闭、VMD 等） | 社区安装流程、1401 BIOS 指引 | 是 | 可导致 Windows 无法启动；BitLocker 可能要求恢复密钥 | **极高** | **禁止** |
| R-11 | NVRAM 残留：1401 故意**不删除** `boot-args`（仅删 `csr-active-config`） | `nullmoth.apply` 注释 | — | 旧 boot-args 会覆盖新配置（1401#26 日志 `boot-args - ignored, exists`），导致排障结论失真 | 中 | 记录 |
| R-12 | `tests/corpus/fetch.py` 下载公开报告语料；`scan --selftest` 下载 acpidump | 上游测试 | 否 | 网络下载并执行 | 中 | **未运行** |

## 2. 主力机自身的风险条件（实测）

- **只有一块磁盘**（Samsung NVMe），Windows、恢复分区、ESP 都在上面；任何磁盘写工具的误判都直接命中系统盘。
- C: 剩余约 10.2 GiB；Secure Boot 开启；BitLocker、WinRE 状态**未知**；没有已验证的 ESP 备份、恢复介质或恢复演练（`hardware.json` → `recovery_readiness = needs_user_confirmation`）。
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
