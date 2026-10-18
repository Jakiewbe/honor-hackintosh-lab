# R27：VBL 引用的可控交错测试（补 R25 的行为证据）（2026-10-18）

R25 只有结构证明。本轮补上行为测试，且**不新增源码改动**（补丁序列仍是 26 个）。

## 方法

`tools/r27-vbl-fixture.py` 从 `kexts/NMIntelFB/intelfb.cpp` 用大括号匹配**原样提取**三个函数：
`armVbl()`、`vblFire()`、`NMIntelFB::stop()`。平台桩把 `thread_call` 换成可控对象
（`pending`/`running`/`freed` 由测试直接设置），因此每个交错都是确定性的，不依赖调度运气。

## 结果

| 运行 | 结果 |
|---|---|
| 候选（R26 树） | **11/11** |
| R22 基线（同一套测试） | **5 项失败**：`late callback does not double release`、`failed allocate takes no reference`、`stop keeps the reference when the call is in flight`、`a second callback entry releases nothing`、`re-arm keeps one reference` |
| 负向控制 | 编译失败、无二进制、未运行 |

覆盖：arm 只取一次引用；stop 成功只归还一次；晚到回调不再释放；分配失败不取引用；
回调在途时 stop 保留引用、由回调归还一次；二次 stop 不重复释放；二次 arm 不重复取引用。

## 边界

- 这是**主机模型**：`thread_call` 是桩，不是 XNU 实现；它证明的是我们代码的引用纪律，不是内核行为。
- LeakSanitizer 关闭（`detect_leaks=0`），因为桩自己分配对象；ASan 仍在检查所有访问。
- 已接入 `tools/verify-all.py` 的 `vbl-host` 步骤。

## 证据

`research/gpu-safety-r5/r27-evidence/`：`candidate.txt`（11/11）、`baseline.txt`（5 失败）、
`run.txt`（源码与生成物 sha256）、编译日志。
