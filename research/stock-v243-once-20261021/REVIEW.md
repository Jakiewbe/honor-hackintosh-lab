# NullMoth v2.4.3（47f818b）只读评估与 v2.4.2 两文件候选合并建议

日期：2026-10-21（Asia/Shanghai）
状态：**SOURCE-REVIEW / GO_COMPILE_ONLY（仅限受控回移） / DEVICE NO-GO**

## 0. 结论先行

1. **值得采纳的是 v2.4.3 的 ONCE 修复本身，不是“把 pin 升到 47f818b”。**
   `7dd3aeb` 修的是一个真实的 panic 路径：vblank/cursor 回调在仍运行时被反复
   `thread_call_enter`，每次都可能再起一个线程，直到 high 组 500 线程上限。
   ONCE 把重复进入折叠为至多一个待运行项，能消除这个无界增长。
2. **建议做“受控回移”（backport），保持上游 pin `272ccd9` 不变。**
   只把 ONCE 加到 10 个参数固定、可重入且 latest-wins 的回调；**不改**
   `gConnectNotify` 的两个分配点，因为它是一个全局 thread_call，却携带
   “哪个 framebuffer”的参数，ONCE 会把另一个 framebuffer 的通知折叠掉。
3. **不做整包 pin 迁移。** 47f818b 还包含 #294 的
   `plugin/NVMTLLibraryLoad.m` 改动和 CHANGELOG；它们不在两 TU 门禁范围内。
   整包迁移会让现有编译证据（run 39452257558）与候选哈希全部失效，收益不足。
4. **不把 ONCE 当作“回调串行化”或“完整安全关闭”。** ONCE 只限制 pending
   队列深度；它不提供互斥、不保证回调不在运行、不 retain 参数、不参与
   `stop()` 的排空决策。上游提交标题“one at a time”比提交正文更强；正文说的是
   “folds those entries into one more run”。
5. **设备维持 NO-GO。** 本轮没有链接、加载、运行或访问设备；没有触发任何
   GitHub Actions。

## 1. 固定输入与证据边界

| 项 | 值 |
|---|---|
| v2.4.3 release commit | `47f818b11cef59acb480210afdf9065fdd44e356` |
| 父提交 | `5e711be242a8b23f12bf15572a6993b6bd08ec9a` |
| tag | `v2.4.3`（轻量 tag，直接指向 47f818b） |
| 两文件候选 pin | `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`（v2.4.2） |
| OGKM pin | `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` |
| 既有候选 | `stock-v242-converged.patch`，NVRM.cpp + NVRMFB/fb/nvrm-fb.cpp |
| 既有原生产出 | run [39452257558](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39452257558)，artifact 12279222611，status `PASS_DARWIN_TWO_TU_OBJECTS_WITH_ACCEPTED_DIAGNOSTICS` |
| 最新审计响应产出 | run [39461235023](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39461235023)，artifact 12282672298，同一 status；两者都绑定旧候选哈希，均不覆盖本报告的新 nvrm-fb.cpp |

### 1.1 本轮实际能读到什么

本地 `g1-stock-work/nm-272ccd9` 是 v2.4.2 的 partial clone（`blob:none`）。
它的对象库里有 v2.4.3 的 **commit/tree/tag**，没有 v2.4.3 的
`nvrm-fb.cpp` blob：

- `git cat-file -p 47f818b` 成功，读到 release commit、tree 和父提交；
- `git diff-tree -r 272ccd9 47f818b` 成功，读到三个改动路径；
- `git cat-file -e c5f01035c863f5fd876aaddef067886dd4aea86d` 失败
  （`GIT_NO_LAZY_FETCH=1` 下本地无此 blob）；
- 直接抓取 GitHub 被当前环境拦截（DNS 返回 198.18.x，TLS 被断开；
  本机 7897/10807 代理分别返回 502/426）。

因此：

- **可证**：v2.4.3 的提交图、改动路径、提交说明、v2.4.2 的 12 个调用点、
  两文件候选的完整内容和既有编译证据。
