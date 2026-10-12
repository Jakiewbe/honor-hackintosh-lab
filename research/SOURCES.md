# SOURCES｜上游来源、固定版本与源码↔二进制关系

> 审计时点：2026-10-13。所有克隆为只读的 `git clone --filter=blob:none`，位于 `upstream/`（已在 `.gitignore` 中排除，
> 本仓库只记录 SHA，不重新分发上游代码）。重建方法见 [`upstream/README.md`](../upstream/README.md)。
> GitHub CLI 未安装，元数据通过 GitHub REST API 只读 GET 获取。

## 1. 固定版本

| 项目 | URL | 审计对象 | Commit SHA | 日期 | 说明 |
|---|---|---|---|---|---|
| NullMoth 1401 | <https://github.com/nullmoth/1401> | tag **v1.14.2**（分支 `support-fixes-1008`） | `46d9fee308bbb8e373807d59773823e6a93c1f63` | 2026-10-11 | 本次审计的主对象；`upstream/1401` 已切到此 tag（detached） |
| NullMoth 1401 | 同上 | `main` | `b211981a5b464bfc7c0677f0c6f8ba27d01798d7` | 2026-10-08 | **main 落后于发布线**；旧知识库 [11](../knowledge/11_EARLY_RESEARCH_AND_1401.md) 引用的是此 SHA |
| NullMoth NVIDIA 驱动 | <https://github.com/nullmoth/nvidia-macos-driver> | tag **v1.14.2** = `main` | `1083a98db33a0bb824290556de255f9a95ca5403` | 2026-10-11 | 驱动包 `nullmoth-nvidia-1.14.2.tar.gz`，SHA256 `7c7f7ac9…6dea6be5`（由 1401 `nullmoth.PACKAGE` 固定） |
| OpCore-Simplify | <https://github.com/lzhoang2801/OpCore-Simplify> | 1401 内置副本（`upstream/OpCore-Simplify`） | `e5d8a9f551b1e2a96e2f968696b460b65a7dad2e` | 2026-08-27 | 由 1401 `upstream/PINNED.json` 固定，BSD-3-Clause；**1401 在运行时对其打猴子补丁** |
| Hardware-Sniffer | <https://github.com/lzhoang2801/Hardware-Sniffer> | 1401 内置副本 | `6570f91c33c63f5bf481db31789f903b0d12099f` | 2026-08-16 | 同上，BSD-3-Clause |
| OpenCorePkg | <https://github.com/acidanthera/OpenCorePkg> | 1401 发布流程固定的 1.0.8 RELEASE | ZIP SHA256 `2011e8b7…0be6d27b` | — | 来自 `windows/release-inputs.json`；本次未下载 |
| Dortania 指南 | <https://dortania.github.io/OpenCore-Install-Guide/macos-limits.html> | 网页（最后更新 2026-03-15） | — | — | 只读抓取；笔记本 CPU 官方覆盖 Arrandale～Ice Lake |

维护状态：1401 和驱动仓库在 2026-10-08～10-12 期间每日多次提交、Issue 非常活跃（见 [COMPATIBILITY](COMPATIBILITY.md) 第 3 节），**属于快速迭代的实验项目**，结论有效期很短，复核时必须先对比 SHA。

## 2. 语言、构建工具与依赖（1401 v1.14.2）

