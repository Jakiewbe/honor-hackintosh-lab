> **2026-10-18 R79 审计纠错：** 已撤回“45个符号闭源”与“351→667证明增量闭包不收敛”；索引及同基线显式链接清单已修。固定346符号新扫描为337个词法候选、9个UNKNOWN，尚非对象闭包。27项工具测试和三组历史回归通过；加入六TU选定ABI布局诊断与严格文本发布。新Darwin/链接/ABI尚未执行。见 [本轮报告](R79-AUDIT-CLOSURE-GATE-20261018.md)。完整闭包与实机继续NO-GO。

> **R28：真实事务 owner-copy 错误传播候选。** 仅 Unsupported 回退；其他执行错误原样返回，symbol 分配失败返回 NoMemory。真实函数 CPU 合同 15/15、旧基线 6 个预期失败、编译失败负控和完整序列往返通过；新增原生门禁尚未执行。[报告与证据](R28-OWNER-COPY-ERRORS-20261018.md)。构建闭包/ABI 与 P0-1/P0-4 继续开放，实机 NO-GO。

> **2026-10-18 当前 G1 断点：构建闭包与 ABI。** 已定位的公开提供者仍需传递依赖与布局核验；不能以旧 R13/R48 文档认定源码缺失或必须转实机。见 [逐符号审计与下一步](G1-CLOSURE-ABI-AUDIT-20261018.md)。本轮新增 35 符号依赖表、跨三个 TU 的 altstack/NULL 栈条件风险证据及精确原生预处理/对象提供者采集入口；新增原生取证尚未运行。P0-1/P0-4 仍开放，KEXT-LOAD NO-GO。

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

### R22（2026-10-18）：安全收敛 —— 先修"改错了地方"

复审发现 R17–R19 改的是**死代码**，这条成立，我复核后确认：

```
$ grep -n nvAccelCopyToScanout kexts/NVRM/accel/nvrm-accel.cpp
32:   static bool nvAccelCopyToScanout(IOAccelResource2 *res);      ← 声明
2113: static bool nvAccelCopyToScanout(IOAccelResource2 *res)       ← 定义
```

**零调用点。** 真正跑的是 `NVDisplayPipe::performTransaction()`，它在 `askFramebufferForScanout()` 之后
直接往 `q.kva` 里拷贝。R17/R19 把 owner-copy 放进了没人调用的函数里，等于没改。

### R22 修的三件

1. **owner-copy 接进真实路径**（P0 功能缺口）：`performTransaction()` 现在先用几何信息尝试
   `NVRM_VRAM_FN_COPY`，成功即返回——**不碰 kva**；只有对端不实现时才回退到旧的 `q.kva` 拷贝。
   `q.kva` 从"必需"降级为"回退"。
2. **孤儿 grab 债务改成计数**（复审 P0-2）：`gOrphanGrab` 布尔改为 `gOrphanGrabs` 整数，
   两个 framebuffer 在 NVKMS 不可用时先后停止会记两笔债，`finishOrphanedDevice()` 用
   `while (gOrphanGrabs > 0)` 逐笔归还。新增回归场景 16（两笔债 → 两次 release → 一次 free）。
3. **VBL 调用持有对象引用**（复审 P0-3）：`armVbl()` `retain()`；若 `stop()` 有界窗口内仍无法
   `thread_call_free`，则把引用交给回调，回调在 `fStopping` 分支里 `release()`。
   这样"停止不再永久等待"的同时，**对象不会先死**。

### R22 没有修的两件（如实记录）

- **P0-1：`nvkms_xnu_suspend()` 仍在 5 s 超时后继续挂起**。pin 只降低窗口，不构成互斥。
  正确做法是把挂起改成"pin 未归零则推迟到最后一个 unpin 执行"，但那要动睡眠时序且我无法在离线下验证，
  **本轮不动**，留作 R23 的单一目标。
