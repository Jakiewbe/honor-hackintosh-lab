# RESEARCH_LOG｜1401 审计支线工作日志

## 当前断点（每次结束前改写本节）

- **更新时间**：2026-10-13
- **模式**：`READ_ONLY_RESEARCH`（未获得任何写盘、管理员、上传、运行 1401 的授权）
- **已完成**：Phase 1–6 中全部非破坏性工作；报告 [`reports/INITIAL_AUDIT.md`](../reports/INITIAL_AUDIT.md)
- **上游固定点**：`upstream/1401` = v1.14.2 `46d9fee3`；`upstream/nvidia-macos-driver` = v1.14.2 `1083a98d`
- **Git**：所有改动尚未提交（等待用户决定是否提交；不 push、不触发 Actions）
- **下一步（需用户选择/批准）**：
  1. 只读：审阅 `research/OPEN_QUESTIONS.md` Q-12 中未审模块；跟踪 PR #131/#133、1401#26。
  2. 用户目视：BIOS 显示模式/MUX（Q-01），外接口归属（Q-02）。
  3. 管理员只读：BitLocker/WinRE/Secure Boot（Q-04/Q-05）。
  4. 沙箱候选 EFI：需要 `Report.json` + 固定 iasl/ocvalidate（Q-06/Q-07）。
- **续做前先跑**：`python tests/test_1401_static_audit.py`（SHA 断言失败 = 上游已变，先更新 `research/SOURCES.md`）

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
