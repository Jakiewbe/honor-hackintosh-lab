# IOVM64 到 NVIDIA RM 页地址数组：P0-DMA 新合同

证据状态：源码与独立手动 CI 入口已提交；新增 host C++ 及 Apple SDK 编译验证尚未运行；RTX 2050 DMA 和 GSP 实机均为 NO-GO。

## 证实的接口事实

- 固定 NullMoth 的 nv_alloc_pages 用 IOBufferMemoryDescriptor 分配并 prepare 内存，把 IOBufferMemoryDescriptor* 存储在 nv_xnu_alloc::md，之后从 getPhysicalSegment(kIOMemoryMapperNone) 形成主机物理页数组。主机物理地址不自动是设备 IOVA。
- 固定 NVIDIA RM osIovaMap 从 allocation owner 得到局部 pPriv，通过 nv_dma_map_alloc 映射并保存为 pIovaMapping->pOsData。分配记录与映射记录是不同资源，不可互相覆盖。
- Apple IODMACommand::gen64IOVMSegments 输出 Segment64(fIOVMAddr, fLength)，每段长度不必恰好等于一个 4096 字节 RM 页。RM 的 scatter va_array 需要一页一地址；contiguous 需要跨所有段连续的一项基地址。

## 本轮新增实质代码

- scripts/g1/dma_page_array.hpp：无 Apple 依赖、不分配内存、两轮验证后发布数据。检查页数乘法无溢出、每段页对齐、总字节覆盖完全匹配、设备地址宽度 1–64、最后字节落在设备 aperture 内、contiguous 相邻及输出数组容量。任一失败不改写输出。
- scripts/g1/test_dma_page_array.cpp：17 项 C++ host 断言，包括多段同址合并、scatter 断裂、长度/对齐/地址掩码/容量/溢出失败。已接入手动 P0 DMA Contract 工作流；目前尚未执行新增测试。
- scripts/g1/dma_iokit_segments_probe.cpp：使用真实 Apple IODMACommand::Segment64 类型和 gen64IOVMSegments 及上述转换器做 compile-only 接口验证。限定 32 个 segment scratch；准备范围未全部覆盖或非受支持地址排列时 fail-closed。手动 Darwin SDK Workflow 使用 Xcode16.4/SDK15.5 编译 x86_64 MH_OBJECT，仅存文本编译/nm/SHA256 证据；新增翻译单元尚未运行。

## 不能跳过的运行前提

1. 当前 nv_xnu_alloc::md 已由 nv_alloc_pages prepare，必须证明与新增 IODMACommand 的 prepare/complete 生命周期兼容；不可盲目重复 prepare 或提前 complete。
2. 必须在设备特定 IOMapper/IOMMU 地址域中形成真实可用的 IOVA，审计实际 DMA address bits 与方向/缓存同步。不能复制主机物理 pte 或强制 kBypassed。
3. 映射成功需要独立且确实持有底层资源的非空 pOsData mapping owner；错误时不能用假句柄掩盖或删除尚有引用的 owner。
4. 在 complete、clear、释放 backing descriptor 和关闭 PCI 前必须证明 GPU/GSP DMA 排空，stop/IRQ/worker 生命周期可回滚。无目标 macOS Build/KDK 或 provider 证据时不得进入实机。
5. 输入 IOVM segments 必须与输出数组互不重叠并且在两轮操作间保持不变。现有算法明确不支持非整页、未知地址位宽、超过 scratch 范围、异步变化的 segments、P2P/MMIO 混合空间，遇到此类请求必须拒绝。

已验收的历史证据：P0 DMA 40/40，Actions 38939252741；旧 Darwin SDK compile-only，Actions 38931389598。不可把历史 PASS 外推到本轮未运行的两个新 C++ 门禁。

最终状态：DATA-SHAPE ADAPTER SOURCE CANDIDATE；MAPPING OWNERSHIP / IOMMU / GSP / TARGET ABI = NO-GO。
