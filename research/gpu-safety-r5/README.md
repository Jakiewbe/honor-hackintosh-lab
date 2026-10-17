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

## R8 门禁：先抓出我自己的编译错误，再通过（2026-10-18）

加入 R8 后连续三次运行，过程本身是结论的一部分：

1. [Run 39049358408](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049358408) `success` — 但查看
   `native-report.json` 才发现：门禁的编译单元里**没有 `kexts/NVRM/fb/nvrm-fb.cpp`**，而 R7/R8 改的正是这个文件。
   也就是说那份"通过"对 R7/R8 零覆盖。
2. 把 `NVRMFB` 加入门禁后，[Run 39049526982](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049526982) **failure**：
   `error: 'dropKapiDevice' is a protected member of 'NVRMNVDAFramebuffer'`——**R8 原本编译不过**，
   因为回滚守卫是命名空间作用域的结构体，无权调用 protected 成员。主机测试与结构门禁都没发现，只有真正的
   Darwin 编译能发现。
3. 把守卫改成**类内嵌套类**（`NVRMNVDAFramebuffer::KapiRollback`），重新以 R1..R7 为基准生成补丁，
   [Run 39049760247](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049760247) `success`：8 个 NullMoth 补丁 + OGKM 补丁全部应用；
   **14/14 对象编译成功**（original 与 candidate 各 7 个 TU，新增 NVRMFB：两profile 均 exit 0、告警 25/25 相同）；
   NVAccel kext 仍然链接成功（244400 B，`sha256 89f9839e…`）。

教训写进流程：**"门禁通过"必须先核对门禁到底编译了哪些文件**，否则它只是证明了没被编译的那部分没问题。
### R9 门禁结果（2026-10-18）

[Run 39050097952](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050097952) `success`（提交 `c5e04ca`）：**10 个补丁**（9 个 NullMoth + OGKM）全部应用，
**14/14 对象编译成功**（含 NVRMFB），每单元告警数与 original 相同，NVAccel kext 链接成功（244400 B）。

### R11（2026-10-18）：给"保留"的共享 Device 一条恢复路径

R10 的规则是"NVKMS 不能调用时不拆除"，代价是有界泄漏。R11 把这个泄漏变成可恢复：

- `dropKapiDevice()` 在 PM 分支里置 `gDevOrphaned = true` 并保留句柄；
- 新增 `finishOrphanedDevice()`：**在下一次 start 时**执行（此时 NVKMS 必然可调用），
  先重新确认 `nvkms_xnu_pm_running()`，再 `releaseOwnership()`（那个死掉的实例抓过、且从未释放的正好一次）
  → `freeDevice()` → 清 `gDev` / `gDevOrphaned` / `gDevUsers`；
- `kapiInit()` 第一件事就是调用它，然后才考虑复用或新建 Device。

这样"睡眠中卸载"导致的孤儿设备不会在每个睡眠周期累积，而是下一次加载时被清掉；如果那时 GPU 仍不可用，
就继续保留，等下一次。

实测（[Run 39051079369](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051079369)，`success`）：**12 个补丁**、**16/16 对象**、告警零增量；
NVAccel kext 244400 B；**NVRMFB kext 311376 B、174 个导出符号**（比 R10 的 311192 B / 173 个各多一点点，
正好对应新增的那个函数）。主机测试 **22/22**（12 组场景，含"孤儿在 PM 恢复后被回收"与"仍挂起则继续保留"）；
结构合同 **32/32**（两个源文件，各自期望值不同）。

## 生产 NVRMFB 的 kext 链接（2026-10-18）

上一轮之前，`KEXT-LINK` 只覆盖 NVAccel。本轮把**生产** `NVRMFB`（单 TU）也链接起来，
链接行是 NVAccel 那行换对象与 bundle（上游没有为 NVRMFB 发布链接行，这一点在报告里标注）：

[Run 39050754261](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050754261) `success`：

| 项 | 结果 |
|---|---|
| 对象 | 16/16 exit 0（原版与候选各 8 TU，含生产 `NVRMFB` 与遗留 `NVRMFB_LEGACY`） |
| NVAccel kext | 链接成功，244400 B |
| **NVRMFB kext** | **链接成功**，311192 B，`sha256 f845538e…`，导出符号 173、未定义符号 481（内核/依赖导入，正常） |
| 发行版 NVRMFB 参照 | 306736 B，`sha256 6B8BEFFF…`（我们的产物大 1.5%，编译器与 SDK 不同 + 新增代码） |

