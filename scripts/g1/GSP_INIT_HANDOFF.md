# G1-B3 — RTX 2050 RM/GSP 初始化工程交接（静态，不可安装）

基线：HONOR GLO-FX6P，i5-12500H，Intel Iris Xe 8086:46A6（当前内屏挂载），RTX 2050 Laptop 10DE:25A9。macOS 已进入桌面，但未确认两块 GPU 的图形驱动加载或 Metal 硬件加速；内屏桌面明显卡顿。

固定源码：NullMoth `cd8e2bb04da48d2fa70cf1895879608f3588dbfb`；NVIDIA OGKM 610.57.04 `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`。B2 原生无补丁候选已在 Actions 38780579095 上产生 x86_64 `MH_KEXT_BUNDLE`，链接器 rc=0；这不是驱动可加载性或 GPU 渲染证明。

## 本轮真正的代码增量

- 从 NullMoth 上游 `610-fsp-timer-double-destroy.patch` 重新编译得到两个补丁对象：`kern_fsp.c.o` 和 `timer_ostimer.c.o`，替代 OGKM 原始归档的 `kern_fsp.o` 与 `timer_ostimer.o`。
- 用替换后的 **1055 个 RM 归档输入成员**、原始的 **230 个 modeset 归档输入成员**，连同 11 个 NullMoth NVRM 原生对象，执行实际的 Apple kext 链接；结果保留文本日志、SHA 与链接映射证据。没有发布、复制、签名、安装或加载任何驱动二进制。
- **不把显示完成补丁混入 GPU 初始化门禁**：`610-display-completion.patch` 需要与同版本 NVAccel/NVRMFB 接口配套，不能仅凭 NVRM 链接完成宣称内屏加速。
- **WP1 定义仍不明**，不将上游补丁自动等同于 WP1。

## 针对 25A9 的初始化代码边界

直接阅读固定源 `kexts/NVRM/NVRM.cpp`：
- `NVRM::probe` 使用 `rm_is_supported_pci_device` 决定是否匹配；设备表中有 25A9 不代表它通过实际 GPU 初始化。
- `NVRM::start` 会注册 PCI、读取并可能重新放置 BAR1，默认调度自动 `go(2)`。这不是只读流程，在真实硬件上可能改变显存窗口和总线状态。
- `NVRM::go(1)` 处理 `rm_init_rm`、事件锁、`rm_is_supported_device`、私有状态和 GSP firmware requested。
- `NVRM::go(2)` **启用 PCI Memory/Bus Master、配置 MSI，随后调用 `rm_init_adapter`**。失败回滚、并发和 stop 生命周期目前不能被“源码能编译”证明，尚未允许实机驱动加载。
- `NVRM::stop` 有 adapter shutdown、MSI removal、private state release，但 `rm_init_adapter` 失败的中间态不能假定自动等价于干净 stop。上游 FSP 补丁解决了一个具体双重销毁问题，**不等于整个失败回退链已闭合**。

固定源 `kexts/NVRM/os-xnu2.cpp` 的 GSP 文件读取通过 `nv_get_firmware` 从 `/Users/Shared/nvfw/nvidia/610.57.04/` 读取。Ampere `GA10X` 分支映射到 `gsp_ga10x.bin`、`gsp_log_ga10x.bin`、`ucodes_ga10x.bin`。这只是**源码中的硬编码路径合同**，不是这些文件存在、来自可靠来源、与 RTX 2050 GSP 启动兼容或能在当前系统中访问的证明。**不得从未知第三方下载固件或绕过校验。**

## 接下来必须完成的真实实现工作（按优先级）

1. **原生带 FSP 补丁的 NVRM 链接**：Runner 对链接映射中两个补丁成员的出现给出明确结果；失败则修复真实编译/归档/链接问题而不是跳过合同。
2. **失败回滚闭包设计与实现**：专门检查 `NVRM::go` 中 BAR1、PCI command、MSI、RM 私有状态、事件锁与 `fPassDone`，尤其 `rm_init_adapter` 返回失败后的处理与并发 stop；先做源码级状态转移和资源所有权，再提交窄范围修复补丁。
3. **固件 provenance 合同**：明确原始下载来源、版本、三个文件的真实 SHA256 与目标机是否已经具有相关文件；不得把“构建 NVRM”误当成“固件准备完成”。
4. **只读实机观察（未来单独授权）**：已实现的 Intel 基础显示必须保留，先锁定当前 macOS 版本、EFI 和可独立启动的恢复路径，并确认 RTX 2050 是否可使用 MSI/GSP。完成回退演练前继续 **NO-GO**。
5. 之后才是 NVIDIA 独立 GPU 命令提交、真实像素读回，再进一步讨论跨 GPU 复制与 Intel 内屏 WindowServer 加速。

每个阶段分开记录 **编译、链接、加载、初始化、真实渲染、内屏加速** 六种证据；不再以 CI 的成功颜色替代功能验收。


## 2026-10-16 追加：B3 FSP 修复归档链接已实证，转入真实初始化安全阻塞

