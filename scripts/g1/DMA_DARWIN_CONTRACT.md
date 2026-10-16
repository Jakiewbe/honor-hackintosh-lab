# P0-DMA: NVIDIA RM ↔ Darwin IODMACommand 适配合同（仅设计，NO-GO）

**固定版本**：NullMoth `cd8e2bb04da48d2fa70cf1895879608f3588dbfb`（`kexts/NVRM/os-xnu2.cpp` Git blob `c1fe41e9ff30649c6d02827aee5995f8eaa944b3`）；NVIDIA 610.57.04 `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`（`kernel-open/nvidia/nv-dma.c` Git blob `f3541a6bf629ce9400ce60dd8a7e09786db337ea`）。目标设备 HONOR GLO-FX6P / NVIDIA RTX 2050 `10DE:25A9`。**本文件不是运行授权。**

## 1. 确认的真实调用约定（Linux 是语义证据，不是可复制的 macOS 实现）

- `nv_dma_map_alloc(dma_dev, page_count, va_array, contig, bReadOnlyDeviceMap, priv)`：Linux `nv-dma.c` 从 `*priv` 读 `nv_alloc_t`，普通页走 `nv_dma_map_pages`，导入 scatter-gather table 走 `nv_dma_map_sgt`。底层的 `nv_dma_map_contig` 将返回 DMA 地址写入 `*va`，scatter 路径输出 DMA 地址段/数组；映射成功时 `*priv` 转为映射资源的句柄。`page_count` 表示页数，`contig` 情形不能错误地假定需要同样数量的 `va_array` 条目。
- 在 `nv_dma_map_contig`，DMA 地址必须满足映射错误检查和设备可寻址范围；超范围会解除底层映射再返回错误。后续 map 失败时，外层恢复先前 `*priv` 的语义。**中间步骤可能已改写调用方数组**，所以实际 Darwin 实现必须经过上游调用方审计确定失败时数组后置条件，而不是臆测 Linux 保证原子性。
- `nv_dma_unmap_alloc` 通过 `*priv` 识别映射种类，普通路径将 `*priv` 变回内部页数组后交由上层释放；**Linux 并不承诺把 `va_array` 恢复为原始 host 地址**。Darwin 的 private slot 销毁/复位政策需明确对接 RM 调用方，不能把测试模型的 `priv[0]=None` 当作原驱动 ABI。
- 目前 NullMoth `nv_requires_dma_remap` 固定 false，`nv_dma_map_alloc` 使用 identity 假设并返回成功，`nv_dma_unmap_alloc` 不持有映射资源也返回成功；无目标 2050 / IOMMU 正确性的证明。

## 2. Apple IODMACommand 源码/文档合同（仅候选路线）

Apple 官方文档：[IODMACommand](https://developer.apple.com/documentation/kernel/iodmacommand)、[prepare](https://developer.apple.com/documentation/kernel/iodmacommand/1811284-prepare)、[genIOVMSegments](https://developer.apple.com/documentation/kernel/iodmacommand/1811150-geniovmsegments)、[IOKit Managing Data](https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/DataMgmt/DataMgmt.html)。

可审查的意向时序：

1. 实机 PCI provider 与目标 IOMMU/IOMapper 的归属、DMA masks、设备方向/缓存属性通过版本精确的接口审查；必须能否定错误设备、地址范围和不存在的物理页。
2. 每个映射维护独立 `IOMemoryDescriptor`、`IODMACommand` 和 owner 资源；`setMemoryDescriptor` 后按正确上下文 `prepare`，利用 `gen64IOVMSegments` 取得**总长度覆盖输入的设备可见 I/O 地址段**；处理分段、页跨越、连续性、bounce 与对齐。**不能拿 `getPhysicalSegment(..., kIOMemoryMapperNone)` 的 host-physical 地址直接声称 DMA/IOVA 成功。**
3. 仅在所有分段均正确映射并检查设备 address aperture、整数溢出、RM 原地数组形态后，原子发布调用方的 `va_array` 与拥有映射的私有句柄；任何失败要逆序清理已经 prepare/映射/retain 的对象，不发布可用成功状态。
4. DMA 发起/完成同步和 `synchronize` 依据方向和 buffer 类型完成；**只有设备已停止访问对应地址**且所有依赖引用完成后，才调用 `complete` / `clearMemoryDescriptor` 并 release。不要在仍有活跃 DMA 时释放页或将同一 IOVA 重新分配给别的设备。
5. Apple 指明 DMA `prepare()` 可能阻塞，不能在中断过滤器、持 WorkLoop gate 等不可阻塞的上下文直接执行；需要独立核查该版本 kernel 可用的锁、内存顺序和对象析构合同。

**尚不清楚**：该 RTX 2050 的真实 IOMMU 地址转换/是否 identity、GSP 固件 DMA 描述符中的地址域和是否属于 IODMACommand 负责范围、可否对任意 RM 传入的物理页构建合规 IOMemoryDescriptor、从输入 scatterlist 到 Apple segment 列表是否需要 bounce，以及 macOS 目标版本的 kernel ABI。由此 **不能着手给实机装载一个盲目变成 `IOMapper` 的 kext**。

## 3. 事务式主机模拟器交付与边界

代码：`scripts/g1/dma_transaction.py`，测试：`scripts/g1/test_dma_transaction.py`，主线提交 `640c415fb8cba3a918ffdc0f6ac6d93b538d096f`。它有假的地址转换后端、单元素 private slot 和映射 receipt；成功时原地发布 IOVA；部分失败 rollback；失败的 rollback/unmap 标记 poisoned 并保留未释放租约；不让错误设备、错误页数、擅自改写的 IOVA 或 stale receipt 解除映射。**它不是 IOMMU/IOKit 的行为仿真，更不是可加载内核代码。** 目前没有模拟真实 bounce、cache coherence、异步 DMA 完成、GSP 固件、IOMapper 节点或多线程调度。

此前 `test_dma_contract.py` 的 10 项用例在 [Actions #38901244659](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38901244659) 真实通过。新增 `test_dma_transaction.py` 的 **13 项新用例已接入**轻量手动 [DMA CI](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/g1-dma-contract.yml)，**尚未实测**；只有拿到新 Actions 日志才算通过。

## 4. 验收与停止条件

- **合成测试门禁**：原有 10 项 + 新增 13 项全部通过；每次失败必须定位到有实际意义的映射不变量，并避免弱化安全断言来刷绿。
- **来源门禁**：upstream SHAs / blobs 均要实测；macOS 目标 Build/KDK 与现有 462 未解析符号逐项核查。
- **硬件门禁**：设备方向、可寻址范围、IOMMU 映射所有权、异步生命周期、GSP 操作和 DMA 静默无实证即 NO-GO；不因源码/CI 通过升级状态。
- **主力系统禁止项**：目前不加载 KEXT、不调用危险的手动 go、不更改 BIOS/EFI/磁盘、不关闭系统安全防护、不试图用 `NV_OK` 隐瞒真实映射失败。

下一个代码任务不是 B11 继续链接，而是 **将 RM 的 DMA 调用方、`nv_alloc_pages` 的 page descriptor 生命周期、`IODMACommand` 能否接受该类内存描述符的来源逐一打通**。在证据充分前保持 NO-GO。
