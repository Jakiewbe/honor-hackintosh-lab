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
