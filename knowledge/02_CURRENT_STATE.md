# 02｜当前事实、阻塞与决策（Codex 最新状态）

**汇总时点：2026-10-12；最新里程碑：R1.4-C0.1 PCI/电源接口合同，完整闭包未验收。**

**主状态：`R14C01_POWER_CONTRACTS_BLOCKED / R14C0_SOURCE_SLICE_RECORDED / FREEBSD_BASE_CANDIDATE_PINNED / DEPENDENCY_CLOSURE_BLOCKED / NO_INDEPENDENT_DRIVER_BUILD / NO_HARDWARE_RUNTIME / RUNTIME_NO_GO`。**

> 这份文件是“现在怎么样”的**单一入口**。历史报告记录当时的事实，不因后来发生新判断而回写成“当时已经知道”。下一阶段完成后必须同步更新此文件。

## 现在已经确定的事情

- [R1.4-C0](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)：按固定上游测试矩阵解析 FreeBSD `release/14.3.0` 为候选 `8c9ce319fef765890ce518cab85d3a470b669849`；156 条源码/头文件/配置/许可文本锁，92 定义/79 源码关系。新增离线测试 **25 通过、0 失败**；完整闭包门禁**退出 2，拒绝放行**，没有 native/ABI/硬件成功。
- base PM 空成功、GT/uc 完整 probe 依赖和 ADL-P plane 回调已定位；DMC 缺 payload 时上游保留电源引用。14 类必需 XNU 协议未实现，见 [接口合同](../research/independent-i915/required-apis.md)。

- 荣耀 GLO-FX6P、Intel 12500H、Intel 46A6、RTX 2050 25A9 的真实硬件身份与**当前内屏连接 Intel** 已确认；不能按 RTX 3050 或内屏归属未知开展新研究。
- `NMIntelFB` 曾经在 GitHub `macos-15-intel` Runner 上完成 **x86_64 real + virtual 两种分支原生编译和 kext 静态链接**，R1.2-C 正式 [Actions #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450)。这是**旧候选的 BUILD-PASS**，不是我们的自主 Intel-only kext。
- Apple 官方 macOS 15.5 的 IOGraphics-599/XNU 11417.121.6 公开源码已核对版本和 SYS→FB 锁序：[R1.2-F Actions #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)。
- VBL 40/40 抽象参考模型 + 10 个真实 Apple IOFramebuffer VBL consumer 结构条件通过：[R1.2-G Actions #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)。**源码风险尚未关闭**，且该阶段没有内核安全证明。
- NullMoth v1.14.2 提供实验性 NMXGPU Intel i915→DRM→IOFramebuffer 源码路径，**上游文档明确未在物理 Intel GPU 上加载验证**。NMXGPUFB 的回调注销/禁用原版为空实现，timer/stop/同步终止有潜在生命周期风险。
- R1.3-D [Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373) 核对 v1.14.2 主资产 SHA256，索引 172 个路径，含 NMXGPU kext binary，**未见已知名称的 GPU 编译清单/源树/对象目录**。这只阻塞**复现上游发布物**，不阻止选择公开源码自主研发。
- 向 NullMoth 正式提交 [Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) 索取实际编译输入；不再开重复 Issue。此前审查时 [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) 未合并，`NVRMFBClaim` 广域匹配 Intel 显示卡风险仍未得到版本证明的修复。
- 已找到自主研发的**版本系列候选** Linux [v6.1 `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476) + FreeBSD [drm-kmod/6.1-lts `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4)。在 FreeBSD `i915_pciids.h` 中看到 `0x46A6`。**未证明跨仓库 ABI 或 FreeBSD base LinuxKPI 版本匹配。**

## 当前必须保持 BLOCKED 的项目

| Gate | 现在缺什么 | 不应如何“解决” |
|---|---|---|
| **P0-SOURCE** | base 候选已固定；生成配置/传递 includes/对象依赖未闭合，12 条本文件内许可证明缺失，组合许可未审完 | 不把测试矩阵当运行成功；不把源码 slice 当完整闭包 |
| **P0-ABI** | XNU 与 LinuxKPI 的锁、中断、内存/PM/DMA、IOKit 资源协议尚未通过可执行的等价性验证 | 不用 `return 0` Stub 伪造供电/固件/映射成功 |
| **P0-SCANOUT** | eDP VBT、AUX、CDCLK/Power Well/PLL/PHY、GGTT backing、真实 plane pitch/format、IOFramebuffer 扫描输出未证明 | 不假定 Stolen base = GGTT 0 = Framebuffer；不直接写未知物理/PCI 寄存器 |
| **P0-PLATFORM** | Intel 12500H P/E 混合核与 macOS 内核/ACPI/启动可靠性未独立验收 | 不把 GPU 构建通过当整机能启动 |
| **P0-LIFETIME** | VBL 注册/注销、停止/回调释放、SYS/FB 锁序等对新实现的证明缺失 | 不重复堆叠原 `NMIntelFB` VBL 微调 |
| **P0-NV** | RTX2050 `10DE:25A9` 的完整 GSP/NVRM/NVAccel/Metal 没有目标实机证据；NVIDIA r610 缺 Darwin 生成编译参数 | 不把 PCI ID 在表中或 Metal 信息字符串视为真实加速 |
| **P0-SAFETY** | 无独立 Intel Xe 硬件恢复环境，主力 Windows 的分区/BitLocker/EFI/恢复演练未做 | 不在主力机安装、修改 BIOS/EFI、关闭 SIP 或加载 kext |

## 正在做什么／马上做什么

**下一任务 R1.4-C0.2：固定匹配 macOS15.5 的 IOPCIFamily 原始来源/commit，查 PCI BAR、PM、IRQ 与释放接口并补 XNU 独立树核验。C0.1已记录生成规则/电源合同，实际配置与预处理仍未执行。** 完整闭包和必要接口关闭前，不进入 native 编译或 kext 原型。

**本知识库/AGENTS.md 的提交只是一项“移交文档”完成，并不推进 kernel 驱动运行等级。**

查看 [10 Codex 交接](10_CODEX_HANDOFF.md) 和 [08 自主开发计划](08_ENGINEERING_ROADMAP.md)。旧实验和每一个正式 CI 的索引见 [03 历史](03_RESEARCH_HISTORY.md)／[04 证据](04_EVIDENCE_LEDGER.md)。

## R1.4-C0.1 最新增量与下一步
55条源锁（相对C0新增26文件）、32定义/14直接调用；实际BSD生成输入已锁，配置/预处理仍未执行。
21通过0失败；结构退出0，闭包退出2。电源超时不能用hw_enabled真值证明成功；XNU PM负值不是拒绝请求。
16条文件内许可未证明、76条slice外include、四项XNU合同BLOCKED；无新编译或硬件证据。
下一项C0.2固定IOPCIFamily/PCI-MMIO-PM生命周期与独立树核验，详见[报告](../docs/R1.4-C0.1_PCI与电源井接口合同.md)。
