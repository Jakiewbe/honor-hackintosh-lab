# Codex 项目级规则 — HONOR Hackintosh Lab

> **主线防偏移门禁（2026-10-17，用户要求恢复 H1–H4 优先级）**：新会话**先读 [knowledge/12_MAINLINE_ALIGNMENT.md](knowledge/12_MAINLINE_ALIGNMENT.md)**，再读 `.agent/GOAL.md` 和 `knowledge/02_CURRENT_STATE.md`。10-15 实机已进入外接 SSD macOS 桌面，早期 EXITBS:START 的 `.agent/CURRENT.md`/任务残留不得当成今天的现场事实。**H1 收尾证据 → H2 Wi-Fi/触控板及外设 → H3 Intel 46A6 显示机制 → H4 加速**。G1/NVIDIA DMA 研发是当前冻结的 H4 技术储备，暂不新增 GPU/DMA 原型、mock 或 CI；除非新证据显示它直接解决 H2/H3，或用户明确重启 H4。每项行动先回答里程碑、最小验收、证据增量、风险/回退，不能回答即 DEFER。无论本条如何，下面所有逐项授权/Windows 安全限制仍然有效。

> 本文件供 Codex / 自动化开发代理在**每次工作开始前**读取。本项目采用“证据先行、失败即停止、原 Windows 不动”的实验规范。下级目录新增 AGENTS.md 不能削弱本文件的安全限制。

## 项目定位和唯一主目标

针对 **HONOR GLO-FX6P / i5-12500H / Intel Iris Xe PCI 8086:46A6 / NVIDIA RTX 2050 Laptop PCI 10DE:25A9**，研究能否构建可靠的 macOS 图形与启动环境。已确认**内屏在当前 Windows 模式下连接 Intel 核显**，不要重新询问此事。

**当前工程目标（2026-10-13 用户批准扩展，决策 D-17）：整机分阶段适配**——H1 外接 SSD 引导与安装 → H2 外设逐项 → H3 Intel 46A6 内屏基础显示（即 L1：基本、持续刷新，允许无 GPU 硬件加速）→ H4 加速可行性。L2 Intel Metal 与 L3 RTX 2050 混合加速只作远期门禁研究，不得同时推动。详见 [`.agent/GOAL.md`](.agent/GOAL.md)。研究方向以[知识库](knowledge/README.md)为权威入口；遇到旧文件与新决定冲突，阅读[决策登记](knowledge/07_DECISIONS.md)并查原始证据。

## 绝对禁区（没有新的明确授权，不得突破）

- **内置 NVMe 与 Windows 永远不动**：不得修改 Windows、内置磁盘分区、内置 ESP、BCD、Windows 启动项、BitLocker、TPM。macOS 只装在外接 SSD；OpenCore 只放在 U 盘或外接 SSD 的 ESP。
- **以下动作每一次都需要用户针对该动作单独批准**（D-17）：改 BIOS/Secure Boot；写入或格式化 U 盘/外接 SSD；从 U 盘/外接 SSD 引导；在外接 SSD 的 macOS 中安装/加载 kext、改 SIP；下载并执行第三方 EFI、安装器或驱动。批准前先说明风险与回滚；未批准时不得以“流程默认”代替授权。
- **不得自行触发、重新运行 GitHub Actions**。所有 workflow_dispatch 仅由用户手动在 GitHub UI 启动；只能创建/修改静态工作流设计。不得使用自动 push/schedule 触发。
- **不得自行公开发 Issue/PR、发布 Release 或上传驱动二进制**，除非用户针对该具体行动明确同意。历史 [NullMoth Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) 已提交，禁止创建重复问题。
- 禁止编造硬件寄存器/固件地址、GPU 成功日志、CI 结果、缺失源码或测试数据。禁止用假成功 Stub（尤其是 MMIO、供电、固件、锁、DMA、eDP）绕过真正阻塞。
- 不得仅为得到绿色构建去更改实际功能语义。默认仅提交源码/文档/文本验证证据；不要提交未审查的 vendor firmware、第三方 EFI、预编译 kext、大体积构建物。
- 不擅自覆盖用户/他人未提交的工作，不强推、不 rebase/重置公共分支，不更改已完成研究的历史结论来掩盖失败。

