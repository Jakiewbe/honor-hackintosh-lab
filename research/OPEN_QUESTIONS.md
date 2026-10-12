# OPEN_QUESTIONS｜未解决问题与只读收集计划

> 每项标明：为什么重要、如何在**不改系统**的前提下获取、是否需要用户操作或管理员审批。
> 状态：`OPEN` 未开始；`NEEDS_USER` 需用户目视或操作；`NEEDS_ADMIN` 需管理员只读命令，必须单独审批；`BLOCKED` 被安全约束阻止。

| ID | 问题 | 为什么重要 | 只读获取方式 | 状态 |
|---|---|---|---|---|
| Q-01 | BIOS 是否有“独显直连 / dGPU only / MUX”选项？ | 决定是否存在让 RTX 2050 驱动内屏的任何可能；类码 `0x0302` 强烈暗示没有 | 用户开机进入 BIOS **只看不改**并拍照；或查 HONOR 官方说明书 | NEEDS_USER |
| Q-02 | HDMI 与 USB-C（DP Alt Mode）物理接在哪块 GPU？ | 若有接口接 NVIDIA，可在无 MUX 时使用外接屏 | 接外接显示器后重跑本项目 `docs/hardware-survey-20261012/collect.ps1` 中显示相关探针（只读），看活动路径属于哪块适配器；步骤见 [NEXT_STEPS_PLAN](NEXT_STEPS_PLAN.md) A2 | NEEDS_USER |
| Q-03 | CFG Lock 是否锁定？ | 决定是否需要 `AppleXcpmCfgLock` 等补丁 | Windows 下无受支持只读接口；可在将来 U 盘引导的 OpenCore `ControlMsrE2.efi` 中**只读查看**（属于引导操作，需审批） | BLOCKED |
| Q-04 | BitLocker 加密/保护状态、WinRE 状态、ESP 文件系统 | 决定任何引导实验的回退能力 | 管理员只读：`manage-bde -status`、`reagentc /info`（**不执行 `-protectors -get`，不读取恢复密钥**）；脚本 [`scripts/readonly_admin_status.ps1`](../scripts/readonly_admin_status.ps1) 经用户批准以 UAC 运行（2026-10-13）：BitLocker C:/D: 未加密、WinRE 启用、ESP FAT32 约 196 MiB（剩 94 MiB），见 HARDWARE | DONE |
| Q-05 | Secure Boot 交叉验证 | 当前只有注册表单一来源 | 管理员 `Confirm-SecureBootUEFI` = `True`，与注册表一致 | DONE |
| Q-06 | 1401 对本机真实会生成什么配置？ | 现有结论来自源码推断 | 会话 2 更正：`plan` 只输出决策、**不生成 config.plist**；需 `p1401.scan` 产出 `Report.json` + ACPI + `scan-evidence.json`，并预置固定哈希的 iasl。方案见 [NEXT_STEPS_PLAN](NEXT_STEPS_PLAN.md) C1/C2 | BLOCKED（等待批准 C1） |
| Q-07 | 生成的候选 config.plist 能否通过 `ocvalidate`？ | 仅是配置结构验证，不代表能启动 | 只能经联网的 `build` 得到 config；ocvalidate 哈希来自运行时 Dortania 数据，**非静态固定**。方案见 NEXT_STEPS_PLAN C3 | BLOCKED |
| Q-08 | `NVRMFBClaim` 修复（[PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131)、[PR #133](https://github.com/nullmoth/nvidia-macos-driver/pull/133)）是否合并、在哪个版本？ | 决定装驱动后本机内屏是否必然无帧缓冲 | 2026-10-13 复查：两个 PR 仍为 open/未合并（最后更新 10-11）；v1.14.2 源码中缺陷仍在（本项目测试固定）。继续定期查询 | OPEN |
| Q-09 | Gen12 Iris Xe 在 macOS 15 仅靠固件帧缓冲能否出安装器 GUI？ | 1401 `KEEP_NOTE` 与 `mux_help` 互相矛盾；1401#7 显示 Tiger Lake 未出 GUI | 只能靠社区新报告或隔离硬件实测 | OPEN |
| Q-10 | 1401#26 当前进展（v1.14.2 后是否复测？） | 最接近本机的案例 | 2026-10-13 复查：仍 open，仅 2 条评论（台式机用户用 `ForceExitBootServices`+`SetupVirtualMap` 自行解决，与笔记本 MUX 问题无关），原报告者无复测 | OPEN |
| Q-11 | 旧知识库“Issue #26 误引”结论需要修正 | 当年核对的是 `nvidia-macos-driver#26`（Alienware），而真正的同平台案例是 `nullmoth/1401#26`（i5-12500H），两个仓库编号相同 | 已在 [knowledge/11](../knowledge/11_EARLY_RESEARCH_AND_1401.md) 追加更正（不改写原文） | DONE |
| Q-12 | 未审阅模块：`selftest.py`、`apple.py`、`report.py`、`probe_report.py`、`hwcapture.py`、`machine_handoff.py`、`dsdt_pass1.py`、`efidoctor.py`、`mirror.py`、`downloads.py`、驱动 `nullmoth-setup.sh` | 可能还有未识别的副作用 | 会话 2 已全部只读审阅，结果见 RISK_ASSESSMENT R-12～R-18、SOURCES 第 5 节 | DONE |
| Q-13 | 1401 Windows 发布包中 1.0.21 基线 ZIP 包含哪些二进制，各自来源？ | 源码↔二进制可追溯性 | 下载基线 ZIP 到隔离目录只做清单与哈希，不执行（需用户同意下载约数十 MB） | OPEN |
| Q-14 | VoodooI2C 是否真的不匹配 ADL I2C `0x51E8`？ | 触控板可用性 | 2026-10-13 已核实：v2.9.1（`e3ac3ed`）与 master（`5c0c99c`）的 `IOPCIMatch` 都只到 `0x34E8`，**不含 `0x51E8`**；原版不会匹配本机触控板所在控制器 | DONE |
| Q-16 | iasl 应固定哪个版本？ | `plan`/`build` 的唯一必需外部二进制；1401 源码无固定值（`acpi_dupnames.py` 注释提到 `iasl 20260930`） | 2026-10-13 GitHub API 只读查询 acpica releases：**20260930 无 Windows 资产**；最新 Windows 版为 **20260408**：`iasl-win-20260408.zip`（1377409 字节，SHA256 `121f5e4f30b1df63d09052294e4a605d4dee2dfb9599fa24af4ac6015df02b70`），内含/同版单独资产 `iasl.exe`（1035776 字节，SHA256 `739c597bcee4563f18d13e73b2051bb661707713e6154cf5712a1b7eef4a5df9`）。哈希为 GitHub 资产 digest。**候选已选出，待用户确认后才下载** | NEEDS_USER |
| Q-15 | HONOR GLO-FX6P 或同模具机型是否有任何 macOS 成功案例？ | 唯一可能的 A 级证据 | 2026-10-13 两次网页检索（英文/中文）**未找到**；只有旧款 MagicBook（i5-8250U、i5-10210U X15、R5-4500U）的 EFI，平台不同、不可引用。后续可查远景论坛、Bilibili | OPEN |