- **P0-4：`freeDevice()` 之后发现关闭被拒，仍然继续释放**。R21 只做到记录。要真正阻止，
  需要在 `freeDevice` 之前就确定"关闭会不会被拒"，而那需要 OGKM 改变 void 接口——不在本项目能力范围内。

### 顺带发现：我自己的测试脚本会假通过

改成计数后主机测试报 `COMPILE=1` 却仍打印 `38/38 passed`——因为它编译失败后**跑了上一次的旧二进制**。
已修 `run-r11-test.sh`：编译失败直接 `exit 2`，并删除旧产物。这也意味着 **R21 那次"38/38"其实没有
编译过**（缺 `nvkms_xnu_kms_close_deferred_count` 桩），是旧二进制在跑。已补桩，现在 **43/43 真通过**。

### 实测

[Run 39058264569](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39058264569) `success`：**22 个补丁**、**16/16 对象**、告警零增量；
NVAccel **248768 B**（R21 是 248584，+184 正是接进真实路径的代码）、生产 NVRMFB 315848 B；
结构合同 61/61 + 30/30；主机测试 **43/43**；20 补丁正反向树哈希复原。

## R21（2026-10-18）：把"不可上报"变成"可计数、可判定"

P0-2 的另一半是接口形状问题：`nvKmsClose()` / `FreeDevice()` 都是 `void`，NVKMS 拒绝关闭后调用方不可能知道。
之前这只被记为"不可关闭"。但"不能向上传播"不等于"无法观测"：

- `kms_close_common()` 在推迟分支里累加 `gKmsCloseDeferred`，并**区分原因**（PM 未运行 vs GPU LOST → `gKmsCloseDeferredLost`）；
- 新增 `nvkms_xnu_kms_close_deferred_count()` 供拆除路径取样；
- `dropKapiDevice()` 在 `freeDevice()` **前后**各取一次计数，出现增量就记录：
  "freeDevice returned but NVKMS refused the close … RM state may be split; the void interface cannot report this upward"。

这样一次真实加载后，日志里能直接回答"设备到底关干净了没有"，而不是只能看到"调用返回了、但不知道结果"。

**诚实的边界**：这仍然**不是**错误传播——调用方拿不到失败。它把"不可知"降级为"事后可判定"，
P0-2 的状态因此从「不可关闭」改为「竞态已关闭（R15）+ 失败可计数（R21）+ 无法向上传播（接口限制，仍开放）」。

实测（[Run 39057316645](RUN_URL)，`success`）：**21 个补丁**、**16/16 对象**、告警零增量；
生产 NVRMFB **315848 B**（R20 时 315744，差 104 B 正是取样与日志）、NVAccel 248584 B；
结构合同 **60/60**（新增 6 条：计数在推迟分支、原因分类、样本包住 freeDevice、拒绝必记日志）。

## R15（2026-10-18）：用 pin 而不是快照，关掉 P0-2 的竞态窗口

复审指出：`nvkms_xnu_pm_running()` 只是一次状态快照，检查完到真正释放之间 PM 可能变化。再加一次检查是表演，
所以这次改的是机制：

- `os-nvkms-xnu.cpp` 新增 `nvkms_xnu_pm_pin()/unpin()`：**只有在 NVKMS RUNNING 时才能拿到 pin**；
- `nvkms_xnu_suspend()` 在切到 SUSPENDED 之前**等待 pin 归零**（上限 5 s，超时记录并继续，避免挂起被永久卡住）；
- `dropKapiDevice()` 与 `finishOrphanedDevice()` 改成**先拿 pin 再拆除**，每条出口都 `unpin`；
  拿不到 pin 就走"保留 + 记 grab 债务"的既有路径。

仍然**没有**关闭的部分（如实记录）：`nvKmsClose`/`FreeDevice` 都是 `void`，NVKMS 拒绝关闭后 `FreeDevice()`
照样释放 RM 侧——这是 OGKM 的接口形状决定的，只能在"不要调用它"这一侧做防护（pin + 使用者计数），
无法让失败向上传播。P0-2 记为**"竞态窗口已关闭，不可上报的部分保留"**。

