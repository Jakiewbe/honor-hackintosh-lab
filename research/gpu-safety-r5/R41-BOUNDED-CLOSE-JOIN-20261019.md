
# R41：有界关闭等待（P0-5）与 D1/D2 检查

## 改动


ullmoth-r41-bounded-close-join.patch（37 行，序列第 35 项），kms_close_common()：

`c
if (popen->eventCall && popen->eventBusy) {
    if (thread_call_cancel(popen->eventCall)) popen->eventBusy = false;
    if (popen->eventBusy) {
        uint64_t deadline;
        clock_interval_to_deadline(kKmsCloseJoinMs, kMillisecondScale, &deadline);
        while (popen->eventBusy) {
            if (IOLockSleepDeadline(gKmsLock, popen, deadline, THREAD_UNINT) == THREAD_TIMED_OUT) break;
        }
    }
    if (popen->eventBusy) {           // 超时：不释放，交给延迟回收
        kms_close_remember_locked(popen);
        IOLockUnlock(gKmsLock);
        kprintf("NVRM-xnu: close of %p timed out waiting for its event call; wrapper kept for reclamation\n", popen);
        return;
    }
}
`

新增 static const uint32_t kKmsCloseJoinMs = 10000;（与 kKmsPmWaitMs 并列）。

## 为什么是"保留"而不是"强制释放"

popen->data 已经 
vKmsClose 并置 NULL，但 event call 可能仍在跑（	hread_call_cancel 失败说明它已在执行）。
此时释放 wrapper 就是 UAF；正确做法与"释放失败"分支一致——**记住并交给延迟回收**，
不改变任何所有权规则，只把"无限等待"换成"最多等 10 s，然后按失败处理"。

## 新检查（D1/D2）

	ools/check-pm-state-machine.py 增加：

| 规则 | 断言 |
|---|---|
| D1 | 不得出现 while (popen->eventBusy) IOLockSleep( 这种无界等待 |
| D2 | 若有 eventBusy 等待，必须使用 IOLockSleepDeadline(...) 且在 THREAD_TIMED_OUT 时跳出 |

## 验证

| 状态 | 检查 |
|---|---|
| 35 项序列（含 R41）逐项应用 | PASS |
| 状态机 | **11/11 PASS**（含 D1/D2） |
| PM exclusion | **32/32 PASS** |
| 未打 R41 时 | 9/11，D1/D2 均 FAIL（证明检查不是摆设） |

## 边界

仍是源码结构结论：没有证明 event call 真的会在 10 s 内结束，也没有证明超时后延迟回收能成功；
真实 RM 锁序与真实内核调度仍未知。
