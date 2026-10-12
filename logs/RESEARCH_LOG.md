# RESEARCH_LOG｜1401 审计支线工作日志

## 当前断点（每次结束前改写本节）

- **更新时间**：2026-10-13
- **模式**：`READ_ONLY_RESEARCH`（未获得任何写盘、管理员、上传、运行 1401 的授权）
- **已完成**：Phase 1–6 中全部非破坏性工作；会话 2 补审全部剩余模块（Q-12 DONE）、VoodooI2C 核实（Q-14 DONE）、下一步方案。报告 [`reports/INITIAL_AUDIT.md`](../reports/INITIAL_AUDIT.md)（含附录 A）
- **上游固定点**：`upstream/1401` = v1.14.2 `46d9fee3`；`upstream/nvidia-macos-driver` = v1.14.2 `1083a98d`
- **Git**：`main` 本地提交 `8869796`（会话 1）+ 会话 2 提交；**未 push**、未触发 Actions（用户选择“只本地提交”）
- **用户已同意的方向**：四项都做，但每条具体命令仍需单独批准。当前状态：
  1. 只读源码工作：**已完成**；剩余仅定期跟踪 PR #131/#133、1401#26（Q-08/Q-10）与选定 iasl 版本（Q-16）。
  2. 用户目视：BIOS 显示模式/MUX（Q-01）、外接口归属（Q-02）——清单见 [`research/NEXT_STEPS_PLAN.md`](../research/NEXT_STEPS_PLAN.md) A。**等待用户**。
  3. 管理员只读：**已完成**（用户批准，UAC 运行一次；Q-04/Q-05 DONE）。
  4. 沙箱候选 EFI：C1 scan → C2 离线 plan → C3 联网 build + ocvalidate，每步副作用已列明。iasl 候选已选出（20260408 Windows 版，Q-16），**等待用户确认 iasl 与批准 C1**。
- **续做前先跑**：`python tests/test_1401_static_audit.py`（13 项；SHA 断言失败 = 上游已变，先更新 `research/SOURCES.md`）

---

## 2026-10-13　会话 1：初始化与初始审计

### 1. 工作区与上游源码

- 工作区根 `D:\Hactk`，唯一子目录 `honor-hackintosh-lab`（已有 Git 仓库，`main` @ `195e465`，干净；另有分支 `docs/windows-readonly-hardware-survey-20261012`）。既有研究全部保留。
- `git clone --filter=blob:none` 克隆 `nullmoth/1401`、`nullmoth/nvidia-macos-driver` 到 `upstream/`。发现 1401 的 v1.14.2（`46d9fee`，分支 `support-fixes-1008`）领先 `main`（`b211981`），切到 v1.14.2 审计。
- `dotnet`、`gh` 不存在；改用 GitHub REST API 只读 GET 获取 Issue/PR。第一次请求 URL 漏了 `/issues/` 导致 404，修正后成功，结果缓存在 `%TEMP%\hk_issues.json`（120950 字节，未入库）。

### 2. 只读环境检测（非管理员）

结果见 `reports/INITIAL_AUDIT.md` 第 3 节。命令要点：`WindowsPrincipal.IsInRole`、`Get-CimInstance Win32_OperatingSystem`、各工具 `--version`、注册表（.NET release、SecureBoot、CI Policy、Internet Settings）、`GetFirmwareType`、`Win32_DeviceGuard`、`Get-Disk/Get-Partition/Get-Volume`（显式排除 SerialNumber/UniqueId）。BitLocker 的 Shell 属性返回 0（含义不明确，按“未知”记录）。

### 3. 证据提取

