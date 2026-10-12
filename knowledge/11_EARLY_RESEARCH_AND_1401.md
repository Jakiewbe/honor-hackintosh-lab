# 11｜早期线索补录：1041/1401、OpenCore 与错误案例引用

本附录补录早期对话中尚未单独归档的研究支线。**它不能替代 Intel `8086:46A6` 的 L1 显示研发目标**。

## 1. 项目最初关注的 NVIDIA macOS “突破”

最早调查了 Intel 笔记本 + NVIDIA RTX 在 macOS 15 下是否能够通过 NullMoth 等新方案实现图形功能。后续 Windows PCI 实测确认实际独显是 **RTX 2050 Laptop `10DE:25A9`**，不是早期口述 RTX3050；内屏活动扫描输出设备是 **Intel Iris Xe `8086:46A6`**。

NullMoth 的 NVIDIA 设备表涵盖部分 Ampere 设备并不意味着 RTX2050 的 GSP/NVRM/NVAccel/Metal 在我们机器上得到验证。单独报告 Metal 字符串、虚拟 framebuffer 或显卡 ID 匹配也不足以证明内屏可用。这些限制后来在 [R1.2-H](../docs/R1.2-H_HONOR技术路线重评与准入门禁.md) 和 [R1.3-A](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md) 中得到了更严格的源码论证。

## 2. 用户曾问的“1041”大概率对应 NullMoth 的“1401”

核对了 [NullMoth 1401 独立 Windows 项目](https://github.com/nullmoth/1401) 的公开 README。检查时的源码 HEAD：`b211981a5b464bfc7c0677f0c6f8ba27d01798d7`，README Git blob：`aa38bd19c98979d42270be4b04f27a456cd057c4`。

`1401` Windows 工具的定位是：**硬件扫描 → 利用 [OpCore-Simplify](https://github.com/lzhoang2801/OpCore-Simplify) 生成并按规则修正 OpenCore 配置 → 创建 macOS 安装 USB → 收集启动诊断**。其 Mac companion 用于已经能够启动的机器部署和配置 NullMoth NVIDIA 驱动。这是**引导管理/安装辅助工具**，不是针对 Intel Iris Xe `46A6` 自动提供的 macOS i915/Metal 显示驱动。

其公开 README 当时写明 Windows 工具仅在某 Core Ultra 5 225F / B860 / RTX 5060 台式平台完成过端到端验证，并不保证本机。Windows 应用需要管理员权限、会制作/擦写目标 USB、提示修改 BIOS，Mac app 会涉及 OpenCore 配置、NVIDIA 驱动和相关安全策略；**因此不允许在主力 HONOR 上运行它或照着执行安装步骤**。1401 内置的回滚入口也不等同于 Windows 分区/EFI/BitLocker 的经过实测的完整恢复保证。

来源：[1401 固定源码 README](https://github.com/nullmoth/1401/blob/b211981a5b464bfc7c0677f0c6f8ba27d01798d7/README.md)、[NullMoth v1.14.2 README](https://github.com/nullmoth/nvidia-macos-driver/blob/1083a98db33a0bb824290556de255f9a95ca5403/README.md)、[HOW-IT-WORKS](https://github.com/nullmoth/nvidia-macos-driver/blob/1083a98db33a0bb824290556de255f9a95ca5403/docs/HOW-IT-WORKS.md)。以上仅是**源码/文档审查**，没有运行或安全验证 1401。

## 3. 一条必须纠正的历史错误引用

早期某次讨论曾把“同类 i5-12500H / Intel Xe / RTX 笔记本卡 `EXITBS:START`”关联到 **NullMoth Issue #26**。重新读取 [该 Issue #26](https://github.com/nullmoth/nvidia-macos-driver/issues/26) 的标题和正文，实际对象是 **Alienware 51MR2 / i9-10900K / RTX 2080 Super**，症状为 macOS 15.7.8 启动后约 90 秒独显接入屏幕黑屏、光标保留。

**判定：不得将 Issue #26 当作 HONOR 或 Alder Lake-P 启动失败的证据。** 若未来找到真正的同平台 `EXITBS:START` 案例，必须单独固定链接、CPU/GPU PCI ID、日志及发生阶段，再列入可引用证据。这条误引不应传递给 Codex。

## 4. 对自主研发路线的影响

`1401` 与 OpenCore 构建属于**后置的启动配置研究分支**。当前研发优先级仍为 [Codex 交接任务](10_CODEX_HANDOFF.md) 的 **R1.4-C0：Intel 46A6、FreeBSD DRM/LinuxKPI/XNU 源码及符号依赖闭包**。直到 Intel 内屏和整机启动具备可信隔离测试路径，不能转而投入 1401 自动安装、EFI 生成或安全策略修改。
