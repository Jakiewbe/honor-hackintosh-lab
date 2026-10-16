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


## B4 2026-10-16 源码补丁与隔离原生链接候选（未运行 Actions）

提交链：

- `98454a4be6594c25ae5926a7286a136850e6ece5`：首次独立 B4 源码补丁，仅修改固定上游 `kexts/NVRM/NVRM.cpp` 的 6 个局部位置。
- `3f587e893e341146e0acb5a6f17b28c6c5af9772`：将 B4 接入显式选择的 GitHub Actions 编译/链接路径；原 B3 链接候选保留不变，B4 对象、临时目录、链接报告独立。

静态校验：六个补丁 hunk 已与固定上游 `NVRM.cpp` 精确逐行匹配（Git blob `bf16040acf05fc1b3dee679a93b8d9973d557d06`），原生 `git apply --check`、`clang++` 和 `ld64` 尚未运行验证，因此不能标记 B4 PASS。

B4 修复内容是有界的：

1. 在 `NVRM::start` 更早读取 `-nvrmnogo`。若手动启动模式被选择，跳过启动前的 `placeLargeBar1` 调用，但仍会运行其他初始化与屏幕快照代码，**不能称为 read-only 模式**；之后人工执行 `go(2)` 仍有真实 PCI/GSP 侧效应。
2. 在 `NVRM::go(2)` 中把 MSI 查询、工作队列及中断源创建和附加移动到 PCI Memory/Bus Master 使能之前，已发生的预初始化内存分配失败不应开启设备总线主控。
3. 已进入 `rm_init_adapter` 并失败时将实例置为“禁止再次初始化”。此标志仅作用于**该 NVRM 实例**，不是跨卸载或重启的安全机制，也不证明 DMA/GSP 资源已回收。

**严格保留的 P0 阻塞：** 正常自动模式 `placeLargeBar1` 成功改写后尚无完整 stop 回退；BAR 修改后的对象分配失败存在未恢复状态；`rm_init_rm`/事件锁分阶段失败处理不完整；`rm_init_adapter` 半初始化清理合同没有上游可核验的闭包；`autoGo`、中断回调与 `stop` 的并发释放关系未验收。**B4 即使编译/链接成功，实机仍维持 NO-GO。**

下一次手动 CI 参数：`main` / `Xcode_16.4.0` / `EXTRA=-DNV_UNIX -DNV_LINUX` / `drop_flags` 留空； `run_rebuild=true`、`run_b2_probe=true`、`run_b4_probe=true`。本次运行按既有策略始终返回 B2 `BLOCKED`；按 `b2-native-probe.json` 的 `b4_source_patch` 和 `b4_native_link_candidate` 判读真实结果，不以上层红色状态代表 B4 链接失败。二进制不上传、不签名、不安装、不加载。


## 2026-10-16 G1-B4 CI 实测结果（已冻结，下一阶段不重复相同测试）

