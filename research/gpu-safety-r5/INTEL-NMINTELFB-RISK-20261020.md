# Intel `NMIntelFB` 的接管风险（2026-10-20，源码级，未上机）

## 1. 事实

| 项 | 值 | 来源 |
|---|---|---|
| Bundle | `com.nullmoth.NMIntelFB` | `kexts/NMIntelFB/Info.plist` |
| Provider | `IOPCIDevice` | 同上 |
| `IOPCIMatch` | `0x00008086&0x0000ffff`（**只匹配厂商 Intel**） | 同上 |
| `IOPCIClassMatch` | `0x03000000&0xff000000`（显示类） | 同上 |
| `IOMatchCategory` | `IOFramebuffer` | 同上 |
| `IOProbeScore` | **60000** | 同上，注释写明"高于固件 framebuffer（IONDRVFramebuffer）" |
| `probe()` 过滤 | `displayVersion(dev)` 不认识就返回 `nullptr` | `intelfb.cpp:272-288` |
| 引导参数杀手 | `-nmintelfboff` 直接拒绝 | `intelfb.cpp:282` |
| 采用固件模式 | 仅当 plane 为 XRGB8888 且未 tiled，否则 `return false` | `intelfb.cpp:290-300` |
| 发行包是否包含 | **否**（只有 NVAccel/NVRM/NVRMAGDC/NVRMFB） | `INTEL-TRACK-20261018.md` |

## 2. 这意味着什么

- 匹配范围**不是**按设备号，而是"厂商 8086 + 显示类"；真正的过滤发生在 `probe()` 的 `displayVersion()`。
  也就是说 plist 层面它**会**对所有 Intel 显示设备发起匹配，靠代码拒绝。
- 60000 的 probe 分数**高于**当前正在提供画面的固件 framebuffer；
  一旦 `probe()` 接受、`start()` 走到一半失败，画面是否还能回到固件 framebuffer，
  **没有运行证据**（plist 注释的"失败就回退"只是设计意图）。
- `adoptFirmwareMode()` 的拒绝条件是明确的（非 XRGB8888、tiled、无使能 pipe），
  但它只覆盖"采用现有模式"这一步；之后设置 mode / 分配 surface 的失败路径未被此分析覆盖。

## 3. 结论与建议（H3 若要推进）

**当前不建议把 `NMIntelFB` 加入发行包或加载。** 理由不是"它一定坏"，而是：

1. 现在能显示桌面的路径只有固件 framebuffer；一旦被替换且失败，**没有已验证的恢复路径**
   （外接 SSD 的 APFS 在 Windows 侧不可写，重新引导安装器需要写 U 盘授权）；
2. 分数 60000 会**优先于**现有提供者，这不是"仅在无人接管时才生效"的语义；
3. 现有 plist 是**厂商级匹配**，不是设备级匹配，任何 Intel 显示设备都会被它尝试。

如果 H3 要重新开启，最小前置改动应为：

| 改动 | 目的 |
|---|---|
| `IOPCIMatch` 改为 `0x46A68086`（设备级） | 不用代码兜底，只匹配目标 GPU |
| `IOProbeScore` 降到低于固件 framebuffer（例如 0） | 语义变成"没人接管时才接管"，而不是抢占 |
| 明确 `-nmintelfboff` 与 `-x` 恢复流程，并先验证一次"加载后能退回" | 出事时有不依赖网络的恢复路径 |
| 先只读确认内屏当前由哪个 `IOFramebuffer` 提供（D0） | 没有这个前提，"会不会被抢占"无法判定 |

## 4. 仍缺的证据

- 内屏当前提供者（`ioreg` 中 `IOFramebuffer` 实例与 `IOClass`）——**只能实机只读取得**；
- 46A6 的固件 plane 实际格式/是否 tiled——决定 `adoptFirmwareMode()` 是否会被拒绝；
- `start()` 中途失败后的回退行为——需要受控实验，且需先有恢复路径。

## 5. 边界

本文全部基于源码与 plist 静态阅读，**没有上机、没有加载、没有观测**。
它不改变主线状态：Intel 基础显示保持现状，KEXT-LOAD 及以上 NO-GO。
