# R43 尝试与回退（2026-10-20）

## 目标

延迟关闭表（KMS_DEFERRED_CAPACITY = 64）满时，kms_close_remember_locked() 只打印
"wrapper retained without a queue slot"，此后**没有任何路径**能回收该 wrapper —— 有界但永久的泄漏。

## 尝试

draft-r43-close-overflow.patch（68 行）：

- struct nvkms_per_open 增加 
extOverflow；
- 新增 gKmsCloseOverflow 侵入式链表与计数；
- 压入失败时挂到溢出表，并在 kms_close_retry_fire() 的回收轮次里
  kms_close_overflow_drain_locked() 尝试关闭 + 释放；
- CPU 场景 overflow-reclaim：填满 64 项后再关闭一个，断言溢出计数为 1、wrapper 未被释放；
  再调用一次回收，断言恰好释放一次。

## 结果：两轮 CI 失败，决定回退

1. 第一次失败：kms_close_overflow_drain_locked 被 kms_close_retry_fire 调用但**定义在后** →
   夹具编译错误（"use of undeclared identifier"）。
2. 修正顺序后再次失败：close-retry 夹具仍未通过，且该工具当时没有编译/场景注解，
   拿不到具体错误；artifact 依旧 401。

已回退两个提交（4debcd7、6dfe58c），序列回到 36 项，**门禁 run 39333814389 success**。
补丁保留为 draft-r43-close-overflow.patch，未进序列。

## 当前残留（仍然是已知缺陷）

| 项 | 状态 |
|---|---|
| 表满时的 wrapper | 保留、不释放、不重复关闭 → **安全但有界泄漏** |
| 可观测性 | 内核日志一行 "deferred-close table full/conflicting" |
| CPU 覆盖 | 单元级 kms_deferred_audit.py 覆盖"溢出被报告"，**OS 层溢出回收未覆盖** |

## 下次重做的正确顺序

1. 先给 close-retry 工具加编译/场景注解（像 R36 工具那样），再改代码；
2. 夹具里显式构造 64 个 
vkms_per_open，先断言填满成功，再断言溢出；
3. 溢出回收函数必须定义在使用点之前（或前置声明）；
4. 每次只改一处，先让新场景在旧代码上**失败**，再上新代码让它通过。

## 结果：R43 已合入并通过（2026-10-20）

按上一轮记录的教训重做，四步都做到了：

1. **先加注解**：close-retry 工具现在会打印 RETRY_SCENARIO / RETRY_COMPILE；
2. **夹具顺序**：kms_close_overflow_drain_locked 定义在 kms_close_retry_fire **之前**，
   两个 static 全局也进入夹具前置声明；
3. **本地先看夹具文本**：无编译器也能生成 ixture.cpp 并核对定义顺序（6096 < 6629）；
4. **逐次只改一处**：先后两次失败都定位到具体问题（定义顺序、场景未持锁），不是盲改。

### 过程中第二个真实问题

overflow-reclaim 场景直接调用 kms_close_overflow_drain_locked() 时**没有持 gKmsLock**，
而 
vKmsClose 桩要求 lock_depth == 1，于是报
ackend close with gate shut/outside lock。这是**夹具错误**，不是代码错误：
真实调用点在 kms_close_retry_fire() 内，那里已持锁。场景已补上 IOLockLock/Unlock。

### 验证

- run **39339549232**（构建门禁，37 项序列 + 5 项链）：**success**，含 overflow-reclaim
  （填满 64 项 → 溢出计数 1、未释放 → 回收后恰好释放一次）
- 离线：状态机 11/11、PM exclusion 32/32、free-order PASS

## 回归护栏（2026-10-20）

CPU 场景证明的是"当前代码能把溢出的关闭回收"。为防止它**悄悄退回**"只打日志"，
新增结构护栏 	ools/check-kms-close-overflow.py：

| 规则 | 断言 |
|---|---|
| R1 | kms_close_remember_locked 在压入失败时必须把 wrapper 挂到溢出链表（而不是只打印） |
| R2 | 存在遍历该链表、通过 kms_deferred_try_free_impl 释放并在成功后摘链的回收函数 |
| R3 | 每个 kms_deferred_drain() 调用点在同一函数内也调用溢出回收 |

自检 3/3（good / log_only / no_companion），并有 4 项单元测试接入门禁。

### 接入时踩到的一个自己造成的 bug

工作流里的守卫步骤最初写成了 --source "\/nm"：我用 shell 内联 Python 生成 YAML 时，
PowerShell 把 $RUNNER_TEMP 展开成空串，只留下一个反斜杠。CI 因此把 /nm 当作源码路径，
守卫以非零退出，注解显示"an overflowed close could be lost again"——**看起来像代码退化，其实是工作流坏了**。

修复方式：改用编辑器直接改文件，并把 $RUNNER_TEMP 完整保留；同时让该步骤打印自己的输出
（OVERFLOW_GUARD RESULT: ...），避免下次再被一句通用错误掩盖。

### 验证

- 安全门禁 run **39343911721**：**success**，注解 OVERFLOW_GUARD RESULT: 3/3; PASS
- 构建门禁 run 39339549232（37 项序列）：success
