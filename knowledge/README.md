> **2026-10-18 KC8实际进展：** P1/P2门禁修复已在[run39133232412](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39133232412)通过，真实失败注入exit2且报告保留、外部身份跨run替换被拒。[KC最终run39134085153](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39134085153)观察到余下8项runner真实外部节定义（6函数+2数据），58项文本交叉核对；SDK六方法真实编译，5项与历史调用IR形状一致，write8调用侧仍未知。**未重新编完整驱动；472名称已有实际定义观察，不等于loader导出/完整ABI/最终用户系统通过；GPU初始化/渲染/读回/安全结束未执行，设备NO-GO。** 下一步定位write8实际TU/对象做单TU诊断，再补family loader/版本/提供侧ABI与PM关闭集成；不重复1280TU或本轮八符号首次取证。[结果](../research/gpu-safety-r5/KC8-20261018.md)｜[网页端审查prompt](../research/gpu-safety-r5/KC8-WEB-PROMPT.md)。

> **2026-10-18 目标提供者新证据：** [run 39130439405](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39130439405) 只读取证成功；在runner macOS15.7.9/24G830内核中，464项有精确KPI条目且实际目标全局存在，14个别名目标已核对；其余8项仅有IOPCIFamily/IOACPIFamily随系统导出名单。完整候选仍是上轮固定字节，本轮未重新编译驱动。**8项实际二进制/C++ABI、完整ABI、最终用户系统、GPU初始化/渲染/读回/关闭仍未验收；设备NO-GO。** 下一步只读检查KC中的这8项，不重复1280TU构建。[报告](../research/gpu-safety-r5/TARGET-PROVIDERS-20261018.md)｜[网页端prompt](../research/gpu-safety-r5/TARGET-PROVIDERS-WEB-PROMPT.md)。

# HONOR Hackintosh Lab｜Codex 接管知识库

**2026-10-17 主线复位**：先读 [H1–H4 防偏移门禁](12_MAINLINE_ALIGNMENT.md)。知识库本索引下方 2026-10-12 的「当前一句话」是历史建立时的摘要；以 2026-10-15 进入外接 SSD 桌面的实机事实为准。H4 Nvidia DMA 目前为冻结技术储备，不是下一工作包。

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

最新交付：[R1.4-C0.1 PCI/电源接口合同](../docs/R1.4-C0.1_PCI与电源井接口合同.md)，21通过0失败，真实接口/构建语义增量；完整闭包仍BLOCKED。下一项见[交接](10_CODEX_HANDOFF.md)。