这仍是 `KEXT-LINK_ONLY_NOT_LOADED`：只证明"能链成 Mach-O kext"，没有任何签名或加载。

### 附带结论：`kexts/NVRM/fb/` 是遗留副本

- `package/install.sh` 的 `KEXTS="NVRM NVAccel NVRMFB NVRMAGDC"`，装的是 `kexts/NVRMFB`；
- 上游自带测试（`test_bar1_budget.py`、`test_boot_raster_modes.py`、`test_display_power_retry.py` 等）全部读
  `kexts/NVRMFB/fb/nvrm-fb.cpp`；
- 没有任何构建脚本或测试引用 `kexts/NVRM/fb/nvrm-fb.cpp`。

所以 R7–R9 对那份旧拷贝的修改是**死代码修改**：对发行驱动无影响，保留它们只是为了不重写已验证的补丁序列；
真正生效的是 R10。门禁同时编译两者，是为了让"哪份被改、哪份没被编译"不再可能被忽略。

## R10 门禁结果（2026-10-18）

- [Run 39050444884](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050444884) **failure**：生产文件里 `extern "C" NvBool …` 被放在 `NvBool` 可见之前 →
  `error: unknown type name 'NvBool'`。同一轮还暴露 `rollback.armed = false` 被写到 `return true` **之后**
  （不可达 → 成功时会误拆设备），由结构合同的 "disarm before the success return" 检查抓出。
- 修正后 [Run 39050580870](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39050580870) `success`：**11 个补丁**、**16/16 对象**（original 与 candidate 各 8 个 TU，
  含生产 `NVRMFB` 与旧的 `NVRMFB_LEGACY`）、每单元告警数与 original 完全相同（生产 NVRMFB 34/34）、
  NVAccel kext 链接成功。

## R10（2026-10-18）：R7–R9 修错了文件——生产 NVRMFB 是另一个 `nvrm-fb.cpp`

仓库里有两个 `nvrm-fb.cpp`，两者的 `Info.plist`（`com.nullmoth.NVRMFB`）**完全一致**：

| 路径 | 行数 | 大小 | 内容差异 |
|---|---|---|---|
| `kexts/NVRM/fb/nvrm-fb.cpp` | 1631 | 90725 B | R1/R7/R8/R9 一直在改这个 |
| `kexts/NVRMFB/fb/nvrm-fb.cpp` | **3406** | **210016 B** | 额外包含 `nvrm-fb-safety.h`、`nvrm-allocation-table.h`、`nvrm_eld.h` |

用发行包 `release-v2.3.3.tar.gz` 里的 `NVRMFB.kext/Contents/MacOS/NVRMFB`（306736 B，
`sha256 6B8BEFFF…`）做字符串判别：

- 大文件独有串 **存在**：`hot-plug: display 0x%x … connected after boot`、`home flip #%u: pure`、`fbmodes: boot raster`
- 小文件独有串 **不存在**：`getPixelInformation ap %d`、`park ceiling reached`

也就是说**发行版 NVRMFB 是从 `kexts/NVRMFB/fb/nvrm-fb.cpp` 构建的**。R7/R8/R9 把关闭路径与共享 Device
生命周期修在了小文件上：对生产驱动**没有任何作用**，而生产文件里的同一批缺陷（`kapiInit` 失败留下
`gDev`、`super::start` 失败不回收、`stop()` 从不释放）仍然存在。

R10 把这些修复移植到生产文件：`extern "C" NvBool nvkms_xnu_pm_running(void)`、`gDevUsers` 计数、
`dropKapiDevice()`（PM 未运行则保留）、嵌套 `KapiRollback`、`kapiInit` 内绑定计数与
`fGrabbedOwnership`、`super::start` 失败与 `stop()` 的拆除调用。生产文件已有 `fOwnsHead`，head 位沿用
既有机制而不是新加字段。

门禁同时改为编译**两个**文件：`NVRMFB`（生产）与 `NVRMFB_LEGACY`（旧拷贝），避免再次出现"编译了没被使用
的文件"这种假通过。

结构合同对两个文件各跑一遍：**32/32**（含"disarm 必须在成功返回之前"——这条抓出了我移植时把
`rollback.armed = false` 写到 `return true` 之后的错误）。