实测（[Run 39054729764](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39054729764)，`success`）：**15 个补丁**、**16/16 对象**、告警零增量；
NVRMFB kext **315744 B / 174 导出**。主机测试 **38/38**（新增 4 条 pin 平衡断言，含"拒绝 pin 时零配对"）；
结构合同 **50/50**（新增 pin 纪律、suspend 等待 pin、`!fDev` 早退不拿 pin）。

## R14（2026-10-18）：复审发现的 P0-1 返工 —— 孤儿回收会提前释放

复审给出的反例成立，我复现并修了：

> A、B 共享 `gDev`（`gDevUsers = 2`）→ GPU 挂起时 A 停止 → 置 `gDevOrphaned` 但**提前 return，没有减小计数**
> → GPU 恢复，C 初始化时 `finishOrphanedDevice()` **不检查还有谁在用**就直接 `freeDevice` 并把计数清零
> → B 的 `fDev` 成为悬空指针，且 B 自己那次 `grabOwnership` 永远没有配对释放。

三处缺陷，一处设计改动：

1. **PM-off 的 stop 现在放弃自己的槽位**（`gDevUsers--`）并把欠下的 grab 记成 `gOrphanGrab`，
   然后再把本例的 `fDev` 清空——它不再算作使用者。
2. **`finishOrphanedDevice()` 先看 `gDevUsers`**：还有人用就**只归还死者的 grab**，不释放设备；
   只有无人使用时才 `freeDevice`。这才是"全部使用者退出"的判定。
3. **创建者被 retain 到设备销毁为止**：`allocateDevice()` 把 `privateData`/`eventCallback` 烧进了创建者对象，
   所以创建者必须比设备活得久，否则即使计数正确，回调仍指向已释放的对象。设备最终释放时最后才 drop 这个 retain。

复查后仍**未关闭**的（如实记录）：

- **P0-2（NVKMS 关闭失败不可上报）**：`nvKmsClose`/`FreeDevice` 都是 `void`，NVKMS 拒绝关闭后 `FreeDevice()`
  仍会释放 RM 侧；`nvkms_xnu_pm_running()` 只是一次快照，检查与调用之间 PM 状态可变。
  **真正的修法是给 OS 层加一个 pin（挂起阻断）语义，而不是再加一次检查**——那需要改 `os-nvkms-xnu.cpp`
  的 suspend 路径，尚未实施。
- **P0-3（加载脚本）**：已**默认禁用**，见 `LOAD-EXPERIMENT-20261018.md` 顶部与脚本内的 exit 90 守卫；
  文档里"用户已授权"的表述已删除。
- **R13 口径**：改为"导出符号 649/17,679 ≈ 3.7%，体积 ≈ 2.15%"，并注明两者不同口径；
  结合 REA 的 7.93 MB 不透明载荷，"9 个 TU 不足以复现"成立，但**不能**据此推断其余实现不公开。

实测（[Run 39054243492](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39054243492)，`success`）：**14 个补丁**、**16/16 对象**、告警零增量；
NVRMFB kext **315680 B / 174 导出**（比 R12 的 311488 B 多 4 KB，正是这次所有权修复的体量）。
主机测试 **34/34**（新增"两个使用者 + 挂起停止 + 后来者回收"与"唯一使用者 + 挂起 + 回收"两个场景）；
结构合同 **45/45**（新增 9 条：计数递减、grab 债务、孤儿不越权释放、创建者 retain 配对）。

## R13（2026-10-18）：NVRM.kext 无法用公开源码重建（负结果，带数字）

问题：上游只发布 `NVRM.kext` 二进制，没有构建配方。能不能自己链一个？

