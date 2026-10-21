> **2026-10-21 撤回执行效力**：本历史计划基于旧R43链，不能用于当前272ccd9/ONCE候选。
> “加载但不触碰GPU”、初始化前默认睡眠/唤醒、热卸载回退等前提不成立。
> 下文仅保留历史设计，不得据此执行；当前唯一入口为
> [设备前检查与后续准入](../stock-v243-offscreen-20261021/DEVICE-CHECKLIST-20261021.md)，B/C均NO-GO。

# 设备阶段计划（2026-10-20，未授权，仅计划）

> **本文不是执行记录。** 截至 `40d17ef`，KEXT-LOAD 及以上一律 NO-GO。
> 本文只把"如果用户逐项授权，会按什么顺序做什么、看什么、如何回滚"写清楚，
> 使授权后不必临时设计。任何一步都需要用户针对该步单独批准。

## 1. 现在已具备的前提

| 前提 | 证据 |
|---|---|
| 官方完整构建（1280 TU + 归档 + 链接） | run 39189188122 / 39294220812 |
| 36 项序列 + 5 项链可逐项应用 | apply_series PASS |
| 关闭顺序（quiesce → FREE_DEVICE → NISO） | free-order 自检 7/7 + ASan 合同 `niso_frees` 断言 |
| 分配失败 owner | alloc-owner E1–E4 |
| PM 状态机与门忙 | 状态机 11/11、PM exclusion 32/32 |

## 2. 仍然**没有**的证据（必须在设备阶段取得）

1. 回调线程**真实并发**下 quiesce 是否真的排空（夹具目前用 `eventBusy` 建模）；
2. 真实 RM 是否会拒绝 `FREE_DEVICE`（拒绝路径只有注入模型）；
3. quarantine 里的 Device 在下一次 resume 是否真的能释放（`nvKmsKapiReapQuarantine` 运行结果）；
4. R40 的代价：断电时 GPU 未进低功耗态，唤醒后能否再次初始化；
5. 完整 ABI / loader 导出 / 卸载安全。

## 3. 阶梯（每步单独授权）

### D0 — 只读采集（无写入，建议第一步）

- 命令：`ioreg -l -p IOService | grep -i -A5 "AGDC\|NVDA\|IGPU"`、`kextstat | grep -i nv`、
  `csrutil status`、`system_profiler SPDisplaysDataType`、`log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"'`
- 目的：确认内屏当前由谁驱动、有无残留 NVIDIA kext、SIP 状态、是否存在已知 PM 违规日志
- 风险：**只读**，无
- 产物：文本日志，纳入仓库 `evidence/device-d0/`

### D1 — 安装不加载

- 前置：D0 完成；明确 kext 路径与版本；确认 `csrutil` 状态与所需设置
- 动作：把 kext 放入 `/Library/Extensions`，**不**执行 `kmutil load`；记录 `kmutil showloaded`
- 回滚：删除目录 + 重建 kext collection
- 观察：`kextutil -n` 静态校验输出

### D2 — 加载但不触碰 GPU

- 前置：D1 完成；用户单独批准
- 动作：`kmutil load -p <bundle>`；观察 `IOService` 是否出现 NVIDIA 节点
- 中止条件：任何 panic、`nvrm-pm-violation` 置位、`kextstat` 异常
- 回滚：`kmutil unload` + 删除 + 重建 cache

### D3 — 初始化（不接管显示）

- 前置：D2 稳定 ≥ 一次睡眠/唤醒周期
- 动作：触发 probe/init 路径，但**不**绑定 framebuffer；采集 `nvrm-pm`、`gKmsCloseDeferred`、
  `nvKmsKapiReapQuarantine` 的日志
- 中止条件：初始化返回非 0、任何 violation、关闭拒绝累积
- 回滚：unload + 重启

### D4 — 离屏渲染 + 像素读回

- 前置：D3 通过；用户单独批准
- 动作：最小离屏渲染，读回 1 像素并与已知常量比对；失败必须非零退出并保留日志
- 中止条件：读回不匹配、超时、任何 PM 违规

## 4. 每一步要采集的观测（对应上面的未证事项）

| 观测 | 回答哪个问题 |
|---|---|
| `nvrm-pm-violation` 是否置位、频率 | R40 路径是否真的可达；B1'/B2 取舍 |
| `NVKMS close deferred` 计数在睡眠/唤醒后的变化 | 延迟关闭是否积累 |
| `Allocation rollback refused; Device ... quarantined` 与后续 `reap` | quarantine 是否真的被回收 |
| 任何 `timed out waiting for its event call` | R41 的 10 s 边界是否被触发 |
| `niso` 释放顺序相关日志 | 回调排空是否真的发生 |

## 5. 明确不做

- 不修改 BIOS / Secure Boot / NVRAM / ESP / BCD / BitLocker / TPM；
- 不写入或格式化任何磁盘；
- 不在内置 NVMe 的 Windows 上做任何操作；
- 不在未授权时安装、加载、卸载任何 kext，也不执行 GPU 初始化。
