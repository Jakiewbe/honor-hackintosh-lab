# WEB-REVIEW-004：独立审查 PM / RM gate / NVKMS 锁序与可失败关闭

请先阅读 reports/DELIVERY-R3.zh-CN.md、evidence/r3/xnu-thread-call-contract.json、R3 两份新补丁及 WEB-REVIEW-003.md。只做独立源码审查和可实施设计，不操作仓库或触发 Actions，不加载驱动。

固定上游：
- https://github.com/nullmoth/nvidia-macos-driver/tree/ac55984c473e746c2a8ebea7ba0913461aa7c393
- https://github.com/NVIDIA/open-gpu-kernel-modules/tree/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb
- XNU 比较源码：https://github.com/apple-oss-distributions/xnu/tree/43a90889846e00bfb5cf1d255cdc0a701a1e05a4

重点源码：NullMoth kexts/NVRM/NVRM.cpp 的 gpuSuspend/gpuResume，os-interface.cpp 的 nv_xnu_pm_*（请按符号查找真实文件），os-nvkms-xnu.cpp 的 suspend/resume、kms_close_common、worker/PM wait；OGKM src/nvidia-modeset/kapi/src/nvkms-kapi.c 的 AllocateDevice/FreeDevice/KmsFreeDevice，及 KAPI freeDevice 接口调用方。

已观察：gpuSuspend 先 NVKMS suspend，再 nv_xnu_pm_close(10000)；busy 非零仍 standby。源码说明先关 RM gate 曾与持 gKmsLock 的 ioctl 死锁。现有 void freeDevice 不能传播 pre-quiesce 失败；事件回调内 freeDevice 可能自等待。thread_call_free 成功不能作为外部 callback join。

请交付：
1. 逐条引用固定 commit 的源码链接和行号，确认/反驳上述观察，标记未知，不从注释推导已实测安全。
2. 绘出 close/事件回调/在途 ioctl/suspend/resume 的锁与引用关系，给出可复现的对抗调度：尤其 RM users pin 为何能/不能阻止 standby、PM wait 放锁后谁持有 Device。
3. 给出最小、可失败、可重试的 pre-quiesce 合同与调用链修改清单：失败时保留哪些对象，如何阻止新入口，如何处理 callback 内关闭，哪些阶段不能回滚。必须证明没有 TOCTOU、反向锁序、自等待。
4. 审 R3 NULL guard 是否覆盖真实首分配失败且不隐藏已分配资源泄漏；区分局部初始化修复和完整退出安全。
5. 给本地 Codex 可直接实施的最小文件级修改建议和有区分力的故障注入/原生编译验收。对不能闭合的条件明确 NO-GO，不以空实现、恒真返回或 mock PASS 代替。

本任务不要求网页端提交代码；不要发送上游 Issue/PR，不建议用户直接部署。最终简体中文，按 P0/P1 与事实/推断/未验证分列。若网页无法读取链接，明确缺失，不编造内容；所需材料均已在同一实验仓库公开文本路径中，无需用户上传附件。
