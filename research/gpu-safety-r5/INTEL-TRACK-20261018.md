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

## 6. R16（2026-10-18）：`stop()` 里的无界等待

审计 `kexts/NMIntelFB/intelfb.cpp` 的停止路径时发现：VBL 定时器的释放是一个**没有出口的循环**——

```c
if (fVblTimer) { thread_call_cancel(fVblTimer);
                 while (!thread_call_free(fVblTimer)) { thread_call_cancel(fVblTimer); IOSleep(5); } ... }
```

只要回调一直"在途"（或者客户端注册的 VBL 处理函数阻塞），`stop()` 就永远不会返回，卸载与关机都会挂在这里。
这跟 NVIDIA 侧 R2 修的是同一类问题：**`thread_call_free` 失败不等于可以无限重试**。

修法（与 NVRM 同一套纪律）：

- 先把句柄搬到局部并 `fVblTimer = nullptr`，防止重入的 stop 二次释放；
- `cancel` 之后给 **至多 ~100 ms** 的有界窗口，成功即退出；
- 仍失败则**保留该 thread call 并继续停止**（`fStopping` 已置位，回调不会再 re-arm），并打一条明确日志。

实测（[Run 39055162192]({RUN})，`success`）：**16 个补丁**、**16/16 对象**、告警零增量；
Intel kext 链接：`NMIntelFB` **44416 B / 33 符号**、`NMIntelFBVirtual` **54408 B / 55 符号**；
NVRMFB 315744 B。Intel 停止路径结构合同 **8/8**。

### 仍未关闭的 Intel 项

- **在途帧拷贝窗口**：R1 的补丁只做到"stop 开始后拒绝新的 kva 查询"，已经拿到 kva 的拷入线程仍可能在
  `OSSafeReleaseNULL(fSurfMap)` 之后继续写。这需要与 NVIDIA 侧同规格的"租约/排空"设计，本轮**没有**做。
- 发行包不含 Intel kext，因此这一切仍只有编译与链接证据，没有任何运行证据。

## 7. R17（2026-10-18）：owner-copy —— 不再把扫描缓冲的 kva 借出去

之前的链路：NVAccel 向 NMIntelFB 要一个 CPU 映射（`kva`），然后**自己**往这个映射里逐行拷贝。
`stop()` 一旦在拷贝中途 `OSSafeReleaseNULL(fSurfMap)`，拷贝就会往已解除的映射里写——R1 只做到"stop 后拒绝
新查询"，管不了已经在写的那一帧。

R17 把拷贝搬进 NMIntelFB 自己：

- ABI 增加 `NVRM_VRAM_FN_COPY`（"nvCopyToScanout"）与 `struct NVRMVramCopyRequest`；
- `copyToScanout()` 校验版本/几何/步幅，**对着自己的映射**逐行写，整个过程持有 `fCopyLock`；
- `stop()` 在释放 `fSurfMap` 之前先取同一把 `fCopyLock`，拷贝不可能与解除映射重叠；随后才 `IOLockFree`；
- NVAccel 优先走 owner-copy，**保留旧 kva 路径作为回退**（对端不实现时仍能工作）。

### 一个必须记下来的教训

第一次门禁 **失败**（[Run 39055521343](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39055521343)）：`member access into incomplete type 'NVRMVramCopyRequest'`。
原因不是代码逻辑，而是仓库里 `nvrm_vram_abi.h` 有 **三份副本**（`kexts/NMIntelFB/`、`kexts/NVRM/`、`kexts/NVRMFB/`），
我改的是 Intel 那份**并不 include** 的副本。这跟 R10 的 `nvrm-fb.cpp` 是同一类陷阱：
**同一个声明存在多份拷贝时，改一份等于没改。**

修正后三份副本字节一致，并新增结构检查"三份副本必须完全相同"，防止再次分叉。

实测（[Run 39055702121](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39055702121)，`success`）：**17 个补丁**、**16/16 对象**、告警零增量；
`NMIntelFB` **44656 B**、`NMIntelFBVirtual` **54600 B**（比 R16 各多 240/192 B，正是 owner-copy 的体量）；
NVRMFB 315744 B。Intel 结构合同 **20/20**。

### 仍未关闭

