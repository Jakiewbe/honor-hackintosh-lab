# 05｜上游源码、版本锁与相互关系

**三条独立链，绝不能混为一谈：** ① 最初审计的 NullMoth 固定 commit；② 2026-10-12 调研时 NullMoth v1.14.2 发布版；③ 我们自主 Intel-only 研发选取的 FreeBSD/Linux 6.1 **候选**。第三条不代表第二条实际构建输入。

## A. macOS 15.5 发行版公开源码（R1.2-F 已验证）

| 组件 | 明确 commit / Git blob | 用途 |
|---|---|---|
| Apple IOGraphics-599 | [commit `4d3fd008c80d1414c9da8f02ea67d534b47158c2`](https://github.com/apple-oss-distributions/IOGraphics/tree/4d3fd008c80d1414c9da8f02ea67d534b47158c2) | macOS 15.5 版 IOFramebuffer 生命周期和显示接口 |
| `IOFramebuffer.cpp` | blob `4763b2fc53cbcaeb2ad5c94531727975d6bc0ff8` | `SYS→FB` 停止锁序、`handleVBL` 与内存共享状态 |
| `IOFramebuffer.h` | blob `8bf176f408ccaf902f0c07689a3785c8efabb5a4` | `getApertureRange` / `getInformationForDisplayMode` / mode + interrupt APIs |
| Apple XNU 11417.121.6 | [commit `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`](https://github.com/apple-oss-distributions/xnu/tree/a1e26a70f38d1d7daa7b49b258e2f8538ad81650) | macOS 15.5 XNU 内核公共源码 |
| `IOWorkLoop.cpp` | blob `1d93f463c39d7bb688d7311ef411ed5ef916a147` | 工作循环命令门、重入 |
| `IOTimerEventSource.cpp` | blob `0ee1fe90653d0babb85e71c84d35ad8db8160fdf` | VBL timer action/超时释放 |
| `IOEventSource.cpp` | blob `8323ce3120ac913e6b35dade31472653cf61af77` | owner 与事件源生命周期 |
| SDK & CI | `macos-15-intel` / Xcode **16.4** / SDK **15.5** | 旧 `NMIntelFB` native build 证据，不证明将来可长期获取相同 GitHub Runner |

参考：[R1.2-F](../docs/R1.2-F_macOS15.5发行源码锁序核验.md)、[正式 CI](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)。**已检查过的 blob 不应无新增依据反复校验**。公开源码版本和实际发行二进制并不必然同等于运行时锁/符号安全的全部证明。

## B. 早期 NullMoth / NVIDIA 固定版本

- NullMoth 初期审计源：[commit `0960b2ef5dbc4a573056d4c8e042a5bd2e15d651`](https://github.com/nullmoth/nvidia-macos-driver/tree/0960b2ef5dbc4a573056d4c8e042a5bd2e15d651)，研究对象 `kexts/NMIntelFB/intelfb.cpp`、`display_ids.inc`、`kexts/NVRM/accel/nvrm-accel.cpp`、`kexts/NVRMFB/fb/nvrm-fb.cpp`、`nvrm_vram_abi.h`；R1.1/R1.2 patch 基于这一固定树按顺序叠加。
- NVIDIA 官方 [open-gpu-kernel-modules release 610.57.04](https://github.com/NVIDIA/open-gpu-kernel-modules/tree/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb)，对应 commit **`e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`**。NullMoth NVAccel Darwin build 依赖生成的 `src/nvidia/_out/Darwin_x86_64/compile_cmds.sh`；该版本公开源码里未提供，**本项目没有完整 NVAccel native build**。报告：[R0.7](../docs/R0.7_build_gate.md)。

## C. NullMoth 发布版 v1.14.2（2026-10-12 调研时最新，非永久“最新”）

- 上游 tag [v1.14.2](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v1.14.2) 精确代码 commit **[`1083a98db33a0bb824290556de255f9a95ca5403`](https://github.com/nullmoth/nvidia-macos-driver/tree/1083a98db33a0bb824290556de255f9a95ca5403)**。
- 新 Intel/AMD `NMXGPU` 路线：`gpu-port/xkpi/xnu/nmx_kext.cpp`、`nmx_fb.cpp`、`override/src/nmx_fb_bridge.c`、`gpu-port/README.md`；`NMXGPU` 仍无可靠真实 Intel GPU macOS 加载证据。
- 旧 Intel `NMIntelFB` 保留固件 plane 接管依赖；NVIDIA `NVRMFBClaim` [Info.plist](https://github.com/nullmoth/nvidia-macos-driver/blob/1083a98db33a0bb824290556de255f9a95ca5403/kexts/NVRMFB/fb/Info.plist) 中 `IONameMatch=display` + 高 probe score 无厂商限定，muxless 风险见 [Issue #119](https://github.com/nullmoth/nvidia-macos-driver/issues/119)、[PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131)。
- R1.3-A 固定 7 个 Git blob 和 18 结构检查见 [报告](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md)、[`scripts/r13a_intel_scanout_source_audit.py`](../scripts/r13a_intel_scanout_source_audit.py)。
- 上游 i915 构建脚本使用开发者本地外部 `drm-kmod`、`freebsd-src`、`linux-6.14`、`amd.flags`、`srcs-i915.txt`、`obj-i915/*.o`；没有本项目可验证的完整 release build manifest。请求 [Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) 已提交。
- 发行主包 SHA256 **`7c7f7ac97dbcdd48786d4384ffcb2d19199b6d3bc0fb013c71f63b766dea6be5`**，172 路径清单的正式记录在 [R1.3-D](../docs/R1.3-D_发行包证据入口与Intel屏幕抢占风险.md)。路径 0 匹配只能证明**对应命名不在这一个归档中**，不代表上游一定没源码或发布物有 bug。

## D. 自主 Intel-only 研究采用的**候选**源，不应冒充已完成依赖闭包

| 仓库 | 固定输入 | 当前阶段 |
|---|---|---|
| Linux i915/DRM 参考 | [Linux v6.1 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476) | 已定位 `i915_gem_stolen.c`、`gt/intel_ggtt.c`、`display/intel_dp.c`、`intel_dmc.c`、`intel_display_power.c`，但不是一套直接可编译的 XNU port |
| FreeBSD DRM 6.1 | [`freebsd/drm-kmod` 6.1-lts commit `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4) | [`include/drm/i915_pciids.h`](https://github.com/freebsd/drm-kmod/blob/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4/include/drm/i915_pciids.h) `INTEL_ADLP_IDS` 含 `46A6`；与 Linux v6.1 ABI 兼容性待查 |
| FreeBSD DRM **不同候选** | [master snapshot `c16de0f9fa84f70b9551f69fde837a7f3a73c0e9`](https://github.com/freebsd/drm-kmod/tree/c16de0f9fa84f70b9551f69fde837a7f3a73c0e9)，近 Linux 6.14 | 用于 R1.3-B 证明 ADL-P 表和 eDP/GGTT **存在**，**不是上面 6.1 源码的替代品** |
| FreeBSD base / LinuxKPI | **release/14.3.0 候选 `8c9ce319fef765890ce518cab85d3a470b669849`** | R1.4-C0 按固定测试矩阵选择并解析 tag；组合构建/ABI 未验收，PM 空实现不能当 XNU 电源成功 |
| Apple XNU/IOGraphics | 采用本页 A 的 macOS 15.5 提交 | 已做过源哈希调查；新的 KMS 使用 ABI 仍要独立证明 |

**后续锁定规则**：生成 `source_manifest.json`（repo、commit、relative_path、Git blob、license、patch）、`object_manifest.json`（源码→编译命令→对象 SHA→符号）、`compat_matrix.md` 和 delta 摘要；不因某个仓库有“6.1”标签就宣称全栈互通。

R1.4-C0 实际基线：[source-lock.json](../research/independent-i915/source-lock.json)、[license-manifest.csv](../research/independent-i915/license-manifest.csv)、[compat-notes.md](../research/independent-i915/compat-notes.md)。仅 source slice 和对象候选，无已编译 object/compiler/link manifest。