- 从既有调查 `P20_pnp_inventory.json` 提取：RTX 2050 硬件 ID 含 `CC_0302`（3D 控制器），Intel 46A6 为 `CC_0300`。
- 读取 14 条 Issue/PR（1401#26、#5、#7；driver#26、#119、#131、#133、#109、#69、#87、#15、#32、#104、#35）。
- 下载 1401#26 附件 OpenCore 日志（公开文本）到 `%TEMP%\hk_1401_issue26_opencore.txt`，SHA256 `E70C38D0735FE9D234C422B0241C796F9FB3844EF05F95254C79AC2F47CBB31C`。要点：核显 `disable-gpu`、`boot-args - ignored, exists`、止于 `EXITBS:START`。
- 抓取 Dortania “Hardware Limitations” 页面：笔记本 CPU 覆盖 Arrandale～Ice Lake；Optimus 独显无法驱动内屏；SST 设备不可用。
- 网页检索 GLO-FX6P / MagicBook 14 2022 黑苹果案例：无结果。
- **发现旧知识库错误**：`knowledge/11` 第 3 节把“同平台 EXITBS 案例”判为误引，但核对的是 `nvidia-macos-driver#26`；真正的案例是 `nullmoth/1401#26`。已在 `knowledge/11` 第 5 节追加更正，原文未改。

### 4. 测试

**上游测试（沙箱）**：事先 grep 测试目录中的 subprocess/网络/磁盘/注册表调用，挑出 8 个仅写临时目录的纯逻辑模块，检查 `p1401/__init__.py`、`tls.py`（`install()` 只替换进程内 urllib opener）的导入期副作用。

```powershell
$sb = "$env:TEMP\hk-1401-sandbox-20261013-001159"
robocopy upstream\1401 "$sb\src" /E /XD .git
python -m venv --without-pip "$sb\venv"
# USERPROFILE/HOME/TEMP/TMP/APPDATA/LOCALAPPDATA -> $sb 子目录；HTTP(S)_PROXY/ALL_PROXY -> http://127.0.0.1:9；PYTHONDONTWRITEBYTECODE=1
& "$sb\venv\Scripts\python.exe" -m unittest -v tests.test_intel_panel_keep tests.test_laptop_display_notes `
  tests.test_laptop_gpu_awake tests.test_unsupported_igpu tests.test_nullmoth_amfipass tests.test_known_machines `
  tests.test_excluded_kexts tests.test_boot_security
```

结果：`Ran 24 tests in 0.503s — OK`；有上游测试未关闭文件的 `ResourceWarning`。沙箱外无写入；之后已把当前 Shell 的环境变量恢复原值。日志：`$sb\unittest.log`。

**本项目测试**：`python tests/test_1401_static_audit.py` → `Ran 11 tests — OK`（`PYTHONDONTWRITEBYTECODE=1`，避免在 `upstream/` 生成 `__pycache__`）。

### 5. 文件改动

新增：`.gitignore`、`.cursor/rules/{read-only-research,evidence-standard,upstream-readonly}.mdc`、`research/*.md`（5 个）、`reports/INITIAL_AUDIT.md`、`logs/RESEARCH_LOG.md`、`tests/test_1401_static_audit.py`、`upstream/README.md`；工作区根 `D:\Hactk\.cursor\rules\honor-lab-pointer.mdc`（仓库外）。
追加：`AGENTS.md`、`README.md`、`knowledge/02_CURRENT_STATE.md`、`knowledge/07_DECISIONS.md`（D-16）、`knowledge/10_CODEX_HANDOFF.md`、`knowledge/11_EARLY_RESEARCH_AND_1401.md`（第 5 节）。

### 6. 明确没有做的事

未运行 `1401.exe` 或任何 1401 扫描/构建/写盘/上传/自更新功能；未生成 EFI；未运行 ocvalidate；未执行任何管理员命令；未读取 BitLocker 信息或序列号；未修改 BIOS/EFI/NVRAM/分区；未 commit、push 或触发 GitHub Actions。

---

## 2026-10-13　会话 2：本地提交与补充只读审计

用户选择：本地提交到 `main`（不 push）；下一步四项“都可以做”，具体命令逐条批准。

### 1. 提交

`git commit` → `8869796 docs(1401): read-only audit of 1401 v1.14.2 against GLO-FX6P`。提交前核对 `git diff`：既有文件只有追加、0 行删除。origin 上另有本地没有的分支 `research/acpi-static-external-review`（`ffbc8fd`），未拉取、未改动。

### 2. 补审源码（三个只读子代理 + 本人抽查）

