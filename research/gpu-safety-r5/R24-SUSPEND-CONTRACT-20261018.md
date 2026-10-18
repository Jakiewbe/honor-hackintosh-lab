# R24：撤回 R23 的错误前提，改成 begin/commit/abort（2026-10-18）

## 1. 已证实的前提错误（源码反证，非推测）

固定 XNU `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`，`iokit/Kernel/IOServicePM.cpp`：

| 行 | 代码 | 含义 |
|---|---|---|
| 4525 | `if ((result == IOPMAckImplied) \|\| (result < 0)) { fDriverTimer = 0; }` | **负返回值 = 立即完成**，与 ack implied 相同 |
| 4248 | 同一判断的第二处副本 | 同上 |
| 4242-4245 | 负返回值只 `PM_LOG(...)` | 仅记录一行日志 |
| 5552-5558 | ack 计时器到期：`kPMLogCtrlDriverTardy` + 日志，随后状态机继续 | 不 ack 也挡不住 |
| 1694 | `fDriverTimer == -1` 时接受 ack："return value from setPowerState() is irrelevant" | 可提前 ack |

**结论：IOKit 没有"拒绝睡眠"的返回值。** R23 的 `kIOReturnBusy` 拒绝机制不成立，**已撤回**，
对应结构检查一并删除，不保留旧结论。

## 2. 新合同：不靠拒绝，靠消除争用

```
setPowerState(0)                        （PM 线程）
  └─ gpuSuspend()
       ├─ nvkms_xnu_suspend_begin(&seq)     ← 先关闭 pin 准入
       ├─ notifyFramebuffers(0)             ← 之后 framebuffer 才停机；它们拿不到 pin，走孤儿保留
       ├─ nvkms_xnu_suspend_commit(gpu_id, seq, 60000)
       │     ├─ 等 pin 归零（有界）；仍不为 0 → 返回 false，**不碰 NVKMS**
       │     └─ 归零 → KAPI 通告 + 置 SUSPENDED + nvKmsSuspend（同一把锁内）
       └─ RM: 关 gate → 停 user channels → STANDBY
```

- **begin 在 notify 之前**：这是关键顺序变化。停机请求发生在挂起请求之后时无法取得 pin，
  于是不会延长等待窗口（这正是 R23 没做的）。
- **commit 失败**：`abort(seq)`、回滚 `fGpuPm`、`notifyFramebuffers(1)`、置 `nvrm-pm-violation=true`，
  **不关 gate、不停 user channels、不做 STANDBY**。
- **通知语义**：`setPowerState` 始终返回 `kIOPMAckImplied`（IOKit 没有别的选择），失败以
  `nvrm-pm-violation` 属性和 `VIOLATION` 日志记录，**不宣称挂起已完成**。

## 3. 仍未解决（P0-1 保持 BLOCKED）

commit 超时后，**IOPM 仍会把插槽断电**——驱动无法阻止（第 1 节）。此时 NVKMS/RM 都还活着，
属于"带违规断电"。它已被记录，但**没有解决**。因此：

> **P0-1 不关闭。** R24 修的是"争用窗口"和"错误前提"，不是"超时后的安全断电"。

`nv_xnu_pm_close(10000)` 超时仍 STANDBY 的既有风险同样保持原样。

## 4. 验证

| 项 | 结果 |
|---|---|
| 并发主机测试（begin/commit/abort，从真实函数生成） | **26/26** |
| R22 基线同一套测试 | **13 项失败**（含 `commit refuses while the pin is held`） |
| 负向控制 | 编译失败、无二进制、未运行 |
| 结构合同 | **24/24**（无 `kIOReturnBusy`；begin 先于 notify；失败分支不碰 RM） |
| 完整序列 | **24 个补丁**，`ea9467f4…` → `7ef22e29…` → `ea9467f4…` |
| `verify-all.py` | 全部离线步骤通过（含新增 `pm-host`，31 s） |

源码哈希见 `r24-evidence/run.txt`；XNU 证据文件 `r24-evidence/IOServicePM-a1e26a70.cpp`（284,767 B）。

## 5. 未执行

- Darwin 原生对象编译 / kext 链接：**未执行**（等你手动门禁；序列已含 R24）。
- KEXT-LOAD 及以上：**未执行**，NO-GO。

## 6. 下一断点

1. 你手动跑一次原生门禁（`patches: 24`），我登记；
2. 之后单独做 R22 审计项 B（VBL retain 唯一归还）——它是唯一还带"二次 release"风险的点；
3. P0-1 的"超时后安全断电"需要架构级方案（例如让 teardown 在挂起请求后不再触碰 KAPI 且可被证明有界），
   在当前接口下**无法证明**，保持 BLOCKED。