## 每次任务的强制工作顺序

1. **先读**：`knowledge/README.md` → `knowledge/10_CODEX_HANDOFF.md` → `knowledge/02_CURRENT_STATE.md` → `knowledge/07_DECISIONS.md` → `docs/研究状态账本_防重复工作规则.md`，再看任务涉及的原始报告、脚本和 GitHub CI。
2. 先回答：**已有哪个结论？现存 P0 阻塞？本轮新增信息量是什么？** 无新增信息则只报告阻塞，不创造重复测试、重复 VBL 模型、重复发布包清单审计。
3. 新任务先写小型方案：目标、假设、输入 commit/SHA、代码路径、可证伪点、验收等级、风险、回退；必要时在隔离工作分支实现，不先大规模复制 i915。
4. 外部源码必须固定 Git commit 和 blob/hash，列出第三方补丁、许可证及 SDK/工具链；生成 **source → object → symbol** 清单，使用清洁目录，`missing=0`、`compiler_failures=0`，否则 FAIL-CLOSED。
5. 每项测试明确层级：**公开源码/静态结构 → 抽象模型 → 原生对象 → kext 链接格式 → 实机 kext 加载 → 真实内屏帧刷新 → GPU Metal → 主力机安全**。下一级不能被上一级冒充。CI 没有 8086:46A6/10DE:25A9 的 eDP 实机硬件。
6. 文档和代码完成后同步更新`knowledge/02_CURRENT_STATE.md`、`knowledge/04_EVIDENCE_LEDGER.md`（若有验证）、`knowledge/07_DECISIONS.md`（若变更决策）、`knowledge/10_CODEX_HANDOFF.md`（下一个动作），适当更新原阶段报告与 README。提供 commit、可验证链接以及未解决事项。

## 当前正确的技术策略