- 1401 其余模块：除 GUI 上传与 U 盘写入外，无固件变量、原始磁盘、注册表写、`bcdedit/diskpart/mountvol/manage-bde` 调用。
- `plan` 路径：`OCPE()` → `ACPIGuru()` → `DSDT()` → `check_iasl()`，**不生成 config.plist、不运行 macserial/ocvalidate**；OCS 构造时删除 `%TEMP%\ocs_*`；创建 `%LOCALAPPDATA%\NullMoth\1401\OCK_Files`。
- `scan-evidence.json` 必须与 `Report.json` 哈希一致，否则核显保护失效。
- Hardware-Sniffer 用 RWX 内存执行 CPUID；1401 扫描可能导出 MSDM；`apple --selftest` 会联网；`efidoctor --fix` 会改写用户所选目录的 config.plist；ocvalidate 哈希来自运行时 Dortania 数据。
- 驱动 Mac 端：root、SIP OR `0x0A43`、`SecureBootModel=Disabled`、有 config 备份/回滚；卸载残留 `wsreset`/`displaytrace` LaunchDaemon；更新取 `releases/latest`。release 1.12.0 声称 headless 模式支持 11 代以后 Intel 内屏；`NMIntelFB` 含 `0x46a6` 但不被安装；NMXGPU 会重置显示引擎。
- 子代理之一执行了 `git diff --no-index`（只读，无改动），已记录为偏离指令。

### 3. 外部只读核实

- PR #131/#133：仍 open、未合并（GitHub API GET）。
- VoodooI2C v2.9.1（`e3ac3ed`）、master（`5c0c99c`）`Info.plist`：`IOPCIMatch` 不含 `0x51E8`。第一次请求用了标签 `2.9.1` 返回 404，改为 `v2.9.1` 后成功。
- 本仓库所有分支历史中检索 MSDM/SLIC：无。

### 4. 测试

`tests/test_1401_static_audit.py` 新增：iasl 未随包（`Scripts/iasl.exe` 不存在）断言、驱动 SHA 固定、`NVRMFBClaim` 匹配条件（plistlib 读取 `kexts/NVRMFB/fb/Info.plist`）。结果 `Ran 13 tests — OK`。

### 5. 文件改动

新增：`research/NEXT_STEPS_PLAN.md`、`scripts/readonly_admin_status.ps1`（未运行）。
修改（本支线自有文件）：`research/{COMPATIBILITY,RISK_ASSESSMENT,SOURCES,OPEN_QUESTIONS}.md`、`reports/INITIAL_AUDIT.md`（就地标注“会话 2”更正 + 附录 A）、`tests/test_1401_static_audit.py`、本日志。

### 6. 本地提交

`4de917e docs(1401): session 2 read-only review, next-step plan, 13 static tests`。

### 7. 用户批准后的管理员只读查询

用户在 AskQuestion 中选择“通过 UAC 提权运行”。运行前复核脚本（无 set/enable/delete、无密钥读取），然后：

```powershell
Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& '<repo>\scripts\readonly_admin_status.ps1' *> '$env:TEMP\hk-admin-status-20261013.txt'`""
```

`-ExecutionPolicy Bypass` 仅作用于该进程。退出码 0。结果：Secure Boot `True`；C:/D: 完全解密、保护关闭、无密钥保护器；WinRE Enabled（partition7）；ESP FAT32/`SYSTEM`/约 196 MiB/剩 94 MiB；固件启动顺序 Windows Boot Manager → USB → DVD → Network，超时 2 s。原始输出（含 BCD GUID）只留在 `%TEMP%`，不入库。

### 8. iasl 版本核对（Q-16，用户选择“先查再决定 C1”）

GitHub API 只读 GET `acpica/acpica/releases`：20260930 只有 Unix 资产，20260408 是最新的 Windows 版（`iasl.exe` SHA256 `739c597b…f9`）。OCS `dsdt.py:get_latest_iasl` 只看最新 release 的正文与资产里的 `iasl*.zip`，因此现在自动下载预计失败（据 API 推断；OCS 实际抓取 HTML，未直接验证）。未下载任何 iasl。

### 9. 明确没有做的事

未运行 `p1401.scan`/`plan`/`build`、iasl、ocvalidate；未下载 iasl 或 1.0.21 基线 ZIP；未 push；未修改 BIOS/EFI/NVRAM/分区/BitLocker。管理员操作仅限上述一次只读脚本。