- **不可证**：47f818b 的 `nvrm-fb.cpp` 逐字节内容。本报告中的回移补丁是按
  `7dd3aeb` 提交说明和 v2.4.2 调用点重建的**最小语义补丁**，不是对上游
  blob 的逐字节 cherry-pick。若必须逐字节一致，需要先取得该 blob，再重跑
  本报告的差异核对。

## 2. v2.4.3 到底改了什么

`git diff-tree --name-status 272ccd9 47f818b`：

```text
M  CHANGELOG.md
M  kexts/NVRMFB/fb/nvrm-fb.cpp
M  plugin/NVMTLLibraryLoad.m
```

三个提交：

| commit | 内容 | 与两文件候选的关系 |
|---|---|---|
| `7dd3aeb` | NVRMFB: run every scheduled callback one at a time (#295) | **唯一需要评估的功能改动** |
| `5e711be` | NVMTLDriver: keep the AIR digest on the text nvmtl_air_to_text made (#294) | 插件侧，不在两 TU 范围；**不纳入** |
| `47f818b` | Release 2.4.3 | 版本提交，无额外代码 |

`7dd3aeb` 提交正文（原文）：

> A plain thread_call that is entered again while it is still running starts
> again on another thread. The hardware vblank and cursor callbacks are entered
> on every vblank and cursor move, so one stuck behind the display gate began a
> new thread each time until the 'high' thread_call group reached its
> 500-thread cap and the kernel panicked. Every NVRMFB callback is now allocated
> with THREAD_CALL_OPTIONS_ONCE, which folds those entries into one more run.

这段文字给出三个事实：

1. 问题在 **NVRMFB**，不在 NVRM.cpp；两文件候选的 NVRM.cpp 生命周期改动与它正交。
2. 触发源是 **vblank + cursor** 的高频进入；`fVblTimer`/`fHwVblCall`/`fCursorCall`
   是主要目标。
3. ONCE 的效果是 **folds entries into one more run**，不是“同一时刻只运行一个”。

## 3. 两文件候选实际改了什么（本地可证）

`stock-v242-converged.patch` 只改两个 TU：

- `kexts/NVRM/NVRM.cpp`
  - `beginTask/endTask/closeTaskAdmission` 任务计数；
  - `willTerminate/didTerminate/finalize` 的 defer 协调；
  - `adoptAdapter` 与 pass 2 失败回滚；
  - `stop()` 顺序：`rm_disable_adapter` → disable/remove MSI → `rm_shutdown_adapter`；
  - `rm_disable_adapter(NULL, &fNv)` 的 `NULL` stack 论证。
- `kexts/NVRMFB/fb/nvrm-fb.cpp`
  - **只改 `getDisplays`/`kapiInit` 的显示枚举**：堆上暂存、失败不发布半张表、
    计数一致性检查；
  - **没有改任何 `thread_call` 分配、回调、retain/release 或 stop 排空**。

这一点很关键：v2.4.3 的 ONCE 改动是**新增**到候选的 nvrm-fb.cpp 上，而不是
替换候选已有的某个回调修复。候选的 12 个分配点仍是 plain
`thread_call_allocate`（见 §4）。

### 3.1 两文件候选 vs v2.4.3 一览

| 维度 | v2.4.3（47f818b） | v2.4.2 两文件候选（272ccd9 + patch） | 交互/判定 |
|---|---|---|---|
| 上游 pin | 47f818b | 272ccd9 | **不迁移 pin** |
| 变更 TU | NVRMFB/fb/nvrm-fb.cpp + plugin + CHANGELOG | NVRM.cpp + NVRMFB/fb/nvrm-fb.cpp | 功能上正交 |
| 回调分配 | 全部 NVRMFB 回调加 ONCE（按提交说明） | 12 个 plain `thread_call_allocate` | 可叠加，但有 1 个例外 |
| 多目标通知 | 若 blanket ONCE，会折叠 `gConnectNotify` | 未处理该冲突 | **排除 gConnectNotify** |
| 显示枚举 | 未改 | `getDisplays` 堆上暂存/失败不发布 | 互不冲突 |
| retain/release | ONCE 不改变调用方 retain 契约 | `scheduleCall` 一 pending 一 retain | 8 个 call 平衡 |
| cancel/drain | 不新增排空 | 8 个 call 在 stop 中 cancel/free | ONCE 不替代排空 |
| 编译证据 | 无本地新证据 | run 39452257558 / 39461235023 通过 | 旧证据保留；新候选需重跑 |
| 设备准入 | 未验收 | 未验收 | **DEVICE NO-GO** |

## 4. 12 个分配点逐项比较

行号以**现有候选** `candidate-stock-v242-converged/nm/kexts/NVRMFB/fb/nvrm-fb.cpp`
为准；上游 v2.4.2 的行号整体少约 18 行，但调用点一一对应。

| # | 行 | 分配 | 参数 | 进入路径 | retain 来源 | 取消/排空 | ONCE 建议 |
|---:|---:|---|---|---|---|---|---|
| 1 | 159 | `fApply`（背光） | 固定 `h` | `thread_call_enter(fApply)` | 无；handler 由 IODisplay 持有 | `NVRMBacklightHandler::free()` 的 cancel/free 循环 | **GO**（latest brightness wins） |
| 2 | 1320 | `gConnectNotify`（全局） | **可变 `fb`** | `thread_call_enter1_delayed(gConnectNotify, fb, d)` | **无** | **不在 stop 数组，永不 cancel/free** | **NO-GO**（会丢另一个 framebuffer） |
| 3 | 1790 | `fCursorCall` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO** |
| 4 | 2240 | `gHotplug`（全局） | 无 | `thread_call_enter_delayed` | 无 | 不在 stop 数组，永不 free | **GO**（仅合并重复 kick；生命周期另计） |
| 5 | 2267 | `gConnectNotify`（全局） | **可变 `this`** | `thread_call_enter1_delayed(gConnectNotify, this, d)` | **无** | 同上 | **NO-GO** |
| 6 | 2297 | `fVblTimer` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO（主目标）** |
| 7 | 2300 | `fHwVblCall` | 固定 `this` | 中断里 `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO（主目标）** |
| 8 | 2305 | `fReflip` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO** |
| 9 | 2306 | `fGpuWake` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO** |
| 10 | 2308 | `fBars` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO** |
| 11 | 2317 | `fHeadProbe` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO**（调试） |
| 12 | 2321 | `fSampler` | 固定 `this` | `scheduleCall` | `scheduleCall` retain | stop 数组 | **GO**（调试） |

### 4.1 为什么单独排除 `gConnectNotify`

`gConnectNotify` 是一个**全局** thread_call（1201 行声明），但它的
参数是 framebuffer：

- hotplug 路径：`thread_call_enter1_delayed(gConnectNotify, fb, d)`（1320–1322）；
- enableController 路径：`thread_call_enter1_delayed(gConnectNotify, this, d)`（2430–2432）；
- 回调第一行把 `p0` 当作 `NVRMNVDAFramebuffer *me` 解引用（1202–1209）。

ONCE 折叠的是**整个 thread_call 的 pending 项**，不是按参数分组。若 fb0 和 fb1
在同一个 pending 窗口内各需要一次 connect 通知，后一个参数会被折叠掉（或覆盖前一个，
取决于 XNU 对 `enter1` 参数的处理），结果是至少一个 framebuffer 的 `fConnect.proc`
不会被调用。这不是“少一次日志”，而是框架的 connect-change 路径不跑，新显示器
可能拿不到 display pipe。

**建议**：本轮回移保持这两个分配点原样（plain `thread_call_allocate`）。后续若要
统一，先把 `gConnectNotify` 改成 per-fb thread_call，或改成“待通知 fb 位图 +
一个 worker”，再考虑 ONCE。这个改动应单独评审，不和本次回移混在一起。

### 4.2 `gConnectNotify` 还暴露了一个与 ONCE 无关的 lifetime 缺口

`hotplugFire` 在 1310–1324 行对 `relight[]` 里的 fb 做了 `retain()`，但在
**调度 500 ms 延迟通知之后、循环末尾**就 `release()` 了。`thread_call_enter1_delayed`
本身不 retain 参数。因此 `connectNotifyFire` 可能在 fb 已经 stop/free 之后运行，
第一行就解引用 `me`。`stop()` 的 8 个 call 数组（2362–2371）不包含 `gConnectNotify`，
所以它也不会被 cancel/free。`fStopping` 检查只能保护“对象还活着”的情况。

这是**既有缺口**，v2.4.3 的 ONCE 不修它，回调串行化也不修它。建议单独开 P0：
给延迟通知一个带 retain 的 ticket（回调释放），或 per-fb call 并在 stop 中排空。

### 4.3 `gHotplug` 的 lifetime 类似

`gHotplug` 也是全局、无参数、永不 free；`hotplugFire` 使用全局 `gFB`（1250 行）。
`gFB` 在 start 时 retain（2239 行），但 stop 只清 `gFBs`（2354–2361），没有释放
`gFB`，所以对象不会立刻 free——这避免了 UAF，但也是泄漏；`hotplugFire` 没有
`fStopping` 检查，仍可能在 stop 后调用 `me->fKms->getDisplays`。ONCE 只合并重复
kick，不改变这个生命周期。

## 5. ONCE 对 retain/release 的影响

`scheduleCall`（2333–2343）的不变量：

```cpp
retain();
const bool alreadyQueued = deadline ? thread_call_enter_delayed(call, deadline)
                                    : thread_call_enter(call);
if (alreadyQueued) release();
```

每个成功排队的 run 对应一个 retain；回调开头的 `NVRMCallReference`
（34–39 行）在返回时 release。ONCE 下分三种情况：

| 情况 | `thread_call_enter*` | retain 处理 | 结果 |
|---|---|---|---|
| 无 pending | false | 保留新 retain | 新 run 有 1 个 retain |
| 已有 pending | true | 立即 release 新 retain | pending run 仍持有原 retain |
| 正在运行、ONCE 抑制新 run | true（无 pending） | 立即 release | 只有运行中的 run 持有 retain |

`stop()` 的补偿逻辑：

```cpp
if (thread_call_cancel(call)) release();
while (!thread_call_free(call)) {
    if (thread_call_cancel(call)) release();
    IOSleep(1);
}
```

- `cancel` 返回 true ⇒ 确实取消了一个 pending 项 ⇒ 该项有一个 retain ⇒ release 平衡；
- 正在运行的 run 不会被 cancel 取消，它的 retain 由回调自己 release；
- 因此，对 8 个走 `scheduleCall` 的 call，ONCE **不引入 over-release/leak**，
  前提是“至多一个 pending 项、每个 pending 项一个 retain”这个不变量成立。

但是：

- `gConnectNotify`、`gHotplug` 不经过 `scheduleCall`，没有 retain；
- `fApply` 也不经过 `scheduleCall`，但它有独立的 free drain；
- ONCE **不会**让 `thread_call_free` 变成“等待回调完成”的新屏障；它只是减少
  pending 项。运行中的回调仍然让 free 返回 false，`IOSleep(1)` 的无界等待仍在。

离线模型 `tests/test_stock_v243_once.py::test_once_is_not_serialization` 把上述
三种情况跑了一遍，并显式断言“运行中仍可有 pending 项”——即 ONCE 不是互斥。

## 6. 取消与排空：ONCE 不能替代什么

`NVRMNVDAFramebuffer::stop()`（2344–2383）的顺序是：

1. `fStopping = 1`（在 `fFlipCacheLock` 下）；
2. 注销 hw vblank；
3. 从 `gFBs` 摘除并 release；
4. 对 8 个 call 逐个 `cancel` + `free` 循环；
5. 再注销一次 `fHwVblCb`（处理“检查 fStopping 之前已通过”的 vblFire 重注册）；
6. detach backlight、free gamma、remove wake gate、remove sleep tap；
7. `super::stop`。

ONCE 对第 4 步的帮助仅限于“pending 项更少”，不改变：

- 运行中的回调必须自己退出，`thread_call_free` 才会成功；
- 回调若在 `fStopping` 之前已通过检查，仍可能在 stop 期间运行；
- `gConnectNotify`/`gHotplug` 不在第 4 步的数组里，stop 不排空它们；
- `NVRMBacklightHandler::free()` 的 cancel/free 循环同样是无界的；
- 回调之间仍可能重叠（一个运行 + 一个 pending），不是“串行化”；
- 对象生命周期依赖 `NVRMCallReference` 的 retain，而不是 ONCE。

**因此：不能把“回调串行化”或 ONCE 当作完整安全关闭。** 关闭安全仍是三个独立
问题：stop 入口/对象生命周期、全部使用者排空、电源转换。ONCE 只处理第一个问题
里的“线程数爆炸”子项。

## 7. 是否值得迁移

### 7.1 价值

- **高**：500 线程上限是内核 panic，不是普通丢帧；vblank/cursor 是常驻高频路径。
- **小**：10 个分配点、单文件、无新逻辑分支、无新头文件、无新结构体。
- **可回退**：保持 pin 272ccd9，补丁可逆；旧候选和旧证据不动。
- **与现有候选正交**：候选的 nvrm-fb.cpp 只改 `getDisplays`，ONCE 改的是
  start/cursor 的分配点，文本上不冲突。

### 7.2 代价

- nvrm-fb.cpp 的候选哈希变化，现有 run 39452257558 / 39461235023 不再覆盖这个文件；
  必须重新跑一次两 TU 原生门禁。
- 对象新增一个未定义符号 `_thread_call_allocate_with_options`（内核已导出），
  需要更新符号批准清单。
- 若把 `gConnectNotify` 也纳入 blanket ONCE，会引入多 framebuffer 通知丢失的
  功能回归；本建议明确排除。
- 整包迁移还会带入 #294 插件改动，超出当前门禁范围。

### 7.3 判定

| 方案 | 判定 | 理由 |
|---|---|---|
| 整包 pin 升到 47f818b | **NO-GO（现在）** | 失效全部候选哈希/证据；带入 #294；收益不值 |
| 在 272ccd9 上回移 10 个安全点 | **GO_COMPILE_ONLY** | 小、正交、可逆；直击 panic |
| blanket 12 点（含 gConnectNotify） | **NO-GO** | 多目标参数被折叠，功能回归 |
| 把 ONCE 当串行化/安全关闭 | **NO-GO** | 语义不成立；排空/生命周期仍未闭 |
| 设备加载/运行 | **NO-GO** | 未链接、未加载、无实机证据 |

## 8. 可复核的合并建议

### 8.1 补丁

- `stock-v243-once-overlay.patch`：只改 nvrm-fb.cpp 的 10 个分配点，
  用于单独审阅；应用顺序是先 `stock-v242-converged.patch`、再 overlay，
  不单独用于门禁；
- `stock-v243-converged.patch`：把现有 `stock-v242-converged.patch` 与 overlay
  合并后的单补丁，直接应用到 272ccd9；SHA256
  `9733c44ff2016b63e1e3c7b84c68c5793dd82a98b0eaba17400955b2031f7ec8`；
- 新候选 nvrm-fb.cpp SHA256
  `c9d39a6da7546c207eb1d6ffcba6ed78d56c1a37bcb43627baf8b7b7b7c4fbec`
  （旧候选 `35ebfb18…`）。

补丁已用与门禁相同的 `git apply --check --whitespace=error-all` 在 272ccd9 的
LF 文件上验证：check/apply 均成功，应用后两个文件哈希与 lock 一致。

### 8.2 新门禁资产

`research/stock-v243-once-20261021/`：

- `source-lock.json`：pin 仍是 272ccd9；patch 指向合并补丁；新增 1 个批准
  未定义符号 `_thread_call_allocate_with_options`（XNU 导出，
  `runner-kernel-nm-raw.txt:20704`）；
- `stock-v243-converged.patch` / `stock-v243-once-overlay.patch`；
- `nvrm-fb-once.cpp`：回移后的完整候选文件，供逐行复核。

新门禁脚本 `scripts/g1/stock_v243_once_native.py` 是旧脚本的副本，只改
patch 名称和 pass 状态；旧脚本与旧证据保持字节不变。新 workflow
`g1-stock-v243-once-native.yml` 仍是 `workflow_dispatch` 手动触发，不自动跑。

### 8.3 预期原生结果（尚未运行）

- 两个 TU 编译：NVRM.cpp 不变；nvrm-fb.cpp 因 ONCE 行变化重新编译；
- 诊断：NVRM.cpp 的 3 条 `-Wdeprecated-declarations` 例外不变；nvrm-fb.cpp
  没有登记例外，若行号变化不影响（例外按文件+行+列匹配，nvrm-fb 无例外）；
- 符号：nvrm-fb.cpp 新增 `_thread_call_allocate_with_options`；由于两个
  `gConnectNotify` 仍用 plain `thread_call_allocate`，旧符号
  `_thread_call_allocate` **不会消失**，因此不需要“移除符号”批准；
- 负控和自检仍应执行；
- 目标状态：`PASS_DARWIN_TWO_TU_OBJECTS_WITH_ACCEPTED_DIAGNOSTICS_ONCE`。

**本轮没有运行这个原生门禁。** 当前是 Windows，macOS runner 需要用户手动
在 Actions UI 触发；禁止自动触发。

## 9. 仍然开放的 P0（ONCE 不解决）

1. **stop 入口/对象生命周期**：`gConnectNotify` 的延迟参数无 retain；
   `gHotplug` 无 stop 检查；`fApply` 的 free 依赖无界等待。
2. **全部使用者排空**：`thread_call_free` 只覆盖 8 个 call；全局 call、
   `fConnect.proc`、`fSleepTap`、wake gate 的排空仍需逐项证明。
3. **电源转换**：RM busy → STANDBY、GPU 唤醒/失联的状态机仍按既有证据为 FAIL。
4. **回调重叠**：ONCE 不提供互斥；两个回调仍可能同时进入显示 gate 或 NVKMS。
5. **整包 ABI/loader**：两 TU 对象不等于整包链接/加载/ABI 验收。

## 10. 本轮工作记录

- **新增事实**：v2.4.3 的唯一功能改动是 nvrm-fb.cpp 的 ONCE；两文件候选的
  nvrm-fb.cpp 没有回调改动；`gConnectNotify` 是唯一“多目标参数 + ONCE”冲突点；
  ONCE 不改变 stop 的排空语义。
- **证据/commit**：47f818b、7dd3aeb、272ccd9、run 39452257558（artifact
  12279222611）、run 39461235023（artifact 12282672298）；本地 blob/路径见 §1。
- **改动文件**：新增 `research/stock-v243-once-20261021/`、`tests/test_stock_v243_once.py`、
  `scripts/g1/stock_v243_once_native.py`、`.github/workflows/g1-stock-v243-once-native.yml`；
  未修改旧候选、旧 patch、旧 lock、旧 gate 或旧证据。
- **实际运行的测试**：`python tests/test_stock_v243_once.py`，8/8 通过；
  既有 `tests/test_stock_v242_diagnostics.py` 26/26、
  `tests/test_stock_v242_symbols.py` 9/9 仍通过；
  用新 lock 跑 `validate_lock`、`check_patch_scope`、`gate_self_checks`（9/9）通过；
  在 272ccd9 的 LF 文件上模拟 `prepare`，`git apply --check/apply` 成功，
  两个文件哈希与 lock 一致；另验证“base patch → overlay”顺序也成功并得到同一对哈希。**未运行**：Darwin 原生编译、链接、加载、GPU 执行、设备访问。
- **未证实/阻塞**：47f818b 的 nvrm-fb.cpp 逐字节内容（本地缺 blob、网络被拦截）；
  新候选的原生对象/符号/诊断结果；整包 ABI/loader；设备安全关闭。
- **风险与回退**：ONCE 折叠可能延迟/丢弃一次事件；本补丁排除了多目标的
  `gConnectNotify`。回退只需丢弃 overlay/合并补丁，pin 与旧候选不变。
- **下一步**：用户手动触发 `g1-stock-v243-once-native.yml`；通过后再评估
  `gConnectNotify` 的 per-fb 化与 stop 排空修复。设备继续 NO-GO。

## 11. 相关文件

- [既有 v2.4.2 收敛报告](../stock-v242-converged/GATE-CONVERGENCE-20261021.md)
- [合并补丁](stock-v243-converged.patch)
- [ONCE overlay](stock-v243-once-overlay.patch)
- [新 lock](source-lock.json)
- [离线合同测试](../../tests/test_stock_v243_once.py)
- [新门禁脚本](../../scripts/g1/stock_v243_once_native.py)
- [新手动 workflow](../../.github/workflows/g1-stock-v243-once-native.yml)
