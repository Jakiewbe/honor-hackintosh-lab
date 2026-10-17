# WEB-REVIEW-005：R4 UserClient 会话锁与 bridge quarantine 独立审查

请以固定 NullMoth 源码 ac55984 和本提交中的 `research/gpu-safety-r4/nullmoth-r4-bridge-owner.patch` 为审查对象，阅读 WEB-REVIEW-003/004 仅作背景。任务是审查新 R4 候选，不修改仓库、不发 Issue/PR、不运行 Actions、不建议设备部署。

请重点核验：
1. `externalMethod` 持有 per-client IOLock 再调用 `super::externalMethod` 后，派发回调是否有递归锁、锁序或 reentrancy 风险；`sKms`、`sKmsEvents`、`sWaitEvent` 和 `clientMemoryForType` 的生命周期覆盖是否完整。
2. `clientClose` 的成功/失败/重试路径：self-retain/provider-retain 与 IOUserClient `terminate/clientClose` 合同是否正确；失败返回后 framework 是否仍会销毁连接；重试扫描 `gNvClients` 的引用与锁序是否可证明；shutdown/stop 后 provider 保留是否足够。
3. `nvkms_xnu_try_close_bridge` 的限定是否可靠：只接受 kernel bridge、无 Device、无 worker；在 `gKmsLock` 下 PM 等待成功并关闭 per-open；此操作和 suspend 的锁序如何。指出 `nvKmsClose` 或 RM gate 交互的剩余竞态。
4. PM gate 变动是否足够：启用 PM 时 gate 分配失败会拒绝 NVRM start；`-nvrmnopm` 保留旧显式行为；`nv_xnu_pm_enter` 缺 gate 的返回仍是否可能被调用方当作“未计数但允许访问”；`nv_xnu_pm_close` 的 -1 会否被 gpuSuspend 当作普通 busy 后继续 standby。
5. `nv_xnu_lookup_fd` 以及嵌入 `fNvfp` / `fMmap` 的引用是否被该锁覆盖；哪些通路仍可能绕过 `externalMethod` 与 `clientMemoryForType`。
6. 给出可复现的具体反例与目标 XNU/KDK API 证据。严格分清固定源码事实、调度推演和未验证。若发现 P0，请指出精确文件/符号并给出最小修复方向。

不要把局部 bridge 修复说成 KAPI `FreeDevice` 安全。完整 Device owner、callbacks、RM/DMA 静默、busy 后 standby 仍未解决，原生门禁也未运行。最终简体中文。
