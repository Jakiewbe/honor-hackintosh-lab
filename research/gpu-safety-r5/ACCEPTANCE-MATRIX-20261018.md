# 双轨验收矩阵（2026-10-18）

一页看清：每个门禁**需要什么证据**、**现在到哪**、**还差谁**。所有数字取自 `evidence/ci-r5/verification.json`、
`evidence/roundtrip.json` 与最近一次门禁报告，不手写估算。

门禁定义：`SOURCE-REVIEW` → `HOST-TEST` → `PATCH-APPLIED` → `DARWIN-COMPILE` → `KEXT-LINK` → `KEXT-LOAD` →
`GPU-RUNTIME` → `DISPLAY-RUNTIME` → `ACCELERATED-DESKTOP`。**上一级不能替代下一级。**

---

## A. NVIDIA RTX 2050（10DE:25A9）

| 验收点 | 需要的证据 | 当前 | 证据位置 | 谁能推进 |
|---|---|---|---|---|
| 补丁序列可回退 | 完整源码正反向、树哈希复原 | ✅ PASS（18 补丁） | `evidence/roundtrip.json` | — |
| 关闭路径无 UAF | 真实函数体 + ASan，含改前对照 | ✅ 40/40，对照报 UAF | `evidence/r5/` | — |
| 隔离态可回收 | 主机测试 + 调用点合同 | ✅ 9/9、12/12 | `evidence/r6/` | — |
| 共享 Device 生命周期 | 计数/孤儿/创建者 retain | ✅ 34/34、45/45（R14） | `evidence/r11/` | — |
| PM 竞态关闭 | pin 语义 + suspend 等待 | ✅ 38/38、50/50（R15） | `evidence/r11/` | — |
| **PM pin 与挂起严格互斥** | 有界等待 + 明确拒绝 + 调用者不 ack | ✅ 主机 23/23、结构 25/25、R22 基线失败 11 项（R23） | `research/gpu-safety-r5/r23-evidence/` | Darwin/链接需用户手动门禁 |
| 关闭失败可上报 | OGKM `void` 接口改造 | ❌ **不可关闭**（已记录） | `README.md` R15 段 | 上游 |
| 原生编译 | 真实 Xcode 工具链 | ✅ 16/16 对象、告警零增量 | run 39058264569 | — |
| Kext 链接 | NVAccel + 生产 NVRMFB 链成 | ✅ 248,584 B / 315,744 B | 同上 | — |
| NVRM 可重建 | 与发行版符号/体积可比 | ❌ **BLOCKED**：361,936 B / 650 符号 vs 16,787,920 B / 17,679；REA 发现 7.93 MB 不透明载荷 | `REA-NVRM-BINARY-20261018.md` | 上游 |
| 加载前一致性 | Info.plist 与链接产物、标识符、provider 类 | ✅ 30/30（`tools/check-bundles.py`） | `evidence/preload/bundle-consistency.json` | — |
| 加载 | 实机加载并采集 RM/GSP 日志 | ⛔ **NO-GO** | `LOAD-EXPERIMENT-20261018.md`（脚本默认禁用） | **用户**（需重新授权） |
| GPU 执行 / Metal / 内屏 | 运行证据 | ⛔ NO-GO | — | 用户 |

**结论**：2050 轨在源码与构建层面已到顶；再往前只有"实机加载（需用户授权）"或"接受上游二进制"两条路。

---

## B. Intel 8086:46A6

| 验收点 | 需要的证据 | 当前 | 证据位置 | 谁能推进 |
|---|---|---|---|---|
| Intel kext 编译 | 真实工具链 | ✅ 两变体均 exit 0 | run 39056413162 | — |
| Intel kext 链接 | 链成 Mach-O | ✅ 44,824 B / 34 符号（真实）；58,752 B / 56 符号（虚拟） | 同上 | — |
| 停机不挂死 | 无界循环消除 | ✅ 8/8 结构合同（R16） | `evidence/intel/stop-contract.json` | — |
| 扫描缓冲不外借 | owner-copy + stop 排空 | ✅ 20/20（R17） | 同上 | — |
| 重启安全 | `fStopping` 复位等四项 | ✅ 25/25（R18） | 同上 | — |
| 拷贝不依赖 kva | owner-copy 优先、kva 仅回退 | ✅（R19） | 同上 | — |
| **内屏由谁驱动** | 实机只读：`IOFramebuffer` 树 + kextstat | ❓ **未知** | `collect.sh` 的 50–54 项 | **用户**（只读采集） |
| 发行物是否含 Intel kext | 发行包内容 | ❌ 不含（只有 NVAccel/NVRM/NVRMAGDC/NVRMFB） | `INTEL-TRACK-20261018.md` | — |
| 加载前一致性 | plist 与链接产物一致、provider 类存在 | ✅ 30/30（同一脚本） | `tools/check-bundles.py` | — |
| 加载 / 持续刷新 / 2160×1440 | 运行证据 | ⛔ NO-GO | — | 用户 |
| i915/eDP 自研闭包 | FreeBSD base/LinuxKPI 固定 commit | ⛔ **BLOCKED_FREEBSD_BASE_SELECTION**（未变） | `knowledge/02` | 需要新证据 |

**结论**：Intel 轨源码侧已清完；下一步是"只读确认内屏现状"（用户几分钟即可），而不是继续改代码。

---

## C. 冻结判断（本轮复核）

- **i915/eDP 自研线**：R16–R19 只碰了 `kexts/NMIntelFB/intelfb.cpp` 与 VRAM ABI，**没有**触及
  FreeBSD base/LinuxKPI 闭包，因此 `BLOCKED_FREEBSD_BASE_SELECTION` 的前提未变，**不重开**。
- **2050 加载实验**：脚本默认禁用；恢复条件 = 用户重新授权 + 接受"验证的是上游预编译件"这一事实。

---

## C2. 一条命令复现全部离线证据

```bash
python tools/verify-all.py --workspace <工作区>
```

11 步：bundle、apply（复用已验路径）、两个 structure、reset、roundtrip、publish、ASan。
末尾固定声明未覆盖 `KEXT-LOAD` 及以上。

## D. 本矩阵的维护规则

任何一格从 ❓/⛔ 变成 ✅，必须同时给出：run id 或日志路径、证据等级、以及"这一级**没有**证明什么"。
只有数字上升而没有被证明边界的变化，不算进展。
