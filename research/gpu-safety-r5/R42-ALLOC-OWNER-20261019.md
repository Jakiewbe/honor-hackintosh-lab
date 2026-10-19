
## R42：分配失败路径的 owner（P0-4 后半）

### 问题

AllocateDevice() 的 ailed: 调用 FreeDevice(device)——那是**返回 void** 的公开包装。
若 
vKmsKapiTryFreeDevice() 被拒绝（例如 FREE_DEVICE ioctl 失败），这个半初始化的 Device
既没有交给任何人，也没有被释放：RM 状态悬空、无人可重试。

### 改动

ogkm-r42-alloc-owner.patch（CHAIN 第三项，r38 → r42）：

- 新增有界隔离表 NVKMS_KAPI_QUARANTINE_MAX = 4 与 KmsQuarantineAdd()；
- ailed: 改用 
vKmsKapiTryFreeDevice()，拒绝时把 Device 放进隔离表并打印；
  表满则明确打印"leaked"，不假装成功；
- 新增 NvBool nvKmsKapiReapQuarantine(void)，逐个重试释放。


ullmoth-r42-os-reap-quarantine.patch（序列第 36 项）：

- 
vkms_xnu_resume() 在 kms_deferred_drain() 之后调用 
vKmsKapiReapQuarantine()，
  使隔离的 Device 在 GPU 恢复时有重试机会。

### 新检查 check-kapi-alloc-owner.py

| 规则 | 断言 |
|---|---|
| E1 | ailed: 使用 
vKmsKapiTryFreeDevice，不是 void 包装 |
| E2 | 拒绝时把 Device 放进隔离表，而不是只打日志 |
| E3 | 隔离表与回收函数都存在 |
| E4 | 回收函数在 
vkms_xnu_resume 中被调用 |

自检 4/4（good / void_wrapper / no_reachability / no_reaper）。

### 验证（36 项序列）

| 检查 | 结果 |
|---|---|
| 序列逐项应用 | PASS |
| free-order | PASS |
| alloc-owner | **4/4 PASS** |
| 状态机 | 11/11 PASS |
| PM exclusion | 32/32 PASS |

### 边界

隔离表是**有界**的（4 个），满时明确记录泄漏而不是掩盖；回收只发生在 resume 且 GPU 正常时。
没有运行证据证明"被拒绝的关闭在下一次 resume 真的能成功"，也没有证明真实 RM 会拒绝。