基于 [Actions #38786989788](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38786989788) 文本产物：

- Commit `dde94b4091bd76cc5699255f60d1cd718011410e`，Xcode 16.4 / SDK 15.5；B1 RM 1055/1055、modeset 230/230、NVRM 本地源码 11/11 均编译。
- 两个 FSP 补丁的编译产物 `kern_fsp.c.o`、`timer_ostimer.c.o` 确认各被 ld64 选中一次，原始 `kern_fsp.o`、`timer_ostimer.o` 选中零次；这是**实际链接映射来源证据**，不仅是文件名搜索。
- FSP 补丁版 Apple 内核 bundle 链接退出码 0、MH_KEXT_BUNDLE x86_64、16,501,192 B、SHA256 `09e433f3b2a0a9fa0b6c2df8ab6fada7a4882f7f2d5be68e5b8e3ac5926f7703`；462 个未定义外部符号尚需目标内核 ABI 核实。二进制没有上传或加载，不能推出可用性。
- 整体 CI Failure 是 B2 在 WP1 和运行时未验收时按设计退出 2；**B3 FSP 链接子目标已实现并冻结**，不应继续重复跑同一套代码。

### P0：当前上游可证实的风险，不得用 `-nvrmnogo` 当作只读/零副作用开关

固定 NullMoth `kexts/NVRM/NVRM.cpp`（`cd8e2bb04da48d2fa70cf1895879608f3588dbfb`）：

1. `NVRM::start` 在解析 `-nvrmnogo` **之前**执行 `snapshotBootScreen(); placeLargeBar1(); readBARs();`。尤其 `placeLargeBar1` 在满足条件时直接写 GPU BAR1/BAR3 PCI config 和 Root Port prefetchable window，并可能进行 BAR resizing。即使内屏走 Intel 46A6，仍可能影响总线资源。**boot arg 仅关闭自动 go，不是被动探测模式**。
2. `placeLargeBar1` 成功写入硬件后，构建 `OSArray/IODeviceMemory` 失败时当前可直接 `return false`，没有在这个分支恢复 PCI BAR / Root Port 寄存器。正常成功后也看不到跨 `stop()` 生命周期的完整 BAR/Root Port 原状态恢复闭包。
3. `NVRM::go(2)` 在验证 MSI 是否存在**之前**执行 `fPCI->setMemoryEnable(true)` 和 `fPCI->setBusMasterEnable(true)`。当无 MSI、事件源创建失败或 `rm_init_adapter` 失败时直接返回；当前代码没有统一的 unwind 路径来恢复原始 PCI command / MSI / WorkLoop。`stop` 仅根据 `fAdapter` 判断是否 shutdown adapter，部分初始化成功但未置 `fAdapter` 的状态不能据此保证安全。
4. `NVRM::start` 还会自动调度 `autoGo`，启动显示栈及可能的翻转路径。对于当前 Intel 核显挂载内屏且缺乏图形加速的机器，不允许把一次成功编译的候选直接带入该路径。
5. GSP `nv_get_firmware` 从固定路径读取文件，没有经过 HONOR 机器上的固件来源、完整性及存在性验证。不能因为 Ampere 分支有 `gsp_ga10x.bin` 映射就断言 RTX 2050 已有可用 GSP 固件。

### 下一项真正的软件开发交付（不是继续增加指标）

**先开发一份独立、可审计的 NVRM 启动安全补丁；此处仅是开发约束，不是补丁已完成：**

- 将不可逆/可观测 PCI 写入之前的预检条件明确化；`-nvrmnogo` 的语义必须与实际副作用一致，不允许宣称其可安全观察。
- 对 `placeLargeBar1` 的 BAR resize、BAR1/BAR3、Root Port 0x24/0x28/0x2c、设备内存映射保留前值和有效标志，区分尚未修改、部分写入、完全修改。每个内存分配失败/校验失败分支按反向顺序恢复；失败后若无法证明恢复，明确 NO-GO，而不是继续调用 `go(2)`。
- 对 `go(2)` 的 PCI command、MSI EventSource、WorkLoop、RM private state、adapter init 进行资源所有权与状态转移建模，先核对上游 RM 半初始化时的合法清理接口；**不能武断对失败的 `rm_init_adapter` 调用 `rm_shutdown_adapter`**。
- 处理线程、boot hold 和 stop 的并发/生命周期：确认 `autoGo` 仍在运行时不发生并发销毁或重复释放。
- 通过固定源码 apply/compile/link、故障注入路径审查后，仍必须完成备份、EFI/磁盘/BitLocker 与实际恢复操作的核对；没有用户对实机加载的独立授权前继续禁止安装/加载。

**状态表：** NVRM FSP 补丁链接 `PASS (CI only)`；PCI 状态失败回滚 `UNVERIFIED / P0`；FSP/GSP 真实初始化 `UNVERIFIED`；GPU 指令与像素读回 `UNVERIFIED`；Intel 内屏硬件加速 `NOT ACHIEVED`；实机 `NO-GO`。
