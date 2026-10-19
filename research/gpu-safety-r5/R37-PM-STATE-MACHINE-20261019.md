# R37 重做：PM 状态机合同（设计稿，无可实施补丁）

> 原 `draft-r37-refuse-standby-when-busy.patch` 已撤下（见 `attic/`）。原因是独立审计与我自己的复核都确认：
> 它在 `nvkms_xnu_suspend_commit()` **已成功**之后调用 `nvkms_xnu_suspend_abort(seq)`，而 abort 只在
> `gKmsSuspendPending && gKmsSuspendSeq == seq` 时生效（候选 `os-nvkms-xnu.cpp:374-385`，commit 在 364 行已把
> pending 置 false），因此是**空操作**；再把 `fGpuPm` 改回 Running，唤醒时 `setPowerState` 会因
> `pm == kGpuPmSuspended` 不成立而跳过 `gpuResume()`，留下 NVKMS 已挂起、RM 未 standby、XNU 已睡眠的分裂状态。

## 1. 参与状态的四份真相

| 状态 | 存放位置 | 由谁改 |
|---|---|---|
| `fGpuPm` | `NVRM` 实例（Running / Suspended / Lost） | `gpuSuspend` / `gpuResume` / 违规回滚 |
| `gKmsPmState` | `os-nvkms-xnu.cpp`（Running / Suspended / Lost） | `nvkms_xnu_suspend_commit` / `resume` / `suspend_abort` |
| `gKmsSuspendPending` / `gKmsSuspendSeq` | 同上，挂起请求令牌 | `begin` / `commit` / `abort` / `resume` |
| RM | 内核 RM 内部（D0 / STANDBY / 未通知） | `rm_power_management`、`nvKmsKapiSuspendResume` |

**合同核心：任何时刻，这四者的组合必须是下表允许的之一。**

| # | fGpuPm | gKmsPmState | pending | RM | 允许？ |
|---|---|---|---|---|---|
| 1 | Running | Running | false | D0 | ✅ 正常 |
| 2 | Suspended | Suspended | false | STANDBY | ✅ 完整睡眠 |
| 3 | Suspended | Suspended | false | D0（standby 失败） | ⚠️ 允许，但必须记录并向唤醒路径证明可恢复 |
| 4 | Lost | Lost | false | 任意 | ⚠️ 终止态，只能走 `resume` 重初始化 |
| 5 | Running | Suspended | false | D0 | ❌ 当前 R37 草案会落在这里 |
| 6 | Suspended | Running | false | 任意 | ❌ 顺序不可能，但一旦出现说明 commit 未执行 |
| 7 | 任意 | 任意 | true | 任意 | ⚠️ 仅允许在 `begin` 与 `commit/abort` 之间 |

## 2. 挂起的真实顺序（现有代码）

```
setPowerState(0)
  └ gpuSuspend()
      ├ CAS Running→Suspended, setProperty("nvrm-pm","suspended")
      ├ nvkms_xnu_suspend_begin(seq)         ← pending = true
      ├ 通知 framebuffer 停机；等 teardown pin 排空
      ├ nvkms_xnu_suspend_commit(seq)        ← pending = false；gKmsPmState = Suspended；nvKmsSuspend(gpuId)
      ├ nv_xnu_pm_close(10000)               ← 关 RM 门，等 10 s
      ├ [busy] ?  ← 就是这里出事
      ├ rm_stop_user_channels()
      └ rm_power_management(STANDBY)
```

关键点：**commit 之后，NVKMS 已经进入 suspended 且 `gKmsSuspendPending` 已清**。所以 busy 分支面对的是
"NVKMS 已挂起、RM 还有调用在跑"的状态，撤销只能通过 **resume 路径**，而不是 abort。

## 3. busy 分支的三种可选语义（必须选一并写明代价）

| 方案 | 动作 | 代价 | 需要什么证据才能采纳 |
|---|---|---|---|
| B0（现状） | 记日志后继续 `stop_user_channels` + `STANDBY` | 在 RM 有活动调用时推进 RM 状态 | 证明"活动调用与 STANDBY 并发"在真实路径不可达（否则不可接受） |
| B1'（正确版拒绝） | **不 abort**：保持 `fGpuPm=Suspended`/`gKmsPmState=Suspended`，跳过 RM standby，置 `nvrm-pm-violation`，睡眠照旧发生 | GPU 未进低功耗态被断电；唤醒必须走完整 `gpuResume`（含 NVKMS resume） | 断电-上电后 GPU 能否再次初始化；唤醒后 NVKMS 是否自洽 |
| B2'（回滚） | busy 时先 `nvkms_xnu_resume(gpuId)` 把 NVKMS 拉回 Running，再 CAS `fGpuPm→Running`，然后跳过 RM standby | 在一个可能已被 IOKit 断电的窗口里重新初始化 NVKMS；失败则进入 Lost | 需要证明 resume 在"睡眠已开始"的时序里不会碰已断电的设备 |

B1' 与 B2' 都**不能**改变一个事实：XNU 不提供拒绝睡眠的手段（`IOServicePM.cpp:4525`）。

## 4. 实施前必须新增的合同检查（都可离线做）

1. **状态合法性检查**：解析 `NVRM.cpp` 与 `os-nvkms-xnu.cpp`，枚举所有对 `fGpuPm`、`gKmsPmState`、
   `gKmsSuspendPending` 的写入点，断言不存在"只改一个"的路径（每个写入点必须伴随另一个的显式转移，
   或在注明的窗口内）。
2. **busy 分支检查**：断言 busy 分支内**不出现** `rm_power_management`、不出现 `suspend_abort`，
   且在返回前要么完成 resume，要么保留 `Suspended` 两侧一致。
3. **唤醒对应检查**：断言 `setPowerState(ordinal != 0)` 的分支条件与 `gpuSuspend` 的终态一致——
   即"进入过 NVKMS suspended"必然能在唤醒时触发 `gpuResume`。

这三条都是源码结构检查，不需要设备；先写检查、再写实现，避免再出现 R37 那种"补丁先行、状态不一致"。

## 5. 本轮只做设计，不做实现

理由：R37 的失败不是"少写一行 resume"，而是缺少一个能被证伪的状态机合同。在 §4 的三条检查到位之前，
任何 busy 分支补丁都只是换一种方式分裂状态。
