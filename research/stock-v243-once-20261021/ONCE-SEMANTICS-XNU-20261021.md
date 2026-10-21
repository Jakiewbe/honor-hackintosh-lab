# ONCE 语义：固定 XNU 逐分支核对

固定输入：XNU `43a90889846e00bfb5cf1d255cdc0a701a1e05a4`，
[thread_call.c](https://github.com/apple-oss-distributions/xnu/blob/43a90889846e00bfb5cf1d255cdc0a701a1e05a4/osfmk/kern/thread_call.c)。
这是对应系列的源码合同，不是用户设备实际内核二进制验收。

## 1. 同一 call 的执行不会重叠

`_pending_call_enqueue` L714–723、`_delayed_call_enqueue` L760–770：
ONCE 且 RUNNING 时不重新入队，只置 RESCHEDULE；重复提交折叠成一次额外运行。
`thread_call_finish` L1588–1617 在当前执行结束后清 RUNNING，再按 RESCHEDULE 重新入队。

因此 **同一个 ONCE call 的回调执行串行**，不同 call 之间没有此保证。
enter 不会等待回调完成，ONCE 也不是 stop 排空屏障。
同一 call 已 pending 时，plain 与 ONCE 都只有一个队列元素，重复 enter 会合并。
`tc_param1` 被最新提交覆盖；已开始执行的调用使用已取出的参数快照。

## 2. cancel 会清除 RESCHEDULE，返回 true，但不等待当前回调

`thread_call_cancel_locked` L1343–1353 的实际首分支：

```c
if (call->tc_flags & THREAD_CALL_RESCHEDULE) {
    call->tc_flags &= ~THREAD_CALL_RESCHEDULE;
    canceled = true;
    assert(call->tc_queue == NULL);
} else {
    /* 检查延迟队列并调用 _call_dequeue */
}
```

`thread_call_cancel` L1391–1402 在锁内调用它，直接返回 canceled。
故运行中已设置 RESCHEDULE 时，cancel 可以取消额外那次调用，返回 true；
当前运行中的回调仍然存在。没有 RESCHEDULE 或 pending 项时可返回 false。
若取消之后另一个线程重新提交，仍可能出现新的工作，需另外关闭准入。

**纠错记录：** 原文“只 _call_dequeue、不清 RESCHEDULE、额外运行不可取消”错误。
本轮第一次审计及提交 `6c8783b` 的参考模型也沿用了该错误；现撤回这一推断。
保留 Git 历史以便复核，测试已同时覆盖取消 deferred 调用与未取消时 finish 重排。

## 3. free 的客户端引用释放不等于回调排空

`thread_call_free` L1105–1113：有队列项或 RESCHEDULE 时返回 false；否则减客户端引用。
运行线程 L1778–1780 已为 ALLOC call 增加引用，回调完成后才释放该运行引用。
因此，本项目普通 ALLOC/ONCE（非 SIGNAL）call 仍运行时，free 可减掉客户端引用并返回 true，
真正的 call 存储在 finish 中释放。SIGNAL+RUNNING 的等待特例见 L1118–1121，不能泛化。

所以 cancel+free 成功不证明回调已结束，也不证明回调访问的对象/参数仍活着。
这项设备阻塞不依赖上述被撤回的“RESCHEDULE 不可取消”说法。

## 4. cancel_wait 的条件与边界

`thread_call_cancel_wait` L1413–1466：要求 ALLOC、开中断，且不能在同一 call 回调中等待自己。
ONCE 分支先取消 pending/deferred 调用，再等待在飞回调；普通 call 的等待行为不同。
函数注释还明确：返回前先前请求已完成，不保证并发重新提交的工作不存在。
是否可用于本驱动 stop 的锁上下文、对象/调用寿命，仍需独立论证；本轮不修改驱动。

## 5. 回移与 retain 记账

12 个分配点均采用 ONCE，与上游 47f818b 覆盖一致。gConnectNotify 的 pending 合并原版已存在；
不能凭该合并单独排除两点，也不能据此证明参数生命周期安全。

scheduleCall 每次先 retain，enter 报告已存在工作时立即归还；运行中首次 RESCHEDULE
对应额外一次 retain。cancel 成功时调用者的补偿 release 可归还该次引用，当前回调仍独立持有引用。
参考模型仅说明账目，不执行 XNU，也不证明每个回调都经过该包装或具有停止检查。
gConnectNotify 参数寿命、gHotplug/applyFire 停止检查与 stop 排空仍是设备阻塞。

源码/对象/链接证据不提升为安全关闭或 GPU 运行证据。设备 NO-GO。
