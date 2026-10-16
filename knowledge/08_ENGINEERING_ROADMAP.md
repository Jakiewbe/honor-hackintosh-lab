# 08｜自主 Intel 46A6 驱动研发路线（阶段/验收/回退）

**当前执行顺序修订**：[H1–H4 主线门禁](12_MAINLINE_ALIGNMENT.md)。本文件下方 B0–B5 是 H3 自研 Intel 技术研究的历史细化，不是当前整机任务排序；不得绕过尚无完整验证的 H1 收尾、H2 Wi-Fi/触控板和显示来源，直接进入 H4 NVIDIA DMA/Metal。2026-10-15 已成功显示桌面，不能按旧「无法进入 macOS」前提重复开发引导链。

## 开发战略

**不同时攻克 L1 Intel 内屏、L2 Metal 和 L3 NVIDIA 混合图形**。第一阶段只讨论能否产生 macOS 15.x 基础内屏持续画面；这仍是待验证的假设，不保证 macOS WindowServer 具有所需软件渲染回退。

优先两条互相独立的**技术假设**：
- **A：firmware handoff**。只在能够证明现有 GOP/活动 Intel pipe/plane 和映射寿命时研究接管，若不存在或格式/电源不满足则停止，不盲目写 stolen。
- **B：Intel-only i915/KMS**。主动初始化 PCI/VBT/Power Well/eDP/GGTT/DRM 并向 IOGraphics 发布 framebuffer，工程复杂但不依赖固件持续保留工作态；作为自研主线。

## 从现在开始的最小连续里程碑

| 阶段 | 任务范围 | 应交付文本/代码 | PASS 条件 | FAIL/BLOCKED 条件 |
|---|---|---|---|---|
| **B0：版本对齐** | 固定 Linux v6.1、FreeBSD drm-kmod 6.1-lts，找到**对应 FreeBSD base/LinuxKPI 精确 commit**；核对许可证/patch | `research/independent-i915/source-lock.json`、`compat_notes.md`、`license_manifest.csv` | 所有输入可定位 commit/blob，差异与许可有记录 | 版本无法匹配、要求不可许可的包含物 |
| **B1：调用/符号闭包** | `46A6 → i915 probe → VBT → power/clock → eDP → GEM/GGTT → IOFramebuffer`，列出真实 required callbacks 和 external symbols | `callgraph.md`、`symbol_inventory.json`、`required_apis.md` | 每个必需外部 API 有实际实现/等价性评估 | 关键接口缺失且无正确等价实现 |
| **B2：安全兼容层** | LinuxKPI↔XNU 的调度、锁/IRQ/内存、DMA、资源所有权与失败传播，严格区分 optional vs required | 针对最小子集的源码、单元/负向模型，代码评审 | 不存在关键硬件 `return 0` fake success；锁和 lifetime 契约可审计 | 自等待、假成功、无法证明对象 ownership |
| **B3：托管原生构建（用户手动）** | 仅对闭包后的 Intel-only 源执行清洁对象编译、最终链接静态检查 | 纯文本编译命令/对象 hash/undefined symbols 与来源 manifest | missing=0、compiler_errors=0、对象集合一致、强符号可解释、输出仅文本 | 旧缓存对象/丢失编译、未说明依赖、未标许可 |
| **B4：GGTT/scanout 与 IOFramebuffer** | 确认真实 framebuffer backing、虚拟/物理/GGTT、pixel format、pitch、VBL/stop API 设计 | `scanout_memory_contract.md`、`fb_lifecycle.md` | 地址空间及所有权/停止合同闭合 | 靠硬编码 BIOS/Stolen/寄存器偏移、伪连续地址 |
| **B5：隔离硬件运行** | 仅在具有独立恢复能力的非主力 Alder Lake-P/46A6 机器中完成 PCI/eDP/WindowServer 实测 | 真实 PCI IDs、macOS 版本、逐阶段时间日志/照片/异常，完整回滚 | 持续可操作桌面 + 成功停止/恢复 | 没有隔离硬件；任何死机/黑屏/无法回退→立即停止 |
| **L2/L3** | Intel Metal、RTX2050 和跨 GPU 链路 | 另立独立实机性能/稳定性证明 | 真实 GPU 渲染证据 | 不使用 L1 的构建结果代替 |

## 如何组织工程

建议下一阶段**先小、再大**：在 `research/independent-i915/` 创建 manifest/接口调查，而不是复制 6.1 整个 Linux 内核树。源码版权、许可证及 patch 路径应可机器检查；外部上游仓库只作为固定版本的临时输入，不盲目提交大量第三方文件到本仓库。用户正式批准独立源码工程结构后，可分子目录存放 minimal headers / C ABI / XNU glue；无需强行采用某个未经依赖检查的文件模板。

建模时可按**能否在当前测试环境证伪**优先：源码存在→类型/ABI→符号→静态/编译→内存/生命周期。CI runner 无真实目标 eDP，所以不要把它用作“内屏是否会亮”的实验。

## 每阶段报告最小格式

```text
目标/反例与价值：
输入仓库 + 精确 SHA + 变更范围：
已重用的前期结果（明确不重做）：
源码与执行证据（链接）：
测试层级、执行环境、结果：
未验证项/残余风险：
失败时是否立即停、如何回退：
下一项一周内可完成的小任务：
当前 GO/NO-GO：
```

**工作流提交和运行分离**：Codex 可以在有必要时设计 `workflow_dispatch`，但**不可自行触发**；运行结果须用户提供具体 URL 后才能升级证据等级。旧 workflow 已经有 10 个，不新增没有信息增量的重复任务。
