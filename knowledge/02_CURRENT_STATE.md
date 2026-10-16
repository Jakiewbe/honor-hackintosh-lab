# 02｜当前事实、阻塞与决策（Codex 最新状态）

## 2026-10-17 P0-DMA 新增 IOVM64→RM page-array C++ 合同（未运行新 CI）

源码提交 410ad56：新增两轮地址段转换器、17 项 CPU-only C++ 用例和 Apple IODMACommand Segment64 的 compile-only 桥接源。提交 71e6b5d 扩展 macOS 15 Intel/Xcode16.4 探针，只保存编译器/nm/散列文本。两个新增测试均未运行，不能承袭 40/40 旧测试或旧 native SDK 的 PASS。完整合同在 scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md。真实 mapper 资源、nv_xnu_alloc::md prepare 兼容、RM pOsData ownership、GSP DMA/quiescence 与 KDK ABI 全部 NO-GO。


## 2026-10-17 G1 P0-DMA 40/40 CI & 真实 DMAR 拓扑 PASS（运行安全仍 NO-GO）

[Actions #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741) 在提交 `791ba38a9bef3e5acb8a8a1e6901b3e434b37d2e` 实际运行，10+13+11+6 **40/40 PASS**，两个固定上游来源审计与已有实机 136-byte DMAR 静态拓扑解析全 PASS。三份真实 JSON 与 SHA256 已永久记在 [专题证据](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)，后续不必重复运行完全相同的 CI。DMAR 报告为两个 DRHD：`0xFED90000` 针对核显 `00:02.0`，`0xFED91000` 是 `include_all=true`；RMRR 仅针对核显 `00:02.0`，范围 `0x4C000000–0x503FFFFF`（68 MiB）。此前 Windows RTX 2050 `01:00.0` 预期属于第二 DRHD 的固件范围，不等于 OS 启用了真实 IOMMU domain。目标 macOS IOVA/GSP/DMA/stop 一律 `NO-GO`。


## 2026-10-17 两条 P0-DMA 工作流真实结论（含故障修复）

- [Darwin DMA SDK #38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) 真正 **SUCCESS**，运行 `71ebc42`；Xcode 16.4（16F6）、SDK macOS 15.5，Intel x86_64、`CLANG_RC=0`、空编译日志、Mach-O 64-bit object x86_64。证据 artifact 12059785493；只验证 C++ API 对象编译，不证明内核链接、真实 IOVA/IOMapper/GSP DMA。
- [P0-DMA #38931378828](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931378828) **FAILURE**，10/10 源码+13/13 事务模型测试通过；RM 11 项仅 9 项通过，另外 2 项的 `//` 注释吞掉相同行 `}`，导致测试代码自行制造了不闭合 C 函数、异常信息与断言不符。因 `set -e`，固定上游取证与 DMAR JSON 步骤均**未运行**。
- 已修复两处负例 fixture：[`636ac9a`](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/636ac9a967b4825750bc163f6e8ec3348778b254) 改用 `/* ... */`，仍要求注释伪造的赋值不能通过 RM audit。此修复**尚未通过新的 CI**；不应提前宣布 40/40 PASS。实机驱动/GSP/PCI/EFI/BIOS 仍 NO-GO。


## 2026-10-16 P0-DMA 最新：源码审计防假阳性 + 实机 ACPI DMAR 拓扑取证（待云端 CI）

新增 [RM 审计器防假阳性修复](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/479e3459ef17e99e8f459219dd963b781ec13d5e)：此前正则即使匹配到 **注释中的赋值**也会被误认作实际 `pOsData=pPriv`，在隔离环境中已复现。现在先剔除注释/字符串，再核对实际 peer 分支对 NULL 的赋值及 failed-unmap 是否提前退出，新增四项负向用例，RM 专项测试数从 7 到 11。**仅本地等价测试验证，远程当前提交尚未运行**。

同时新增 [DMAR 结构解析工具](https://github.com/Jakiewbe/honor-hackintosh-lab/commit/444e959421edaa61beac09ffc1dd0360cff58e67)。仓库既有实机 Windows P40 ACPI 证据 `docs/hardware-survey-20261012/evidence/acpi/fw_DMAR.bin`：136 字节、签名 DMAR、ACPI 校验和在 P40 报告中为真，SHA256 `e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86`；新 `dmar_evidence.py` 会验签并解析 DRHD、RMRR、ATSR 及 PCI device scopes，生成 `dmar-topology.json`。其 6 项合成表结构/负向用例本地 PASS，**实际实机 DMAR 内容细项还没有新 CI 报告**。DMAR ACPI 表存在不等于目标 OS 正在启用 Intel VT-d，更不等于 RTX2050/GSP 可正确 DMA。RUNTIME NO-GO 不变。


## 2026-10-16 P0-DMA RM IOVA 映射所有权新证据（待独立 CI）

固定 NVIDIA 610.57.04 的 [os.c](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb/src/nvidia/arch/nvalloc/unix/src/os.c)（Git blob `b441a66fe735e834f830bae9344333c31b16c1f2`）已确认：`osIovaMap` 通过局部 `pPriv=memdescGetMemData(...)` 将映射地址数组交给 `nv_dma_map_alloc`，并将返回句柄记录为 `pIovaMapping->pOsData`。NullMoth 固定 `os-xnu2.cpp` 的映射回调将该局部指针清空并返回 `NV_OK`，使系统内存映射记录在该路径中为 NULL。RM `osIovaUnmap` 按 `pOsData` 是否 NULL 选择 system DMA 或 peer DMA 的解除路径；此外它在底层 DMA unmap 失败后仍清空该映射记录。**这些是源码控制流和条件分支证据，非已执行的硬件路径。**

早先关于「原始分配 `nv_xnu_alloc` 指针必然丢失」的判断不成立：主 RM 调用路径用局部副本，原始分配记录仍存在 memory descriptor，供 `osFreePagesInternal` 使用。新 [`dma_rm_path.py`](../scripts/g1/dma_rm_path.py) 及 7 项负向测试已写入手动 DMA CI，**新测试尚未运行**；若源码版本、句柄归属或分类流程不同将要求重新人工审查。原 [Darwin SDK 探针](../.github/workflows/g1-darwin-dma-sdk.yml) 同样尚未运行。实际 IOMMU/GSP/设备 DMA/目标内核 ABI 一律保持 `RUNTIME_NO_GO`。


## 2026-10-16 P0-DMA 最新工作：Darwin API 原生编译核验待执行

[P0-DMA 23/23 合成测试](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709) 已真实通过，固定源码审计返回 `BLOCKED_DEVICE_DMA_MAPPING_UNVERIFIED`。本轮新增 `scripts/g1/dma_sdk_probe.cpp` 和默认手动 `.github/workflows/g1-darwin-dma-sdk.yml`，核对 Xcode 16.4/macOS15 Intel SDK 中的 `IODMACommand` 真正 C++ API 与 x86_64 内核对象编译。**当前工作流未运行，不能标记 SDK BUILD PASS；真实 IOMMU/IOVA、GSP/DMA 和目标内核 ABI 仍 NO-GO。**


## 2026-10-15 最新增量：已进入桌面，显卡加速仍未验证

用户通过 H1-COUNT 越过 EXITBS，完成外接 SSD 安装并进入正式桌面；内屏 2160×1440 可显示。两块 GPU 的系统报告均为 No Kext Loaded，桌面卡顿，尚无硬件加速验收。用户已关机，本阶段只做显卡驱动可行性调研；没有安装或加载新驱动、修改 BIOS 变量或触发 CI。

本轮[调研归档](../research/gpu-feasibility-20261015/README.md)含路线比较、固定源码版本与检查记录。RTX2050 渲染到 Intel 内屏桥接是待验证方案。此前记录的 31 项通过、0 项失败仅为源码/文档检查；没有新原生构建或硬件测试。本次上传已获用户明确授权。原始照片、设备日志、EFI 和驱动二进制不上传。

**以下保留历史记录；其中“仍卡 EXITBS”“尚未进入 macOS”等描述已不代表最新用户实测。旧自主驱动的未验收结论仍成立。.agent/ 本轮未迁移，接手时请先读上述增量。**

---


**汇总时点：2026-10-12；最新里程碑：R1.4-C0.1 PCI/电源接口合同，完整闭包未验收。**

**主状态：`R14C01_POWER_CONTRACTS_BLOCKED / R14C0_SOURCE_SLICE_RECORDED / FREEBSD_BASE_CANDIDATE_PINNED / DEPENDENCY_CLOSURE_BLOCKED / NO_INDEPENDENT_DRIVER_BUILD / NO_HARDWARE_RUNTIME / RUNTIME_NO_GO`。**

> 这份文件是“现在怎么样”的**单一入口**。历史报告记录当时的事实，不因后来发生新判断而回写成“当时已经知道”。下一阶段完成后必须同步更新此文件。

## 现在已经确定的事情

- [R1.4-C0](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)：按固定上游测试矩阵解析 FreeBSD `release/14.3.0` 为候选 `8c9ce319fef765890ce518cab85d3a470b669849`；156 条源码/头文件/配置/许可文本锁，92 定义/79 源码关系。新增离线测试 **25 通过、0 失败**；完整闭包门禁**退出 2，拒绝放行**，没有 native/ABI/硬件成功。
- base PM 空成功、GT/uc 完整 probe 依赖和 ADL-P plane 回调已定位；DMC 缺 payload 时上游保留电源引用。14 类必需 XNU 协议未实现，见 [接口合同](../research/independent-i915/required-apis.md)。

- 荣耀 GLO-FX6P、Intel 12500H、Intel 46A6、RTX 2050 25A9 的真实硬件身份与**当前内屏连接 Intel** 已确认；不能按 RTX 3050 或内屏归属未知开展新研究。
- `NMIntelFB` 曾经在 GitHub `macos-15-intel` Runner 上完成 **x86_64 real + virtual 两种分支原生编译和 kext 静态链接**，R1.2-C 正式 [Actions #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450)。这是**旧候选的 BUILD-PASS**，不是我们的自主 Intel-only kext。
- Apple 官方 macOS 15.5 的 IOGraphics-599/XNU 11417.121.6 公开源码已核对版本和 SYS→FB 锁序：[R1.2-F Actions #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)。
- VBL 40/40 抽象参考模型 + 10 个真实 Apple IOFramebuffer VBL consumer 结构条件通过：[R1.2-G Actions #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)。**源码风险尚未关闭**，且该阶段没有内核安全证明。
- NullMoth v1.14.2 提供实验性 NMXGPU Intel i915→DRM→IOFramebuffer 源码路径，**上游文档明确未在物理 Intel GPU 上加载验证**。NMXGPUFB 的回调注销/禁用原版为空实现，timer/stop/同步终止有潜在生命周期风险。
- R1.3-D [Actions #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373) 核对 v1.14.2 主资产 SHA256，索引 172 个路径，含 NMXGPU kext binary，**未见已知名称的 GPU 编译清单/源树/对象目录**。这只阻塞**复现上游发布物**，不阻止选择公开源码自主研发。
- 向 NullMoth 正式提交 [Issue #146](https://github.com/nullmoth/nvidia-macos-driver/issues/146) 索取实际编译输入；不再开重复 Issue。此前审查时 [PR #131](https://github.com/nullmoth/nvidia-macos-driver/pull/131) 未合并，`NVRMFBClaim` 广域匹配 Intel 显示卡风险仍未得到版本证明的修复。
- 已找到自主研发的**版本系列候选** Linux [v6.1 `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`](https://github.com/torvalds/linux/tree/830b3c68c1fb1e9176028d02ef86f3cf76aa2476) + FreeBSD [drm-kmod/6.1-lts `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`](https://github.com/freebsd/drm-kmod/tree/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4)。在 FreeBSD `i915_pciids.h` 中看到 `0x46A6`。**未证明跨仓库 ABI 或 FreeBSD base LinuxKPI 版本匹配。**

## 当前必须保持 BLOCKED 的项目

| Gate | 现在缺什么 | 不应如何“解决” |
|---|---|---|
| **P0-SOURCE** | base 候选已固定；生成配置/传递 includes/对象依赖未闭合，12 条本文件内许可证明缺失，组合许可未审完 | 不把测试矩阵当运行成功；不把源码 slice 当完整闭包 |
| **P0-ABI** | XNU 与 LinuxKPI 的锁、中断、内存/PM/DMA、IOKit 资源协议尚未通过可执行的等价性验证 | 不用 `return 0` Stub 伪造供电/固件/映射成功 |
| **P0-SCANOUT** | 本机ACPI已给IGDM/ASLB字段、条件_DOD/_ADR与背光通知声明；OpRegion/VBT内容仍未取得，ASLB赋值者UNKNOWN，固定20250404选表-e逐表16通过0失败；DSDT仍有外部方法警告，EDMX仍UnknownObj。AUX/CDCLK/Power Well/PLL/PHY、GGTT backing与实际scanout仍未证明 | 不假定 Stolen base = GGTT 0 = Framebuffer；不直接写未知物理/PCI 寄存器 |
| **P0-PLATFORM** | Intel 12500H P/E 混合核与 macOS 内核/ACPI/启动可靠性未独立验收 | 不把 GPU 构建通过当整机能启动 |
| **P0-LIFETIME** | VBL 注册/注销、停止/回调释放、SYS/FB 锁序等对新实现的证明缺失 | 不重复堆叠原 `NMIntelFB` VBL 微调 |
| **P0-NV** | RTX2050 `10DE:25A9` ACPI位图/PEGP._DOD/电源方法已有静态记录；MUX仍无法判断，NOPR/GPIO/EC实际状态未知。完整GSP/NVRM/NVAccel/Metal无实机证据；r610仍缺Darwin参数 | 不把 PCI ID 在表中或 Metal 信息字符串视为真实加速 |
| **P0-SAFETY** | 无独立 Intel Xe 硬件恢复环境，主力 Windows 的分区/BitLocker/EFI/恢复演练未做 | 不在主力机安装、修改 BIOS/EFI、关闭 SIP 或加载 kext |

## 正在做什么／马上做什么

**当前R1.4-C0-pre静态结果已交付，选表-e逐表16通过0失败，原表冲突不再列为解析阻塞。下一步保持R1.4-C0 T0→T4：已定位PEG1/HS10重复和触摸板电源重复，选表解析成功，T2引入本机声明及真实ACPI/PCI/OpRegion消费者合同。C0.1实际配置/预处理与IOPCIFamily来源等缺口继续保留。** 完整闭包和必要接口关闭前，不进入 native 编译或 kext 原型。

**本知识库/AGENTS.md 的提交只是一项“移交文档”完成，并不推进 kernel 驱动运行等级。**

查看 [10 Codex 交接](10_CODEX_HANDOFF.md) 和 [08 自主开发计划](08_ENGINEERING_ROADMAP.md)。旧实验和每一个正式 CI 的索引见 [03 历史](03_RESEARCH_HISTORY.md)／[04 证据](04_EVIDENCE_LEDGER.md)。

## 2026-10-13 补充：1401 只读审计支线（D-16）

- 完成 1401 v1.14.2（`46d9fee`）与驱动 v1.14.2（`1083a98`）的源码审计，报告见 [INITIAL_AUDIT](../reports/INITIAL_AUDIT.md)。**未运行 1401、未生成 EFI、未写任何磁盘/固件。**
- 新提取的硬件事实：RTX 2050 PCI 类码 **`0x0302`（3D 控制器）**，与显示源 0、连接目标 0 一致 → 强烈指向 muxless（推断）。
- 1401 仅凭设备表把 `25A9` 标为 macOS 15 可用（`tested` 只有 `2D05`），同时对本机给出相互矛盾的内屏提示；装驱动后 `NVRMFBClaim` 抢占 Intel 帧缓冲（driver#119，修复 PR #131/#133 未合并）。
- 更正：`nullmoth/1401#26` 是真实的同 CPU（i5-12500H）案例，见 [11 第 5 节](11_EARLY_RESEARCH_AND_1401.md)。
- 主状态不变：`RUNTIME_NO_GO`；L1 主线下一步仍是 R1.4-C0。
- 同日后续（用户逐步批准）：沙箱内运行 1401 扫描/plan/build，生成候选 EFI 并通过 OpenCore 1.0.9 ocvalidate（仅结构校验）；EFI 未写入任何磁盘。见 [docs/1401-plan-run-20261013](../docs/1401-plan-run-20261013/SUMMARY.md)。上一条“未运行 1401、未生成 EFI”是会话 1 当时状态。

## R1.4-C0.1 最新增量与下一步
55条源锁（相对C0新增26文件）、32定义/14直接调用；实际BSD生成输入已锁，配置/预处理仍未执行。
21通过0失败；结构退出0，闭包退出2。电源超时不能用hw_enabled真值证明成功；XNU PM负值不是拒绝请求。
16条文件内许可未证明、76条slice外include、四项XNU合同BLOCKED；无新编译或硬件证据。
下一项C0.2固定IOPCIFamily/PCI-MMIO-PM生命周期与独立树核验，详见[报告](../docs/R1.4-C0.1_PCI与电源井接口合同.md)。

## R1.4-C0-pre（SOURCE-STATIC）
[原表静态证据](../research/acpi-static-20261012/README.md)：36表校验通过；同一iasl20250404选择外部代表逐表16通过0失败；历史失败日志保留。38项findings有定位；两组重复对应空闲PEG1和蓝牙HS10，与MUX/内屏/OpRegion无关。DSDT外部方法警告与EDMX UnknownObj仍保留；NVS/OpRegion内容未取得，RUNTIME_NO_GO。
