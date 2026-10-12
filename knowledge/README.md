# HONOR Hackintosh Lab｜Codex 接管知识库

**整理日期：2026-10-12（UTC+08）**。这是供 Codex 反复读取、在 GitHub 持续维护的 **活文档与原始证据索引**。原研究报告、补丁和 CI 日志保持原貌；本知识库不是新驱动、也不是成功适配报告。

## 接手前先读（顺序不要颠倒）

| 顺序 | 文件 | 作用 |
|---|---|---|
| 0 | [根目录 AGENTS.md](../AGENTS.md) | 不可突破的安全规则、证据分级、Codex 工作规范 |
| 1 | [00 目标与愿景](00_PROJECT_CHARTER.md) | 项目究竟为了什么，什么算真正成功 |
| 2 | [01 硬件真实档案](01_HARDWARE_BASELINE.md) | Intel 内屏已确认、RTX2050 而非 RTX3050；未知边界 |
| 3 | [02 最新现状与阻塞](02_CURRENT_STATE.md) | R1.4-B 为止已证明什么、下一步未证明什么 |
| 4 | [10 Codex 交接任务](10_CODEX_HANDOFF.md) | 第一份可以立即执行的开发任务与验收标准 |
| 5 | [07 决策日志](07_DECISIONS.md) | 已否决的捷径、冻结原因、何时可以改变决定 |
| 6 | [03 历史研究时间线](03_RESEARCH_HISTORY.md) | R0.6—R1.4-B 的里程碑，不重复研究 |
| 7 | [04 GitHub 验证账本](04_EVIDENCE_LEDGER.md) | Actions 运行链接、样本、测试等级、误用限制 |
| 8 | [05 源码版本锁定](05_SOURCE_LOCKS.md) | Apple/NullMoth/NVIDIA/Linux/FreeBSD 的已核验版本和关系 |
| 9 | [06 架构风险与技术门禁](06_ARCHITECTURE_AND_RISKS.md) | Intel 显示链、NV 混合路径、驱动安全风险 |
| 10 | [08 自主开发阶段计划](08_ENGINEERING_ROADMAP.md) | R1.4-B 下一步阶段与准入/停止条件 |
| 11 | [09 全量资料索引](09_REPOSITORY_INVENTORY.md) | 所有现存报告、脚本、补丁、测试、workflow 的用途 |
| 12 | [11 早期线索与 1401/OpenCore](11_EARLY_RESEARCH_AND_1401.md) | 1041 名称澄清、1401 研究以及 Issue #26 误引纠正 |

**历史阶段事实的唯一原始依据**仍是 [docs/](../docs/) 的对应报告、[测试源代码](../tests/)、[研究脚本](../scripts/)、[GitHub Actions](https://github.com/Jakiewbe/honor-hackintosh-lab/actions) 的正式运行日志，以及固定 commit 的上游源码。知识库汇总若有争议，回到原始证据核对，不要凭旧概述直接编码。

## 项目当前一句话

**2026-10-12 R1.4-C0 首轮接管增量：** FreeBSD base 14.3.0 精确候选已固定，源码/调用/许可台账和负向检查已交付；完整接口闭包仍 BLOCKED，无自主 native/硬件证据。当前只认 [02 最新状态](02_CURRENT_STATE.md)，交付见 [R1.4-C0 报告](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)；下段是知识库建立时的 R1.4-B 摘要。

针对荣耀 GLO-FX6P、Intel i5-12500H、**内屏目前连接 Intel Iris Xe 8086:46A6**、RTX 2050 10DE:25A9 的设备，**独立研究 Intel 基础内屏显示 L1**；此前 NullMoth/NVIDIA/VBL 调查已有价值但**都没证明 macOS 内屏实际点亮**。当前状态：**R1.4-B 方案审查结束、独立源码候选已定位、FreeBSD base/依赖闭包尚未完成、没有自主原生驱动构建或实机验证；`RUNTIME_NO_GO`**。

## 知识库维护规则

- 所有硬件事实标注来源（用户 Windows 实测 / 第三方实机 / 官方公开源码 / 未证实）。
- 在 `02_CURRENT_STATE.md` 维护**唯一当前状态**；在 `03_RESEARCH_HISTORY.md` 保留不可改写的历史阶段结果；不得让 README 中旧期结论盖过新门禁。
- 在 `04_EVIDENCE_LEDGER.md` 区分 **实际运行 SUCCESS**、**仅工作流存在未运行**、**本地模型**、**源码静态核验**。
- 新上游版本必须新建版本证据并复核差异，不能把 NullMoth 初期 commit 的审计直接套用 v1.14.2。
- 正式研究为中文，代码/符号/仓库术语可用英文，使用 Markdown 表格但不制造花哨徽章或“成功率”猜测。
- 如果没有新的可证伪假设/源码输入/外部证据，明确报告阻塞，不制造无效 CI。
