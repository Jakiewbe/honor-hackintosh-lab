# 03｜项目历史研究全阶段时间线（不要重复刷 CI）

> 原始研究文档在 `docs/` 完整保存。这里记录因果、结果和分歧；细节回到对应报告。**除用户机器型号和当时输入外，不得把新阶段认识回写成旧阶段已验证事实。**

| 阶段 | 研究内容及重大结论 | 权威记录 |
|---|---|---|
| **R0 前置线索** | 初步调研 “NVIDIA macOS 驱动攻克”、所谓“1041”自动适配 OpenCore；后续对照官方源码识别为 **NullMoth 1401** 安装/引导工具，不代表 46A6 显示可用；此前错把 [Issue #26](https://github.com/nullmoth/nvidia-macos-driver/issues/26) 引作 12500H 启动失败案例，**已纠正、不得引用**。 | [早期调查补录](11_EARLY_RESEARCH_AND_1401.md) |
| **R0.6** | 建立 macOS Intel 云端 **手动** preflight，不触碰主力 HONOR。最早探索适配基础与源码校验。 | [README R0.6](../README.md)、[preflight workflow](../.github/workflows/macos-preflight.yml) |
| **R0.7** | NVIDIA `610.57.04` 公开源码缺少 `src/nvidia/_out/Darwin_x86_64/compile_cmds.sh`；不能按上游说明复现 NVAccel Darwin native build。云端 [#38210653466](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38210653466) 的 prerequisites SUCCESS **不是 NVAccel 编译通过**。 | [R0.7](../docs/R0.7_build_gate.md) |
| **R0.8** | 对固定 NullMoth 源码 `NMIntelFB/intelfb.cpp` 做 macOS x86_64 kernel object/link；[run #38197014657](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38197014657) 成功但有 SDK deployment target 警告。 | [R0.8](../docs/R0.8_intelfb_compile.md)、[R0.9 静态审计](../docs/R0.9_static_kext_audit.md) |
| **R0.9** | 修正 min macOS deployment 15.5 后完成原版 Intel Kext 原生构建/链接、plist 和静态设备表检查；仍无实机可加载/显示证据。 | [R0.9 结果](../docs/R0.9_results_and_R1.0_gates.md)、[静态审计](../docs/R0.9_static_kext_audit.md) |
| **R1.0** | 分析 NVIDIA→Intel `NVRM_VRAM_FN_SCANOUT`：Intel 端 `actualSize=0`、NVAccel 复制范围缺容量上界，BAR MMIO 边界、VBL timer 生命周期等风险。 | [R1.0](../docs/R1.0_跨驱动安全审计与准入结论.md) |
| **R1.1** | 提出容量/overflow/MMIO fail-closed 候选补丁，断开危险旧异步 flip 主动入口；Intel 端构建和源码门禁通过 [#38199566264](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38199566264)，**NVAccel 未原生编译**。 | [候选修复](../docs/R1.1_候选修复与验证边界.md)、[CI 结论](../docs/R1.1_CI结论与R1.2并发修复准入.md) |
| **R1.2-A** | VBL lifecycle NEW→ARMED→STOPPING→DRAINED 参考模型，10/10、61 状态；不能证明真实 XNU 锁/时序。 | [R1.2-A](../docs/R1.2-A_VBL状态机与XNU接口审查.md) |
| **R1.2-B** | 使用 `IOTimerEventSource` + workloop gate 的候选补丁；编译及模型检查成功，但回调同步停止、资源回收有残余风险。 | [R1.2-B](../docs/R1.2-B_VBL候选补丁与准入.md) |
| **R1.2-C** | 增加 callback owner/timer 临时 retain，修补特定重入 UAF 窗口；经历两个仅 CI 脚本问题的失败 [#38202526277](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202526277)、[#38202869877](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202869877) 后，**最终 [#38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450) real+virtual 原生构建成功、37/37 模型通过**。 | [R1.2-C](../docs/R1.2-C_回调重入引用保护与残余风险.md) |
| **R1.2-D** | 识别 Apple 系统工作循环 `SYS→FB` 与回调 `FB→SYS` 条件 ABBA 反例；引用计数不足以修复锁序。 | [R1.2-D](../docs/R1.2-D_双Workloop锁序与重入停止风险审计.md) |
| **R1.2-E** | 两阶段 quiesce/drain/finalize 模型，12/12、113 状态；异步提前返回违背 `IOService::stop` 的同步完成语义，无内核可用补丁。 | [R1.2-E](../docs/R1.2-E_两阶段停止模型与内核准入阻塞.md) |
| **R1.2-F** | 把 Apple IOGraphics-599 + XNU 11417.121.6 精确锁定在 macOS 15.5 官方发布源；[CI #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259) 5 Git blob + 12 结构条件、24 模型通过；ABBA 条件风险仍在。 | [R1.2-F](../docs/R1.2-F_macOS15.5发行源码锁序核验.md) |
| **R1.2-G** | 上游 `IOFramebuffer::handleVBL` 消费 shmem/timer 资源，不能盲目将回调派发到 FB gate 外；epoch/ticket 抽象模型 16/16、363 状态。正式 [#38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141) 10 结构项 + D/E/G 合计 40/40 **模型**，仍 NO-GO。 | [R1.2-G](../docs/R1.2-G_VBL门锁外派发与生命周期审查.md) |
| **R1.2-H** | 纠正连续 VBL 微调引起的方向偏移：内屏实际接 Intel；停止继续 VBL 补丁，RTX 2050 与 Intel 显示的真实运行证明优先。 | [R1.2-H](../docs/R1.2-H_HONOR技术路线重评与准入门禁.md) |
| **R1.3-A** | 比较 `NMIntelFB` 固件现有平面接管 vs 新的 `NMXGPU` i915→DRM→IOFramebuffer；固定 NullMoth v1.14.2 7 个源码 blob，18 个源码结构条件核对（**非 CI**）。发现 NMXGPU VBL 注销/禁用空实现。 | [R1.3-A](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md) |
| **R1.3-B** | 独立 FreeBSD `drm-kmod` 6.14 候选 i915 明确有 `46A6`、eDP、GGTT；但不等于 NullMoth 构建输入。NMX framebuffer 对 CPU 物理地址连续提出额外条件。 | [R1.3-B](../docs/R1.3-B_46A6_i915构建依赖与GGTT_eDP准入核查.md) |
| **R1.3-C** | 固定 v1.14.2 的 `srclist.py` 缺失诊断被重定向、i915 构建失败计数不强制中止、旧对象 glob 链接风险；对已发布二进制完整性没有证明。 | [R1.3-C](../docs/R1.3-C_NMXGPU构建来源与对象完整性门禁.md) |
| **R1.3-D** | [Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373) 发布包 SHA256 一致、172 路径、1 个 NMXGPU 二进制、已知名称的源码/对象清单 0；上游 [Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) 已提交。发现 `NVRMFBClaim` 广域匹配 Intel framebuffer，[Issue #119](https://github.com/nullmoth/nvidia-macos-driver/issues/119)、[PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131)。 | [R1.3-D](../docs/R1.3-D_发行包证据入口与Intel屏幕抢占风险.md) |
| **R1.4-A** | 不再以复现 NullMoth 预编译包为自主开发前提；自主 i915 Intel-only，先 L1 真实内屏、后 L2 Metal、最后 L3 RTX 混合渲染。 | [R1.4-A](../docs/R1.4-A_自主适配Intel46A6_技术架构与最小可行路线.md) |
| **R1.4-B** | 第一性原理审查：拒绝 `Stolen base == GGTT 0 == 活动 scanout`、关键初始化假成功 Stub、CI=可加载；定位 Linux v6.1 / FreeBSD drm-kmod 6.1-lts **候选**，尚未做自己的驱动 native build。 | [R1.4-B](../docs/R1.4-B_方案批判性审查与独立源码基准.md) |
| **R1.4-C0 首轮** | 接管后固定 FreeBSD 14.3.0 base 候选，156 条源锁/许可、92 定义/79 关系、14 类 XNU 必需接口；25 项离线负向测试通过。完整闭包门禁退出 2；没有 native/硬件，仍 NO-GO。 | [首轮交付](../docs/R1.4-C0_独立i915源码与接口依赖基线.md) |

**历史结论不需要反复跑：** R1.2-C 的旧 Intel 编译、R1.2-F/G 的 Apple 源码/模型、R1.3-D 的发布包路径索引。只有新版本、出现与旧结论冲突的新证据或新增独立可证伪假设才启动新的实验。**整个项目至今没有 Intel 46A6 的 macOS 内屏实机画面，也没有 RTX2050 Metal 运行证明。**