| 组件 | 语言 / 工具 | 来源 |
|---|---|---|
| Windows 前端 `1401.exe` | C# WinForms，.NET Framework 4.8 目标，CI 用 .NET SDK 8.0.425 构建；`app.manifest` 要求 `requireAdministrator` | `windows/App/*`、`.github/workflows/windows-candidate.yml` |
| 引擎 `p1401` | Python 3.12（发布包内嵌运行时）；运行时依赖 pywin32 312、WMI 1.5.1、certifi 2026.7.22 | `windows/release-inputs.json` |
| 扫描 | Hardware-Sniffer（Python）+ 1401 `hwcapture`/`devicemap`（ctypes 调 Windows API）+ `acpidump.exe`（按 SHA256 `9f54227f…64a07fd4` 固定下载） | `p1401/scan.py` |
| 配置生成 | OpCore-Simplify（headless，1401 以“提示规则自动应答”驱动交互流程） | `p1401/engine.py` |
| ACPI 编译 | **iasl**：OpCore-Simplify `Scripts/dsdt.py:check_iasl` 在缺失时从 acpica GitHub 最新 release 下载并执行，**未固定版本或哈希** | `upstream/OpCore-Simplify/Scripts/dsdt.py` |
| 本地 CPU 辅助程序 | C（MSVC 编译） | `tools/build_cpu_helper.py` |
| UEFI loader | Rust（`loader/`），仅 QEMU 测试，发布流程未使用 | `loader/`、`tests/loader_qemu.py` |

## 3. 源码 ↔ 二进制 ↔ 第三方关系

1. **Windows 发布包并非完全由源码构建**。`tools/windows_release.py prepare` 的步骤：
   下载并校验 **1401-Windows-1.0.21.zip 二进制基线**（SHA256 `2b42a8be…44e5a37`）→ 解压 → 替换为新编译的 `1401.exe` → 用仓库中的 `p1401/` 覆盖 → 复制 `upstream/` 已跟踪文件 → 从驱动 release 下载并三重核对（源码固定值、release digest、SHA256SUMS）驱动包与 Mac companion。
   因此：内嵌 Python 运行时、基线中的其他二进制工具**继承自 1.0.21 基线 ZIP**，本仓库源码无法独立复现它们。
2. `1401.exe` 带自更新：`MainForm.cs` 通过 `swap.cmd` 替换自身程序目录（v1.14.2，约第 160–200 行）。
3. 驱动包、Mac companion 有 SHA256 固定；**iasl 没有**；Apple 恢复镜像由 `apple.py` 从 Apple 服务器下载（未审计其校验细节，见 OPEN_QUESTIONS）。
4. Mac 端驱动：NVIDIA open-gpu-kernel-modules r610.57.04（GSP 架构，Turing 及以后）移植到 XNU；kext 非 Apple 签名，需要放宽 SIP/AMFI。

## 4. 许可证与使用限制

| 项目 | 许可 | 对本研究的影响 |
|---|---|---|
| 1401 | **PolyForm Noncommercial 1.0.0** + `NOTICE.md` | 仅非商业使用；NullMoth 名称与标志**不在许可内**，修改版必须去掉 NullMoth 名称/标志。本仓库不复制其代码，只引用路径与 SHA |
| nvidia-macos-driver | PolyForm Noncommercial 1.0.0（含 NVIDIA 开源部分的原有许可） | 同上；不得分发其二进制 |
| OpCore-Simplify / Hardware-Sniffer | BSD-3-Clause | 可引用 |
| OpenCorePkg | BSD-3-Clause | — |

## 5. 审阅过的路径（v1.14.2）与不存在的路径

已审阅：`README.md`、`docs/HOW-IT-WORKS.md`、`NOTICE.md`、`LICENSE`、`upstream/PINNED.json`、`windows/release-inputs.json`、
`.github/workflows/windows-candidate.yml`、`tools/windows_release.py`（prepare 段）、`p1401/{__init__,__main__,engine,nullmoth,policy,panel_guard,validate,scan,usbwriter,rawdisk,tls}.py`、
`p1401/{nvidia_gsp_ids,known_machines}.json`、`windows/App/{Program,Engine,Disks,MainForm}.cs`、`windows/App/app.manifest`、
OpCore-Simplify `Scripts/{dsdt,config_prodigy,kext_maestro,smbios,compatibility_checker}.py`、`Scripts/datasets/cpu_data.py`、
驱动仓库 `README.md`、`docs/CARD-SUPPORT.md`、`LICENSE`、`docs/RELEASE-1.14.0.md`（片段）。

