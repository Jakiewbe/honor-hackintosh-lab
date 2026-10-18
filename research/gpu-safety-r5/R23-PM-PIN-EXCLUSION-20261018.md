# R23：teardown pin 与系统挂起严格互斥（2026-10-18）

> **撤回（R24，2026-10-18）**：本文第 2 节"返回 `kIOReturnBusy` 拒绝挂起"的前提**错误** ——
> XNU `IOServicePM.cpp:4525` 规定负返回值与 `IOPMAckImplied` 等价，挂起继续。本文保留作记录，
> 现行合同见 [R24](R24-SUSPEND-CONTRACT-20261018.md)；P0-1 仍为 **BLOCKED**。

本轮唯一实现目标：P0-1。不夹带 owner-copy、VBL、P0-4 或其它修改。

## 1. 真实调用链与设计依据

### 1.1 读到的调用链（固定源码，R22 状态）

```
IOPM（内核 PM，setPowerState 在“干净且独立的线程上下文”中调用）
  └─ NVRM::setPowerState(ordinal, device)                       NVRM.cpp:1356
       └─ gpuSuspend()                                          NVRM.cpp:1368
            ├─ OSCompareAndSwap(running → suspended, &fGpuPm)
            ├─ notifyFramebuffers(0)   → 各 framebuffer 停止/拆除（可能取 pin）
            ├─ nvkms_xnu_suspend(gpuId)                          os-nvkms-xnu.cpp:200
            ├─ nv_xnu_pm_close(10000)  → gNvPmGate 关闭，等 gNvPmUsers
            ├─ rm_stop_user_channels()
            ├─ pciSaveForSleep()
            └─ rm_power_management(STANDBY)
       └─ return kIOPMAckImplied        ← 无论上面做了什么
```

拆除侧（持 pin 的一侧）：

```
NVRMNVDAFramebuffer::dropKapiDevice()      kexts/NVRMFB/fb/nvrm-fb.cpp
  ├─ NVRMDisplayGate gate（startLock，递归）
  ├─ nvkms_xnu_pm_pin()                     ← R15，成功才继续
  ├─ releaseOwnership / freeDevice / ...
  └─ nvkms_xnu_pm_unpin()
```

锁序：`NVRMDisplayGate`（framebuffer startLock）→ `gKmsLock`；`gNvPmGate` 独立，
由 PM 线程在 `nv_xnu_pm_close/take/open` 中持有，`nv_xnu_pm_enter` 在 RM 调用前置位计数。
`nvKmsKapiSuspendResume(NV_TRUE)` 在 R22 中位于 `gKmsLock` 之外、**且早于 pin 等待**——若此时还有在途
操作，NVKMS 已被要求按挂起处理，但 GPU 还在跑。R23 把它移到 pin 归零之后。

### 1.2 R22 的缺陷（本轮要修的那一条）

1. `nvkms_xnu_suspend()` 等 pin **5 秒后继续**，并把状态切成 SUSPENDED、调用 `nvKmsSuspend`。
2. 调用者不管成败继续 `nv_xnu_pm_close` → `rm_stop_user_channels` → `rm_power_management(STANDBY)`。
3. `setPowerState()` 无条件 `return kIOPMAckImplied`，向 IOPM 报告挂起已完成。

所以"拿到 pin 就保证不被挂起"不成立；也不会向 IOPM 暴露失败。

### 1.3 XNU/IOKit 的真实完成契约（核对过，非推测）

`reference/IOService.h` 的 `setPowerState` 文档：

> The driver must return `IOPMAckImplied` if it has complied with the request when it returns. Otherwise,
> if it has started the process of changing power state but not finished it, the driver should return a
> number of **microseconds** which is an upper limit of the time it will need to finish. Then, when it has
> completed the power switch, it should call `acknowledgeSetPowerState`.

即：要么**同步完成**并返回 `kIOPMAckImplied`（`IOPM.h:551`，值为 0），要么返回超时（µs）并异步
`acknowledgeSetPowerState()`。

**R23 选择同步完成**：在 `setPowerState` 的调用栈内、PM 线程上把 pin 等干净再挂起；等不到就**拒绝**，
返回错误（`kIOReturnBusy`），**不返回 ack、也不调用 `acknowledgeSetPowerState`**。
这样不引入异步完成状态机（无需维护 provider 生命周期、重复完成、晚到请求等额外契约），
也不存在"报告已完成但实际没挂起"。

