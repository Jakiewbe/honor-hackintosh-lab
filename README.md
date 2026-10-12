# HONOR Hackintosh Lab — Intel + NVIDIA macOS Compatibility Research

> **Codex handoff / 当前权威入口（2026-10-12）**：**先读 [AGENTS.md](AGENTS.md) → [knowledge/README.md](knowledge/README.md) → [当前状态](knowledge/02_CURRENT_STATE.md) → [Codex 交接任务](knowledge/10_CODEX_HANDOFF.md)**。原 README 以下的 R0.6–R1.4-B 章节是**历史过程记录**，不能单独代表当前准入等级；阶段/源码/实验、冻结工作及实际 CI 以知识库和原始报告为准。
>
> **最新策略：自主 Intel `8086:46A6` 内屏 L1 研究；FreeBSD/Linux 6.1 同系列源码仅为候选；自主驱动未进行 native build 或实机运行；`RUNTIME_NO_GO`。** 已确认内屏在 Windows 连接 Intel 核显、独显实测为 RTX 2050 `10DE:25A9`（非 3050）。**不得触碰主力 Windows、EFI、BIOS、磁盘、安全设置，不得加载/签名 kext；不得代用户启动 Actions。**

> **R1.4-C0 首轮新增：** FreeBSD 14.3.0 base 候选已固定为 `8c9ce319fef765890ce518cab85d3a470b669849`；156 条文本源锁、92 函数定义、79 条源码关系；新增离线测试 **25 通过、0 失败**。**完整依赖闭包仍 BLOCKED，禁止进入编译/部署**。见 [正式报告](docs/R1.4-C0_独立i915源码与接口依赖基线.md) 与 [工程入口](research/independent-i915/README.md)。

## Codex 交接与研发知识库

- **[项目目标与愿景](knowledge/00_PROJECT_CHARTER.md)** · **[硬件档案](knowledge/01_HARDWARE_BASELINE.md)** · **[当前状态](knowledge/02_CURRENT_STATE.md)** · **[首个开发任务包](knowledge/10_CODEX_HANDOFF.md)**
- **[全部研究历史](knowledge/03_RESEARCH_HISTORY.md)** · **[真实 CI/证据账本](knowledge/04_EVIDENCE_LEDGER.md)** · **[外部源码版本锁定](knowledge/05_SOURCE_LOCKS.md)**
- **[架构与风险](knowledge/06_ARCHITECTURE_AND_RISKS.md)** · **[决策日志](knowledge/07_DECISIONS.md)** · **[自主开发路线](knowledge/08_ENGINEERING_ROADMAP.md)** · **[原有文件完整索引](knowledge/09_REPOSITORY_INVENTORY.md)** · **[1401/OpenCore 早期调查与纠错](knowledge/11_EARLY_RESEARCH_AND_1401.md)**

**Codex 下一任务 R1.4-C0.1**：固定 FreeBSD 14.3 生成配置/include 次序，补齐 PCI→probe→Power Well 的直接/传递接口与许可，制定 XNU 电源状态和资源清理合同。已有源码 slice 不等于完整闭包。详细验收与禁止事项见 [10_CODEX_HANDOFF.md](knowledge/10_CODEX_HANDOFF.md)。

---


**Research-only repository. Do not deploy drivers to the primary Windows laptop.**

Target hardware:
- HONOR GLO-FX6P / Intel Core i5-12500H
- Intel Iris Xe iGPU: `8086:46A6` (internal display connected to Intel)
- NVIDIA RTX 2050 Laptop GPU: `10DE:25A9`

