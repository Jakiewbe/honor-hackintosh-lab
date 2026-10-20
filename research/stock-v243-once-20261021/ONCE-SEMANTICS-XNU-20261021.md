# ONCE 语义复核（依据固定 XNU 源码）

证据来源：`apple-oss-distributions/xnu`，固定 commit
`43a90889846e00bfb5cf1d255cdc0a701a1e05a4`（= `rel/xnu-11417`，与目标 macOS 15 对应系列），
文件 `osfmk/kern/thread_call.c`。行号为该 commit 中的实际行号；本轮通过 git 从该 commit 取出文本
（67,209 B）后逐段阅读。

## 1. ONCE 在哪一层生效

```c
thread_call_allocate_with_options(func, param, group, options)   // L1062
    if (options & THREAD_CALL_OPTIONS_ONCE) call->tc_flags |= THREAD_CALL_ONCE;   // L1062-1063
```

真正改变行为的只有两处入队函数：

```c
_pending_call_enqueue(...)                                  // L709-730
    if ((THREAD_CALL_ONCE | THREAD_CALL_RUNNING)            // L714-715
        == (call->tc_flags & (THREAD_CALL_ONCE | THREAD_CALL_RUNNING))) {
        call->tc_pqlink.deadline = 0;                       // L716
        call->tc_flags |= THREAD_CALL_RESCHEDULE;           // L719
        return flags & THREAD_CALL_RESCHEDULE;              // L723
    }
_delayed_call_enqueue(...)                                  // L753-781
    ... 同样条件：记录最新 deadline、置 RESCHEDULE、返回旧 RESCHEDULE 位   // L760-771
```

结论 1：**ONCE 只在"该 call 正在运行"时改变行为**——不再往队列放第二个元素，而是记一个
`THREAD_CALL_RESCHEDULE`。当 call 只是 pending（未运行）时，ONCE 与 plain 走同一条入队路径，
因为 **call 对象本身就是队列元素**，重复 enter 只会覆盖参数/截止时间，不会产生第二个元素。

## 2. "折叠成一次额外运行"发生在 finish

```c
thread_call_finish(...)                                     // L1563
    call->tc_flags &= ~(RESCHEDULE | RUNNING | WAIT);       // L1588
    if ((!alloc || call->tc_refs != 0) && (old_flags & RESCHEDULE)) {   // L1590-1591
        assert(old_flags & THREAD_CALL_ONCE);               // L1592
        ... _delayed_call_enqueue(...) 或 _pending_call_enqueue(...)     // L1607-1617
    }
```

结论 2：ONCE 的效果是**当前这次运行结束后再跑一次**，不是"同一时刻只运行一个"、
也不是"进入时等待运行中的回调结束"。运行中的回调不会被取消、不会被等待。

## 3. 参数覆盖：latest-wins

```c
thread_call_enter1(...)                                     // L1185-1190
    if (call->tc_queue != &group->pending_queue)
        result = _pending_call_enqueue(...);                // L1185-1187
    call->tc_param1 = param1;                               // L1189  ← 无条件覆盖

thread_call_enter_delayed_internal(...)                     // L1260
    call->tc_param1 = param1;                               // L1319
    _delayed_call_enqueue(...)                              // L1323
```

结论 3：无论 ONCE 与否，重复 enter 都覆盖 `tc_param1`；被折叠的那次运行的参数是**最后一次**的值。
调用进入 `thread_call_invoke(func, param0, param1, call)`（L1674-1693）时参数已按值快照，
因此并发运行之间不会互相改写对方的参数，但**合并后的那次运行只会看到最后一个参数**。

## 4. cancel / free

```c
thread_call_cancel(call)                                    // L1390-1402
    thread_call_cancel_locked(call)                         // L1330-1379：只做 _call_dequeue，不清 RESCHEDULE
thread_call_cancel_wait(call)                               // L1412
    if (!(flags & THREAD_CALL_ALLOC)) panic(...)            // L1417-1420  ← 客户端自有存储不可 wait
    if (ONCE) { thread_call_cancel_locked(); thread_call_wait_once_locked(); }   // L1437-1445
thread_call_free(call)                                      // L1097
    if (call->tc_queue != NULL || (flags & RESCHEDULE)) return FALSE;   // L1105-1111
    ...
    if (flags & THREAD_CALL_RUNNING) panic("freeing a running once call");   // L1136-1137
```

结论 4：
- `thread_call_cancel()` 只能取消**队列里的 pending 项**；对正在运行的 ONCE call，
  它既不能停止当前运行，也不能清掉 `RESCHEDULE`，所以**那次额外运行仍会发生**。
- `thread_call_cancel_wait()` 对客户端自分配的 call 直接 panic，本驱动的 call 全部属于这一类，
  因此不能用它做 stop 排空。
- `thread_call_free()` 在 `RESCHEDULE` 未清或 call 仍在运行时会返回 FALSE / panic，
  所以 stop 里必须循环到它成功，且回调要在入口检查 `fStopping` 才会让"额外的那次运行"空转退出。

## 5. 对回移的直接含义

1. **ONCE 不是串行化、不是 stop 屏障**：现有候选在每个回调入口用 `NStopping`/`fStopping` 提前返回，
   这正是让 `RESCHEDULE` 的额外运行不至于重新武装的关键；文档不得把 ONCE 写成关闭安全。
2. **gConnectNotify 的两个点没有理由排除**：plain 模式下同一个 call 对象也是唯一队列元素，
   重复 enter 在 pending 时同样覆盖参数、合并通知；运行中 enter 在 plain 下会入队一次、
   在 ONCE 下记一次 RESCHEDULE，两者最终都只多跑一次。ONCE 只是把并发运行变成顺序运行，
   对"另一个 framebuffer 的通知是否会丢"没有新增损失。上游 47f818b 也是把 12 个分配点
   全部走 `nvrmfbCall()`（含两处 gConnectNotify），本轮回移已改为同样 12 点。
3. **retain 记账**：`scheduleCall()` 每次 retain，`thread_call_enter*` 返回"已存在待运行项"时立即
   release；`NVRMCallReference` 在回调结束时 release 一次。ONCE 下"第一次折叠"返回 FALSE
   （保留 retain）、后续折叠返回 TRUE（立即 release），与"只多跑一次"一一对应，记账仍平衡。
4. **参数生命周期**（`gConnectNotify` 携带 per-framebuffer 指针）是**独立于 ONCE 的既有风险**：
   `thread_call_enter1_delayed(gConnectNotify, fb, d)` 之后调用方立即 `fb->release()`，
   回调里 `p0` 的解引用依赖 framebuffer 对象本身仍被 IOKit/gFBs 持有。ONCE 不改变这一点，
   继续登记为设备阶段阻塞。
