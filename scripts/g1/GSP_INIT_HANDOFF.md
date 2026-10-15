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
