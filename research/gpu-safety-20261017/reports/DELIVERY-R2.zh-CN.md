# GPU 源码安全候选 R2：NVKMS open / event / 释放失败分支

日期：2026-10-17。仅源码候选。SOURCE-REVIEW、PATCH-APPLIED、HOST-TEST 有新增证据；DARWIN-COMPILE 未运行；KEXT-LINK BLOCKED；运行 NO-GO。

## 本轮实际修复

只新增修改 `kexts/NVRM/os-nvkms-xnu.cpp`，候选位于 `candidate/nullmoth-v2.3.3-gpu-safety-r2`。R1 候选、补丁与验证记录保持原样。

1. 真正 KAPI 客户必须先取得事件 worker，再调用 nvKmsOpen。worker 分配失败返回 NULL，不能发布缺少事件能力的成功 open。nvKmsOpen 失败则回滚预分配 worker 和 wrapper；若 thread_call_free 拒绝，报告并保留参数对象，不继续释放。
2. NVRMUserClient 的 ioctl bridge 使用 kernel client 类型，但 Device 为 NULL。此类客户不分配 KAPI worker，改为维护 eventsAvailable 供已有轮询接口读取；保留 kernel client 类型，不能改成 USER_SPACE 而改变 copyin/参数合同。
3. close 不再忽略 thread_call_free 失败；失败时报告并保留 closing wrapper。这里是显式保留资源，不是可回收性成功，也没有新增无限重试。

上游 nvKmsKapiHandleEventQueueChange 在 device==NULL 时会直接返回。因此旧桥接行为的问题是事件被送到无效果的 worker、轮询状态未更新，不能将其写成已证实的空指针崩溃。

## 有效源码序列与实测

固定完整 NullMoth ac55984c473e746c2a8ebea7ba0913461aa7c393，OGKM 仍 e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb。

有效源码顺序：

1. patches/gpu-safety-r1.patch
2. patches/gpu-safety-r2-kms-open.patch

在完整原始 611 文件树上依次 check/apply 均退出 0，所得 612 文件哈希与 R2 候选全量一致。反向撤销 R2 全量恢复 R1，再撤销 R1 全量恢复原始源码。R2 相对 R1 仅一个文件不同，R1 记录的三个修改文件哈希不变。详见 evidence/r2/verification.json。

HOST-TEST 实际命令：`wsl -d Ubuntu -- bash /mnt/d/Hactk/gpu-mainline-20261017/work/run-r2-fault-injection.sh`。

测试提取实际 struct、kms_open_common、kms_close_common、nvkms_event_queue_changed 函数体，注入平台分配/锁/调度依赖。使用既有 g++ 13.3，-std=c++17 -Wall -Wextra -Wconversion -Werror -fsanitize=address,undefined。单线程，不执行真实 IOKit、RM、GSP 或 GPU。

- 旧实现：7/13，退出 1，作为新 R2 合同的负向对照；不是对 R1 既有 CPU 像素测试的撤销。
- R2：13/13，退出 0。覆盖 wrapper/worker/open 分配失败、rollback 释放拒绝、成功 KAPI open、事件合并、closing 拒绝新提交、无 Device bridge 轮询及正常用户态轮询、close 释放拒绝及正常一次释放。
- 证据：evidence/r2/r1-results.txt、r2-results.txt、*-compile.txt、*-exit.txt、fault-injection-inputs.json。平台依赖为测试注入，不能据此证明原生调用正确或并发安全。没有测试卡住的 close/self-wait 分支，也未将其视作通过。
- 初次 WSL 访问被普通沙箱拒绝；同一低风险主机测试经自动审批执行。不曾安装软件或改系统配置。

## 关闭合同的新增结论

源码链：OGKM KmsFreeDevice → nvkms_close_from_kapi → kms_close_common；随后 FreeDevice 继续 RmFreeDevice、close_gpu、sema_free 和释放 Device。公开 close 与 freeDevice 都是 void，不能直接向调用者表达“尚未安全静默”。

仍存在以下 P0：

- kms_close_common 在 nvKmsClose 前没有停止/排空外部 KAPI eventCallback；eventBusy 的无界等待和同回调发起 freeDevice 的自等待仍在。
- PM wait 失败时仍会丢弃 data 引用并释放 wrapper 的既有问题没有被本补丁解决。仅保留 wrapper 也不能阻止上层继续释放 RM/Device；不能把局部返回当安全回滚。
- 某些 ioctl 先检查 data 再进入会释放 gKmsLock 的 PM 等待；close 与在途操作尚无引用合同。必须把入口引用、关闭状态、在途回调与 PM/代际联合设计，单加一个 closing 布尔值不足。
- 本次释放拒绝的保留对象没有后台回收器，存在资源保留/泄漏风险；不把它说成完整 quarantine owner 或可重试关闭协议。
- OGKM FreeDevice 在调用 OS close 之前已开始释放 KMS notifier/semaphore 等资源；后置 close 的局部保护不是整个 Device teardown 的安全屏障。

因此尚未迁移唯一无头 Device owner，未插入 freeDevice/releaseOwnership，也未启用 Head4。下一源码工作应先设计并审查 **freeDevice 开始之前的可失败 pre-quiesce**，跨 `kapi/src/nvkms-kapi.c`、`os-interface/include/nvidia-modeset-os-interface.h` 与 XNU OS wrapper 定义拒绝新调用、等待在途操作、回调重入拒绝和资源保留合同；不得让调用者在 pre-quiesce 失败后继续释放。固定 OGKM 原缓存不得修改，后续需单独候选副本及补丁。该设计尚未实施。

## 原生门禁

ci-export-r2/ 是独立、自包含的 R2 导出：工作流、scripts/gpu-safety-r2/native_compile.py、research/gpu-safety-r2 下两份顺序补丁。原版/候选分别编译 NMIntelFB real、virtual、NVAccel 与 os-nvkms-xnu 共八个实际翻译单元对象，记录依赖、命令、源/对象散列及 nm 文本；不链接、不加载、不上传对象。

本地校验手动触发、contents:read、四段 shell 语法与 Python 语法均通过，见 evidence/r2/native-export-check.json。宏提取函数与已验证 R1 完全相同。**没有运行 Xcode 或 Actions，不得宣称八个对象已编译。** 当前编译 profile 是明确标注的重建候选，不声称复现发行构建。目标 KDK/私有 IOFamily ABI/导出仍 BLOCKED。

## 许可、文档与回退

原有源文件 PolyForm-Noncommercial-1.0.0 声明保留；新增补丁只改公开固定源码，不引入二进制或固件。source → object → symbol 清单在 evidence/r2/source-object-symbol.json；实际 nm 列表待 CI，未知字段保持 null。

lab-overlay-r2 是待审阅状态文件；patches/project-status-r2.patch 相对原始实验仓库 bb523a5，包含本轮及 R1 记录，**替代文档 R1 patch，不与它叠加**。不改 .agent、不覆盖旧检出、不提交或推送。

回退源码可先反向撤销 R2 保留 R1，或再反向撤销 R1 恢复上游，均已实际验证。直接弃用隔离候选也可。无系统、设备、EFI 或驱动部署变更。
