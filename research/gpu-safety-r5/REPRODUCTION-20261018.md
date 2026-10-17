# 复现手册（R1–R20，2026-10-18）

目的：别人（或半年后的我）拿到这棵树时，**按主题**知道每个补丁改什么、依赖上游哪些形状、
怎么验证、上游一改哪里会失效。表格里的文件/行数是从补丁本身解析出来的，不是手写。

当前状态：19 个补丁的正反向通过（树哈希 `ea9467f4cca9c823` → 应用 → 复原），
最近门禁 run `39056924734`，门禁覆盖 16 个编译单元与 4 个 kext 链接目标。

## 0. 怎么用这份手册

1. 取上游 `nvidia-macos-driver` @ `ac55984c473e746c2a8ebea7ba0913461aa7c393`；
2. 按序列依次 `git apply`（顺序不可换，后面的补丁依赖前面的上下文）；
3. 用 `scripts/gpu-safety-r5/native_compile.py` 跑门禁，看 16/16 与告警零增量；
4. 任何一步失败，先看下面「脆弱锚点」，多半是上游动了同一个标识符。

## 1. 按主题分组

### 生命周期与所有权（NVIDIA）

这些补丁全部依赖 `NVRMNVDAFramebuffer` 的成员名与 `gDev/gDevUsers/gDevOrphaned/gHeadsTaken` 这几个文件级全局。上游一旦改名或改变共享方式，它们会一起失效——这也是为什么它们被串成一条序列而不是散装。

| 补丁 | 文件数 | hunk | +/− |
|---|---|---|---|
| `nullmoth-r5-kms-close-deferred.patch` | 1 | 2 | +17/−3 |
| `nullmoth-r6-kms-close-reclaim.patch` | 1 | 5 | +21/−1 |
| `nullmoth-r7-kapi-device-rollback.patch` | 1 | 4 | +30/−0 |
| `nullmoth-r8-shared-device-lifetime.patch` | 1 | 7 | +56/−28 |
| `nullmoth-r9-pm-gated-device-teardown.patch` | 2 | 3 | +26/−0 |
| `nullmoth-r10-nvrmfb-production-lifetime.patch` | 1 | 7 | +54/−1 |
| `nullmoth-r11-orphan-device-recovery.patch` | 1 | 4 | +28/−0 |
| `nullmoth-r12-serialize-device-state.patch` | 1 | 2 | +13/−0 |
| `nullmoth-r14-orphan-ownership-fix.patch` | 1 | 5 | +34/−6 |
| `nullmoth-r15-pm-pin-teardown.patch` | 2 | 9 | +46/−6 |

### Intel 内屏（NMIntelFB）

依赖 `fVblTimer`/`fStopping`/`fSurfMap`/`fCopyLock` 与 `NVRM_VRAM_FN_*` 三个字符串常量。R17/R19 还依赖 `nvrm-accel.cpp` 里的 `nvAccelCopyToScanout` 形状。

| 补丁 | 文件数 | hunk | +/− |
|---|---|---|---|
| `nullmoth-r16-intel-bounded-vbl-teardown.patch` | 1 | 1 | +15/−2 |
| `nullmoth-r17-intel-owner-copy.patch` | 5 | 9 | +104/−1 |
| `nullmoth-r18-intel-restart-safety.patch` | 1 | 4 | +13/−5 |
| `nullmoth-r19-owner-copy-without-kva.patch` | 1 | 2 | +10/−3 |
| `nullmoth-r20-intel-register-dump.patch` | 1 | 2 | +15/−0 |

### 桥接与旧线（历史，仍在序列里）

R1 依赖 `intelfb.cpp` 的 VRAM 请求路径与 `fStopping`；R4 依赖 bridge 的 owner 语义。这几个是早期工作，保留是为了让序列可完整回退。

