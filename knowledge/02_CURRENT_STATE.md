# 02｜当前事实、阻塞与决策（Codex 最新状态）

**汇总时点：2026-10-12；研究最新里程碑：R1.4-B 批判性设计审查。**

**主状态：`OWN_INTEL_SCANOUT_PORT_DESIGNED / SOURCE_CLOSURE_PENDING / NO_INDEPENDENT_DRIVER_BUILD / NO_HARDWARE_RUNTIME / RUNTIME_NO_GO`。**

> 这份文件是“现在怎么样”的**单一入口**。历史报告记录当时的事实，不因后来发生新判断而回写成“当时已经知道”。下一阶段完成后必须同步更新此文件。

## 现在已经确定的事情

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
| **P0-SOURCE** | 自主 FreeBSD base/LinuxKPI SHA 未选择；6.1 候选 KMS→DRM→XNU 真实调用/对象依赖和许可证未闭合 | 不简单照搬 NullMoth 的开发者私有路径；不混用 master 6.14 当作 6.1 |
| **P0-ABI** | XNU 与 LinuxKPI 的锁、中断、内存/PM/DMA、IOKit 资源协议尚未通过可执行的等价性验证 | 不用 `return 0` Stub 伪造供电/固件/映射成功 |
| **P0-SCANOUT** | eDP VBT、AUX、CDCLK/Power Well/PLL/PHY、GGTT backing、真实 plane pitch/format、IOFramebuffer 扫描输出未证明 | 不假定 Stolen base = GGTT 0 = Framebuffer；不直接写未知物理/PCI 寄存器 |
| **P0-PLATFORM** | Intel 12500H P/E 混合核与 macOS 内核/ACPI/启动可靠性未独立验收 | 不把 GPU 构建通过当整机能启动 |
| **P0-LIFETIME** | VBL 注册/注销、停止/回调释放、SYS/FB 锁序等对新实现的证明缺失 | 不重复堆叠原 `NMIntelFB` VBL 微调 |
| **P0-NV** | RTX2050 `10DE:25A9` 的完整 GSP/NVRM/NVAccel/Metal 没有目标实机证据；NVIDIA r610 缺 Darwin 生成编译参数 | 不把 PCI ID 在表中或 Metal 信息字符串视为真实加速 |
| **P0-SAFETY** | 无独立 Intel Xe 硬件恢复环境，主力 Windows 的分区/BitLocker/EFI/恢复演练未做 | 不在主力机安装、修改 BIOS/EFI、关闭 SIP 或加载 kext |

## 正在做什么／马上做什么

**下一项唯一合理的自研交接任务：R1.4-C0（也可以延续命名 R1.4-B/B0）——独立版本对齐与最小依赖调用图。** 先固定兼容 FreeBSD base/LinuxKPI commit，创建源码 manifest / license manifest / C ABI contracts 和精确的 **46A6 PCI → i915 probe → VBT/OpRegion → power/clock → eDP AUX/KMS → GGTT/plane → XNU IOFramebuffer** 调用图；对每一条缺失符号作明确阻塞，只有输入闭合才能规划原生编译。

**本知识库/AGENTS.md 的提交只是一项“移交文档”完成，并不推进 kernel 驱动运行等级。**

查看 [10 Codex 交接](10_CODEX_HANDOFF.md) 和 [08 自主开发计划](08_ENGINEERING_ROADMAP.md)。旧实验和每一个正式 CI 的索引见 [03 历史](03_RESEARCH_HISTORY.md)／[04 证据](04_EVIDENCE_LEDGER.md)。