## 2. 设计：单一请求、关闭准入、有界等待、明确拒绝

状态（`os-nvkms-xnu.cpp`）：

| 变量 | 含义 |
|---|---|
| `gKmsPmState` | running / suspended / lost（不变） |
| `gKmsPmPins` | 已持有的拆除 pin（R15） |
| `gKmsSuspendPending` | 已接受的挂起请求；**置位期间不再发放新 pin** |
| `gKmsSuspendSeq` | 每次请求 +1；resume 也 +1，用来取消尚未提交的等待者 |
| `kKmsSuspendPinWaitMs` | 30000（有界） |

`NvBool nvkms_xnu_suspend(NvU32 gpuId, uint32_t waitMs)`：

1. 非 RUNNING → 拒绝（已挂起 / LOST）；
2. 已有 pending → 拒绝（重复请求）；
3. 置 `pending`、取 `seq`（**准入在此关闭**）；
4. 若 `pins > 0`，在 `gKmsLock` 上以 deadline 睡眠等待；**每个 unpin 唤醒这个地址**；
5. 超时、或 `seq` 被 resume 改变 → 撤销：`pending=false; seq++`，返回 `NV_FALSE`。**绝不调用 NVKMS**；
6. 只有 pin 归零且请求仍在 → `nvKmsKapiSuspendResume(NV_TRUE)` → 再取锁复核 seq/pins →
   状态置 SUSPENDED、`nvKmsSuspend()`、返回 `NV_TRUE`。若复核失败（resume 抢跑）→
   `nvKmsKapiSuspendResume(NV_FALSE)` 撤销并返回 `NV_FALSE`。

`nvkms_xnu_pm_pin()`：仅当 `state == running && !gKmsSuspendPending` 时成功——挂起请求一旦记录，
新拆除一律拒绝（fail-closed，走既有的孤儿保留路径，恢复后再回收）。
`nvkms_xnu_resume()`：清 pending、`seq++`、唤醒等待者，再执行既有恢复。

`NVRM::gpuSuspend()` 改为返回 `bool`：

- 失败时**不**关 `gNvPmGate`、**不**停 user channels、**不**做 STANDBY、**不**禁中断；
- 回滚 `fGpuPm`（suspended→running）、`setProperty("nvrm-pm","running")`、`notifyFramebuffers(1)` 重新点亮；
- `setPowerState()` 在 `gpuSuspend()` 返回 false 时 `return kIOReturnBusy`（**不报告完成**）。

### 2.1 为什么不在 unpin 里内联完成挂起

`unpin()` 的调用线程是 framebuffer 停机的上下文，可能仍持 `NVRMDisplayGate`；RM 的 PM owner 还有线程
身份约束（`gNvPmOwner`）。把整段挂起放进 unpin 会在这两个约束上出错。R23 让 unpin 只做一件事：
递减计数并唤醒**已经在 PM 线程上等待**的挂起请求——真正的挂起仍在 PM 线程执行。

### 2.2 错误与边界

| 情况 | 行为 |
|---|---|
| 重复 suspend | 立即返回 false（不排队、不嵌套） |
| resume 与 pending 竞争 | resume 清 pending + 改 seq；等待者为 false；若已过 KAPI 通告则撤销通告 |
| GPU LOST | 拒绝，不调用 NVKMS |
| 晚到的 unpin | 只减计数，不会触发挂起（请求已撤销或已提交） |
| 超时 | 拒绝挂起；`setPowerState` 返回错误；IOPM 视为失败而不是完成 |
| 分配/调度失败 | 本轮不新增线程、不新增分配，故无此路径 |

**明确未解决**：`nv_xnu_pm_close(10000)` 超时后仍继续 `rm_stop_user_channels`/STANDBY 的既有风险
（用户点名的第 6 条）**未在本轮修改**，也没有并入 P0-1 的结论。

## 3. 修改文件

| 文件 | 改动 |
|---|---|
| `kexts/NVRM/os-nvkms-xnu.cpp` | 新增 pending/seq 状态；`nvkms_xnu_suspend` 改为返回 `NvBool` 的有界等待 + 提交复核；resume 取消；pin 准入；`nvkms_xnu_pm_suspend_pending()` 诊断 |
| `kexts/NVRM/NVRM.cpp` | `gpuSuspend()` 返回 bool；拒绝时回滚且不做 RM 工作；`setPowerState()` 拒绝时返回 `kIOReturnBusy` |

