# R32b：关闭回收的限定修复；正常回调等待仍失败

R31 的原生构建成立，但真实关闭函数 CPU 合同只有 2/4 通过。R32 在明确候选副本中修改 `os-nvkms-xnu.cpp` 和 `NVRM.cpp`，不改取证输入、显示所有权或上游版本。当前有效候选是R32b，只有源码与CPU证据，Darwin/链接尚未执行。初稿0d4c329/run39186159503仅作历史构建观察，不验收其异步正常close设计。

## 实现及依据

正常 close 已完成 `nvKmsClose` 后，在原有eventBusy等待完成后，如果 `thread_call_free` 拒绝，wrapper 以 NULL data 入 R31 单一所有者队列；后续 drain 不重复 backend close。关闭先置 closing，禁止重新提交事件。已入关闭流程的重复调用只在调用者仍保证 wrapper 有效的前提下幂等；这不允许对已释放的指针重试。

仅 deferred try_free 不再 `IOLockSleep` 等待 eventBusy；运行中回调则保留wrapper，由预分配的全局ONCE worker每100ms再尝试。新到节点不重置已排定deadline；不声称backend内部调用有执行时间上限。

**初稿的正常close异步返回已撤销。** 独立继续读固定OGKM真实 `KmsFreeDevice:446` 与 `FreeDevice:629-643` 后确认：void close返回后，Device的RM对象、semaphore和Device内存继续被释放；事件处理 `HandleEventQueueChange:3827` 仍可能读取Device字段。仅保住wrapper不能支撑Device寿命。因此正常close继续保留原eventBusy join，其无界等待以单独命令真实exit1记录。不能把删等待作为完整修复，也不能把此源码交错推断写成已观察到内核UAF。原初稿13/13仅测wrapper边界，对该Device合同不足，不作为整条close验收。

恢复链原为 `nvkms_xnu_resume → nv_xnu_pm_open`，事件可能正在等 RM gate。因此 resume 不再原地 drain；重试 ready 保持 false。`NVRM::gpuResume` 打开 RM gate 后，调用新 `nvkms_xnu_reap_closes` 才允许 worker 工作。worker 在同一 KMS lock 下复核 RUNNING、无 suspend pending、ready。挂起 commit 关闭 ready；pending abort 重新调度仍可运行的 backlog。worker 不等待事件，因而没有持 KMS lock 等事件再等 RM gate 的显式环。

原 deferred counter 仍用于上层 freeDevice 的差值观测。新增 wrapper 字段 `deferredCounted`，只让确实曾被拒绝 backend close 的对象减少该计数，正常关闭后的 callback backlog 不消费别的对象的计数。原计数的全局差值/并发可解释性仍 OPEN。

核对公开 XNU `xnu-11417.140.69/osfmk/kern/thread_call.c` 与 `thread_call.h`：`thread_call_free` 对 pending/reschedule 返回 FALSE；成功不等于等待普通 ONCE 回调结束。因此仍需 eventBusy/closing 和最后一次 wrapper 访问的锁合同。参考：[实现](https://github.com/apple-oss-distributions/xnu/blob/xnu-11417.140.69/osfmk/kern/thread_call.c)、[声明](https://github.com/apple-oss-distributions/xnu/blob/xnu-11417.140.69/osfmk/kern/thread_call.h)。这不是用户内核运行验证。

## 已执行证据

- 两文件 delta 反向恢复 R31 SHA256、再正向恢复 R32 SHA256，均逐字节核对；[roundtrip](r32b-close-evidence/roundtrip.json)。完整固定输入补丁序列等待 CI。
- 从实际候选提取 11 个完整函数、实际 retry 全局声明及 ops，连接实际 R31 queue：限定范围12/12 CPU场景通过，正常busy join另为1项FAIL/exit1。包括 PM 超时保留、恢复前 gate 拒绝、正常 free 拒绝、deferred busy回调及其完成、cancel、pending abort、LOST、重复 close、计数隔离、worker 不可用保留和稳定 deadline。锁与 IOKit/NVKMS 是注入边界；每场景独立进程，只计 free 不删除内存，不证明 XNU 调度或内核 UAF 已被实测排除。
- 四个负向控制通过：非法语句导致编译失败、无二进制且未运行；删除正常入队、绕过 ready、去掉计数归属，各被实际非零失败拒绝。四项 PM/加载顺序源码结构检查通过。
- Python 语法及历史回归 10/10、5/5、7/7 通过。

本地命令：`python tools/g1_kms_close_retry_contract.py --candidate <R32候选> --out <新目录> --cxx g++`；负控 `tools/g1_kms_close_retry_checks.py` 同参数。原生 workflow 使用实际对象依赖快照绑定 OS、queue cpp/h，clang++ 执行同合同和负控。失败不继续执行旧二进制。

最终补丁SHA256 `a9c5a4f3d2bf1eae90a23767aded5b332e95021e71b14c93b40650f38f018912`。OS `7d86b6b96c0911b2aebd3fdc567fa5ba1dde1122630c515db28b271c3f1f4430`；NVRM `f284893a1dc8e5a2ab7ae1071598ec528db25cfd248c613d8a523059b79a5469`。完整提取文件保留 NullMoth 版权/SPDX；[LICENSE](../gpu-safety-20261017/licenses/NullMoth-LICENSE.txt)、[NOTICE](../gpu-safety-20261017/licenses/NullMoth-NOTICE.txt)。

## 未关闭项与断点

正常close的eventBusy等待仍无界，CPU合同真实失败；容量64溢出仍保留资源却无队列槽；open rollback 的 thread_call_free 失败仍未入队；永久繁忙的 callback 会保持 backlog，重试不保证最终可释放。新增 worker 为模块寿命资源，未设计模块卸载，不得热卸载。KAPI Device 在 wrapper callback 完成前的上层生命周期/P0-4 未修；全局 counter 差值问题、RM busy 仍 STANDBY（31/32 FAIL）、完整 ABI/loader 仍 OPEN。

下一步先原生编译链接验证R32b的限定修改（不构成关闭安全验收）；失败仅按真实日志修复。成功后优先继续 KAPI Device/close 的可失败所有权传播，并处理容量溢出，不能把本轮 callback wrapper 合同当成整个 freeDevice 安全闭环。GPU 初始化、执行、正确像素及安全结束均未运行，KEXT-LOAD 及以上 NO-GO，Intel 基础显示保持。

复盘：先保存真实失败，再修实际函数，再用反向变异证明合同能拒绝错误；原生链接的绿色不能覆盖剩余 PM/设备生命周期失败。

有效证据：[r32b-close-evidence](r32b-close-evidence/)，含Device源码边界与正常busy的非零FAIL；r32-close-evidence仅保留被取代初稿的历史结果。下一轮需在FreeDevice最初入口关闭事件准入并保留完整Device所有权，或提供可失败的quiesce/teardown传播，不能在void close末尾才尝试补救。
