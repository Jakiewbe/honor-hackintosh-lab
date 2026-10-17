# GPU 源码候选 R4：UserClient 会话关闭与桥接 per-open 保留

R4 根据 WEB-REVIEW-003/004 的在途 ioctl 和失败传播问题，只修改 NullMoth 两个固定源文件。它为 NVRMUserClient 的外部方法分发、clientMemoryForType 和 clientClose 增加同一会话锁；关闭入口先关闭准入，桥接 ioctl 若因 NVKMS PM 状态不可用而无法安全关闭，则保留 per-open、Client 与 NVRM provider，清理步骤不继续，并提供内部显式重试入口。R4 在启用 PM 时于发布服务前分配 gate，分配失败则拒绝启动；`nv_xnu_pm_close` 对缺失 gate 返回错误哨兵，PM owner 身份检查改在 gate 锁内。`-nvrmnopm` 保留原有显式关闭 PM 的行为。RM gate 初始化与 owner 读取改动仍需原生验证，且 RM users 超时后当前代码仍会继续 standby。

修复文件与补丁：[nullmoth-r4-bridge-owner.patch](../patches/nullmoth-r4-bridge-owner.patch)。基础是固定 NullMoth ac55984 的 R1→R2→R3 顺序，再应用 R4；OGKM R3 空指针补丁仍独立。

## 首轮原生对象门禁结果

候选实现阶段未执行自动化测试或 Darwin 编译。随后用户手动运行 [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)，基于提交 `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`、Xcode 16.4 Build 16F6 / macOS SDK 15.5。作业在原版/候选对象编译步骤失败。报告记录两个 NVKAPI C 对象编译通过；五个 C++ 翻译单元的原版和候选共 10 个对象编译失败，首个错误类别均为 `IOPCIDevice` 的 SDK 弃用诊断被 `-Werror` 升级为错误。NVRM 日志到达编译器错误上限，后续是否还有其他诊断需在修正警告策略后确认。

诊断包：[artifact 12104692976](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976)，ZIP SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`。门禁脚本将仅对 `deprecated-declarations` 使用 `-Wno-error=deprecated-declarations`：保留警告输出，其他警告仍由 `-Werror` 控制。该修改不改变驱动源码；修正后的原生编译仍需用户手动运行。此次运行未链接 Kext、未加载驱动、未访问设备，也未运行 GPU。

范围限定：R4 为 NVRMUserClient 分发层提供单客户端串行化和失败保留；未解决 KAPI Device 的回调排空、共享 `gDev` owner、PM/RM gate 全活动静默、RM users 超时后仍进入 standby、FREE_DEVICE/void freeDevice 失败原子性、XNU 生命周期 ABI。外部平台 `nv_xnu_lookup_fd` 裸返回 UserClient 内嵌私有数据的引用合同仍待独立核对。因此关闭安全总门禁仍 BLOCKED，实机加载及 GPU 运行 NO-GO。

已检查候选 diff，仅两个固定源文件；没有修改 upstream 缓存或 `.agent`。R4 代码可按该补丁逆序回退。完整 Kext 链接未做。