- 实际运行：[GitHub Actions #38836458007](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38836458007)，提交 `14b585231be2ac4411e88a425281fa1dcb5e36f7`，Xcode 16.4、macOS SDK 15.5。
- B1：RM 对象 1055/1055、modeset 对象 230/230，独立 validator 通过。
- B3 基线：带两份 FSP 修补对象的 NVRM 完整链接成功（Apple clang++ RC=0）；修补后的 `kern_fsp.c.o`、`timer_ostimer.c.o` 在链接映射中各选中一次，原件均未选中。
- B4：固定源码的 `b4_nvrm_manual_go_msi_preflight.patch` 通过 SHA256 校验（`deed09545b1a3a54096ab36a7f4809a0b891fea5eef8d5ca1615bbd2bb9b5e44`），`git apply --check` 和 `git apply` 均 RC=0；修改后的 `NVRM.cpp` 原生编译 RC=0，38 条 warning，未出现编译错误。
- B4：Apple 原生 NVRM 链接 RC=0，x86_64 `MH_KEXT_BUNDLE`，大小 16,501,256 B，SHA256 `d1dfc28888fd75983a02654a6f43dd8114025f9f5e5f0f9257e76f487d64b05a`；链接映射中 B4 `NVRM.cpp` 对象选中 1 次，未修补原始对象 0 次；FSP 两个修补对象仍各选中 1 次。剩余 462 个未定义外部引用仅为静态数量，不代表 macOS 内核一定可以满足。
- GitHub Actions 总结果 `failure` 源于测试脚本保守返回 `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE`（exit 2），**不是 B4 原生编译或链接失败**。
- 未生成可发布的 kext 安装包，没有签名、安装、加载或访问 RTX 2050 硬件。

### 下一项功能阻塞：B5 PCI/BAR 与半初始化安全清理（尚未实现）

不应再重复已验证的 B3/B4 原生链接。应以固定 NullMoth 源码真实实现以下狭窄 P0 修复，再进行一次新的原生编译/链接：

1. **BAR1 改写事务的异常回滚。** `NVRM::placeLargeBar1()` 在 GPU BAR1/BAR3、Resizable BAR 和 Root Port 窗口写入后，构建 `OSArray/IODeviceMemory` 失败时可能直接返回 false。应保存修改前硬件状态，识别部分修改，按反向依赖恢复 BAR、桥窗和命令寄存器，并逐项读回核验；不可仅恢复一部分状态就报告成功。
2. **PCI command 所有权与中断资源。** `NVRM::go(2)` 已在 B4 将 MSI 查询/资源准备放在 Memory/Bus Master 使能之前。但正常 stop 及错误路径尚不能证明恢复原始 PCI command；不能假定强行关闭 DMA 在部分 GSP 初始化失败后总是安全。
3. **半初始化 RM/GSP 的清理合同。** 要先核对被固定的 NVIDIA RM 的内部生命周期和 `rm_init_adapter()` 失败语义，明确何时可安全调用 `rm_shutdown_adapter()`，避免虚构回退逻辑；需要以 `fAdapterInitFailed` 区分故障终止、手动重试和重入场景。
4. **并发 stop 及自动线程。** 检查 `autoGo`、boot-hold timer、中断回调、用户客户端与 `NVRM::stop()` 的生命周期；在拥有证据前不允许以“能链接”替代安全性验收。

**硬件状态仍为 NO-GO：** 当前 HONOR 内屏挂载 Intel 46A6，macOS 桌面严重卡顿；两块 GPU 的 Metal 加速均未实证，RTX 2050 的 GSP 启动、命令执行和像素读回均未验证。正式实机加载需要独立的备份、回退和授权条件。


## 2026-10-16 G1-B5 原生链接实测结果及下一阶段 P0（已核对实际产物）

实际运行：[GitHub Actions #38838922705](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38838922705)，提交 `e626b0eb0de5702ff19502290aa9b2e3dc3e95b3`，Xcode 16.4、macOS SDK 15.5，实际 JSON 产物 `b2-native-probe.json` 与编译/链接文本日志一致。

### B5 构建证据

- B1：RM 1055/1055 与 modeset 230/230 原生对象构建完成。B3 基线、B4、B5 分别在隔离目录中链接。
- B4 修补版：`NVRM.cpp` 编译 RC 0，Apple 内核 bundle 链接 RC 0；`NVRM.cpp.b4.o` 在 Apple 链接映射中实际选中一次，基线 `NVRM.cpp.o` 零次；16,501,256 字节，SHA256 `e564ab111e9185c0973e20966d37aba18194eae29e9b7e12029b69a38687bce6`。
- B5 叠加 B4：固定上游 `b5_nvrm_bar_rollback.patch` 被 `git apply --check`、`git apply` 接受；B5 的 `NVRM.cpp` 原生编译 RC 0（38 warnings），链接 RC 0；`NVRM.cpp.b5.o` 在链接映射中选中一次，未修补基线对象零次；16,501,424 字节，SHA256 `57f2f2d8fb46e84d50a37f5d659a2d0df1e338943d58025500957b668d4590a2`。
- B5 链接保持 FSP 两个已修补成员 `kern_fsp.c.o` 和 `timer_ostimer.c.o` 各选中一次，两个原始成员均未选中。格式 x86_64 `MH_KEXT_BUNDLE`；剩余 462 个未定义外部符号，尚不能推断目标 macOS 内核的符号提供能力。
- Actions 的 `failure` 来自 B2 依设计返回 `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE`（RC 2），而非 B4/B5 编译失败。**B5 的真实原生链接子目标已 PASS，无需原样重复同一 CI。**

### B5 源码的实际边界与仍待修复的 P0

固定补丁 `scripts/g1/patches/b5_nvrm_bar_rollback.patch` 将 `OSArray`、`IODeviceMemory` 分配与对象列表填充放在首次 PCI 写入之前；为失败路径增加原 PCI command、BAR1/BAR3、ReBAR、Root Port prefetchable window 的恢复及读回验证，并在读回失败时阻止继续设备注册。这是**具体的局部安全改动**，不是整套 GPU 生命周期安全证明。

仍存在必须通过实际补丁关闭的风险：

1. **成功的 BAR 重定位未见完整逆操作。** B5 在重定位成功后设置 `nvrm-bar1-placed` 并返回 true，固定 NVRM 的 `stop()` 只处理 RM adapter、MSI 事件源、WorkLoop、private state，不恢复 BAR1/BAR3、ReBAR、Root Port 原始窗口及对应 IOPCIFamily 设备内存描述符。必须明确恢复责任、时序和同一桥上其它设备的依赖，不能把失败回滚等同于正常 stop 回滚。
2. **`rm_init_adapter()` 失败后的半初始化状态未安全清理。** B4 的 sticky flag 阻止同一对象上的重新执行，但无法证明 GSP、DMA、RM 锁和 GPU 中断资源均可安全销毁，或重新实例化后不会重入损坏状态。
3. **PCI command/MSI 状态仍未形成统一生命周期合同。** B4 改善了初始化前置检查，但 `stop()` 和故障终止时原始 PCI command 的恢复、已激活的中断回调与工作队列 drain、设备所有权仍需独立实现与审查。
4. **自动启动、定时器与 stop 并发风险依旧。** 必须针对 `autoGo`、boot-hold cap、headWatch 与 stop 的取消/引用计数作事件顺序验证。
5. **GSP 固件与目标硬件/系统兼容性没有证据。** 固定路径 `/Users/Shared/nvfw/nvidia/610.57.04/` 的真实文件存在性、来源、哈希及 macOS 版本合同仍未知；CI runner 未连接 RTX 2050。

**验收原则：** B3、B4、B5 `PASS (native compile/link only)`；安全加载 `NO-GO`；RTX 2050 实际 GSP 初始化/命令执行/像素读回及 Intel 内屏加速仍然 `UNVERIFIED`。下一步不重复链接统计，优先实现可审计的 PCI/BAR 成功路径 stop 回退与 adapter 错误状态所有权合同；实机操作必须待独立备份、回滚实证及用户授权。


## 2026-10-16 G1-B6：实验性 BAR 正常停止恢复候选（代码完成，macOS 编译待验收）

当前基线最新提交 `ffced5daf01e152a16392fb79e23c9e6b67c21ff`，补丁为 `scripts/g1/patches/b6_nvrm_bar_stop_ownership.patch`，固定 Git blob SHA1 `9fe603c6b1a84831ef9904471ddfd27378d6927b`。已从固定 NullMoth 原始 `NVRM.cpp` 顺序应用 B4（6 hunks）+B5（5 hunks）+B6（8 hunks）做源码行级验证通过；**尚未在 Xcode 下执行 B6 `git apply`、`clang++` 或 `ld64`**，不得写作 B6 LINK PASS。

B6 为**真正源码候选变更**，包括：

- 自动模式下默认跳过 `placeLargeBar1()`，需显式实验参数 `-nvrmrelocate` 才进入资源重定位（此参数**不构成安全运行许可**）。保留 B4 `-nvrmnogo` 的手动路径：手动模式永不自动重定位。
- 在 BAR 写入前分配共用客户端锁，并确认原 `OSArray` 资源描述符可保留且无既有本实例快照。**如果原 PCI command bus-master 位已启用，就立即拒绝实验性重定位**，以免正常停止时错误重新启用 DMA。
- 对成功重定位的 BAR1/BAR3、ReBAR 配置、Root Port 预取窗口以及 IOPCIFamily 原始设备内存描述符保存独立实例快照及 retain 引用。B5 失败回滚不被替换。
- `stop()` 先处理 `rm_shutdown_adapter`、中断事件源与 WorkLoop，再**有条件**调用 `restorePlacedBar1ForStop`。只在没有已知 `rm_init_adapter` 半初始化失败、没有适配器活跃标志、原硬件配置仍与快照一致且当前 PCI bus-master 已关闭的情况下，尝试恢复原寄存器并读回核验。否则明确标记 BLOCKED，不推测 DMA 已停。
- 成功恢复后重新设置 IOKit 原始内存描述符并验证 PCI command；停止阶段统一释放保存的 IOObject 引用。失败时仍标记无有效回退，实机保持 NO-GO。

**尚未解决的 P0 风险，阻止安装/加载：**

1. `rm_shutdown_adapter` 的返回语义和 DMA 完全静默、MSI 回调 drain 没有得到独立确认。`fAdapter=false` 并不能证明 GPU 没有在使用旧 BAR。
2. `autoGo`、`headWatch`、boot-hold 定时器、`IOUserClient` 与 `stop()` 的并发所有权未形成闭包；本补丁没有将这些线程同步化。
3. GSP 固件真实来源/校验、macOS 目标内核 API/ABI、异常终止后 GPU 和 PCIe Root Port 的完整硬件状态未得到验证。
4. B6 源码使用实验性恢复逻辑，**目前只有行级补丁匹配证据，不存在编译、链接、可加载或硬件安全结论**。即便 CI 原生链接通过，仍不能把失败回退通过或 Metal 加速通过混同。

`G1 native gate` 已加入 B6 **显式手动选项**，默认 `false`；需设置 `run_rebuild=true`、`run_b2_probe=true`、`run_b4_probe=true`、`run_b5_probe=true`、`run_b6_probe=true`，其他采用经验证的 Xcode 16.4 / 原 EXTRA 参数。实际诊断字段为 `b6_source_patch` / `b6_native_link_candidate`，与 B3/B4/B5 隔离。所有产物仅临时对象和文本日志，**绝不上传、签名、安装、加载任何 kext**。最终 B2 总门禁仍因 WP1、硬件初始化及运行时资格保持 BLOCKED。


## 2026-10-16 G1-B6 CI 验收：原生链接通过，硬件仍 NO-GO

本节覆盖上文“B6 未编译”的历史阶段描述，保留其作为当时记录。新的实证为 [Actions #38841991105](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38841991105)，已读取原始产物 `b2-native-probe.json` 和 `b2-details/b6-NVRM-compile.txt`、`b2-details/nvrm-real-link.txt`。

- 运行提交 `ea5c35ee02dc83f3dbb3cc99d3afb13171725d61`、Xcode 16.4、macOS SDK 15.5。
- B1 RM 1055/1055，modeset 230/230 对象成功。
- B4、B5、B6 补丁依次 `git apply` 成功；B6 `NVRM.cpp` 原生编译 RC 0（40 warnings），Apple kext 链接 RC 0。
- B6 输出 Mach-O x86_64 `MH_KEXT_BUNDLE`（filetype 11），16,506,080 字节，SHA256 `acee793fad42535f0f89f1572348c1399d294086c769d43a712b37cedb560396`；462 个未定义外部引用，尚未验收目标机内核 ABI。
- B6 修补后的 `NVRM-NVRM.cpp.b6.o` 在 ld64 object table 中选中一次，基线 `NVRM-NVRM.cpp.o` 零次；FSP 的 `kern_fsp.c.o`、`timer_ostimer.c.o` 各选中一次，原始 RM 成员零次。即 B6 候选实证来自修补源码。
- 诊断脚本原本误将 B6 的 `source_variant` 标签显示为 B4，且把任意替换源的统计字段称为 `b4_source_object_link_map_count`；这是**元数据标签错误**，实际对象名、ld64 链接命令和选中计数正确。后续代码改为据对象后缀记录 B3/B4/B5/B6 实际变体，统一使用 `selected_override_object_link_map_count`。
- Actions 顶层 failure 为 B2 持续阻塞运行时与未定义 WP1 的预期 RC 2；**B6 native build/link 子目标 PASS 并冻结**。不要反复重跑同一 CI 证明静态链接。

**下一阶段 P0：** 只继续解决来源确定的 GSP firmware、`rm_init_adapter` 半初始化对象的合法清理合同、PCI/MSI 中断 drain 与 `autoGo/stop` 并发；之后才可能讨论分阶段受控的 25A9 实机加载。B6 的 BAR 资源恢复是**受条件限制的源码设计**，尚无硬件执行证据；当 stop 恢复被拒绝时，当前实现释放保存的 IOKit 引用并保留失败状态，不能解释成硬件已经恢复。即使编译成功也必须保持主力 HONOR EFI/BIOS/Windows/macOS 不变、硬件 NO-GO。


## 2026-10-16 G1-B7：RM 控制/设备事件锁分阶段初始化（源码修复已提交，CI 待运行）

目标提交：`95a68485ac8aad80a0a938bc5feebffe5f78286d`（驱动源补丁）；`386d5653824926a173c8eec2fb738a6a11d3abf4`（独立 B7 原生编译与链接脚本）。目标文件：`scripts/g1/patches/b7_nvrm_rm_preflight_event_locks.patch`，固定 Git blob `3a47f85508017fcd8d56a88c81dd85899b72d9c5`。已基于固定 NullMoth 原始源码和 B4/B5/B6 补丁链精确应用，B7 新增 5 个修改块。**还没有运行新的 B7 Actions；不得声称原生编译、链接或 GPU 功能通过。**

### NVIDIA OGKM 610.57.04 源码事实

固定 NVIDIA 源码 `src/nvidia/arch/nvalloc/unix/src/osapi.c`：

- `rm_init_rm` 调用 `RmInitRm()` 并返回布尔结果；这只是 RM 全局初始化，**不表示设备事件锁、私有状态或 GSP 准备完成**。
- `rm_init_event_locks(sp, nv)` 为传入的 `nv_state_t` 分配 `event_spinlock`，失败返回 `NV_FALSE`。`rm_destroy_event_locks` 提供对应销毁 API，但实现不将 `event_spinlock` 指针置空；销毁时机必须确认不会与中断、用户客户端/事件队列并发。
- `rm_init_adapter` 调用 `RmInitAdapter()`；`rm_shutdown_adapter` 调用 `RmShutdownAdapter()`。不能推断失败中的 `RmInitAdapter()` 可以安全配对销毁；固定的 Linux `kernel-open/nvidia/nv.c` 在适配器初始化失败路径主要清理 IRQ、内核队列等已知外围资源，没有直接在该分支调用 `rm_shutdown_adapter`。

### B7 实际修正

NullMoth 原代码 `NVRM::go(1)` 在 `rm_init_rm` 成功后立刻设置 `gRmInitDone`，而后续控制设备事件锁和 GPU 自身事件锁的建立仍可能失败；后续对同一/另一 GPU 的 `go(1)` 会基于 `gRmInitDone` 跳过锁初始化。B7 现在：

1. 区分 `gRmInitDone`（全局 RM 已初始化）、`gRmCtlEventLocksReady`（控制设备事件锁）和 `fGpuEventLocksReady`（当前 GPU 事件锁），避免将它们归入一个全局分支。
2. 在进入 `rm_init_private_state` 和后续 `go(2)/rm_init_adapter` 之前，分别确认两类事件锁已创建。即使全局 RM 已初始化，仍需为每个 GPU 建立自己的锁。
3. 对 `rm_init_rm`、任一事件锁、`rm_is_supported_device`、`rm_init_private_state` 失败设置本实例 `fRmPreflightFailed`，拒绝在同一个设备实例上重复初始化，不假设半初始化对象已安全回滚。
4. 保留 B4-B6 的 FSP/PCI BAR 原生候选、原有 GSP 和 MSI 逻辑；B7 没有主动调用未证明合法的半初始化清理函数。

### 明确还未解决的缺口

- **已有事件锁的最终销毁**：B7 只增加就绪状态，不等于正确实现 `rm_destroy_event_locks` 的驱动停止清理。GPU 停止、活动 `IOUserClient`、ISR 以及全局 RM 控制状态的并发安全还需核实。
- **全局 RM 生命周期**：`gRmInitDone` 和 `gRmCtlEventLocksReady` 均未随 module unload/reset 建立完整状态恢复；如果全局半初始化，另一设备实例的行为仍不一定安全。
- **适配器失败后的资源所有权**：B4 的 `fAdapterInitFailed` 仅阻止同一对象重试；并不能证明 GSP、DMA、MSI、BAR 或 RM 锁已干净释放。
- **firmware 和实际 GPU 运行**：RTX 2050 `10DE:25A9` 对应的实际 GSP 固件文件、来源 SHA256、目标机 macOS 内核 API/ABI、固件启动/指令执行和 Intel 内屏传输均尚未实证。

### 下一个明确的 CI 验收

手动启动 `.github/workflows/g1-native-gate.yml`：`main` / `Xcode_16.4.0` / `extra_cflags=-DNV_UNIX -DNV_LINUX` / `drop_flags` 空；开启 `run_rebuild`、`run_b2_probe`、`run_b4_probe`、`run_b5_probe`、`run_b6_probe`、`run_b7_probe`。B7 仅在 B6 构建实际通过后，在临时源码目录追加固定 B7 补丁，复用 B6 native clang flags，独立链接并输出 `b7_source_patch` 与 `b7_native_link_candidate`。二进制不上传/签名/安装/加载；总 B2 门禁继续 `BLOCKED`，不能用 Actions 红绿代替 B7 子目标判定。

**实机状态：NO-GO。** 不触碰 HONOR EFI、BIOS、Windows、macOS 主力安装；直到有独立备份恢复演练和明确实机实验授权。


## 2026-10-16 G1-B7 原生链接实测验收（冻结）

证据：[GitHub Actions #38844286925](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38844286925)，运行提交 `28740527217eed59e53520a7872f64ef770248c2`，Xcode 16.4 / macOS SDK 15.5。读取该 run 的文本 artifact `honor-g1-b1-Xcode_16.4.0` 内 `b2-native-probe.json`、`b2-details/b7-NVRM-compile.txt` 和 `b2-details/nvrm-real-link.txt`。

- B1 原生 OGKM 构建 1055 RM / 230 modeset；B3–B7 候选编译及 Apple kext 原生链接均为 RC 0。
- B7 `NVRM.cpp` 源码实际基于已验证的 B6 源应用固定 B7 patch（Git blob `3a47f85508017fcd8d56a88c81dd85899b72d9c5`），本轮 B7 编译 RC 0，**40 warnings，0 errors**。警告混有 Apple SDK IOKit 头文件 override 提示及源码自身类型转换等，编译成功不能作为运行时安全证据。
- ld64 真实 Object Files 映射包含 `NVRM-NVRM.cpp.b7.o` 一次、基线 `NVRM-NVRM.cpp.o` 零次；FSP 修复后的 `kern_fsp.c.o`、`timer_ostimer.c.o` 均选中一次、未修复成员零次。
- 实际 B7 产物：x86_64 `MH_KEXT_BUNDLE`，16,506,136 字节；SHA256 `0a6c1eca5f6a6519ea4148fda4b4520455a48c3ba4e8963fa0f91976541e77ea`；462 个未定义外部符号的目标 macOS 内核 ABI/导出仍未通过实机合同验证。所有候选二进制只存在于 CI 临时目录，没有上传、签名、安装或加载。
- Actions 总体 `failure` 原因是顶层 B2 依设计以 `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE` 返回 exit 2，**不是 B7 本地编译或链接失败**。当前将 B7 的构建子目标标为 `PASS (native build/link only)`，不再原样重跑 B3–B7。
- **仍然 NO-GO 的关键事项**：RM control/per-GPU event lock 的最终销毁与重载全局状态一致性、`rm_init_adapter` 半初始化 GSP/RM 资源的可证明清理、MSI/WorkLoop/autoGo 与 stop 的并发顺序及 DMA 静默、GSP 固件文件真实来源/哈希、目标 macOS 内核/IOKit ABI、RTX 2050 实际初始化与指令执行。不能从本次链接 PASS 推出 NVRM 可加载，更不能推出 Intel 46A6 内屏 Metal 加速。


## G1-B8 source milestone (2026-10-16, NOT native compiled)

Commit `cb107caf07b523375145743734fb1a2afb8c89af` introduces source-pinned `scripts/g1/patches/b8_nvrm_global_rm_stop_gate.patch`, Git blob `PATCH_SHA`. It cleanly follows pinned NullMoth NVRM + B4 (6 hunks) + B5 (5) + B6 (8) + B7 (5); B8 adds 10 hunks.

Code changes: do not schedule autoGo merely by loading the kext; `-nvrmautogo` would require a separate deliberate experimental opt-in; poison future `go` if global RM or control-state event-lock creation failed; reject newly admitted `go` when `stop()` sets `fStopping`; exit headWatch at next loop and cancel autoGo after its settling wait when stop is already set.

**P0 unresolved:** `go()` already in flight may still race against `stop()`; stop does not wait for all RM/ISR/client callbacks, confirm DMA quiescence, destroy GPU/control RM event locks safely or unwind a partially initialized GSP. The boot-hold timeout/threads also have unverified lifetimes. Manual `go` is still a hardware-mutation entrypoint. This patch is not a safe loader.

**Validation status:** exact source-hunk application PASS; Apple native compile/link NOT RUN; hardware tests NOT RUN; CI workflow B8 opt-in integration NOT COMMITTED. Two earlier attempted workflow edits were aborted before GitHub write on strict anchor mismatch. Do not claim CI is available for B8 until it is actually committed and verified. Previous B7 build/link remains frozen PASS. Live system remains NO-GO.


## G1-B8 — 2026-10-16 实际原生编译/链接验收（冻结构建证据）

本节替代上文“B8 未运行原生编译”的历史阶段判断；不改动原有试验记录。

- 真实 GitHub Actions 运行：[38846766604](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38846766604)，head commit `3dd0155dbbf37d73389776796985e078538cd95b`，Xcode 16.4 / macOS SDK 15.5。已读取上传的诊断 ZIP `honor-g1-b1-Xcode_16.4.0` 中 `b2-native-probe.json`、`b2-details/b8-NVRM-compile.txt` 及 native link 日志。
- RM/Modeset B1 对象 1055/230 构建完成，B3–B8 在独立链接候选路径执行，B8 继承已经通过的 B7 源并应用 Git blob `ca6f45d20df3c2b7b2ff260499d42ddcda3d4e9e` 的固定补丁。
- B8 改动后的 `NVRM.cpp` 原生编译 RC=0（**40 warnings，0 errors**，数量与本轮 B7 相同）；Apple `clang++ -fapple-kext` 链接 RC=0，Mach-O 为 x86_64 `MH_KEXT_BUNDLE`。
- ld64 Object Files 映射：`NVRM-NVRM.cpp.b8.o` 选中 **1 次**、基线 `NVRM-NVRM.cpp.o` **0 次**；FSP 补丁 `kern_fsp.c.o`、`timer_ostimer.c.o` 各选中 1 次，原始对象 0 次。证明 B8 实际修补源码参与链接。
- B8 Mach-O **16,506,312 字节**；SHA256 `6ddb0658a43b4b368eadf7bda7ee59858c11ea0c2cd804cf10eaf816bb3adb09`；**462** 个未定义外部符号，目标内核 ABI 是否满足未证明。候选仅生成在 CI 临时目录，未上传驱动二进制、签名、安装或加载。
- 上层 Actions conclusion=failure 来自 `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE` 的预期退出码 2，并非 B8 原生构建错误。B8 子目标标记 `PASS (native compile/link only)`，B3–B8 相同静态构建门槛已验证，不再重复运行。
- **必须保留的 NO-GO**：B8 的 `fStopping` 及共享 RM 失败标志未提供完备的跨线程同步、正在执行的 `go()` 与 `stop()` 的 drain、ISR/MSI 与 WorkLoop 回调停止证明；RM 控制/设备事件锁销毁尚无生命周期闭环；失败中的 `rm_init_adapter()` 半初始化 GSP/DMA 资源没有已验证的清理合同。硬件 GSP 固件来源/哈希、RTX 2050 `10DE:25A9` 实际初始化及计算、Intel `8086:46A6` 内屏路径均无实证。不得从 CI 静态链接成功推导可装机性或 macOS GPU/Metal 加速。
- **下一阶段目标**：先在隔离源候选中设计并验证进入/退出 `go()` 的并发所有权（包括停止时等待机制）、ISR/MSI 与 WorkLoop 销毁顺序和事件锁所有权；不在未知半初始化 RM/GSP 状态下胡乱调用 `rm_shutdown_adapter()`。任何实机加载均需要另行审查与授权。


## G1-B9 — 2026-10-16 go/stop 单实例活动所有权候选（等待真实 Xcode CI）

当前 B8 已由 Actions 38846766604 证明 macOS 原生对象编译和 Apple kext 静态链接成功；**不能以此证明运行时安全**。新阶段提交：

- `50fc8b67b9f76f300ebec0da32e64a64073c770b`：新增 `scripts/g1/patches/b9_nvrm_go_stop_drain.patch`（Git blob `BLOB_SHA`），作为固定 B8 已合并源码上的 3 hunk 实验补丁。
- `cdf9956d20edaa63fe78399e7a4cbdb60f28c975`：为该版本增加单独 B9 原生编译/链接路径和手动 `run_b9_probe` 输入；保留 B3–B8 产物及原链接映射，禁止签名/上传/加载。

### 实际改动

1. `NVRM::go` 在 `gNvClientsLock` 下检查 `fStopping`/全局 busy 状态，成功接受调用时设置 `fGoInFlight` 并保留该 `NVRM` 对象引用；在所有返回路径由 RAII 清除运行标记并释放额外引用。保护范围是**当前 go 函数的执行期**，不是后台 GSP、GPU DMA 或已生成异步任务的执行期。
2. `NVRM::stop` 在同一把锁下关闭后续 `go` 进入通道，并放开锁，以最多 200 次 × 10 ms 的周期观察实例是否仍有 `go` 在运行。正常观察到其结束后才进入现有 RM/MSI/PCI 释放路径。
3. 如果 2 秒内未结束，或全局客户端锁根本不可用，则明确标记 `nvrm-stop-quiescence=BLOCKED`，不调用当前 stop 中危险的 RM/MSI/PCI 显式清理。若曾发生 `rm_init_adapter` 失败而处于半初始化状态，同样跳过显式资源销毁（不猜测可调用 `rm_shutdown_adapter`）。

### P0：不可据此视为安全卸载

- 有界等待超时后仍调用 `super::stop(provider)`，这只能避免当前代码进一步直接释放活动 RM/MSI 对象，**不能证明 IOKit 提供者断开、其他驱动回调或设备内存映射仍然安全**。设备实例虽然由在途 go 保留引用，但被终止的 provider 可能仍使 GPU 状态失效。超时明确视为无法安全停止，绝不能作为实机成功。
- B8 的 `autoGo`、`headWatch`、boot-hold cap 等工作线程可能在 go 函数返回后继续运行；本次同步保护只覆盖 go 的函数调用，不覆盖线程余生，也不等待它们退出。
- MSI 的 filter/workloop handler 完成、RM/GSP 异步任务、DMA quiescence、`rm_shutdown_adapter` 返回后的固件/PCI 状态、控制/设备事件锁销毁及重载全局状态仍待独立源码证明与故障注入。当前 B9 未引入强制 GSP reset 或未知半初始化对象清理 API。
- 目标 HONOR GLO-FX6P 仍无经过验证的 macOS 版本、GSP 固件 SHA/来源、目标内核 ABI 或 RTX 2050 真实指令执行、像素读回、Intel 46A6 内屏加速证据。**主力电脑实机仍为 NO-GO。**

### 唯一必要的下一次 CI

在 GitHub `.github/workflows/g1-native-gate.yml` 手动选择 `main` / `Xcode_16.4.0` / `-DNV_UNIX -DNV_LINUX`、空 `drop_flags`；打开 `run_rebuild` 和 `run_b9_probe`，B4–B8 依赖会自动打开。读取 `b9_source_patch`、`b9_native_link_candidate`、 `b9-NVRM-compile.txt` 以及 ld64 对象映射；顶层返回 2 仍表示 WP1/runtime NO-GO，不等同于 B9 原生链接失败。**尚未运行本次 B9 CI。**


## G1-B9 2026-10-16 实际原生编译/链接验收（冻结）

这是 B9 的**实际 CI 验证**，覆盖上文“B9 原生编译待验收”的历史描述；原实验日志保留。

- Actions [#38851526101](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38851526101)，运行提交 `bf5a97fc8b4f5fddcbacf1d94dbbc6d3f98d59f0`，Xcode 16.4 / macOS SDK 15.5；已下载并解压 artifact `honor-g1-b1-Xcode_16.4.0`，实读 `b2-native-probe.json` 和 `b2-details/b9-NVRM-compile.txt`。档案 ZIP SHA256：`c198cc78d95c35860b35f6223f15242a94fffa9ba3d628dd1d70eb69718289f6`。
- B1 RM/modeset 编译对象计数 `1055/230`，报告均 0 编译错误。补丁链 B4–B9 成功；B9 patch Git blob `fa6ee96cc0da18a923ceb33204c360d48ef6cf7b`，SHA256 `20ee6d5e165073c3450c98a8a94e222e5a78364a65c0880d0b11402856ba2a3f`，B9 合成源 SHA256 `954d6e616be48358806151ea7d51c50cf24616d24e53ca42f93757843ab0ce2e`。
- B9 `NVRM.cpp` native clang++ **RC=0**、**40 warnings、0 errors**，对象 SHA256 `f5a470ec01aa6b8ad04c526a91f69f01bd25d06a50e20ef738179fd14e2453e8`。Apple ld64/native KEXT link **RC=0**，并成功输出 x86_64 Mach-O `MH_KEXT_BUNDLE`（filetype=11）。
- 链接映射证据：B9 修补源 `NVRM-NVRM.cpp.b9.o` 选中**一次**，基线源 `NVRM-NVRM.cpp.o` **零次**；FSP 受检修补成员 `kern_fsp.c.o` 和 `timer_ostimer.c.o` 各选中一次，各对应原始成员零次。
- B9 二进制候选 **16,506,344 字节**，SHA256 `3bf77043a1ed33481d51b02dee0559fe3157897e1a9a07f0f1cf04bb136cf039`，462 个 unresolved 外部符号（是否由目标系统内核提供尚未经 API/ABI 合同验收）。候选二进制未上传、签名、安装或加载。
- 顶层 workflow `failure` 来自明确保留的 B2 总门禁 `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE`、exit 2，**不是 B9 链接失败**。B3–B9 原生构建/链接子目标已通过，不需要重跑相同链路来证明静态链接。

**运行时安全 NO-GO（B9 链接通过不改变）：** B9 的 `go()` 引用保留、同锁停止准入和最多 2 秒等待仅覆盖同步 go() 函数。`autoGo/headWatch`、boot-hold cap、NVRM UserClient、MSI/filter/WorkLoop、RM 事件锁、GSP 固件与 DMA 仍可能在 `go()` 返回后活动。尤其超时和 rm_init_adapter 半初始化失败时，代码虽然避免显式释放 RM/MSI/PCI 对象，但仍调用 `super::stop(provider)`；不得将这当作安全卸载。未验证主力机器的 GSP 固件来源/哈希、目标 macOS 兼容性、RTX 2050 指令执行、像素读回或 Intel 46A6 内屏 Metal 加速。

**下一阶段优先事项：** 定义可审查的活动引用/工作线程和 ISR 回调销毁合同；在失败路径安全停止语义不明确前，只构建隔离源码与测试，不触发真实设备加载、BAR/PCI 改写、EFI/BIOS 修改。


## G1-B10：异步任务禁入与 RM ISR 同步计数（源码已提交，macOS 原生构建待验证）

本阶段源补丁提交 `32efe12223637a892aeb974fad144e065a86cd9e`；CI 实验入口提交 `b7c34e70753d2c486be5710fc6aa6b5610fb6759`。源补丁 `scripts/g1/patches/b10_nvrm_async_isr_gate.patch`，Git blob `BLOB`，对固定 NullMoth + B4–B9 复合源码增加 5 个修改块。来源链 B4(6)→B5(5)→B6(8)→B7(5)→B8(10)→B9(3)→B10(5) 已逐行模拟应用通过。**不是 Xcode 原生编译通过，也不是实机运行通过**。

### 实现边界

1. **彻底封禁自动线程调度，而非简单改变启动参数默认值。** 从 `NVRM::start()` 删除异步 `kernel_thread_start(&NVRM::autoGo)` 和 `thread_call_enter_delayed` 调度入口。遗留的静态 `autoGo/headWatch/bootHoldCap` 函数仍存在，但启动过程不再生成这三种后台任务，即使附带 `-nvrmautogo` 也不允许重新激活。保留具有真实硬件改写风险的手动 `go()` 仅供后续独立批准的受控实验，**当前仍禁止实机调用**。
2. **中断处理期间显式跟踪活动状态。** `interruptOccurred()` 以 `OSIncrementAtomic` / `OSDecrementAtomic` 包括 `rm_isr` 与条件性 `rm_isr_bh` 的执行期；`interruptFilter()` 在检测到停止标记时不再调度新处理。`stop()` 对仍活动的 RM ISR 做最多约 2 秒有界等待，超时则不执行原有 RM/MSI/PCI 显式清理。
3. **沿用 B9 的 go 调用期活动引用/等待**，避免停止时直接与正在执行的同步 RM 初始化竞争。B10 未自动销毁 RM 事件锁或对半初始化 GSP 调用未经验证的 shutdown API。

### 不能称为已解决的 P0

- 原子 ISR 活动数为 0 **不代表**已排队的 `IOFilterInterruptEventSource` 回调不会在随后运行，更不代表中断源 `disable` / `removeEventSource` 与提供者终止的所有线程安全已证明；本补丁不假装已经证明 IOKit 的回调同步机制。
- 在观察到 go/ISR 超时或适配器半初始化失败时，B9/B10 仍可能走 `super::stop(provider)`，这会推进 IOKit 生命周期，却没有保证 RM/GSP/DMA 的活动全部完成。当前处理是 fail-stop 状态记录和尽量避免**本项目**直接释放仍在使用的内核对象，**不是安全卸载**。
- `rm_shutdown_adapter`、`rm_isr_bh`、PCI Bus Master/MSI、DMA 排空、全局控制/设备事件锁销毁及资源最终所有权仍需实证；GSP 固件实际来源/哈希和 HONOR 10DE:25A9 的 macOS 运行环境也未核实。
- 禁止实机加载、EFI/BIOS/磁盘改写，也不接入用户的 Intel 内屏。B10 的 CI 只在 Mac runner 中编译、链接临时候选二进制，不上传/安装/加载任何 KEXT。

### 下一次有意义的验证

手动 <Link...> `.github/workflows/g1-native-gate.yml`：选 `main`、`Xcode_16.4.0`、`extra_cflags=-DNV_UNIX -DNV_LINUX`，`drop_flags` 空、`run_rebuild=true`、`run_b10_probe=true`。B4–B9 自动作为源码/编译/链接前提执行。检查 `b10_source_patch`、`b10_native_link_candidate`、`b10-NVRM-compile.txt` 和 ld64 map 选中 `NVRM-NVRM.cpp.b10.o` 的次数；总 B2 gate 的 RC=2 仍属运行时/来源未验收的预期阻断。


## 2026-10-16 G1-B10 Native Link CI Evidence (FROZEN; not runtime acceptance)

- [Actions #38865900189](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38865900189), head `e6f617477eb45cbb6bb198a4caf58188a1bf2eed`, workflow_dispatch, Xcode 16.4, SDK 15.5. Actual artifact `honor-g1-b1-Xcode_16.4.0` inspected: `b2-native-probe.json`, `b2-details/b10-NVRM-compile.txt`, `b2-details/nvrm-real-link.txt`. Diagnostic ZIP SHA256 `5a149bb6a1c0097417f48040f6d684f690901388d990298f0cbc02aa2cb496ae`.
- B1 build: NVIDIA RM 1055 objects and modeset 230 objects, no compile errors. B4–B10 patch chain applied; B10 source patch blob `649426166a727eb0bb95b8e11b70d58f66eb333c`, patch SHA256 `d57eb6f4025a9d9b2a691a479d777962a42632d64e283868a64352c6074be328`. B10 combined source SHA256 `4ef9f284700ee3424c8a05bb60e846403a19009c4161aacd51304aed1e2a364d`.
- `NVRM.cpp` B10 x86_64 native compile RC=0 (40 warnings, 0 errors); object SHA256 `a732562e0c91e22041075aed340b1dd2cbd32d188ef90ef8fa9b8b52d5295001`. Apple KEXT link RC=0; ld64 selects `NVRM-NVRM.cpp.b10.o` exactly once and the original `NVRM-NVRM.cpp.o` zero times. Two FSP patched objects selected once each, originals zero.
- Resulting diagnostic Mach-O x86_64 `MH_KEXT_BUNDLE` (filetype 11): 16,506,264 bytes; SHA256 `8bc47da6ff954005525b266fb4c8a90c929a9e62a37551d1ba6534b2fcb5c1d5`. 462 unresolved external symbols: destination kernel symbol/ABI compatibility not proven. Binary not uploaded, signed, installed or loaded.
- Top-level Actions `failure` = expected B2 fail-closed `BLOCKED_WP1_OR_NVRM_LINK_PROVENANCE`, exit code 2. B10 subtarget: `B10_NATIVE_LINK_CANDIDATE_PASS_NOT_LOADABLE`. Do not rerun B3–B10 unchanged simply to repeat native link evidence.
- P0 NO-GO remains: ISR active counter equal to zero is **not** a proof that IOKit queued callbacks/filters cannot enter later; `fStopping` uses volatile state with no independently established cross-thread memory-ordering/interrupt-drain contract. `stop()` may still invoke `super::stop(provider)` after go/ISR timeout or RM/GSP partial init failure; retained references are not a substitute for provider-safe termination, hardware DMA quiescence or GSP stop. RM event-lock teardown and user-client lifetime remain unclosed. This patch intentionally disables autoGo worker scheduling but does not prove manual `go()` safe.
- No RTX 2050 10DE:25A9 real initialization, compute or framebuffer readback, no GSP firmware provenance and no Intel 8086:46A6 hybrid-display/Metal evidence. Main Windows/EFI/BIOS/macOS must remain unchanged. Before any hardware test: obtain verified backups and recovery drill, target macOS version/ABI, firmware integrity, explicit safety and stop criteria.