用户任务书提到的模块与实际路径对照：

| 任务书写法 | 实际情况 |
|---|---|
| `engine` / `policy` / `validate` / `nullmoth` / `scan` / `usbwriter` / `rawdisk` | 均位于 `p1401/` 下 |
| `apple` | `p1401/apple.py` 存在，**本轮未逐行审阅**（恢复镜像下载） |
| `windows/` | 存在（`windows/App/` C# 源码 + `release-inputs.json`） |
| `upstream/` | 存在，只含 OpCore-Simplify、Hardware-Sniffer 副本与 `PINNED.json` |
| `tests/` | 存在，约 70 个 `test_*.py` + `tests/native/*.c|cs` + `tests/corpus/fetch.py`（会下载公开报告） |

会话 1 时未审阅（列入 OPEN_QUESTIONS）：`selftest.py`、`apple.py`、`report.py`、`probe_report.py`、`hwcapture.py`、`machine_handoff.py`、`dsdt_pass1.py`、`efidoctor.py`、`bootfix.py`（仅测试覆盖）、`mirror.py`、`downloads.py`，以及驱动仓库的 Mac 端安装脚本 `nullmoth-setup.sh`。

**会话 2（2026-10-13）补审**（只读，结果并入 RISK_ASSESSMENT R-12～R-18 与 NEXT_STEPS_PLAN）：
- 1401 `p1401/` 其余全部模块（含 `fwres`、`cpunative`、`peripheral_caps`、`job_guard`、`scan_evidence`、`archive_download`、`dependency_cache`、`kernel_patches`、`acpi_diagnostics`、`acpi_dupnames`、`guide`、`loc`）。结论：除 GUI 上传与 U 盘写入外，没有模块调用 `SetFirmwareEnvironmentVariable`、原始磁盘句柄、`DeviceIoControl`、注册表写入、`bcdedit`/`diskpart`/`mountvol`/`manage-bde`。
- Hardware-Sniffer（`6570f91`）入口、采集方式与输出格式；OCS `dsdt.py`/`acpi_guru.py`/`smbios.py`/`gathering_files.py` 的 iasl、macserial、下载路径；1401 `validate.py` 的 ocvalidate 获取方式。
- 驱动仓库 `app/Resources/nullmoth-{setup,install,uninstall}.sh`、`app/Sources/*.swift`、`kexts/NVRMFB/fb/Info.plist`、`kexts/NVRM/Info.plist`、`kexts/NVRM/accel/nvrm-accel.cpp`、`docs/RELEASE-1.11.0～1.14.2.md`、`docs/TROUBLESHOOTING.md`、`gpu-port/README.md`。
- 外部：[VoodooI2C v2.9.1 `e3ac3ed`](https://github.com/VoodooI2C/VoodooI2C/tree/e3ac3ed207170c39db88d6a67a76cc9fd3a1895a) 与 master `5c0c99c` 的 `Info.plist`（只读获取）。

关键更正：`plan` 路径**不生成 config.plist、不运行 ocvalidate/macserial**；生成 EFI 只能走联网的 `build`。ocvalidate 的哈希来自运行时 Dortania `latest.json`（经 OCK 缓存的 `history.json`），**不是静态固定**；`release-inputs.json` 中 OpenCore 1.0.8 的哈希仅用于发布流程。

## 6. 社区证据来源（只读获取）

GitHub Issue/PR 原文缓存于 `%TEMP%\hk_issues.json`（未入库）；`nullmoth/1401#26` 附带的 OpenCore 日志缓存于
`%TEMP%\hk_1401_issue26_opencore.txt`，SHA256 `E70C38D0735FE9D234C422B0241C796F9FB3844EF05F95254C79AC2F47CBB31C`，262144 字节。
引用清单见 [COMPATIBILITY](COMPATIBILITY.md) 第 3 节。
