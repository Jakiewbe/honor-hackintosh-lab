# 10｜Codex 正式交接单：现在接手做什么

**交接时点：2026-10-12。仓库主分支 main；依据 R1.4-B 审核后的方案。此文档是执行任务说明而不是“驱动已实现”。**

**最新断点：** R1.4-C0 首轮台账和负向静态检查已交付，base 候选 `release/14.3.0 / 8c9ce319fef765890ce518cab85d3a470b669849` 已固定；完整 B0/B1 闭包仍 BLOCKED。下方保留原任务定义，当时“base 待查”不代表现在未取得 SHA。见 [结果](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)。

**Next Task R1.4-C0.1：** 固定 FreeBSD 14.3 生成头文件/配置及 include 次序，补齐 PCI→probe→Power Well 最小 slice 的直接/传递提供者与许可，制定 XNU 电源状态/所有权/失败清理合同。必要语义缺证据即停止，不直接继承 PM 空成功，不进入 B2/B3 或 kext 原型。

## 先读清楚底线

1. 执行 [`AGENTS.md`](../AGENTS.md)，再读 [当前状态](02_CURRENT_STATE.md)、[目标](00_PROJECT_CHARTER.md)、[版本锁](05_SOURCE_LOCKS.md)、[技术风险](06_ARCHITECTURE_AND_RISKS.md)、[决策](07_DECISIONS.md)。
2. 主力 Windows 禁止改动；不运行/安装 kext/EFI/BIOS/SIP；不自己启动/rerun Actions，不发重复上游 Issue。
3. 已知内屏接 Intel `8086:46A6`；RTX 为 `10DE:25A9` 的 **2050**，不是 3050。**已经确认的硬件不要再让用户重复测**。
4. `RUNTIME_NO_GO`，R1.2-C 旧候选虽 real+virtual BUILD-PASS，但**我们的自主驱动没有任何 native build**。不要混淆。

## 推荐 Codex 首个工作包（R1.4-C0：B0 + B1，不允许先做内核部署）

**任务目标：** 将“FreeBSD drm-kmod 6.1-lts + Linux v6.1 可作为独立 Intel 46A6 KMS 研究输入”的假设落实为**有证据的版本和最小函数/对象依赖闭包**。**本工作包优先交付原始源码追溯、C ABI 合同和可证伪依赖矩阵，不应声称产出可加载 AlderFB.kext。**

### 已固定输入候选（不得暗换）

