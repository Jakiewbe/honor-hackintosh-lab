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
