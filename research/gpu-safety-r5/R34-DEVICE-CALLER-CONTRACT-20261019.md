# R34：Device关闭的真实调用者合同与修复边界

本轮新增的是贯穿 framebuffer→OGKM→OS 的可证伪CPU合同与修复设计，**没有新增驱动补丁，也没有修复P0-4**。R33完整来源原生验收已通过；GPU未运行、设备NO-GO。

## 固定输入与真实结果

驱动源码7a5cb7188ef6477b7383f9529228bbb4426aa1fd / 原生run39189188122。NullMoth固定ac55984c473e746c2a8ebea7ba0913461aa7c393；原始611文件加31个固定补丁重建为614文件，整体tree28a9125ec7279a3c11fc51bbb10abf8d5fcc6d1798dcda83bea0fa4622b5a37d，与已验收候选一致。OGKM固定e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb加R33两项固定补丁，不改缓存。

tools/g1_fb_device_close_contract.py从实际文件提取完整dropKapiDevice()、finishOrphanedDevice()、OGKM KmsFreeDevice/FreeDevice/event handler、OS close/PM pin/running/unpin和队列辅助函数，编译实际kms_deferred.cpp。FB SHA4849c2f4...与OS SHA7d86b6b9...同时绑定已验收native-report；该报告完整SHA固定eb6cd2104952a8df3c9656fd48d5bf87eec8db9ddddf5db89b1adf21a3987c1d。OGKM源固定7e5492e0...。拒绝未知源和非固定报告，不能静默套用旧基线。

WSL现有g++真实编译exit0、执行总体exit1：

| 场景 | 结果 | 观察 |
|---|---|---|
| 最后使用者正常drop | PASS | 后端/wrapper/RM/Device释放各一次，creator释放一次 |
| 无使用者正常orphan收尾 | PASS | 两笔grab归还，释放一次 |
| 仍有其他使用者的drop | PASS | 共享Device和creator保留 |
| PM pin拒绝 | PASS | 实例脱离、共享owner和grab债务保留 |
| orphan但仍有使用者 | PASS | 只归还债务，不释放Device/creator |
| drop通过pin检查后FREE_DEVICE被拒 | **FAIL** | backend_close0、wrapper_free0、queue1；RM_free1、Device_free1、creator_release1、gDev/creator指针均丢失 |
| orphan收尾时FREE_DEVICE被拒 | **FAIL** | 同上，ownership_release2 |

两个失败不是被计入绿色总数的“预期通过”：工具本身真实exit1。源码已证明存在缺口，CPU合同进一步确认两个真实上层调用者都会丢掉共享所有权。初次fixture因注入层多带未使用变量编译失败，无二进制/未执行；只修正注入变量后在新目录编译。独立#error编译负控同样非零、无二进制、scenarios为空，不复用旧产物。

[原始场景、编译日志、实际生成fixture和结果](r34-caller-evidence/result.json)。实际NISO/RM/分配器/IOKit服务和releaseOwnership为注入边界，free只计数不删内存，display gate是替身；这里不证明真实XNU并发/锁实现、NISO失败或内核UAF。FREE_DEVICE处的拒绝/LOST转换是确定性注入，不声称正常suspend能够绕过真实pin。源码中pin本来就不能阻止另一条resume将状态改为LOST。

## 不能再用的局部改法

1. 只让OS wrapper入队：上层Device和creator仍会被释放，反例已覆盖。
2. 只在freeDevice调用后比较全局计数：破坏性释放已经发生，计数也不是单个Device的结果。
3. 只在FB失败时保留creator：已经被释放的Device仍无救，且不能恢复资源句柄。
4. 在eventBusy时等待而持有display gate：callback可能需要同一把gate；不允许用无界join把生命周期问题藏成死锁。
5. 只把表里的void改为bool：旧producer/consumer匹配、ABI和allocate回滚没有因此获得证明。

## 下一项源码修改的具体合同（设计，尚未实施）

使用独立、带版本的内部关闭接口；保留公开NvKmsKapiFunctionsTable布局。NVRM与现代NVRMFB显式配对新接口，缺接口时在分配Device之前拒绝启动，不能回退到旧void析构。接口可以通过既有nub属性机制发布，但必须有版本/表配对验证，不把“非空函数指针”当ABI验收。

关闭入口在gKmsLock下先拒绝新callback、取消未开始的事件；遇到在途callback只返回未完成，不等待display gate上的自己。只有callback对Device的引用已排空，且本次PM/RM准入可靠时，才开始NISO/KMS/RM破坏性清理。关闭状态必须区分保留待重试与已完成，失败不能恢复为可供kapiInit复用的活动Device。

NISO注销/解映射/RM free逐阶段检查结果，只在该阶段真实成功后清相应句柄；失败保留剩余资源和明确所有者。NVKMS FREE_DEVICE、per-open backend close失败须在RmFreeDevice/Device free之前传播。完成状态必须覆盖后端、wrapper、RM Device、GPU引用和回调上下文，不能只观察一层。

dropKapiDevice最后一个使用者和finishOrphanedDevice两处都必须消费显式结果：未完成时保留gDev、gDevCreator及重试状态；完成后才清全局和归还creator retain。kapiInit禁止复用关闭中的gDev。还必须覆盖AllocateDevice失败→KmsAllocateDevice清理→FreeDevice链：privateData/eventCallback只在KmsAllocateDevice成功之后写入，但失败后已分配Device/popen/RM资源仍需要明确保留owner，不能裸泄漏或由wrapper worker提前销毁。

锁序继续是display/startLock→gKmsLock，RM gate独立；不能持gKmsLock睡等一个要重新取得它的callback，不能在PM owner线程内联执行需要普通RM准入的回收。新接口在现代FB、OGKM、OS三层真正接线之后才可运行本合同候选版；不能先改测试期望或用未调用helper报完成。

验收顺序：本页两个真实反例在候选中变为PASS，并保留五条正常路径；增加callback在途/重试、每阶段失败、关闭中再绑定、allocate失败所有权、重复关闭及编译失败负控；补丁完整正反向和缓存不变；再做Darwin真实对象与完整官方参数最终路线验收。源码/CPU通过仍不放行设备。

## 当前断点

R33构建来源缺口已关闭。R34调用者合同已运行，P0-4仍FAIL，新的Device接口尚未实现。正常busy join、RM busy→STANDBY也仍FAIL；容量64、open rollback、完整ABI/loader、安全结束尚未闭合。下一动作是按上面合同实现最小可失败关闭候选，不继续重复1280构建或发布物来源审计。当前工具-only提交无需重跑未改变的原生驱动输入。