- 不等待 NullMoth 私有构建源；自研可以选择**我们自己固定版本的公开源码**，但绝不能声称因此复现了上游发布物。
- 已找到**候选** Linux v6.1 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476` 和 FreeBSD `drm-kmod/6.1-lts` commit `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`；仅版本系列匹配，**跨库 ABI 和 FreeBSD base/LinuxKPI commit 尚未闭合**。
- 第一项代码任务是**建立版本/许可证/接口依赖清单与目标调用图**，不是宣称写成可加载 Intel 驱动。
- **BDSM Stolen Memory 基址 ≠ GGTT 0 ≠ 当前 eDP scanout Surface**。没有证据不读写未知 MMIO/Stolen/页表地址；不通过强制连续物理地址的假设绕过内存管理。
- `IOFramebuffer` 存在不代表 macOS 15 WindowServer 一定呈现无加速桌面。`GuC/HuC` 与显示 DMC 分开判断；关键电源状态不能 `return 0` 假成功。
- 旧 `NMIntelFB` VBL 补丁链已冻结；R1.2-C 原生双模式 BUILD-PASS、R1.2-F/G 的源码与模型、R1.3-D 的归档检查**均不重复执行**。

## 工作完成汇报模板

`本轮新增事实 | 证据链接及 commit | 改动文件 | 实际运行的测试（如无写“未运行”） | 未证实或阻塞项 | 风险与回退 | 下一步`。始终保持 `RUNTIME_NO_GO` 直至满足真实硬件与安全门禁。

## 1401 审计研究线（2026-10-13 起，用户授权的只读支线，见决策 D-16）

**目标**：以源码可追溯的方式评估 [NullMoth 1401](https://github.com/nullmoth/1401) 与 [NullMoth NVIDIA 驱动](https://github.com/nullmoth/nvidia-macos-driver) 对本机的适用性，为后续 OpenCore 适配研究提供证据；**产出是研究结论，不是 macOS 安装盘或 EFI**。不改变上文 L1 主目标的优先级。

**默认模式 `READ_ONLY_RESEARCH`**（细则见 [`.cursor/rules/read-only-research.mdc`](.cursor/rules/read-only-research.mdc)）：
- 禁止：修改 Windows EFI/BCD/引导配置/NVRAM 启动项；覆盖任何 EFI 分区；新建/删除/格式化/调整分区；修改 BIOS、Secure Boot、TPM、BitLocker；执行磁盘写入工具或 macOS U 盘制作；未经许可运行需要管理员权限的 1401 程序；未经许可安装 macOS 驱动/kext/系统组件；自动向第三方服务器发送硬件报告、启动日志或设备信息；未经代码审查执行来源不明的脚本或可执行文件；导出或上传 BitLocker 恢复密钥、序列号、个人身份信息。
- 允许：Git 克隆、阅读源码、读取系统信息、检测开发工具、在 `%TEMP%` 隔离沙箱中做非破坏性测试。
- 所有具有系统副作用的命令必须先解释风险并取得用户**单独批准**；自动化流程的默认动作不等于授权。遇到风险操作：停止该项，继续其他安全任务。

**证据标准**：兼容性结论一律按 A–E 分级，并区分“代码测试 / ocvalidate 配置校验 / UEFI 能引导 / macOS 能安装 / 完整 GPU 加速”五个验证层级（[`.cursor/rules/evidence-standard.mdc`](.cursor/rules/evidence-standard.mdc)）。不修改原始证据，不伪造检测结果，不为让测试通过而改结论；冲突证据并列保留。

**文件布局**：`research/`（HARDWARE、SOURCES、COMPATIBILITY、RISK_ASSESSMENT、OPEN_QUESTIONS）、`reports/INITIAL_AUDIT.md`、`logs/RESEARCH_LOG.md`（工作日志 + 当前断点）、`tests/test_1401_static_audit.py`、`upstream/`（只读克隆，不入库，SHA 见 [`upstream/README.md`](upstream/README.md)）。

**阶段进度（2026-10-13）**：Phase 1 结构 DONE；Phase 2 源码审计 PARTIAL（核心模块已审，部分模块未审）；Phase 3 环境检测 PARTIAL（管理员项未查）；Phase 4 离线验证 PARTIAL（单元测试已跑，候选 EFI/ocvalidate BLOCKED）；Phase 5 兼容性分析 DONE（全部未经实机验证）；Phase 6 报告 DONE。详见 [`reports/INITIAL_AUDIT.md`](reports/INITIAL_AUDIT.md)。

**断点续做流程**：
1. 读本文件 → `logs/RESEARCH_LOG.md` 顶部“当前断点” → `reports/INITIAL_AUDIT.md` 第 9–10 节 → `research/OPEN_QUESTIONS.md`。
2. 运行 `python tests/test_1401_static_audit.py`；若 SHA 断言失败说明上游已变，先更新 `research/SOURCES.md` 再继续。
3. 只做 OPEN_QUESTIONS 中状态为 `OPEN` 的只读项；`NEEDS_ADMIN`/`NEEDS_USER`/`BLOCKED` 项先向用户申请。
4. 结束前更新 `logs/RESEARCH_LOG.md`（追加日志 + 改写当前断点）以及受影响的 `research/*`、`knowledge/02`、`knowledge/10`。

<!-- codex-rules:project=1.0.0 -->
# 项目状态约定

重要工作前、新会话接续或上下文压缩后，读取最新 .agent/GOAL.md、CURRENT.md 和 tasks.json；写入使用最新 revision，冲突时重新读取，不覆盖他人更新。
目标模板中的“待确认”不代表用户已经批准。禁止自行扩大目标或开始草案任务。
若仓库提供 kit.py，则使用它的 task/state 命令维护状态；否则直接编辑 .agent/ 中的状态记录并保持 revision 一致，不依赖仓库外工具或本地安装路径。
直接编辑 tasks.json 时递增任务 revision，并同步 state.json 的 revision、task_revision、文档哈希及历史；更新 CURRENT 后同步 current_task_revision，PROGRESS.md 保持与真实任务一致。修订冲突时停止写入，不覆盖他人记录。
重要决策、任务完成、用户确认变更、重大修复后，及时按上述可用方式更新对应状态文件。
GOAL 修改必须有用户批准；CURRENT 保持 50 行以内，描述当前阶段、任务、阻塞、下一步和 Git 检查。
先 Review 查 Bug，再检查实现是否简单稳健，完成声明必须对应验证证据。
禁止擅自创建分支或工作树、推送、覆盖用户改动。任务证据结构校验不等于实际验收。