| 补丁 | 文件数 | hunk | +/− |
|---|---|---|---|
| `gpu-safety-r1.patch` | 3 | 17 | +83/−32 |
| `gpu-safety-r2-kms-open.patch` | 1 | 3 | +22/−4 |
| `nullmoth-r3-thread-call-comment.patch` | 1 | 1 | +2/−2 |
| `nullmoth-r4-bridge-owner.patch` | 2 | 12 | +134/−14 |
| `ogkm-r3-kapi-null-free.patch` | 1 | 1 | +5/−0 |

### 文档/状态（不含代码）

只改 knowledge 文档，不参与编译。

| 补丁 | 文件数 | hunk | +/− |
|---|---|---|---|
| `project-status-r1.patch` | 5 | 5 | +20/−0 |
| `project-status-r2.patch` | 5 | 5 | +40/−0 |

## 2. 脆弱锚点（两个以上补丁共用，上游一改就整串失效）

从补丁的**上下文行**里提取——它们必须仍以原样存在于上游文件中，补丁才能应用。

| 标识符 | 出现在几个补丁 |
|---|---|
| `NVKMS` | 9 |
| `fDev` | 8 |
| `gHeadsTaken` | 8 |
| `FBLOG` | 7 |
| `NvKmsKapiDevice` | 7 |
| `fHead` | 7 |
| `fKms` | 7 |
| `gDev` | 7 |
| `gpuId` | 6 |
| `IOLockLock` | 5 |
| `NULL` | 5 |
| `NVRMNVDAFramebuffer::kapiInit` | 5 |
| `fGpuId` | 5 |
| `fOwnsHead` | 5 |
| `grabOwnership` | 5 |
| `privateData` | 5 |
| `GPU` | 4 |
| `IOLockUnlock` | 4 |
| `LOST` | 4 |
| `NVAccel` | 4 |
| `NVKMS_KAPI_MAX_CONNECTORS` | 4 |
| `NVRM` | 4 |
| `NvKmsKapiAllocateDeviceParams` | 4 |
| `NvU64` | 4 |
| `OSSafeReleaseNULL` | 4 |

**解读**：`fDev`/`gDev`/`gDevUsers`/`gHeadsTaken` 这些共享状态是最脆的——它们同时被 5–8 个补丁
引用。上游若把共享设备改成 per-instance，R5–R15 整段都要重做；反之若只是内部重构，补丁可能仍能应用。

## 3. 每个补丁验证什么（与验收等级对应）

| 层级 | 怎么验 | 覆盖哪些补丁 |
|---|---|---|
| PATCH-APPLIED | `work/roundtrip_r5.py`（正反向 + 树哈希） | 全部 |
| HOST-TEST | `work/run-r11-test.sh`（WSL + ASan，提取真实函数体） | R5–R12、R14–R15 |
| SOURCE-STRUCTURE | `work/check_r11_lifetime.py`（50/50）、`work/check_intel_stop.py`（30/30） | R9–R20 |
| DARWIN-COMPILE | Actions 门禁，16 个单元，告警差分 | 全部 |
| KEXT-LINK | NVAccel / NVRMFB / NMIntelFB ×2 | R1、R4、R10–R20 |
| KEXT-LOAD 及以上 | **未做**（需实机） | — |

## 4. 上游变更时的处置顺序

1. 先跑 `work/roundtrip_r5.py`——应用失败会立刻告诉你是哪一段；
2. 再看失败补丁的「脆弱锚点」是否改名；
3. 只修**最早**失败的那个补丁，后面的重新生成（序列是累积 diff，不是独立补丁）；
4. 重新跑门禁，确认 16/16 与告警零增量都还在。

## 5. 明确不做的事

- 不把补丁合并成一个「大补丁」——那样上游一变就无从定位；
- 不为通过门禁而放宽告警策略（R10 曾因此返工）；
- 不在没有实机证据时宣称任何 KEXT-LOAD 及以上等级。

## 6. 证据文件

- `evidence/repro/patch-dependencies.json`（本文件的机械来源）
- `evidence/roundtrip.json`、`evidence/ci-r5/verification.json`
- `REA-NVRM-BINARY-20261018.md`、`INTEL-REGISTER-AUDIT-20261018.md`、`ACCEPTANCE-MATRIX-20261018.md`
