# GPU 主线 R5–R7：关闭路径、回收者与初始化回滚

状态：**SOURCE-REVIEW + HOST-TEST + PATCH-APPLIED 已达成；DARWIN-COMPILE / KEXT-LINK 未运行；KEXT-LOAD 及 GPU/内屏加速 NO-GO。**

固定输入：NullMoth `v2.3.3` / `ac55984c473e746c2a8ebea7ba0913461aa7c393`；OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`。

## 三个补丁修了什么

| 补丁 | 文件 | 问题 | 修法 |
|---|---|---|---|
| `nullmoth-r5-kms-close-deferred.patch` | `kexts/NVRM/os-nvkms-xnu.cpp` | `kms_close_common()` 在 PM 等待失败后仍清 `popen->data` 并释放 wrapper。而 `nvidia-modeset-os-interface.h:288-301` 规定该指针就是 NVKMS 之后回传 `nvkms_event_queue_changed()` 的 `pOpenKernel`，于是 NVKMS 会写进已释放内存 | 失败即保留 per-open / wrapper / event worker，置 `closing`、拒绝新 ioctl、返回失败；不再把"没关成"当"关好了" |
| `nullmoth-r6-kms-close-reclaim.patch` | `kexts/NVRM/NVRM.cpp` | r5 之后隔离态没有回收者：唯一的重试入口没有调用者，泄漏无界且不可观测 | 隔离时计数，`gpuResume()` 在 `nv_xnu_pm_open()` 之后、PM 线程、非回调上下文扫一次回收；只读 sysctl `debug.nvrm_kms_close_deferred`；唤醒失败时不递减、不假装成功 |
| `nullmoth-r7-kapi-device-rollback.patch` | `kexts/NVRM/fb/nvrm-fb.cpp` | `kapiInit()` 先建共享 `NvKmsKapiDevice`（`gDev`）并 `grabOwnership`，再查显示器；查不到就返回失败，两样都不收回。后续 framebuffer 会复用它，而它的 `privateData`/`eventCallback` 指向已失败的实例 | RAII 回滚：仅自建 Device 才 `releaseOwnership` + `freeDevice` + 清 `gDev`；复用路径不碰 Device，但归还本次占用的 head 位；成功时解除 |

应用顺序（顺序敏感，缺一不可）：

```
gpu-safety-r1.patch → gpu-safety-r2-kms-open.patch → nullmoth-r3-thread-call-comment.patch
→ nullmoth-r4-bridge-owner.patch → nullmoth-r5-kms-close-deferred.patch
→ nullmoth-r6-kms-close-reclaim.patch → nullmoth-r7-kapi-device-rollback.patch
```

## 已实测（本机隔离工作区 `D:\Hactk\gpu-r5-20261017`）

| 项 | 级别 | 结果 |
|---|---|---|
| 7 补丁完整源码正向 + 反向 | PATCH-APPLIED | 全部 exit 0；611 文件树哈希 pristine `ea9467f4…` → applied → 复原 `ea9467f4…` |
| 关闭合同（真实函数体 + ASan/UBSan） | HOST-TEST | 候选 40/40；改前实现触发 heap-use-after-free，释放栈在 `kms_close_common` 内 |
| bridge-owner（含隔离计数） | HOST-TEST | 9/9 |
| 回滚析构器 | HOST-TEST | 15/15 |
| 调用点/计数合同 | SOURCE-STRUCTURE | 12/12 |
| 回滚作用域/所有权合同 | SOURCE-STRUCTURE | 14/14 |

## 同轮记录的证据问题

- **R4 门禁口径**：`scripts/gpu-safety-r4/native_compile.py` 自加 `-Wextra -Werror`，而上游 `build/accel_build.sh` 只用 `-Wall` + 三条 `-Wno-*`。因此上次 R4 运行在**未改动的原版对象**上也失败（`IOPCIDevice` 弃用被升级为错误），对候选零信息量。r5 门禁改为上游口径，并新增"候选不得比原版多告警"的差分检查与 NVAccel kext 链接步骤。
- **R4 fixture 与最终补丁不一致**：已发布的 `evidence/r4/bridge-owner-actual.cpp` 中 `sKms`/`sKmsEvents` 含两行最终补丁并不存在的会话锁，`inputs.json` 记录的 `NVRM.cpp` 哈希也因此不可复现。该锁**不能补回**：`externalMethod` 已持非递归 `IOLock` 再分发到 `sKms`，第二次获取会死锁。

## 如何运行本门禁（仅手动）

GitHub UI → Actions → **HONOR GPU safety R5 native object and kext link gate** → Run workflow，
分支 `main`，`xcode=Xcode_16.4`。它会：

1. 校验两个固定 commit；
2. 在完整源码上按序 `git apply --check` 并应用 r1–r7；
3. 用上游 `accel_build.sh` 口径编译 original/candidate 五个 C++ TU 与 KAPI C 单元；
4. 比较每单元告警数（候选不得多于原版）；
5. 用上游链接行链接 NVAccel kext（只链接，不加载）；
6. 上传文本诊断与 `native-report.json`。

**不会**安装、加载、签名或运行任何驱动，也不访问 GPU。

## 仍未闭合

- `super::start()` 在 `kapiInit` 成功后失败，以及最后一个 framebuffer 停止 / kext 卸载，都没有对称销毁路径（F5b）。
- `freeDevice()` 返回 void，销毁失败不可上报；该路径必须先经原生门禁。
- KAPI 事件回调与 Device 销毁的先后顺序、PM busy 后仍进 standby、VRAM/GPUVA 跨 sleep 无代际、真实 IOMapper/IOVA 与 GSP DMA 静默——全部未验证。

## 原生门禁结果（2026-10-18，首次通过）

[Run 39048772269](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39048772269) — `completed success`，提交 `bfa7c3e`，`workflow_dispatch`，Intel runner。

- 工具链：macOS 15.7.9 (24G830) / Xcode 16.4 (16F6) / Apple clang 17.0.0 / macOS SDK 15.5 / GNU Make 4.4.1
- 补丁序列全部应用：r1 → r2 → r3注释 → r4 → r5 → r6 → r7 → OGKM
- **12/12 对象编译成功**（original 与 candidate 各 6 个 TU：NMIntelFB、NMIntelFBVirtual、NVAccel、NVKMSOS、NVRM、NVKAPI），每个对象都由门禁校验为 Mach-O 64-bit x86_64 `MH_OBJECT`
- **告警零增量**：original/candidate 每单元告警数完全相同（7/8/24/14/33），补丁没有引入任何新诊断
- **KEXT-LINK 通过**：NVAccel kext 按上游 `build/accel_build.sh` 链接行生成，244400 字节，
  `sha256 89f9839e0f39bccf1336672e0f8a5e8c047dfd8408d3fe5d1d4e6128095e6cf1`；
  唯一输出是三条 `ld` 警告（SDK 15.5 静态库按 15.0 部署目标链接）

**本轮达到的证据等级：`DARWIN-COMPILE` + `KEXT-LINK`（仅链接，未签名、未加载）。**
`KEXT-LOAD` / `GPU-RUNTIME` / `DISPLAY-RUNTIME` / `ACCELERATED-DESKTOP` 仍为 **NO-GO**：
本次没有加载任何驱动，也没有访问 GPU。

已知遗留（下一轮门禁修正项）：链接行沿用上游写法，缺少 `-mmacosx-version-min=15.5`，因此三条 ld 部署目标
警告属于配置不一致而非源码问题；`super::start()` 在 `kapiInit` 成功后失败、以及最后一个 framebuffer 停止 /
kext 卸载时的对称销毁仍缺（F5b）。
