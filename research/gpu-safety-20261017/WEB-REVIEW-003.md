# WEB-REVIEW-003：独立审查 NVKMS 可失败静默与关闭合同

本任务供 ChatGPT 网页端直接读取仓库完成，不需要用户上传附件。提交后请在链接的固定 commit 上审查；不要依据随后移动的 main 猜测输入。

## 先读

1. [R2 交付与残余阻塞](reports/DELIVERY-R2.zh-CN.md)
2. [R2 增量补丁](patches/gpu-safety-r2-kms-open.patch)
3. [原始 OS wrapper](source-context/original/os-nvkms-xnu.cpp)、[R2 候选完整 wrapper](source-context/candidate-r2/os-nvkms-xnu.cpp)
4. [固定关闭调用链摘录](source-context/CLOSE-CALL-CHAIN.md)
5. [实际测试记录](evidence/r2/r2-results.txt)、[应用与回滚记录](evidence/r2/verification.json)、[无头 owner 设计](reports/headless-device-owner.md)

上游固定 NullMoth ac55984c473e746c2a8ebea7ba0913461aa7c393、OGKM e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb。如需上下文，读取摘录中链接的完整固定源码，不得换版本。仓库中只发布必要源码上下文，不是完整上游镜像。

## 具体工作与产出

先独立检查 R2 是否引入新回归：预分配事件 worker、无 Device kernel bridge 的轮询、thread_call_free 拒绝后的参数对象保留，是否符合真实调用合同。只报告有源码依据的问题；单线程故障注入13/13不证明XNU调度或并发安全。

再提出一个在 FreeDevice/KmsFreeDevice 释放第一项资源之前执行的、可失败的 pre-quiesce 最小合同，回答：

- 谁拒绝新 ioctl、谁持有在途调用与回调引用、在哪个锁域或控制上下文等待？
- 从 eventCallback 内部请求关闭时如何拒绝或转交，避免自等待？
- PM suspended/lost、超时、取消或 thread-call 释放失败时，哪些资源必须保留，谁拥有后续处理责任？
- 现有 void close/freeDevice 与函数表 ABI 对失败传播有什么限制？怎样保证 pre-quiesce 失败后绝不继续释放 notifier/semaphore、RM 或 Device？
- ioctl 在 PM 等待释放 gKmsLock 后如何重新验证对象，而不在释放后解引用？

输出一个有精确源码引用的审查报告：问题按严重性排列；给出调用/所有权表、必要跨文件修改列表、接口草案、失败分支和验收门禁。若证据足够可附统一 diff 候选，但不要用空实现或成功 Stub 填补未知平台行为；无法闭合的地方明确 BLOCKED。

本任务不实现完整无头 owner、不启用 Head4、不改 Intel 显示所有权。不重复通用 Mock，不编造原生编译、CI或GPU证据。不得提交、推送、发 Issue/PR、触发/重跑 Actions、运行安装器、安装/加载kext或操作硬件。本次用户授权由本地 Codex 发布输入材料，不是对网页端自动写仓库或设备部署的授权。

请把报告、可选diff及未解决问题直接回复用户，由本地 Codex 复核后接续。