- Linux v6.1 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`
- FreeBSD drm-kmod 6.1-lts commit `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`
- Apple XNU macOS 15.5 commit `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`
- Apple IOGraphics macOS 15.5 commit `4d3fd008c80d1414c9da8f02ea67d534b47158c2`
- **FreeBSD base LinuxKPI 对应版本与 commit 待查，不能编造。** 先从 FreeBSD drm-kmod 6.1-lts 真实构建说明、Makefiles、includes 和 FreeBSD Release 分支选择一个可审查 SHA。

### 允许 Codex 立即实施的步骤

**T0｜仓库复核/任务约束**

- 逐一列出 [历史/验收账本](03_RESEARCH_HISTORY.md)、[证据台账](04_EVIDENCE_LEDGER.md) 中与 B0/B1 重复的工作；**不再运行这些旧任务**。
- 如果现有仓库还有外部用户修改，先报告冲突，不覆盖。

**T1｜源版本/许可证闭包**

- 在 `research/independent-i915/` 建立文本形式 `README.md`、`source-lock.json`、`license-manifest.csv` 和 `compat-notes.md`。
- `source-lock.json` 每项至少含 `repo`、`commit`、`path`、`blob_sha`、`role`、`status`；缺失 commit 标为 `BLOCKED`，**不能填一个“看起来差不多”的哈希**。
- 选择 FreeBSD base/LinuxKPI **具体可公开核实的版本**，检查 DRM 6.1 includes 是否确实存在与之匹配的接口和 licensed symbols；展示缺口。
- 对 GPL/dual-license/MIT/BSD 等逐文件标注 SPDX/许可来源、是否允许后续重分发。没有许可证明不可默认合并为可分发闭源 kext。

**T2｜针对 46A6 的真正最小调用图**

- 从 FreeBSD `i915_pciids.h:INTEL_ADLP_IDS`、`i915_pci.c` 到 ADL-P display/eDP 相关核心函数，构造 **`pci-probe → VBT/OpRegion → Power Wells/CDCLK/PLL → eDP AUX/link training → GEM/GGTT plane backing → IOFramebuffer publication`** 的带版本来源图。
- 输出 `callgraph.md`、`symbol-inventory.csv`、`required-apis.md`。每条记录写出提供定义的具体源码/对象以及内核线程/中断上下文；目前未识别的明确标注 `UNRESOLVED`。
- 不直接按固定的 `intel_edp.c`、`i915_gem_gtt.c` 名称搜索不存在的 Linux v6.1 文件：eDP 在 DP/panel，GGTT 在 `gt/intel_ggtt.c`。
- `IOFramebuffer::getInformationForDisplayMode` 是模式信息 API，不是物理 frame buffer 基址映射 API；用 `getApertureRange` 等 pinned API 审核桥接。

**T3｜机读负向检查（仅当确有信息增量）**

- 如需写脚本，只做**不下载/执行上游二进制、不读写硬件**的 manifest/schema 校验：包括源 commit 必填、路径/blob 唯一、source-object mapping 不遗漏、许可缺失 fail-closed、关键 API 不允许“未实现但返回成功”。
- 本地离线测试应包含：缺文件/缺许可/重复对象/版本不对应→**退出非零且输出具体诊断**；不能用假数据证明真实上游闭包。
- **不创建或运行没有新增验证能力的 GitHub Actions**；即使创建了手动 workflow，也要等用户通过 GitHub UI 自行触发。

**T4｜提交和交接报告**

- 给出 **真实改动文件、Git 提交、外部固定 SHA、实测过的本地命令与输出、明确尚未运行的步骤、未解决符号和许可证**。
- 根据实际结果更新 `knowledge/02_CURRENT_STATE.md`、`knowledge/04_EVIDENCE_LEDGER.md`（有实际验证才改）、`knowledge/07_DECISIONS.md`（若需要变更）、本文件的 Next Task。
- 若连 FreeBSD base 版本都无法证明，应在该处停下报告 `BLOCKED_FREEBSD_BASE_SELECTION`，而不是为了推进插入大规模缺实现的 Stub。

### 本工作包**不做**

- 不复制整套 6.1 内核到仓库、不开启大规模源文件硬剪裁；不尝试一次建好最终 `AlderFB.kext`。
- 不写入 `BDSM + 0`、`GGTT 0`、未知 Stolen Memory，不从主力机访问 PCI config/MMIO。
- 不允许用空返回函数替代必需 Power Well、DMC/固件、DMA/页映射、锁和 eDP link training。
- 不研究 Metal shader/RTX 混合显卡，不修改 OpenCore/EFI，不更改主力 Windows。

## 验收与下一跳

第一份 PR/commit 应在 **T1/T2 文本源闭包** 上有真实信息增量，明确适配 Intel `8086:46A6` 的 PCI/display/eDP 路径，能复核每个 external commit 和许可。**不要为了“代码量”制造无法证明的 kext Stub**。

只有 B0/B1 验收并解决必要的接口与许可阻塞，才允许规划 B2/B3 的真正 macOS hosted native compile（仅静态）和 B4 GGTT/scanout memory contract。

**交接时的下一句提示（供 Codex 直接使用）**：

> 阅读根目录 AGENTS.md、knowledge/README.md、knowledge/02_CURRENT_STATE.md、knowledge/10_CODEX_HANDOFF.md 及所引原始文档。按 R1.4-C0 的 T0→T4 执行：先在 GitHub 核对既有成果避免重复，追溯 FreeBSD drm-kmod 6.1-lts 需要的 FreeBSD base/LinuxKPI 固定 commit，建立最小 Intel 8086:46A6 i915/eDP 的源/符号/许可证/接口依赖清单与 FAIL-CLOSED 检查。不得加载、安装或签名内核驱动，不触碰主力 Windows/EFI/BIOS，不自行启动 Actions，不写假成功 Stub。提交代码与报告，标明真实测试和未关闭阻塞，保持 RUNTIME_NO_GO。