**Historical original reference (R0–R1.2):** [NullMoth NVIDIA macOS Driver](https://github.com/nullmoth/nvidia-macos-driver), pinned at `0960b2ef5dbc4a573056d4c8e042a5bd2e15d651`. Later v1.14.2 and our independent Linux/FreeBSD 6.1 source candidates use **different commits**; see [source locks](knowledge/05_SOURCE_LOCKS.md).

## R0.6: Manual macOS Intel preflight

The [Actions workflow](.github/workflows/macos-preflight.yml) runs **only on explicit manual dispatch** using `macos-15-intel`. It requests GitHub token permission `contents: read`, has a 12-minute job timeout, and does not use secrets or upload artifacts.

### Run the first check

1. Go to **Actions** → **HONOR R0.6 macOS Intel preflight**.
2. Choose **Run workflow** on `main`.
3. Choose **mode: preflight** and click **Run workflow**.
4. Wait for the run result. Share its run URL or copied failure details for analysis.
5. **Only after preflight succeeds**, optionally choose **mode: source**. It fetches the pinned upstream Git commit, checks known source blob hashes, and compiles a standalone C++ x86_64 ABI smoke binary.

The first check uses a hosted Mac and consumes GitHub Actions capacity; review your GitHub billing settings before triggering it. Public repository standard GitHub-hosted runners are generally free under GitHub's public-repository rules. No run has been initiated by this repository setup.

### Scope and validation limits

This workflow can check Xcode 16, x86_64, Kernel.framework headers, the selected macOS SDK, pinned source integrity and a standalone ABI layout smoke test.

It **does not** compile, sign, install, load, test or distribute an NVIDIA/Intel kernel extension. It never modifies an EFI, BIOS, disk partition, or the primary HONOR Windows installation. Success does **not** prove RTX 2050 Metal support or Intel Iris Xe laptop display output.

### Files

- [`.github/workflows/macos-preflight.yml`](.github/workflows/macos-preflight.yml) — manual-only macOS Intel Actions workflow.
- [`scripts/verify_pinned_source.py`](scripts/verify_pinned_source.py) — read-only commit and source blob integrity checks.
- [`tests/abi_smoke.cpp`](tests/abi_smoke.cpp) — standalone C++ x86_64 ABI check, not a kext compile.

## R0.7: Real macOS kernel compilation gate (experimental)

The [manual-only R0.7 native build gate](.github/workflows/nvaccel-build-gate.yml) adds an x86_64 kernel-header compile probe, checks fixed NullMoth and NVIDIA r610 source commits, and reports whether the NVIDIA-generated Darwin compiler metadata is available. It does **not** install or load drivers; compiler outputs are never uploaded.

Start with **Actions → HONOR R0.7 NVAccel build gate → Run workflow → mode: prerequisites**. Read the [R0.7 guide](docs/R0.7_build_gate.md) before running. A successful *prerequisites* check is **not** a successful NVAccel kext build: official NVIDIA Linux source currently lacks the required Darwin-generated build metadata.

## R0.9: Static NMIntelFB kext package audit

R0.8 successfully linked the original NMIntelFB source into an x86_64 Mach-O kext bundle, but that says nothing about whether it can load or drive a screen. The [R0.9 manual-only package inspection workflow](.github/workflows/intelfb-package-audit.yml) now verifies complete temporary bundle metadata, macOS 15.5 deployment target, Mach-O type and Intel `8086:46A6` source-table coverage without ever loading or publishing a driver.

[Detailed safety and test scope](docs/R0.9_static_kext_audit.md). Run manually on GitHub Actions only after reviewing your usage/billing settings.

## R1.0: Source security audit (no new cloud build)

The [cross-driver source audit and go/no-go checklist](docs/R1.0_跨驱动安全审计与准入结论.md) examines Intel MMIO bounds, the `nvScanoutInfo` capacity ABI, NVIDIA-to-Intel copy bounds, VBL lifetime and asynchronous transaction completion. This follows the successful **static** R0.9 CI, and must not be mistaken for real-device graphics support.

The standalone [13-case offline safety contract model](tests/test_r10_bounds_model.py) is runnable locally with `python3 tests/test_r10_bounds_model.py`. **The model tests proposed failure predicates, not existing NullMoth driver behavior or patched source.** No new workflow is needed. No hardware or Windows settings are changed.

## R1.1: Review-only fail-closed candidate patch

[Review the R1.1 safety patch and limitations](docs/R1.1_候选修复与验证边界.md). The [candidate unified diff](patches/r11_scanout_bounds_and_mmio.patch) fixes NMIntelFB's BAR0 read window guard and scanout mapping-size reporting, adds source/destination bounds checks to NVAccel's active display-pipe copy path, and disables the unreviewed async flip enqueue site. It is **not** installed or automatically applied to any machine.

The [manual-only qualification workflow](.github/workflows/r11-review-patch.yml) validates a pinned temporary upstream checkout, checks patch reversibility and offline bounds cases, then attempts to compile only the patched Intel framebuffer source on hosted macOS. NVIDIA NVAccel native compilation, driver loadability, VBL lifetime and real hardware acceleration remain unverified.

## R1.2-A: VBL lifetime design, before a kernel patch

The [R1.2-A XNU API review and state-machine analysis](docs/R1.2-A_VBL状态机与XNU接口审查.md) documents timer reentrancy hazards, workloop-gate semantics, interrupt unregister obligations and stop/release ordering. The [deterministic Python model](tests/test_r12_vbl_lifecycle_model.py) passed 10 tests and explored 61 unique states up to depth 9 locally. **No R1.2 kernel patch is claimed or deployed**; reentrant stop from inside a callback remains a hard blocker. Existing R1.1 source fixes are unchanged.

## R1.2-B: Review-only gated VBL patch (not runtime qualified)

The [R1.2-B technical note](docs/R1.2-B_VBL候选补丁与准入.md) records a [stacked VBL patch](patches/r12b_vbl_workloop_gate.patch) that follows R1.1, replacing raw VBL thread calls with `IOTimerEventSource` and serializing callback registration/unregistration with `IOWorkLoop::runAction`.

[Manual-only cloud qualification](.github/workflows/r12b-vbl-review.yml) checks the pinned two-patch stack, runs offline capacity and lifecycle models, and attempts the patched Intel framebuffer native build. **No R1.2-B macOS build has run yet.** Callback-reentrant stop and runtime timer failure recovery remain unresolved; the candidate is not suitable for loading or installing.

## R1.2-C: Callback owner/sender lifetime candidate (not runtime qualified)

The [R1.2-C callback lifetime patch](patches/r12c_vbl_callback_lifetime.patch) is designed to be stacked **after** R1.1 and R1.2-B. It retains the `NMIntelFB` owner and `IOTimerEventSource` sender while an external VBL callback may synchronously unregister or stop the framebuffer, then releases both only after post-callback state checks. This addresses one potential dangling-access window; it **does not** establish safe reentrant `IOFramebuffer::stop`.

The [manual R1.2-C CI](.github/workflows/r12c-reentrant-vbl-review.yml) has now **passed in full** in [run #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450): pinned reversible R1.1 + R1.2-B + R1.2-C patches, **37/37 abstract reference model tests**, all source-invariant gates, and native x86_64 compile+link for **both real and `NMINTELFB_VIRTUAL` builds** with Xcode 16.4 / macOS 15.5 SDK. Both are Mach-O kext bundles. [Detailed evidence and remaining blockers](docs/R1.2-C_回调重入引用保护与残余风险.md). This does **not** prove safe recursive `IOFramebuffer::stop`, kernel loadability, panel takeover, NVAccel, RTX 2050, or Metal. No binaries were uploaded or installed.

## R1.2-D: Two-workloop lock-order audit (runtime NO-GO)

The [R1.2-D lock-order audit](docs/R1.2-D_双Workloop锁序与重入停止风险审计.md) cross-references public Apple IOGraphics `IOFramebuffer::stop` (`SYS → FB`) with the R1.2-C VBL callback which invokes external code while holding the framebuffer controller gate (`FB`). If that callback synchronously requests stop while another thread already holds SYS and waits for FB, the two threads can form an **ABBA wait cycle**. This is a **conditional source-derived risk**, *not an observed macOS 15.5 or HONOR deadlock*.

The [12-case reference lock-order test script](tests/test_r12d_lock_order_model.py) documents the counterexample, correct gate release, deferred-stop ordering and recursion conditions. This script has **not been run in GitHub Actions**. No new kext patch or workflow was launched: R1.2-C remains both-mode native **BUILD-PASS / RUNTIME-NO-GO**. The next gate requires an independently reviewable non-reentrant quiesce/finalize design and version-matched IOGraphics evidence.

## R1.2-E: Two-stage stop model and explicit runtime no-go

The [R1.2-E design review](docs/R1.2-E_两阶段停止模型与内核准入阻塞.md) documents the quiesce/finalize reference protocol for callback-triggered `stop()`, `terminate()`, and target destructor reentrancy. Its [12-case deterministic model](tests/test_r12e_quiesce_finalize_model.py) passed locally and explored 113 states through depth 8; **this models a hypothetical safe external finalizer, which has not been implemented or proven in IOKit**. An additional [source risk gate](scripts/r12e_stop_source_gate.py) explicitly returns NO_GO on the existing three-patch candidate rather than inferring hardware safety from a green build.

**No R1.2-E kernel patch, new CI run, or device changes.** R1.2-C still has successful real/virtual x86_64 links, but the reverse `FB→SYS` lock acquisition and callback target final release remain unresolved, as do NVIDIA NVAccel native build and RTX 2050 Metal support.

## R1.2-F: Official macOS 15.5 release-matched SYS/FB evidence

Apple's official [`distribution-macOS/macos-155/release.json`](https://github.com/apple-oss-distributions/distribution-macOS/blob/macos-155/release.json) pins **IOGraphics-599** at `4d3fd008c80d1414c9da8f02ea67d534b47158c2` and **xnu-11417.121.6** at `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`. At those exact release source revisions, both `IOFramebuffer::stop` and `terminate` acquire **SYS before FB**, while the VBL event action invokes external callbacks under the controller FB gate. This validates the conditional lock-order inversion risk for the **official macOS 15.5 public source**; it does not demonstrate that a particular Mac or the HONOR actually deadlocks.

The [detailed R1.2-F evidence report](docs/R1.2-F_macOS15.5发行源码锁序核验.md) records source Git blob SHAs, matched functions and unresolved callback contracts. The [read-only pinned-source checker](scripts/r12f_verify_macos155_sources.py) and [manual-only GitHub Actions audit](.github/workflows/r12f-apple-155-lock-audit.yml) have now been verified by [successful run #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259): **5/5 Apple Git blobs**, **12/12 source contracts**, and **24/24 abstract lock-order/stop model tests** (113 enumerated stop states). No kernel patch, kext loading, deployment, or local machine action has occurred. Current state: **R1.2-C dual native BUILD-PASS / R1.2-F RELEASE-SOURCE-MATCHED / RUNTIME-NO-GO**.

## R1.2-G: VBL dispatch outside FB gate — reference model, NOT a driver patch

The [R1.2-G architecture review](docs/R1.2-G_VBL门锁外派发与生命周期审查.md) cross-checks macOS 15.5's IOGraphics `handleVBL` consumer against the published `IOFramebuffer::stop` resource-release path. **Moving the external VBL callback outside the FB workloop gate may avoid one ABBA path, but it introduces unresolved callback self-join and concurrent framebuffer shared-state teardown hazards.** `handleVBL` updates VBL timing/counters, signals semaphores and schedules timer events; retaining the target alone does not protect all associated resources.

The [out-of-gate callback ticket/epoch reference model](tests/test_r12g_vbl_ticket_model.py) passed **16/16 local tests**, enumerating **363 states at depth 8**. The [IOGraphics-599 pinned VBL contract checker](scripts/r12g_verify_iofb_vbl_consumer.py) confirms 10 source facts (checked against pinned Apple source through the GitHub connector). The [manual-only R1.2-G workflow](.github/workflows/r12g-vbl-dispatch-review.yml) **passed in [Actions #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)**: 10/10 pinned IOGraphics VBL source contracts, 40/40 D/E/G reference tests, R1.2-E 113 states and R1.2-G 363 states. Passing these offline models does not establish that an out-of-gate callback worker or synchronous `IOService::stop` can be implemented safely. No kernel patch, kext load or primary-Windows change. **R1.2-G remains RUNTIME_NO_GO.**

## R1.2-H: Re-focus on actual HONOR graphics feasibility — freeze VBL patches

**Project goal:** determine whether the HONOR GLO-FX6P / i5-12500H / Intel Iris Xe `8086:46A6` / NVIDIA RTX 2050 Laptop `10DE:25A9` can obtain **usable macOS graphics**, not just compile an isolated Intel framebuffer object. [R1.2-H route evaluation and strict no-go gates](docs/R1.2-H_HONOR技术路线重评与准入门禁.md).

**Decision: VBL PATCHES FROZEN / RUNTIME-NO-GO.** R1.2-C real and virtual modules compile; R1.2-F/G confirm version-matched Apple source contracts and reference models, but no runtime or hardware proof follows. Further VBL micro-patches should wait until real graphics routing and accelerator viability are established.

The currently published [NullMoth v1.14.2 release](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v1.14.2) is a relevant **unverified vendor-supplied** build lead, not approval for installation. [CARD-SUPPORT.md](https://github.com/nullmoth/nvidia-macos-driver/blob/main/docs/CARD-SUPPORT.md) still lists Ampere physical validation as pending; the `25A9` RTX 2050 device ID is in the table but has no qualifying test. The new **NMXGPU** path for Intel Iris Xe is explicitly a test driver with **no verified Intel GPU run** as of its release notes. [An issue on a muxless MSI laptop (#135)](https://github.com/nullmoth/nvidia-macos-driver/issues/135) reports an NVIDIA device showing Metal 3 while the internal panel remains frozen — independent self-report, not evidence about this HONOR.

**The HONOR internal panel is already confirmed connected to Intel Iris Xe in Windows** (previous user test, re-affirmed on 2026-10-12): do **not** request the same “Advanced display → Connected to” internal-screen screenshot again. The user also reported a working USB-C→DP 1080p/200 Hz external screen, which establishes display capability, **not** which GPU owns that port. HDMI/USB-C GPU ownership and MUX switching are still unverified. The [canonical hardware evidence ledger](docs/HONOR_GLO-FX6P_硬件实测与证据等级.md) differentiates these facts. Focus next on Intel `8086:46A6` macOS scanout (or a proven NVIDIA→Intel scanout bridge), independent RTX 2050 Metal evidence, and only optionally external-port routing. The [Windows read-only probe](scripts/r12h_windows_readonly_display_probe.ps1) is available for non-duplicative follow-up, but is **not required to re-prove panel ownership**. No Windows, EFI, BIOS, partition, SIP or macOS security changes; do not run third-party installers.

## R1.3-A: Intel Iris Xe 8086:46A6 scanout is now the primary feasibility gate

The HONOR internal panel is **already confirmed to scan out through Intel Iris Xe in Windows**. [R1.3-A source-anchored route review](docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md) compares two **unverified macOS** approaches against NullMoth [v1.14.2 commit `1083a98db33a0bb824290556de255f9a95ca5403`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403):

- **Old `NMIntelFB` + NVIDIA NVAccel** only adopts a **still-active firmware Intel pipe** with a **linear XRGB8888 plane**, then exposes an Intel scanout CPU mapping for NVIDIA's head-4 copy path. Its successful R1.2-C native build does **not** show this firmware state survives actual macOS takeover or that RTX 2050 accelerates.
- **New `NMXGPU` Intel `i915` + DRM client modeset + `NMXGPUFB`** has a real source path for setting display modes and publishing a scanout buffer, more directly aligned with the HONOR panel. However upstream explicitly states its GPU port **has not been loaded on hardware**. `NMXGPUFB::unregisterInterrupt()` and `setInterruptState()` are currently no-ops, and its raw VBL timer and synchronous `stop()` still lack proven lifetime synchronization. No Intel 46A6 macOS scanout or Metal runtime evidence.
- The [source-only R1.3-A gate](scripts/r13a_intel_scanout_source_audit.py) pins seven upstream Git blob SHAs and 18 observed structures; **18/18 were inspected directly from GitHub, not run as CI**. It always retains **RUNTIME_NO_GO**.

**Decision: VBL PATCHES FROZEN; prioritize independent physical evidence for the Intel `8086:46A6` i915 bridge, then consider the NVIDIA→Intel display-copy route only if hardware evidence justifies it.** The AMD/Intel `vk_chip_matrix` 41/41 results use a mock/noop DRM shim, not real GPU execution. No GitHub workflow launched, kernel patch installed, or HONOR Windows/EFI/BIOS/disk change.

## R1.3-B: Alder Lake-P 46A6 i915 build-input and GGTT scanout preconditions

[**R1.3-B report**](docs/R1.3-B_46A6_i915构建依赖与GGTT_eDP准入核查.md) first cross-checked **all existing repository reports, scripts, tests and workflows**, then pursued the unresolved upstream i915 provenance and actual framebuffer mapping.

- NullMoth [v1.14.2 `1083a98...`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403) builds i915 from **external** `drm-kmod` and FreeBSD LinuxKPI trees, and Linux 6.14, through local `/Volumes/MiniData/build/gpu-src/` paths and generated flags/object lists. The exact external dependencies and actual linked `46A6` path are **not established** by this release repository.
- An **independent, candidate-only** [FreeBSD drm-kmod snapshot `c16de0f...`](https://github.com/freebsd/drm-kmod/tree/c16de0f9fa84f70b9551f69fde837a7f3a73c0e9) confirms `0x46A6` under `INTEL_ADLP_IDS` and the corresponding i915 PCI/display device tables, along with eDP and GGTT source code. **Its identity with NullMoth's build inputs is unverified.**
- `nmx_fb_bridge.c` requires the scanout CPU mapping's page translations to present one **physically consecutive address range**, using `pmap_find_phys`; i915's GGTT address continuity alone does not prove that contract. The actual mapping may be RAM or BAR-backed, so this is a **conditional compatibility gate**, not a demonstrated failure on the HONOR.
- **No further VBL patch or repeated CI** until the build provenance, buffer backing and i915 eDP scanout path are auditable. Intel internal-panel ownership is already confirmed; no screenshot repeat or host changes.

To prevent repetitive work, **read the [persistent research gate ledger](docs/研究状态账本_防重复工作规则.md) before every future phase**: it lists verified CI outcomes, unresolved P0 gates, and explicit stop/duplication rules. **R1.3-B SOURCE-REVIEW COMPLETE / BUILD-PROVENANCE-BLOCKED / SCANOUT-UNPROVEN / RUNTIME-NO-GO.**

## R1.3-C: upstream NMXGPU/i915 build provenance remains unverified

Before proceeding, the [project evidence ledger](docs/研究状态账本_防重复工作规则.md) and [R1.3-B report](docs/R1.3-B_46A6_i915构建依赖与GGTT_eDP准入核查.md) were checked; no previous CI or VBL reference tests were rerun.

The [R1.3-C release-pinned audit](docs/R1.3-C_NMXGPU构建来源与对象完整性门禁.md) identifies **three distinct missing completeness checks in NullMoth v1.14.2**: `srclist.py` emits missing-source messages to stderr but `all-i915.sh` suppresses them; `all-i915.sh` counts compiler failures without a mandatory nonzero exit; and `obj-i915/*.o` can be linked by `kext/build.sh` without a clean-object manifest or strict source/object set comparison. These are **conditional build-integrity weaknesses**, not proof the distributed binary is incomplete.

The v1.14.2 GitHub Release has a compiler-input **NMXNPU** source archive generated by `kext-npu/mksource.sh`, but no separately listed equivalent NMXGPU GPU-source archive. The contents of the 371 MB distribution tarball have **not** been audited; therefore we do not assert that no GPU-related source files exist inside it. The actual drm-kmod, FreeBSD LinuxKPI and Linux source commits, generated `amd.flags`, `srcs-i915.txt`, per-object SHA records and linker manifest **remain missing from our evidence**. The independent FreeBSD candidate commit from R1.3-B is **not** proven to be the release's build input.

**Decision:** No new kernel patch, repetitive build CI or host modification. Prioritize a **version-matched upstream build-input and object manifest** before resuming Intel GGTT/eDP scanout mapping research. **R1.3-C PROVENANCE-UNRESOLVED / RUNTIME-NO-GO**.

## R1.3-D: obtain actual upstream release evidence; new Intel framebuffer conflict

After reviewing the [research ledger](docs/研究状态账本_防重复工作规则.md) and [R1.3-C](docs/R1.3-C_NMXGPU构建来源与对象完整性门禁.md), the [R1.3-D source/evidence assessment](docs/R1.3-D_发行包证据入口与Intel屏幕抢占风险.md) found **one new release-artifact question and one new independent display-integration risk**:

- Published NullMoth [v1.14.2](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v1.14.2) offers a complete compiler-dependency source bundle for **NMXNPU**, but no separately named NMXGPU/i915 source bundle. The **371,689,122-byte** distribution tar has now been SHA256-verified and **inventoried in [manual Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373)**: 172 archive paths, one published `NMXGPU.kext/Contents/MacOS/NMXGPU` binary, and **zero path matches for known `amd.flags`, `srcs-i915.txt`, i915 objects, drm-kmod/FreeBSD/Linux input trees or compiler/link manifests**. The [manual-only workflow](.github/workflows/r13d-release-provenance-index.yml) listed filenames without extraction/execution and uploaded **text only**. This does not rule out differently named or externally published source records. **Do not rerun; this release archive index is complete.**
- [Upstream Issue #119](https://github.com/nullmoth/nvidia-macos-driver/issues/119) records a **different** muxless Intel-panel laptop without a working GUI because NVIDIA's `NVRMFBClaim` took Intel's `IOFramebuffer` matching category. The **exact v1.14.2** [`NVRMFB/fb/Info.plist`](https://github.com/nullmoth/nvidia-macos-driver/blob/1083a98db33a0bb824290556de255f9a95ca5403/kexts/NVRMFB/fb/Info.plist) still includes an unrestricted `IONameMatch=display` `NVRMFBClaim` with probe score 30000. [Upstream PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) proposing NVIDIA vendor/class matching is **open/unmerged as reviewed**. This is **conditional risk**, not proof the HONOR itself black-screens.
- The scoped [English upstream build-manifest request](docs/R1.3-D_NullMoth_NMXGPU_构建证据请求_EN.md) was **publicly submitted as [NullMoth issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146)** on 2026-10-12 after confirming no matching answered issue. It requests the real v1.14.2 drm-kmod/FreeBSD/Linux source commits, `amd.flags`, i915 source/object inventory and link evidence. The issue is **open; no build provenance has been provided or verified yet**.

**No repeat CI, new VBL patch, NMXGPU build, actual driver execution, or host change.** The v1.14.2 archive has now been inventoried with a verifiable hash and the **upstream source-provenance request was submitted as issue #146**. Next action: review substantive maintainer replies or a new version-matched source/manifest, **not** repeat CI or open duplicate issues. **R1.3-D RELEASE-INDEX-PASS / I915-PROVENANCE-BLOCKED / IGPU-FBCLAIM-RISK / RUNTIME-NO-GO.**

## R1.4-A: independent Intel 46A6 macOS display-driver research

**We are no longer blocked on NullMoth's own unreleased compiler manifests to begin original development.** They remain necessary only to reproduce **its particular published NMXGPU binary**. [R1.4-A engineering architecture and hardware gates](docs/R1.4-A_自主适配Intel46A6_技术架构与最小可行路线.md) defines a **new, independently version-pinned source and object chain** built from verifiable FreeBSD DRM/i915 + LinuxKPI + XNU/IOGraphics macOS 15.5 APIs. The target is the HONOR GLO-FX6P's **already verified Intel-connected internal panel**.

**The development order is strict:**
1. **L1 basic panel image:** firmware scanout handoff if its premises can be proven, otherwise independent Intel i915/DRM KMS→IOFramebuffer path; single internal panel, fixed mode, XRGB8888, no acceleration claim.
2. **L2 Intel acceleration:** only after scanout/display/stop lifecycle is genuinely observed on isolated non-primary Intel Xe hardware; Linux i915 code alone does not provide macOS Metal/IOAccelerator.
3. **L3 RTX 2050 Metal + NVIDIA→Intel composition:** independent future project after L1/L2 hardware evidence.

**First engineering gate R1.4-B:** pin our own FreeBSD source SHA (the previous [drm-kmod `c16de0f...`](https://github.com/freebsd/drm-kmod/tree/c16de0f9fa84f70b9551f69fde837a7f3a73c0e9) is a **candidate**), FreeBSD LinuxKPI, XNU/IOGraphics references, compile flags, per-file licenses, source/object sets and missing symbols; fail closed when missing. Design an **Intel-only** object subset, not the entire AMD/xe/NVIDIA port. Existing R1.2 CI and R1.3-D release archive inventory stay frozen; NVRMFBClaim's Intel slot conflict and CPU P/E-core platform boot requirements remain unresolved.

**Status: INDEPENDENT_PORT_DESIGN_ONLY / NO_NEW_DRIVER_BUILT / NO_RUNTIME_PROOF / RUNTIME_NO_GO.** No kernel extensions installed/loaded, no new Actions started, no main-Windows/BIOS/EFI/disk changes.

## R1.4-B: review of Intel 46A6 minimum-display assumptions

[First-principles technical review](docs/R1.4-B_方案批判性审查与独立源码基准.md) checks the proposed BIOS framebuffer reuse, stolen memory, i915 dependency trimming, IOGraphics interface and build acceptance criteria.

**Accepted:** investigate basic Intel scanout before acceleration. **Not established:** a macOS 15 WindowServer desktop automatically appears with any IOFramebuffer; GOP output guarantees firmware scanout survives takeover; stolen DRAM begins at GGTT offset zero; source linkage implies a loadable driver.

The 12th-gen Intel **BDSM 0xB0 belongs to the host bridge 00:00.0** and yields a stolen DRAM base, not a writable display plane. Linux 6.1 skips or reserves parts of stolen memory. An essential firmware, power, memory, or synchronization operation must not be replaced by a success-returning stub.

New independently pinned **candidate version pairing**: [FreeBSD drm-kmod 6.1-lts `dba60e1...`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4) and [Linux v6.1 `830b3c6...`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476), plus our previously pinned Apple IOGraphics 599. The FreeBSD base/LinuxKPI commit and true ABI/object closure are **not yet established**; a matched version label alone does not imply compatibility.

**Next:** identify the actual minimal i915/KMS/DRM/LinuxKPI/XNU source/symbol/ownership/licensing dependencies and verify them against a clean, reproducible build. No new driver build or hardware run has occurred. **RUNTIME_NO_GO** remains.

## Safety and evidence

The original NullMoth source carries a PolyForm Noncommercial license. No upstream source code or vendor firmware is copied into this repository. All upstream code is fetched from its public GitHub repository into an ephemeral runner only when source mode is explicitly requested.

The NVIDIA and Intel graphics bridge remains experimental. PCI device IDs in a source table and simulated tests are not sufficient proof of hardware acceleration or a working laptop screen.
