# PM 安全两风险：可执行方案与需要设备才能定的分叉（2026-10-18，R114）

本文件只处理两个**已被代码证据确认**的风险，并把"能静态推进的"与"必须实机才能定的"分开。
当前状态：`tools/check-pm-exclusion.py` 为 **31/32 FAIL**，"门忙仍 STANDBY" 保持失败项，不改回 PASS。

---

## 风险 A：延迟的 KMS close 永不回收

### 代码事实

`os-nvkms-xnu.cpp` `kms_close_common` 超时分支（L143–150）：

```cpp
popen->closing = true;
popen->eventWanted = false;
gKmsCloseDeferred++;
if (gKmsPmState == kKmsPmLost) gKmsCloseDeferredLost++;
IOLockUnlock(gKmsLock);
return;                       // per-open / wrapper / event call 全部保留
```

全文件检索：`gKmsCloseDeferred` 只有 `++` 与读取，**没有任何重试或释放路径**。

### 为什么不能"就地重试"

超时发生时 GPU 处于 suspended/lost，`nvKmsClose()` 会触碰显示引擎；注释已说明此时推 core channel
会在 `nvEvoMakeRoom` 里自旋。所以正确时机是**恢复之后**。

### 可执行方案（不需要设备即可实现与测试）

1. 维护一个"延迟关闭"链表：`closing == true && data != NULL` 的 per-open 注册到 `gKmsDeferredList`
   （在超时分支里挂入，用一个自旋锁或复用 `gKmsLock` 保护）；
2. 在 `nvkms_xnu_resume()` 的尾部、**确认 PM 状态回到 running 之后**，遍历该链表：
   - 对每一项重试 `nvKmsClose(popen->data)`；
   - 成功后按 `kms_close_common` 的成功路径释放 wrapper 与 event call，并从链表摘除；
   - 若 `thread_call_free` 失败，保留并计数（与现有注释一致）；
3. 在 `nvkms_xnu_unload()` 里对剩余项做最后一次 drain；
4. 计数器改为"待回收"语义：`gKmsCloseDeferred` = 当前挂起数（减一当回收成功）。

### 失败用例（主机可测）

- 构造一个 `pv` 释放失败后进入 delayed 状态的对象，调用 resume 的 drain，断言：
  (a) `nvKmsClose` 被调用一次；(b) wrapper 被释放；(c) 计数归零；
- 再构造 `thread_call_free` 返回 false 的情形，断言保留且计数不减；
- 断言 drain 在 PM 非 running 时**不执行**（不能提前碰显示引擎）。

这类测试是纯 CPU 契约，与现有 `nvlink_locks_contract.cpp` 同路数，不需要实机。

---

## 风险 B：RM 门忙时仍进入 STANDBY

### 代码事实

`NVRM.cpp:1441-1447`：

```cpp
const int busy = nv_xnu_pm_close(10000);
if (busy) LOG("sleep #%u: %d RM call(s) still running after 10 s - suspending anyway", ...);
NV_STATUS cst = rm_stop_user_channels(NULL, &fNv);
pciSaveForSleep();
NV_STATUS st = rm_power_management(NULL, &fNv, NV_PM_ACTION_STANDBY);
```

即：门没关干净（仍有 RM 调用在跑）也照样 STANDBY。

### 为什么"阻止挂起"不是一个可以直接勾选的选项

XNU `IOServicePM.cpp:4525`：`setPowerState` 返回负值等同于 implied ack，**系统照常断电**。
所以"返回 false 阻止睡眠"在 IOPM 层面无效——这也是我把该检查改成失败项的原因：
它不是"已实现"，而是"要求实现"。

### 两个可选合同（互斥，需要决策）

| 选项 | 行为 | 好处 | 代价 |
|---|---|---|---|
| **B1 拒绝进入 STANDBY** | `busy > 0` 时**不调用** `rm_power_management(STANDBY)`，仅禁中断、记录 violation，GPU 保持 D0 | RM 不会在"还有活动调用"时被要求待机；唤醒后 RM 状态仍然有效 | 系统断电时 GPU 不在低功耗态，且 RM 从未被通知睡眠；真实硬件行为未知 |
| **B2 继续 STANDBY（现状）** | 记录 violation 后照常 stop + STANDBY | 与上游 Linux 的"尽力而为"一致 | 可能存在 RM 调用与待机并发，正是审计标记的危险 |

两者都不是"安全"的证明，只是不同风险取舍。**没有实机就无法判断哪一个更糟**：
B1 依赖"GPU 在系统断电时被强行断电也不损坏/可在唤醒时重初始化"，B2 依赖"STANDBY 与进行中的 RM 调用并发仍不致损坏"。

### 现在能做的