- owner-copy 只有编译与结构证据，**没有一次运行**（发行包不含 Intel kext）。
- 旧 kva 回退路径仍然存在同样的窗口——只有对端升级到 owner-copy 才真正生效。

## 8. R18（2026-10-18）：重启后永久失效，以及三处失败路径

审计 Intel 的 `start()`/`stop()` 失败路径，发现四个真实缺陷：

1. **`fStopping` 只被置位、从不复位**：`stop()` 把它设成 `true`，`start()` 没有清。一旦这个 framebuffer 被重启
   （显示重连、kext 重载），`vblFire` 第一行就 `return`——**没有 VBL 中断**，而 WindowServer 对加速显示要靠它
   推进；同时 `copyToScanout` 永远拒绝。等于"重启后这个面板就废了"。
2. **`fCopyLock` 只在真实路径分配**，虚拟面板那条分支从不分配，owner-copy 在那里必然被拒。
3. **虚拟变体每次 start 都注册同一个 sysctl oid**，注册两次是 bug。
4. **`registerPowerDriver` 的返回值被丢弃**：注册失败时睡眠/唤醒处理不存在，但日志里看不出来。

修法：`start()` 开头（`#ifdef` 之前）复位 `fStopping` 并只在这里分配一次 `fCopyLock`；虚拟变体的注册用
`if (gVirt != this)` 保护；两处 `registerPowerDriver` 都检查返回值并记录失败。

### 门禁又抓到一次我自己的错

第一次跑（[Run 39055993196](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39055993196)）编译失败：
`invalid operands to binary expression ('IOReturn' (aka 'int') and 'std::nullptr_t')` ——
`registerPowerDriver()` 返回 `IOReturn`，不是指针，我却写了 `== nullptr`。改成 `!= kIOReturnSuccess` 后通过。

实测（[Run 39056169253](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39056169253)，`success`）：**18 个补丁**、**16/16 对象**、告警零增量；
`NMIntelFB` **44664 B**、`NMIntelFBVirtual` **58752 B**（虚拟变体 +4 KB，正是这次新增检查的体量）；
Intel 结构合同 **25/25**。

### 仍然只有编译证据

发行包不含 Intel kext，所以以上全部未经运行验证；"重启后失效"这条尤其需要实机重现才能确认修复有效。

## 9. R19（2026-10-18）：owner-copy 不再依赖借来的 kva

R17 引入 owner-copy 之后仍留了一个尾巴：`nvAccelCopyToScanout` 在尝试 owner-copy **之前**就要求
SCANOUT 查询返回 `q.kva`/`q.pitch`——也就是说，如果对端只实现了拷贝入口、不再外借映射，这段代码根本走不到。

R19 把顺序改成：

1. 只要求**几何**（`q.width`/`q.height`）就能尝试 owner-copy；
2. owner-copy 成功即返回，全程没有用到 `q.kva`；
3. 只有 owner-copy 不可用时，才要求 `q.kva`/`q.pitch` 走旧路径；两者都没有就明确拒绝并记日志
   （"peer offers neither owner-copy nor a scanout mapping"）。

这样"外借映射"从**必经之路**降级为**兼容回退**。

实测（[Run 39056413162](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39056413162)，`success`）：**19 个补丁**、**16/16 对象**、告警零增量；
`NMIntelFB` 44664 B、`NMIntelFBVirtual` 58752 B、NVRMFB 315744 B。

## 10. 只读取证清单（`tools/gpu-forensics/collect.sh` 新增）

下次进 macOS 一次采全，不需要装任何东西：

| 文件 | 回答什么 |
|---|---|
| `50-intel-kexts.txt` | 当前到底加载了哪些 intel/nvrm/nvaccel kext（"No Kext Loaded" 的确切反面） |
| `51-intel-fb-tree.txt` | `IOFramebuffer` 树：内屏由谁发布、有几个 framebuffer |
| `52-fb-provider.txt` | `display0` 的 provider 链 |
| `53-display-full.txt` | 完整显示信息（分辨率/刷新/连接类型） |
| `54-counters.txt` | `debug.nmintelfb_sample`、`debug.nvrm_kms_close_deferred`、`debug.nvrm_pm_waited`、`debug.nvaccel_iop_ok_h4` |

这些全部只读；脚本仍不加载、不写入、不改 SIP/EFI。
