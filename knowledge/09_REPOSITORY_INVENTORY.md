# 09｜GitHub 仓库现存研究资产全量索引

**盘点时点：2026-10-12，主分支**。本文件尽可能覆盖知识库建立前的所有核心工程资产：**24 份原始 `docs/`、7 个 `scripts/`、11 个 `tests/`、10 个 Actions、3 个 patch**。创建知识库后还新增 `AGENTS.md` 与 `knowledge/` 下的新文件；以实际 GitHub tree 为准。

## 原有 docs/（24 份，不移走、不删除）

| 文件 | 研究范围 |
|---|---|
| [`HONOR_GLO-FX6P_硬件实测与证据等级.md`](../docs/HONOR_GLO-FX6P_硬件实测与证据等级.md) | 本机硬件与 Intel 内屏已确认事实 |
| [`R0.7_build_gate.md`](../docs/R0.7_build_gate.md) | NVIDIA NVAccel native 构建前置阻塞 |
| [`R0.8_intelfb_compile.md`](../docs/R0.8_intelfb_compile.md) | NMIntelFB 初次原生编译 |
| [`R0.9_results_and_R1.0_gates.md`](../docs/R0.9_results_and_R1.0_gates.md) | 静态 kext bundle 与运行时准入区别 |
| [`R0.9_static_kext_audit.md`](../docs/R0.9_static_kext_audit.md) | plist、设备表、Mach-O 验证 |
| [`R1.0_跨驱动安全审计与准入结论.md`](../docs/R1.0_跨驱动安全审计与准入结论.md) | VRAM actualSize、copy bounds、MMIO、VBL 问题 |
| [`R1.1_CI结论与R1.2并发修复准入.md`](../docs/R1.1_CI结论与R1.2并发修复准入.md) | 容量补丁 CI 与 VBL 准入 |
| [`R1.1_候选修复与验证边界.md`](../docs/R1.1_候选修复与验证边界.md) | R1.1 修改内容、限制 |
| [`R1.2-A_VBL状态机与XNU接口审查.md`](../docs/R1.2-A_VBL状态机与XNU接口审查.md) | 初始 VBL 状态模型 |
| [`R1.2-B_VBL候选补丁与准入.md`](../docs/R1.2-B_VBL候选补丁与准入.md) | 工作循环与计时器改造 |
| [`R1.2-C_回调重入引用保护与残余风险.md`](../docs/R1.2-C_回调重入引用保护与残余风险.md) | retain、双模式编译与失败归因 |
| [`R1.2-D_双Workloop锁序与重入停止风险审计.md`](../docs/R1.2-D_双Workloop锁序与重入停止风险审计.md) | ABBA/SYS-FB |
| [`R1.2-E_两阶段停止模型与内核准入阻塞.md`](../docs/R1.2-E_两阶段停止模型与内核准入阻塞.md) | quiesce/drain/finalize 模型 |
| [`R1.2-F_macOS15.5发行源码锁序核验.md`](../docs/R1.2-F_macOS15.5发行源码锁序核验.md) | Apple 15.5 固定源码 hash |
| [`R1.2-G_VBL门锁外派发与生命周期审查.md`](../docs/R1.2-G_VBL门锁外派发与生命周期审查.md) | ticket/epoch 与 IOFramebuffer handleVBL |
| [`R1.2-H_HONOR技术路线重评与准入门禁.md`](../docs/R1.2-H_HONOR技术路线重评与准入门禁.md) | 冻结 VBL、Intel 内屏优先 |
| [`R1.3-A_IntelXe46A6显示输出双路线源码核验.md`](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md) | NMIntelFB/NMXGPU 架构比较 |
| [`R1.3-B_46A6_i915构建依赖与GGTT_eDP准入核查.md`](../docs/R1.3-B_46A6_i915构建依赖与GGTT_eDP准入核查.md) | FreeBSD PCI/eDP、构建 provenance、GGTT backing |
| [`R1.3-C_NMXGPU构建来源与对象完整性门禁.md`](../docs/R1.3-C_NMXGPU构建来源与对象完整性门禁.md) | source list 缺失、旧对象、链接完整性 |
| [`R1.3-D_NullMoth_NMXGPU_构建证据请求_EN.md`](../docs/R1.3-D_NullMoth_NMXGPU_构建证据请求_EN.md) | 上游公开 Issue #146 的历史工作稿 |
| [`R1.3-D_发行包证据入口与Intel屏幕抢占风险.md`](../docs/R1.3-D_发行包证据入口与Intel屏幕抢占风险.md) | 172 路径与 NVRMFBClaim/PR |
| [`R1.4-A_自主适配Intel46A6_技术架构与最小可行路线.md`](../docs/R1.4-A_自主适配Intel46A6_技术架构与最小可行路线.md) | 独立自研、L1/L2/L3 成功等级 |
| [`R1.4-B_方案批判性审查与独立源码基准.md`](../docs/R1.4-B_方案批判性审查与独立源码基准.md) | BIOS stolen 误区、版本对齐与假成功 Stub |
| [`研究状态账本_防重复工作规则.md`](../docs/研究状态账本_防重复工作规则.md) | 旧有项目状态与重复工作规则 |

## scripts/（7 个，所有脚本适用范围有边界）