## R9（2026-10-18）：拆除只允许发生在 NVKMS 能碰 GPU 的时候

R8 让 `stop()` 也走 `dropKapiDevice()`，但**没有检查 NVKMS 当时能不能被调用**。读 OGKM 源码
（`nvkms-kapi.c`，固定 `e4a5faa`）后确认这条链是危险的：

- `ReleaseOwnership()` 与 `KmsFreeDevice()` 都调用 `nvkms_ioctl_from_kapi()`
  （`NVKMS_IOCTL_RELEASE_OWNERSHIP` / `NVKMS_IOCTL_FREE_DEVICE`）；
- 我们的 OS 层把 `nvkms_ioctl_from_kapi` 映射到 `kms_ioctl_common()`，而它用
  `kms_pm_wait_locked(false, 30000)` **最多等 30 秒**，GPU LOST 时直接返回失败；
- `FreeDevice()` 不检查这些 ioctl 的返回值，仍会继续执行 `RmFreeDevice()` 与 `nvkms_close_gpu()`。

因此在挂起/丢失状态下从 `stop()` 拆除会产生两个后果：**最长 30 秒的阻塞**，以及**RM 侧被释放、KMS 侧被拒绝**
的撕裂状态——而 R5 的 `kms_close_common()` 又会在失败时保留 per-open，于是那个 per-open 的 `device` 指针
指向已被释放的对象。

R9 的做法：新增 `nvkms_xnu_pm_running()`（在 `gKmsLock` 下读 `gKmsPmState == kKmsPmRunning`），
`dropKapiDevice()` 在释放 ownership / 调用 `freeDevice()` 之前必须先问它；不满足就**原样保留**并记录日志，
head 位照常归还。这是有意的有界泄漏，换掉"阻塞 + 撕裂"。

实测：9 补丁完整源码正反向 exit 0（树哈希回到 `ea9467f4…`）；`dropKapiDevice()` 真实函数体主机测试 **16/16**
（含"NVKMS 未运行时不拆除"用例）；生命周期结构合同 **27/27**（含谓词位置与锁内读取）。

## R8（2026-10-18）：共享 Device 的生命周期闭环

R7 只处理了 `kapiInit()` 内部失败。R8 把同一件事做成可复用的成员函数 `dropKapiDevice()`，让三条路径共用：

| 路径 | 之前 | 现在 |
|---|---|---|
| `kapiInit()` 任一步失败 | R7 的作用域回滚 | 同一个 `dropKapiDevice()`（由 RAII 调用） |
| `super::start()` 在 `kapiInit` 成功后失败 | **Device 留在 `gDev`，`privateData` 指向即将释放的实例** | 调用 `dropKapiDevice()` |
| `stop()` / kext 卸载 | **从不释放，永久泄漏** | 归还自己的 ownership 与 head 位；最后一个使用者才 `freeDevice()` |

新增 `gDevUsers` 计数：每次绑定 +1，每次 drop -1；`remaining > 0` 时只放弃自己的引用、不销毁 Device，
归零时才 `freeDevice()` 并清 `gDev`（仍做身份比对，避免清掉别的共享设备）。"设备不能比它的 owner 活得更久"
因此有了明确判定，而不是依赖"只有一个 framebuffer"的假设。

实测：8 补丁完整源码正反向 exit 0（树哈希回到 `ea9467f4…`）；`dropKapiDevice()` 真实函数体主机测试
**12/12**（ASan+UBSan）；生命周期结构合同 **19/19**。

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

### 第二次运行（链接参数修正后，无任何诊断）

[Run 39049023927](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39049023927) 在 `3ef269e` 上同样 `completed success`：链接行补 `-mmacosx-version-min=15.5`
（与对象一致），三条 ld 部署目标警告消失，链接日志只剩 `ARGV` 与 `EXIT=0`。
**kext 字节与第一次完全相同**（244400 B，`sha256 89f9839e…5e6cf1`）——说明该参数只消除了诊断，
没有改变产物，这也反证第一次的告警是链接配置不一致而非源码问题。

已知遗留：`super::start()` 在 `kapiInit` 成功后失败、以及最后一个 framebuffer 停止 / kext 卸载时的
对称销毁仍缺（F5b）；共享 Device 的"最后使用者"判定尚未定义。
