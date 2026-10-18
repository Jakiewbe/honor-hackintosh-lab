# R25：VBL 引用唯一归还（R22 审计项 B）（2026-10-18）

## 缺陷（R22 引入，登记未修）

1. `armVbl()` 在 `thread_call_allocate()` **之前** `retain()`：分配失败时没有 call，也就没人归还引用。
2. 二次 `armVbl()` 会为同一个 call 再取一次引用，而 `stop()`/回调只释放一次。
3. `vblFire()` 在 `fStopping` 分支无条件 `release()`，与 `stop()` 成功 free 后的 `release()` 可能对同一引用各释放一次。

## 修法：单所有者 + 标志位

- 新增 `bool fVblRefOwned`：表示"这个 call 持有一份对象引用"。
- `armVbl()`：已存在 call 直接返回；成功分配后**才** `retain()` 并置位；分配失败不取引用（日志写明）。
- `stop()`：仅在 `thread_call_free` 成功后，且 `fVblRefOwned` 仍为真时，清标志再 `release()`。
- `vblFire()`：`fStopping` 分支同样先清标志再 `release()`，二次进入不会重复释放。

三条路径都在同一串行化上下文（`stop()` 与回调互斥于 call 的生命周期）内完成"检查并清除"，因此一次 retain 只有一次归还。

## 验证（分层）

| 层 | 结果 |
|---|---|
| 源码 | 补丁 `nullmoth-r25-vbl-single-owner.patch`（sha256 `C1A2649B…`） |
| 结构合同 | **39/39**（新增 9 条：retain 在 allocate 之后、armVbl 只 retain 一次、失败不取引用、重复 arm 不重复取、两条释放路径都先清标志、单一 retain） |
| 完整序列 | **25 个补丁**，`ea9467f4…` → `1db6cab8…` → `ea9467f4…` |
| 离线总门禁 `verify-all.py` | **PASS**（bundle / 3×structure / pm-host / roundtrip / publish / ASan） |
| 主机行为测试 | **未执行**（本轮只有结构证明，没有针对引用计数的并发测试） |
| Darwin 编译 / 链接 | 由本轮 CI 门禁执行（见下） |
| KEXT-LOAD 及以上 | **未执行**，NO-GO |

## 未解决

- 结构合同不能证明并发正确性；"唯一归还"目前靠代码形态与串行化前提，缺少可控交错的引用计数测试。
- P0-1（挂起/pin）仍 **BLOCKED**（见 R24）。

## CI 结果

- R25 首次门禁 [39083549619](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39083549619) **失败**：
  `NVKMSOS-new-warnings` —— R24 把 `kKmsPmPinWaitMs` 的唯一使用者改掉后，该常量变成未使用，
  新增 `-Wunused-const-variable` 告警。门禁把"新增告警"判为失败是对的。
- **R26**（`nullmoth-r26-drop-unused-const.patch`，573 B）删除该常量；
  门禁 [39083710862](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39083710862) **通过**：
  `patches: 26`、16/16 对象、告警零增量、NVRMFB 315,848 B、NVAccel 248,768 B。
- 完整序列现为 **26 个补丁**，`ea9467f4…` → `0909aa6b…` → `ea9467f4…`。
