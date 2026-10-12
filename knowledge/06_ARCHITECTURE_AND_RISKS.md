# 06｜系统架构、关键风险、技术难点与 FAIL-CLOSED

## A. 目标端到端链路

```text
HONOR GLO-FX6P (12th Gen Intel)
├─ CPU i5-12500H P/E cores ──[独立内核/ACPI/引导准入，未验证]
├─ Intel Iris Xe 8086:46A6 [Windows 内屏扫描输出已确认]
│    ├─ PCI probe / BAR/MMIO, LinuxKPI/XNU resource ownership
│    ├─ VBT/ACPI OpRegion, panel power/Power Wells/CDCLK/PLL
│    ├─ eDP AUX/DPCD/EDID/link training → pipe/transcoder/plane
│    ├─ Stolen RAM / GEM buffer / GGTT address → CPU mapping
│    └─ DRM KMS (候选 port) → C ABI → IOFramebuffer
│                   ↓
│         macOS WindowServer → 内屏 L1 [未经实机证明]
└─ NVIDIA RTX 2050 Laptop 10DE:25A9 (Ampere)
     └─ GSP/NVRM/NVAccel/Metal [未经实机证明]
          └─ 跨 GPU 同步/复制→Intel Scanout [远期，未经证明]
```

**主线只做 L1**。兼容 Intel 显示硬件/DRM 的最小源码与安全启动链，不等于实现 Metal，也不预先保证 WindowServer 接受无加速桌面。

## B. 方案 A 与方案 B 的准入条件

**A｜Firmware scanout handoff（次级候选，不排除）**：旧 `NMIntelFB::adoptFirmwareMode` 仅借用 firmware 留下的活动 pipe/plane，而且要求线性 XRGB8888 等约束；若 macOS 启动时电源、pitch、tiling 或显存 backing 改变，便无法安全接管。源码 [R1.3-A](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md)；R1.2-C 是旧候选编译证据，**不是状态保持证明**。

**B｜Intel-only i915 KMS（当前自主研发主候选）**：完成 `46A6` probe、VBT/OpRegion、Power Wells、显示时钟、eDP modeset、GEM/GGTT 及 IOGraphics bridge。不能为了避免对象依赖而删除实际运行需要的电源、锁、内存或 firmware 路径。必须先从真实源建立调用图/符号闭包，再决定裁剪。

## C. 资源、地址空间不能混用

| 名词 | 实际描述 | 常见错误 |
|---|---|---|
| BIOS GOP | 固件当前设置的图形输出和 framebuffer | 认为 GOP 总会在 XNU/WindowServer 阶段保持不变 |
| VBT/OpRegion | Intel 面板、端口、电源/背光配置信息 | 误当成 GOP 协议 |
| Host bridge `BDSM` / Stolen Memory | PCI **00:00.0** `0xB0` 所在配置空间的保留 RAM 基址（不等于 GPU 00:02.0 同偏移） | 以 `BDSM+0` 当已知活动扫描缓冲区的 CPU 可写地址 |
| GGTT | GPU graphics virtual address/PTE 区间 | 认为 `GGTT 0` 一定映射 Stolen RAM 起点 |
| GMADR/BAR aperture | CPU 可见 GPU aperture 的 I/O 映射地址范围 | 将 MMIO BAR 的内存属性/拥有权直接与普通 RAM 等同 |
| Scanout plane surface | 实际被显示控制器读取的 buffer 和 pitch/tiling/pixel format | 未证明 CPU VA→设备地址与映射寿命就暴露给 IOFramebuffer |
| XNU `IODeviceMemory` / VM | 向 IOGraphics 提供受控的内存映射与生命周期 | 使用虚假物理连续范围代替多页/显存 backing |

Linux v6.1 [`i915_gem_stolen.c`](https://github.com/torvalds/linux/blob/830b3c68c1fb1e9176028d02ef86f3cf76aa2476/drivers/gpu/drm/i915/gem/i915_gem_stolen.c) 跳过/扣除 reserved stolen 区；`intel_ggtt.c` 还有动态 PTE 和清理逻辑。**不能无证明读写未知物理地址、关闭连续性检查或重映射现有固件使用的物理页**。

## D. 并发、显示协议与启动的阻塞

- 旧 `NMIntelFB` 的 `fStopping volatile`、`unregisterInterrupt` 空实现、裸 timer 回调等存在静态风险；R1.2-B/C 的 retain/workloop 改造**仍不能解决** Apple `SYS→FB`、回调链反向 `FB→SYS` 的条件 ABBA。模型研究详见 [R1.2-D/E/F/G](../docs/R1.2-G_VBL门锁外派发与生命周期审查.md)。
- 新 `NMXGPUFB` 在上游 `v1.14.2` 同样有回调注销/禁用空实现、裸 timer、同步 `terminate` 和 stop/drain 所有权风险；旧补丁不可机械套用。
- 上游 [Issue #119](https://github.com/nullmoth/nvidia-macos-driver/issues/119) muxless 其他型号记录 `NVRMFBClaim` 广泛占用 `IOFramebuffer` 匹配；现有 [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) 是潜在修复方向，**不能把第三方失败泛化成本机必然失败**。
- `IOFramebuffer` 的 display mode、pixel format、aperture、interrupt、stop 生命周期需要 macOS 15.5 版本 API 核查。错误想法“WindowServer 必调用 `setConfiguration` 或 `validateMode`”**未见于 pinned `IOFramebuffer` 源文件**，见 [R1.4-B](../docs/R1.4-B_方案批判性审查与独立源码基准.md)。
- Linux `workqueue`、`mutex`、spinlock/IRQ、`msleep/usleep_range` 不能一对一自动转成 XNU timer、`IOCommandGate`、`IOLock`；需要逐接口的线程上下文和所有权证明。
- **GuC/HuC≠DMC**：前者与 GT 调度/媒体有关，DMC 是显示微控制器和电源状态的一部分。不可为了 L1 盲目将所有 firmware/PM 操作 Stub 为成功。
- **平台另设门禁**：Intel 12500H 的混合 P/E 核、CPU/ACPI 电源/引导环境还没有经完整实机验证。内屏驱动 build 与系统启动是不同问题。

## E. 绝对停止条件

1. 缺少真实源文件、编译对象、许可证明或必要符号 → `BLOCKED_SOURCE`，不能用猜测 Stub。
2. 必需 MMIO、锁、供电、PCI resource、DMA、firmware 功能无法实现 → `BLOCKED_REQUIRED_API`，不允许 `return 0` 伪报成功。
3. 不能证明 plane backing、地址翻译、物理内存连续性、缓存一致性及释放责任 → `BLOCKED_SCANOUT_MEMORY`，不得写未知 buffer。
4. 无法满足 `stop/unregister` 的同步完成与回调释放保证、出现自等待/ABBA → `BLOCKED_LIFETIME`，停止内核原型。
5. 无隔离硬件、可恢复 Windows 备份/EFI 和授权 → `BLOCKED_HARDWARE_TEST`；主力机始终不变。
6. 无实物持续 macOS 画面 → 维持 `RUNTIME_NO_GO`；不得宣称成功适配。
