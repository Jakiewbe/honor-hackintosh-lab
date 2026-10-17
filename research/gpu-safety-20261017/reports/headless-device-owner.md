# 无头 NVKMS Device / VRAM / GPUVA 的最小所有权方案

状态：SOURCE-REVIEW；设计候选，尚未实现。固定 NullMoth ac55984 与 OGKM e4a5faa。不能据此启用功能或部署。

## 已回答的问题

| 问题 | 源码证据与结论 | 尚未证明 |
|---|---|---|
| 无物理 NVIDIA 显示器能否有 Device | OGKM nvkms-kapi.c:493-504 有明确 displayless 分支；allocateDevice:963-982先分配RM再分配KMS资源。其公共合同不要求连接显示器 | 本机 RM/GSP 成功、显存映射成功或 Metal 可用 |
| 谁创建 Device | NVRMFB/fb/nvrm-fb.cpp:664-673，首个 framebuffer 创建全局 gDev，其他 framebuffer 复用；privateData来自首次 this | 独立于显示的稳定 owner 尚不存在 |
| grabOwnership是否渲染前置 | nvkms-kapi.h:683 明确“ownership is required to do modeset”；GrabOwnership在hKmsDevice=0时直接成功 | 不能把这条源码分支当实际硬件初始化成功 |
| 对称释放 | 公共 releaseOwnership/freeDevice真实存在；NVRMFB当前文件未调用两者，stop:2082-2115主要撤回局部注册/回调 | 不能随意在某个 framebuffer stop中释放共享gDev |
| 无 framebuffer 的用户 | NVAccel::askFramebufferForVram:454-460依赖fFB；nvAccelRmHandles:1304-1327同样依赖fFB并全局缓存借用指针 | 仅恢复MetalPluginName不会创建这些内存服务 |
| 私有RM handles能否合法解析 | NVRM/nvrm_kapi_fields.c通过固定OGKM nvkms-kapi-internal.h的真实类型读取；nvrm_gpuva.cpp:43-52已复用它 | 外部不能猜结构偏移或把非空kapiDevice当有效期证明 |
| 回调能否注销 | mask=0只影响事件兴趣，不证明在途回调结束；OGKM event队列在锁外调用eventCallback | 必须证明关闭与回调自身重入之间的顺序 |
| 现有关闭保障 | os-nvkms-xnu.cpp:kms_close_common设置closing，取消/等待eventBusy，再free thread_call/per-open | eventBusy等待无期限；从自身回调关闭会自等待；PM失败仍会丢弃部分per-open引用，不能视作已quiesce |
| 休眠/复位 | 当前GPUVA与全局handles缓存没有按Device代际失效的完整合同 | VRAM、GPUVA、映射在sleep/reset后继续有效，均未证实 |

## 最小改造位置与唯一 owner

1. 将 Device 创建从 framebuffer::kapiInit 移到 NVRM 已确认 RM/GSP ready 且 NVKMS 可用后的独立内存服务。owner按物理NVRM/PCI设备唯一，不按framebuffer或显示数量创建。复用NVRM现有GPUVA执行函数，避免重复rm_init_adapter。
2. 服务持有真实NvKmsKapiDevice、分配登记、映射登记、GPUVA登记和代际。显示framebuffer只持有服务引用；有物理NVIDIA显示器时继续原有模式选择/显示初始化，只把Device来源改为共享owner。
3. modeset ownership与Device lifetime分开：仅显示客户端请求grab，最后一个显示客户端释放对应ownership；无头内存服务不谎称拥有显示器。freeDevice只能由owner在所有分配/映射/VA与回调均已安全结束后调用一次。
4. NVAccel的VRAM/handles请求转向该内存服务，不能让NMIntelFB充当fFB，也不能以Intel显存伪装NVIDIA BAR1。优先将操作经服务转发，而非长期外借原始kapiDevice；替代gRmHandlesValid全局永久缓存，使用受验证的owner/代际。
5. 失败原样传播：分配失败不发布handle；映射失败保留需要回滚的真实资源；GPU无法静默、取消或回收失败时保留quarantine所有权并返回错误，不能以NULL/identity DMA/成功Stub作为完成证据。
6. stop协议先拒绝新操作，再在不持有回调所需锁的控制上下文撤回回调和已接受操作；不从回调内部同步等待自身。不得重用早期0002租约等待方案，也不把超时后释放映射当回滚成功。
7. PM suspend/reset先关闭新提交并建立真实硬件静默，再更改代际；恢复时必须重新验证Device/VA/分配是否仍可用，不能只翻转ready布尔值。实验服务初始默认关闭，只有原生门禁和独立运行许可齐备后才讨论启用。

## 为什么本轮不直接实现 freeDevice

FreeDevice的公开返回值为void，KmsFreeDevice与底层XNU close路径并不向上提供完整可失败quiescence结果。直接补调用会把目前的资源泄漏变为潜在UAF/自等待。必须先修并验证os-nvkms-xnu.cpp:kms_close_common的可失败关闭/回调线程合同，再整合NVRM owner；不能从getDisplays失败就释放共享Device。

## Stop / BRIDGE-06 的明确边界

BRIDGE-01～06与旧0002实体未在当前仓库、隔离源码、工作区和附件的有限搜索中找到。没有可证实的补丁链，故有效序列仅本轮gpu-safety-r1.patch，不继承旧租约设计，亦不声称已修复缺失的0002。

v2.3.3 NMIntelFB仍有：裸scanout指针外借、volatile fStopping而非同步、thread_call_free无限重试及可能的回调自等待、虚拟采样timer清理不足。当前补丁只拒绝stop开始后的新查询并提供真实长度，**不能关闭已有指针与stop并发的竞态**。

真正BRIDGE-06式owner-copy应由NMIntelFB在自己持有的映射上完成同步、严格有界的CPU复制，不把目标kva外借；stop与复制共享明确的资源所有权协议，最终release必须在锁外。具体锁序要对照IOGraphics SYS→FB与回调上下文，不能现在发明一套锁就宣称安全。此改造处于GPU初始化和无头服务之后，不在本轮启用。

## 下一项最有价值的源码工作

先在kexts/NVRM/os-nvkms-xnu.cpp厘清kms_close_common及事件线程可重入/取消协议，然后在NVRM.cpp与nvrm_gpuva.cpp整合唯一内存owner。DMA回调的真实IOMapper/IOVA与GSP静默也仍是更底层P0；三条DMA回调函数体与旧cd8e2bb逐字相同，见evidence/dma-source-continuity.json，旧40/40不重复运行、也不能被当成实际映射实现。
