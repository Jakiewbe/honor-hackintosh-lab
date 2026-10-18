# NVLink Darwin 锁后端候选（2026-10-18）

目标：消除完整 NVRM 重建候选中的四个真实内部缺口，不裁剪 NVLink 调用链，不使用空桩。设备运行继续 NO-GO。

## 本轮小型方案

- 输入：实验仓库 main `63e489892fb8b1702d6883c24cceb6087c911b7c`；OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`；NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393`。不修改 upstream。
- 已有事实：[run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) 完成 1280 个 C TU、5 个 shader 对象、完整归档和候选链接，剩四个 NVLink 内部导入与 471 个目标导出/ABI 未验收项。
- 契约：`nvlink_os.h:56–60` 声明 void acquire/release/free；`kernel-open/nvidia/nvlink_linux.c:564–598` 用初值 1 的 Linux semaphore。`nvlink_lock.c` 在 NV_LINUX 下开启顶层锁，不能移除该宏或调用以消除依赖。
- 候选路径：`research/gpu-safety-r5/darwin/nvlink_locks.cpp` 独立附加 TU。通过固定 OGKM 真实接口头校验 C linkage 和声明，显式编译并纳入完整链接清单。原版 OGKM 归档保持原样。
- Darwin 依据：[XNU xnu-11417.121.6 sync_sema.c](https://github.com/apple-oss-distributions/xnu/blob/xnu-11417.121.6/osfmk/kern/sync_sema.c)。`semaphore_wait()` 可返回 KERN_ABORTED（THREAD_INTERRUPTED）、KERN_TERMINATED（THREAD_RESTART）；`semaphore_signal()` 具有 prepost 语义；`semaphore_destroy()` 消费创建方引用。不把该参考源码当成目标系统导出或 ABI 证据。
- 实现：内核 semaphore 初值 1；create 失败释放包装内存并返回 NULL；acquire 仅 KERN_ABORTED 重试；其他 wait/signal/destroy 错误和无效句柄 panic，不假成功返回。void 接口没有可恢复错误通道，panic 是本候选的致命不变量策略，不能称为安全运行验收。
- free 必须由调用方保证无持有者、等待者和晚到调用。此后端不提供并发销毁、递归、线程 ownership 检查或生命周期仲裁；`nvlink_isLockOwner` 不属于本轮四个实际导入，不添加恒真实现。
- 可证伪点：真实源码的 CPU 故障/并发合同；原生对象精确四个导出；同 run 完整链接后四个导入消失且没有新导入；失败或缺失证据均拒绝通过。CPU 模拟系统边界不是 XNU 运行证据。
- 验收层级：工具与 CPU 合同 → Darwin 对象 → 完整源码候选链接。加载、GPU 初始化/渲染/像素读回均未授权。
- 回退：后端和完整构建集成可通过后续普通快进提交撤销，不改公共历史、不操作设备。

## 实际结果

源码提交 `0dcc527c1e2fa44867b55d70a2e387bcd5703be4`；[run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329) 实际 success。文本artifact `12133706259`，ZIP SHA256 `e1d20a5164368838cd68e7657cd47a39d0d2d6a069d7133f23057e1d822db312` 已下载校验；完整 report SHA256 `1f1143e8c9d57d6d28ec9aafdc5f91b787216ca68d3bba7eb2d0dc76a0f52eba`。

| 层级 | 真实结果 | 边界 |
|---|---|---|
| CPU合同 | 真实候选TU、17/17；12000次竞争临界区；编译失败负控没有二进制、未运行 | 系统边界模拟，非XNU运行 |
| Darwin后端对象 | 原生编译成功，精确四个外部导出 | 不含ownership恒真桩 |
| 完整构建 | 1280个C TU、5 shader对象、独立后端对象全部成功；归档1055/230 | 原版OGKM归档未修改 |
| 同run链接对照 | 导入 475 → 472；精确移除4个NVLink，新增1个_panic | 剩余目标导出/ABI均未验收 |
| GPU初始化/渲染/读回 | 未执行 | 加载及设备运行NO-GO |

候选SHA256 `bbde79f1601ee7bc89bcef04f48dc45276d39f9dec9e3f8bbed456f157c1e1d3`。source→object→symbol、命令、四个导出、最终符号与同run差分已本地独立复核；1278个官方源、两个生成ID与5个shader源哈希与固定输入对应。完整文本在run artifact（14天）；结构化摘要见 [nvlink-evidence/native-result.json](nvlink-evidence/native-result.json)。

本地58项工具合同及历史WP1 10/10、FBClaim 5/5、B2 7/7通过。参考清单初次提交的XNU摘要多计一个末尾换行，本轮已改为与固定提交Git blob `585f0d00c282bcf89f6fef5eee01c8f0360236c7` 一致的原始字节摘要，候选源码和已执行CI不受影响。

## 仍开放的边界与下一步

四个函数的真实构建/链接缺口本轮已关闭，不等于NVLink全调用链或设备生命周期验收。void接口不可恢复错误走panic，连续KERN_ABORTED会持续等待/重试，均不是可恢复安全结束证明；free仍要求caller先排空，不支持并发销毁。上层调用是否满足排空需后续源码证据。

剩余472个导入（含新增_panic）需逐项绑定目标系统/家族导出与ABI；完整官方逐TU参数的共享结构、签名、altstack/NULL栈仍未验收；旧probe选定布局MATCH不能替代。完整OGKM仍未自动集成局部KAPI探针修复，PM关闭/资源保留问题继续开放。

下一最小动作：从完整构建report的实际candidate_argv提取三个RM profile，与三个真实NVRM C++ profile比较，明确数据布局、调用约定及altstack行为；之后按剩余导入的真实目标提供者核对。不改.agent、不动upstream或旧检出、不安装/签名/加载、不传二进制。

本轮复盘：接口候选必须由真实信号量操作提供，接受标准是同一次运行的精确符号变化；不能用链接exit0、mock通过或错误被panic截断来宣称驱动可用。