1. 保持检查为失败项（已如此），并在验收矩阵中标注"需实机或架构决策，不是代码遗漏"；
2. 把选项 B1 写成一个**可开关的补丁**（默认不启用），使决策一旦做出即可施加，而不是临时改代码；
3. 记录判定所需的观测：睡眠期间是否有 RM 调用超时/断言、唤醒后 `rm_resume` 是否成功、
   `nvKmsClose` 延迟计数是否持续增长。

---

## 本轮不做的

- 不修改候选源码（上述方案未实现，避免未经验证就改变行为）；
- 不把任何一项标为已解决；
- 不做设备操作。

## 六十五、延迟关闭的回收补丁（草案 R30）已实现并验证可应用（R115）

按 PM-SAFETY-PLAN 的方案 A 写出补丁，**未合入序列**，仅作为可核对的草案：

esearch/gpu-safety-r5/draft-r30-deferred-close-drain.patch（3,271 B，+32 行，单文件）

### 补丁内容

1. struct nvkms_per_open 增加 deferredNext 字段；
2. 新增文件级链表头 gKmsDeferred；
3. 超时分支从"只计数"改为"挂入链表 + 计数"；
4. 新增 kms_deferred_drain_locked()：
   - 仅在 gKmsLock 持有、且 PM 已回到 running 时调用；
   - 对每项执行 
vKmsClose(popen->data)、取消并释放 event call；
   - 	hread_call_free 失败则**保留在链表中**，等下次 resume 再试；
   - 成功则摘链、gKmsCloseDeferred--、释放 wrapper；
5. 
vkms_xnu_resume() 在 gKmsPmState 已更新为 running 之后调用 drain。

### 验证

`
git apply --check  -> exit=0
git apply          -> exit=0
应用后：L288 定义、L323 在 resume 中调用
`

补丁应用后我已把工作树恢复到 2b6828b（git status 零修改）。

### 仍缺的部分

- **没有**主机测试：这类测试需要模拟 
vKmsClose/	hread_call_free/IOLockSleep，
  现有 
vlink_locks_contract.cpp 的夹具不覆盖这些符号，需要新夹具；
- **没有**合入补丁序列，因此 check-pm-exclusion.py 目前仍不检查 drain（避免"检查一项尚未合入的能力"）；
- **没有**在官方构建线里编译过这个改动。

### 下一步

合入前应先补夹具测试三例：drain 成功释放、	hread_call_free 失败保留、PM 非 running 时不执行。
这三例通过后，再把补丁加入序列并加一条结构检查（断言 drain 存在于 resume 路径）。

## 六十六、为什么 drain 还没有主机测试，以及可行的替代结构（R116）

### 实测：这个 TU 的宿主化成本

kexts/NVRM/os-nvkms-xnu.cpp（633 行）的直接依赖：

| 项 | 数量 | 内容 |
|---|---|---|
| 直接 include | 9 | 
v-xnu.h、kern/thread_call.h、sys/sysctl.h、mach/semaphore.h、mach/task.h、sys/proc.h、modeset-os-interface.h、
v-gpu-info.h、
vUnixVersion.h |
| 经由 
v-xnu.h 的 IOKit 依赖 | 4+ | IOKit/IOLib.h、IOKit/IOLocks.h、IOKit/pci/IOPCIDevice.h、libkern/libkern.h |
| 需打桩的外部符号 | **35** | IOLock*(6)、IOSimpleLock*(3)、	hread_call_*(7)、kprintf/IOLog/IOSleep、
vKms*(10)、
vkms_alloc/free、clock_interval_to_deadline 等 |

对比：
vlink_locks.cpp 能轻易宿主化，是因为**它是我们自己写的**、只 include 了 5 个头。
os-nvkms-xnu.cpp 直接吃 IOKit 内核头，编一个桩头文件集不是小工作量。

### 因此下一步不是"硬编夹具"，而是先改结构

把"延迟关闭链表 + drain"抽成一个**不依赖 IOKit 的小单元**：

`cpp
// kms_deferred.h
struct kms_deferred_ops {
    void (*close)(void *data);
    bool (*cancel)(void *call);
    void (*freeNode)(void *node);
};
void kms_deferred_push(void *node, void *data);
unsigned kms_deferred_drain(const struct kms_deferred_ops *ops, bool pm_running);
unsigned kms_deferred_count(void);
`

- 生产代码在 resume 时用真实实现（
vKmsClose/	hread_call_cancel/
vkms_free）调用；
- 单元本身零 IOKit 依赖，可以用与 
vlink_locks_contract.cpp 相同的方式做**真行为测试**：
  成功释放、cancel 失败保留、pm_running == false 时不执行；
- 这样测试的是**真实被调用的代码**，不是模型复制品。

### 本轮没做的

- 没有写这个单元（结构改动需谨慎，且要同步更新 R30 草案）；
- 没有把任何测试标为通过。

## 结论

drain 目前只有"可应用的补丁"，**没有行为证据**。下一步必须先做结构拆分（kms_deferred 单元），
才能在不伪造夹具的前提下测到真实代码。
