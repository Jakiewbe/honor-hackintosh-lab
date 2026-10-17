# Intel 主线交接起点（2026-10-18）

按用户要求把主线改成**双轨**：2050 优先，2050 卡住时推 Intel。本文件是 Intel 轨的当前基线。

## 1. 已确认的事实

| 事实 | 证据 |
|---|---|
| 内屏 2160×1440 在 Windows 下连的是 Intel `8086:46A6` | 既有硬件档案（D-17 已确认，不再重复测） |
| macOS 下内屏能显示桌面，但两块 GPU 都是 **No Kext Loaded** | 2026-10-15 实机报告 |
| **发行包不含 Intel kext**：`release-v2.3.3` 只装了 `NVAccel / NVRM / NVRMAGDC / NVRMFB` 四个 | 发行 tarball 的 `pkgroot/Library/Extensions/*.kext` 列表 |
| 仓库里确有 Intel 源码：`kexts/NMIntelFB/intelfb.cpp` + `Info.plist` + `Info-virtual.plist` | 源码树 |
| 该源码可在真实 Darwin 工具链编译并链接 | 见下 |

## 2. 本轮推进：Intel kext 也进入 KEXT-LINK

门禁新增两个链接步骤（链接行沿用 NVRMFB 那套，上游没有发布 Intel 链接行）：

| 变体 | 产物 | 导出符号 | 状态 |
|---|---|---|---|
| `NMIntelFB` | **44,408 B** | 33 | `KEXT-LINK_ONLY_NOT_LOADED` |
| `NMIntelFBVirtual` | **54,400 B** | 55 | `KEXT-LINK_ONLY_NOT_LOADED` |

[Run 39054884485](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39054884485) `success`：
16/16 对象、告警零增量、NVAccel 244400 B、生产 NVRMFB 315744 B、两个 Intel kext 如上。

## 3. 这说明什么、不说明什么

**说明**：Intel 侧的源码在固定工具链上能编译、能链成 kext，格式与符号表齐全。

**不说明**：
- 发行包**不包含**它，所以用户现有 macOS 上**不存在**这个 kext，它从未被加载过；
- 链接成功不代表它能在 46A6 上点亮内屏——这正是 A1 要证的；
- 它是 NullMoth 的 Intel framebuffer（不是我们自研的 i915 移植），其行为与上游发行物的关系未知。

## 4. Intel 轨的下一步（按代价排序）

1. **只读**：在实机上确认当前内屏到底由谁驱动（`ioreg -l -c IOFramebuffer`、`system_profiler SPIODisplay`、
   `kextstat | grep -i intel`）——这决定 H3 的真实起点，且不需要装任何东西。
2. **源码**：审计 `intelfb.cpp` 的停止路径与 VBL 生命周期（它与 NVRMFB 的 R5–R15 是同类问题），
   产出一份与 NVIDIA 侧同规格的缺陷清单。
3. **构建**：该文件目前只有"单 TU 链接"，若要与发行物对齐需要上游的 Intel 构建配方（不存在）。
4. **实机**：安装/加载 NMIntelFB 属于设备操作，需要单独授权；在 1、2 有结论前不建议。

## 5. 与既有冻结结论的关系

`knowledge/02` 里记录的 Intel 自研路线（i915 / FreeBSD drm-kmod 6.1-lts）仍停在
`BLOCKED_FREEBSD_BASE_SELECTION`，本轮**没有**重新拾起那条线——因为它需要新的源码闭包证据，
而不是又一次源码摘要。Intel 轨当前选择的是"先把这个已存在的 Intel kext 弄清楚"，
它比从零移植 i915 便宜得多，也更容易被证据推翻。
