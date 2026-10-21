# 12 个 ONCE 回移点的逐点核对

候选：`research/stock-v243-once-20261021/nvrm-fb-once.cpp`（SHA256 `69df8a94…`），
基线 272ccd9 + v2.4.2 两文件候选 + 本轮回移。语义依据见
[ONCE-SEMANTICS-XNU-20261021](ONCE-SEMANTICS-XNU-20261021.md)（XNU `43a9088` 的
`osfmk/kern/thread_call.c`）。

## 1. 逐点表

| # | 分配点 | 参数 | 回调 | 入口 `fStopping` | `NVRMCallReference` | 回调内自行 re-arm | 结论 |
|---|---|---|---|---|---|---|---|
| 1 | `fApply`（背光） | `h` | `applyFire` L203 | **无** | **无** | 无 | 参数固定；但回调没有任何停止检查或对象持有，见 §2.3 |
| 2 | `fCursorCall` | `this` | `cursorFire` L1952 | 有 | 有 | 无 | 参数固定，安全边界与 ONCE 无冲突 |
| 3 | `gHotplug` | `nullptr` | `hotplugFire` L1248 | 有 | 无 | 无 | 全局单例、永不 free；停止检查已有 |
| 4 | `fVblTimer` | `this` | `vblFire` L2034 | 有 | 有 | `scheduleCall` | 周期重排；ONCE 折叠使"运行中重排"变成结束后再跑一次 |
| 5 | `fHwVblCall` | `this` | `hwVblDeliver` L2025 | 有 | 有 | 无 | 参数固定 |
| 6 | `fReflip` | `this` | `reflipFire` L1730 | 有 | 有 | `scheduleCall` | 同上 |
| 7 | `fGpuWake` | `this` | `gpuWakeFire` L3704 | 有 | 有 | 无 | 参数固定 |
| 8 | `fBars` | `this` | `barsFire` L1959 | 有 | 有 | `scheduleCall` | 同上 |
| 9 | `fHeadProbe` | `this` | `headProbeFire` L2104 | 有 | 有 | `scheduleCall` | 同上 |
| 10 | `fSampler` | `this` | `sampleFire` L1605 | 有 | 有 | `scheduleCall` | 同上 |
| 11 | `gConnectNotify`（hot-plug 路径） | `fb`（**可变**） | `connectNotifyFire` L1202 | 有 | **无** | 无 | 参数是 per-framebuffer 指针，见 §2.2 |
| 12 | `gConnectNotify`（enableController 路径） | `this`（**可变**） | 同上 | 有 | **无** | 无 | 同一个全局 call，见 §2.2 |

代码位置均在候选文件内。参数"固定"指同一个 call 对象每次 enter 传的是同一个指针值
（`this`/`h`/`nullptr`），因此 XNU 的 `tc_param1` 覆盖（`thread_call.c` L1189/L1319）
不会改变语义；只有 11、12 两点参数会变。

## 2. ONCE 到底新增了什么、暴露了什么

### 2.1 新增：一次不可取消的额外运行

`thread_call_cancel()` 只做 `_call_dequeue`（L1330-1379），不清 `THREAD_CALL_RESCHEDULE`；
`thread_call_finish` 看到 RESCHEDULE 就在 L1590-1617 重新入队。因此：

> 运行中的 ONCE call 被再次 enter 之后，**即使 stop 调用了 cancel（返回 FALSE，表示没有取消队列项），
> 那次额外运行仍然会发生**。

plain 模式下同样的 enter 会排进队列，`cancel` 能把它取走。这是 ONCE **新增**的、
且只影响"运行中被重新 enter"的场景。

### 2.2 被暴露而不是新增：`gConnectNotify` 的合并与参数生命周期

- 合并：plain 模式下同一个 call 对象也是**唯一**队列元素，pending 期间的第二次 enter
  只覆盖 `tc_param1`（L1319），不会多排一次。所以"另一个 framebuffer 的通知被合并掉"
  **在 v2.4.2 原版就存在**，ONCE 不新增这类丢失；它只是把并发运行变成顺序运行。
  上一轮据此排除这两个点，结论不成立，本轮回移已改为 12 点。
- 生命周期：`thread_call_enter1_delayed(gConnectNotify, fb, ...)` 之后调用方立即
  `fb->release()`（候选 L1324 附近），回调里 `p0` 的解引用依赖 framebuffer 仍被其他所有者持有。
  这与 ONCE 无关，继续登记为**设备阻塞**。

### 2.3 被暴露而不是新增：`free` 不等待运行中的回调

本项目普通 ALLOC/ONCE call（不含 SIGNAL 特例）的 `thread_call_free` 在 call 仍在运行时 **不等待**：ALLOC call 的引用计数是"客户端 1 + 运行线程 1"
（L1778-1780），free 减到 1 就返回 TRUE，真正的 `zfree` 由运行线程在 finish 里做（L1620-1640）。
所以 `while (!thread_call_free(call)) { IOSleep(1); }` 并**不是**排空屏障：

- plain：`cancel` 能把 pending 项取走，循环立刻退出，但正在执行的这次回调仍在栈上；
- ONCE：连那次额外运行也取不走，会更晚才跑，窗口更大。

`applyFire` 同时没有 `fStopping` 检查和对象持有，是这条风险最明显的点（背光 handler 的
`free()` 之后仍可能有一次调用）。这条**不是 ONCE 引入**，但 ONCE 加重了它；
按任务边界，登记为设备阻塞，不在本轮扩大范围去改 stop 语义。

## 3. 若要修，最小方案已经具备的原料

- `_thread_call_cancel_wait` 在目标内核的符号集里（`kernel-symbolsets-decoded.txt:24975`
  的 `SymbolName`，以及 `runner-kernel-nm-raw.txt:20708` 的 `T`），且对
  `thread_call_allocate*` 分配的 call 合法（`thread_call.c` L1417 只对非 ALLOC 抛 panic）；
  对 ONCE call 它会"取消 pending 并等待在飞"（L1439-1445）。
- 但 `thread_call_cancel_wait` 会阻塞，且 panic 条件包含"在同一个 call 的回调里等待自己"
  （L1429-1432）。是否在 `stop()` 的锁上下文里安全，需要在设备阶段确认；本轮不引入。

## 4. retain 记账

`scheduleCall()`（候选 L2333）每次 `retain()`，`thread_call_enter*` 返回"已存在待运行项"时
立即 `release()`；回调里的 `NVRMCallReference` 在析构时 `release()` 一次。
ONCE 下：运行中第一次 enter 返回 FALSE（保留 retain），后续 enter 返回 TRUE（立即 release），
对应"只多跑一次、只多一次 release"，记账平衡。这一点已在 `tests/test_stock_v243_once.py`
的参考模型测试里覆盖；该模型不执行 XNU，也不验收 stop 安全。