补丁：`research/gpu-safety-r5/nullmoth-r23-pm-pin-exclusion.patch`（10,059 B，
sha256 `E7F0A54E…`），在 R1–R22 之上应用；序列现为 **23 个补丁**，完整应用/反向复原通过
（树 `ea9467f4…` → `5692f2ae…` → `ea9467f4…`）。

## 4. 测试证据（全部可复跑）

### 4.1 主机并发测试（从真实函数生成，非手抄）

- 生成器 `tools/r23-pm-fixture.py` 从**补丁后的** `os-nvkms-xnu.cpp` 中按大括号匹提取状态块与五个函数，
  平台桩用 pthread 实现 `IOLock*`/`clock_interval_to_deadline`，NVKMS 入口为计数桩。
- 驱动 `tools/run-r23-test.sh`：每次 `mktemp -d` 全新目录；编译失败 `exit 2` 且不运行任何产物；
  负向控制注入非法语句必编译失败且不产生二进制。

结果（`research/gpu-safety-r5/r23-evidence/`）：

| 运行 | 结果 |
|---|---|
| 候选（R23） | **23/23 检查通过** |
| R22 基线 | **11 项失败**，首条正是 `held pin -> suspend refuses` |
| 负向控制 | 编译失败、无二进制、未运行 → fail-closed |

候选覆盖的场景：无 pin 直接挂起；持 pin 拒绝且**不调用 NVKMS**；等待**有界**；准入恢复；
pending 期间新 pin 被拒；最后一个 unpin 让挂起成功且**恰好一次** `nvKmsSuspend`；重复请求被拒且首个仍完成一次；
resume 取消（`nvKmsSuspend` 为 0）；LOST 拒绝；撤销后晚到 unpin 不触发挂起；跨线程 unpin 完成一次。

源码哈希：`os-nvkms-xnu.cpp` = `b951b59e…`，生成测试 = `e834c993…`（见 `run.txt`）。

### 4.2 结构合同

`tools/check-pm-exclusion.py`：**25/25**——包括"撤销发生在任何 NVKMS 调用之前"、
"`nvKmsKapiSuspendResume(TRUE)` 在 pin 等待之后"、提交复核、`setPowerState` 拒绝路径、
以及"未使用异步 ack"。

### 4.3 未执行的验证（如实登记）

- **Darwin 原生对象编译与 kext 链接：未执行**。按指示不自行触发 Actions；需用户手动运行
  `gpu-safety-r5-native`（workflow_dispatch），补丁清单已含 R23。
- **KEXT-LOAD / GPU-RUNTIME / 显示 / 像素读回：未执行**，保持 NO-GO。

## 5. 登记但不修复的 R22 审计项

| 编号 | 内容 | 状态 |
|---|---|---|
| A | owner-copy 对所有非成功结果都回退到 kva，与"仅接口不支持才回退"的表述不符 | 已登记，**未修** |
| B | VBL 回调在 `fStopping` 分支 `release()` 后，`stop()` 仍可能 free 成功并再次 `release()`，同一 retain 缺唯一归还者；`armVbl` 分配失败也未归还 retain | 已登记，**未修** |
| C | R21 的 38/38 已撤销；R22 的 43/43 在测试材料归档前属作者报告，尚未独立复核 | 已登记，**未复核** |

## 6. 手动原生门禁（需要你在网页上执行）

1. 打开 `https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/gpu-safety-r5-native.yml`；
2. `Run workflow` → 分支 `main` → 输入 `xcode = Xcode_16.4` → 运行；
3. 期望：`patches: 23`、16/16 对象 exit 0、告警零增量、NVAccel / NVRMFB / NMIntelFB×2 链接成功；
4. 把 run id 回复给我，我登记为 R23 的 DARWIN-COMPILE/KEXT-LINK 证据。

## 7. 下一断点

- 若原生门禁通过：R23 的源码/主机测试/结构合同/Darwin 编译与链接即为完整离线闭环，**P0-1 的源码与并发合同可视为已关闭**；
  但 `nv_xnu_pm_close` 超时仍 standby（第 6 条）与 P0-4（void 接口不可传播）仍未解决，实机加载继续保持 NO-GO。
- 若门禁失败：以失败日志为准修正，不扩大改动面。