| 文件 | 职责 |
|---|---|
| [`verify_pinned_source.py`](../scripts/verify_pinned_source.py) | 固定上游源结构/内容的静态完整性核验 |
| [`validate_intelfb_bundle.py`](../scripts/validate_intelfb_bundle.py) | NMIntelFB bundle 结构静态检查 |
| [`r12e_stop_source_gate.py`](../scripts/r12e_stop_source_gate.py) | 旧候选 stop 源码 fail-closed 风险扫描 |
| [`r12f_verify_macos155_sources.py`](../scripts/r12f_verify_macos155_sources.py) | Apple 15.5 发行源码版本/锁序检查 |
| [`r12g_verify_iofb_vbl_consumer.py`](../scripts/r12g_verify_iofb_vbl_consumer.py) | IOFramebuffer VBL 消费者结构审查 |
| [`r12h_windows_readonly_display_probe.ps1`](../scripts/r12h_windows_readonly_display_probe.ps1) | Windows 只读 GPU/显示信息（**不是走线/MUX 证明**，勿重复要求内屏测试） |
| [`r13a_intel_scanout_source_audit.py`](../scripts/r13a_intel_scanout_source_audit.py) | NullMoth v1.14.2 的 7 blob/18 contract 检查；不等于 CI 或实机验证 |

## tests/（11 个，历史参考模型和编译 smoke）

- [`abi_smoke.cpp`](../tests/abi_smoke.cpp)、[`kernel_header_smoke.cpp`](../tests/kernel_header_smoke.cpp)：头文件/ABI compile smoke。
- [`test_r10_bounds_model.py`](../tests/test_r10_bounds_model.py)、[`test_r11_patch_contract.py`](../tests/test_r11_patch_contract.py)：VRAM/容量、旧候选补丁约束。
- [`test_r12_vbl_lifecycle_model.py`](../tests/test_r12_vbl_lifecycle_model.py)、[`test_r12b_patch_guards.py`](../tests/test_r12b_patch_guards.py)：旧版 VBL 状态与补丁。
- [`test_r12c_patch_guards.py`](../tests/test_r12c_patch_guards.py)、[`test_r12c_reentrant_stop_model.py`](../tests/test_r12c_reentrant_stop_model.py)：callback 目标引用/重入模型。
- [`test_r12d_lock_order_model.py`](../tests/test_r12d_lock_order_model.py)、[`test_r12e_quiesce_finalize_model.py`](../tests/test_r12e_quiesce_finalize_model.py)：跨 workloop ABBA 与 stop/drain。
- [`test_r12g_vbl_ticket_model.py`](../tests/test_r12g_vbl_ticket_model.py)：ticket/epoch callback 与取消参考模型。

## .github/workflows/（10 个，只可用户手动启动）

| workflow | 验证用途 |
|---|---|
| [`macos-preflight.yml`](../.github/workflows/macos-preflight.yml) | R0.6 macOS hosted preflight |
| [`nvaccel-build-gate.yml`](../.github/workflows/nvaccel-build-gate.yml) | R0.7 NVIDIA Darwin 构建条件，而非已成功编译 NVAccel |
| [`intelfb-native-compile.yml`](../.github/workflows/intelfb-native-compile.yml) | R0.8 Intel framebuffer 原生编译 |
| [`intelfb-package-audit.yml`](../.github/workflows/intelfb-package-audit.yml) | R0.9 静态 bundle/plist/Mach-O 审计 |
| [`r11-review-patch.yml`](../.github/workflows/r11-review-patch.yml) | R1.1 scanout/MMIO 候选 |
| [`r12b-vbl-review.yml`](../.github/workflows/r12b-vbl-review.yml) | R1.2-B workloop timer 候选 |
| [`r12c-reentrant-vbl-review.yml`](../.github/workflows/r12c-reentrant-vbl-review.yml) | R1.2-C callback lifetime 双模式 |
| [`r12f-apple-155-lock-audit.yml`](../.github/workflows/r12f-apple-155-lock-audit.yml) | R1.2-F Apple 发行源码锁序 |
| [`r12g-vbl-dispatch-review.yml`](../.github/workflows/r12g-vbl-dispatch-review.yml) | R1.2-G ticket/epoch consumer source/model |
| [`r13d-release-provenance-index.yml`](../.github/workflows/r13d-release-provenance-index.yml) | R1.3-D 发行包 SHA/文件名目录，正式一次检查已完成 |

## patches/（3 份，**冻结、不可直接部署**）

- [`r11_scanout_bounds_and_mmio.patch`](../patches/r11_scanout_bounds_and_mmio.patch)：容量边界/MMIO，审查候选。
- [`r12b_vbl_workloop_gate.patch`](../patches/r12b_vbl_workloop_gate.patch)：旧 VBL IOTimerEventSource 候选。
- [`r12c_vbl_callback_lifetime.patch`](../patches/r12c_vbl_callback_lifetime.patch)：旧 callback owner/event source retain 候选。

上述三补丁的历史依赖顺序 `R1.1 → R1.2-B → R1.2-C`；R1.2-D/E/F/G 发现了尚未关闭的 stop/callback 安全问题，**不得将其视为可投产或已加载的驱动**。

## 仓库新增交接资产

根目录 [`AGENTS.md`](../AGENTS.md)，`knowledge/00–10` 汇总和决策文件。新的研发工作在 `research/independent-i915/` 下以可核对的 manifest 和调用图为起点；首次实现需按 [10](10_CODEX_HANDOFF.md) 的验收工作，不是再复制一批旧模型。