做法：把 `kexts/NVRM/` 根目录下**全部 9 个 C++ 翻译单元**（`NVRM.cpp`、`os-xnu.cpp`、`os-xnu2.cpp`、
`os-nvkms-xnu.cpp`、`nv_xnu_stubs.cpp`、`nvrm_gpuva.cpp`、`nvrm_fbinfo.cpp`、`nvrm_surfshare.cpp`、
`nvkms_shaders.cpp`，不含 accel/agdc/fb 这些独立 bundle）编译并链接成 `NVRM.kext`
（[Run 39051715396](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051715396)，`success`，9/9 编译 exit 0，链接 exit 0）。

结果与发行版对照（Mach-O 解析，不是估算）：

| | 我们的链接产物 | 发行版 `NVRM.kext/Contents/MacOS/NVRM` |
|---|---|---|
| 大小 | **361,768 B** | **16,787,920 B**（2.15%） |
| `__TEXT` | — | 14,155,776 B |
| 符号总数 | 649 导出 | **34,302**（33,830 defined / 17,679 external） |

结论：**链接"成功"但只覆盖发行版约 2% 的符号**。仓库里也没有任何预编译对象（`kexts/NVRM` 下只有源码，
最大的是 325 KB 的 `nvkms_shaders.cpp`）。也就是说 `NVRM.kext` 的绝大部分输入不在公开树里——最可能是
OGKM 的 `nvidia-modeset` 核心源在私有构建里被一起编进去。

因此：**`KEXT-LINK` 的覆盖面仍然只有 NVAccel 与 NVRMFB**，不能把这次的 NVRM 产物当成"NVRM kext 可构建"。
门禁字段已改为 `KEXT-LINK_INCOMPLETE_UNIT_SET`，避免下一个人误读。

下一步（若继续这条线）：把 OGKM `src/nvidia-modeset/**.c` 纳入 NVRM 链接再比符号覆盖——但那是一个独立的
大工作量，且必须先把 `nvkms-kapi.h` 之外的内部头文件闭包固定下来。

## R12（2026-10-18）：共享 Device 状态的竞态

**先取证，再改。** 两条结论来自源码而不是推测：

1. **谁还能销毁这个 Device？** OGKM `nvkms-kapi.c`（固定 `e4a5faa`）里，`FreeDevice()` 只有一个非表项调用点——
   `AllocateDevice()` 自己的 `failed:` 分支（L988，此时设备从未交给我们）。也就是说：**设备一旦分配成功，
   除了我们自己的 `freeDevice()` 之外没有任何路径会销毁它**。这证明 `nvkms_xnu_pm_running()` 作为"
   设备是否还能被安全拆除"的判据是充分的（它回答的是 NVKMS 能不能碰 GPU，而不是设备是否存在）。
2. **`dropKapiDevice()` 没有持锁。** `kapiInit()` 在 `startLock()`（`IORecursiveLock`）里跑，
   `stop()` 只在更新 `gFBs[]` 时短暂持锁，然后**在锁外**于函数末尾调用 `dropKapiDevice()`。
   而 `gDev` / `gDevUsers` / `gDevOrphaned` / `gHeadsTaken` 是全局共享的——一个 framebuffer 在 stop、
   另一个在 start，就会在这些全局量上交错。

R12：`dropKapiDevice()` 与 `finishOrphanedDevice()` 都先取 `NVRMDisplayGate`（就是 `startLock()` 的 RAII
守卫，递归锁，所以 `kapiInit` 内的回滚可以安全重入）。拿不到锁就**保留设备并记日志**，不做无锁拆除。

实测（[Run 39051324224](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39051324224)，`success`）：**13 个补丁**、**16/16 对象**、告警零增量；
NVAccel kext 244400 B；NVRMFB kext **311488 B / 174 导出**（比 R11 的 311376 B 多 112 B，对应新增的守卫）。
主机测试 **22/22**；结构合同 **36/36**（含"drop 先取 gate""拒绝无锁拆除""bind 路径持锁跨 kapiInit"）。

## R11（2026-10-18）：给"保留"的共享 Device 一条恢复路径

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

