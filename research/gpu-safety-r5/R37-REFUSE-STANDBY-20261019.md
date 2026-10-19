
# R37 草案：门忙时拒绝 STANDBY（B1 形态）

## 依据

	ools/check-pm-exclusion.py 现在断言"RM 门忙必须阻止挂起"，当前代码**失败**（31/32、exit 1）。
这不是检查写错，而是把已知危险行为固化成通过项后的纠正。本草案给出让该检查能自然转绿的一种实现。

## 改动（草案，未合入）

esearch/gpu-safety-r5/draft-r37-refuse-standby-when-busy.patch（27 行 diff）

在 NVRM.cpp::gpuSuspend() 里，
v_xnu_pm_close(10000) 返回非零时：

1. 
v_xnu_pm_open() —— 先把门重新打开，让仍在 RM 里的调用**跑完**，而不是被关在门外直到唤醒交接；
2. 
vkms_xnu_suspend_abort(seq) —— 撤销此前 suspend_begin 占用的 NVKMS 挂起请求；
3. OSCompareAndSwap(kGpuPmSuspended, kGpuPmRunning, &fGpuPm) + setProperty("nvrm-pm","running")；
4. setProperty("nvrm-pm-violation", kOSBooleanTrue) + 
otifyFramebuffers(1) —— 与既有 pin 违规路径同样的上报；
5. 记录日志并 eturn false，**不调用** m_stop_user_channels / m_power_management(STANDBY)。

## 为什么不是"直接 return false 就安全了"

XNU IOServicePM.cpp:4525：setPowerState 返回负值等同 implied ack，**系统照常断电**。
所以 B1 并不能阻止机器睡眠；它阻止的是"**在 RM 仍有活动调用时把它推进 STANDBY**"。
随之而来的是一个已知代价：系统断电时 GPU 不在低功耗态，RM 也从未收到睡眠通知。
这个代价只能用实机观测来裁定是否可接受。

## 裁定 B1 与 B2（保持现状）需要的最小观测集

| 观测 | 为什么能裁定 |
|---|---|
| 睡眠/唤醒后 
vrm-pm-violation 是否出现、出现频率 | 判断 10 s 超时是否真实可达（若从不触发，B1 是死代码） |
| 唤醒后 m_resume 返回码与 NVKMS 是否恢复 | B1 下 RM 未被通知睡眠，唤醒路径是否仍自洽 |
| 唤醒后 gKmsCloseDeferred 是否持续增长 | B1 不改变延迟关闭语义，但可暴露 PM 交错 |
| 睡眠期间是否有 RM 调用超时/断言日志 | 判断"活动调用与断电并发"是否真的发生（B2 的风险面） |
| 断电-上电后 GPU 是否可再次初始化 | B1 的核心未知：GPU 未进低功耗态时被硬断电 |

在上述任一项有观测前，**不建议把 B1 设为默认**；它应保持为可施加草案。

## 状态

- 本地 git apply --check 通过（R27 树）
- 未合入序列、未编译、未实机
- 检查仍 31/32 FAIL；草案合入并通过门禁后才可能转绿
