## 当前有效覆盖（2026-10-17 用户 GPU 优先指令）

外接 SSD 首次 macOS 桌面已达成的事实不变。用户当前唯一研发 P0 是 RTX 2050 `10DE:25A9` 的 NVRM/GSP、真实 GPU 执行/像素读回、错误传播与安全关闭；**H2 外设暂缓**，Intel `8086:46A6` 只维持现有基础显示，当前不推进 Head 4/WindowServer、Intel Metal、G2/G3。下文 D-18 冻结 H4、H2 优先的表格和验收路线保留为历史，不再是当前工作指令。所有 Windows、磁盘、EFI、BIOS、NVRAM、Kext 和 Actions 逐项授权/禁止规则继续有效，禁止实机部署。R4 最新构建与 P0 安全阻塞见 [审计](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)。

## 2026-10-17 GPU R4 原生对象门禁诊断（编译失败；运行 NO-GO）

R4 为 NVRMUserClient 外部方法分发、映射和关闭增加串行会话门禁；NVKMS bridge close 失败时保留 per-open 与 owner，提供显式重试；启用 PM 时预先分配 gate，PM owner 检查在 gate 锁内执行。RM users 超时仍可能进入 standby，KAPI Device owner、回调排空、完整 RM/DMA quiescence 和裸 lookup_fd 引用合同仍未闭合。

用户手动运行 [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)，基线为 `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`、Xcode 16.4 Build 16F6 / macOS SDK 15.5。两个 NVKAPI C 对象编译通过；五个 C++ 翻译单元的原版与候选共 10 个对象均因 `IOPCIDevice` 弃用诊断被 `-Werror` 升级而失败。NVRM 日志达到编译器错误上限，其他诊断尚未完整确认。

候选门禁脚本仅增加 `-Wno-error=deprecated-declarations`，保留弃用警告输出，其他 `-Werror` 检查不变；此修正尚未在 macOS runner 上验证，需用户手动重跑。该次运行未链接 Kext、未加载驱动、未访问设备、未运行 GPU。关闭安全仍 BLOCKED，实机加载/运行 NO-GO。详见 [R4 报告](../research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) 和 [诊断包](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976) (SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`).

下一次 R4 原生对象验证仍仅由用户手动触发。本段的 `H4 冻结` 是旧 D-18 优先级；已由用户当前 GPU 优先指令覆盖，不改变 H1/H2/H3 历史验收或设备、Windows、EFI、Actions 权限。

此项为 7c9f50d 当时的历史叙述；用户当前明确恢复 GPU 优先，H4 源码适配已重新开放，设备加载/运行仍 NO-GO。

## 2026-10-17 GPU R3 增量（源码/主机验证，运行 NO-GO）

修复 OGKM 首次分配失败的 FreeDevice(NULL) 崩溃；主机完整 KAPI 原版/候选编译通过，实际释放函数三项候选测试通过。纠正 R2 thread_call_free 解释，未宣称安全关闭已解决。原生十对象门禁已准备、未运行；Kext 链接 BLOCKED，实机加载/渲染 NO-GO。PM busy 后仍 standby 阻塞 pre-quiesce 合同。

手动 Actions：HONOR GPU safety R3 native object gate，首次 Xcode_16.4；不自动触发。NullMoth 源码顺序 R1→R2→R3注释，OGKM 单独应用 R3 NULL 补丁。重建 profile 不解释 Makefile 条件块，不代表上游实际配置或发布物复现。


完整报告：[R3](../research/gpu-safety-20261017/reports/DELIVERY-R3.zh-CN.md)。新增门禁尚未运行，PM/在途调用/关闭失败传播仍阻塞；R2 thread_call_free 失败原因解释由 R3 公开 XNU 证据纠正。以下保留历史记录。

## 2026-10-17 本轮发布授权补记

用户要求将网页端协作材料直接提交到本实验仓库并提供具体链接。本次纳入 GPU R1/R2 源码补丁、测试与证据、R2 手动对象门禁及独立审查任务；不触发 Actions，不改 .agent，不扩大为设备部署。完整入口见 [GPU R2 研究记录](../research/gpu-safety-20261017/README.md)。下方“未提交/未推送”是生成候选时的历史状态，不能据此否认本次发布。

## 2026-10-17 GPU 候选 R2 增量（待审阅，运行 NO-GO）

在完整 ac55984 上按 R1→R2 顺序应用并反向恢复均通过。R2 仅修改 os-nvkms-xnu.cpp：KAPI worker 分配失败不再返回成功 open；无 KAPI Device 的 kernel bridge 改走已有事件轮询；thread_call_free 拒绝时报告并保留 wrapper。实际函数平台依赖故障注入 R2 13/13，旧实现按新合同 7/13（预期负向对照）；单线程 HOST-TEST，不是原生/并发/GPU 证据。原生八对象手动门禁 ci-export-r2 已准备、未运行。PM 失败、close 自等待、在途 ioctl 引用和上层 void freeDevice 继续释放仍阻塞；不宣称 stop 安全。下一先审跨 OGKM/XNU 的 freeDevice 前可失败 pre-quiesce 合同。详情 research/gpu-safety-20261017/reports/DELIVERY-R2.zh-CN.md。未提交、推送、触发 Actions、改 .agent 或设备。

## 2026-10-17 后续用户任务覆盖：GPU 优先，仅隔离研发

用户最新明确任务为“接管显卡主线，推进原生构建与GPU闭环”，并明确GPU优先、外设暂缓。因此下文D-18冻结作为历史保留，本轮按D-19恢复GPU源码/编译研究；所有系统/设备权限不变。单项门禁仍独立，不能把源码应用、CPU拷贝、编译或链接当真实GPU/内屏加速。当前成果仅gpu-safety-r1候选，详见research/gpu-safety-20261017/。此为未推送的审阅覆盖层，不修改原始取证或.agent。

# HONOR Hackintosh Lab｜H1–H4 主线复位与防偏移门禁

> 时间：2026-10-17。此文件按已批准的 D-17 整机适配路线解释当前任务优先级；用户本次仅要求回归主线，不意味着授权新的重启、写盘、EFI/BIOS、安全设置或 KEXT 操作。

## 唯一产品目标与成功定义

在 HONOR GLO-FX6P（i5-12500H / Intel 8086:46A6 / RTX 2050 10DE:25A9）上，**不损害主力 Windows 和内置 NVMe**，在外接 SSD 建立实际可用、可复现、可回退的 macOS 环境。研究 Intel/NVIDIA 图形加速服务于这一目标，而非以 CI 测试数量、已链接对象或论文式适配方案作为终点。

已确认 Windows 下内屏连接 Intel 核显；RTX2050 的实测 PCI ID 10DE:25A9。是否具备可用的 macOS NVIDIA GPU 加速必须有实机计算和完整恢复证据，不能靠 PCI device table、静态 Mach-O 或 DMA Mock 判定。

## 当前主线状态：以 2026-10-15 实机记录为最后可信现场

| 阶段 | 可核实的实际事实 | 未达到的验收/阻塞 | 项目优先级 |
|---|---|---|---|
| H1 外接 SSD 引导安装 | 用户通过 H1-COUNT 越过 EXITBS，在外接 SSD 完成 macOS 安装、首次设置并进入正式桌面 | 尚缺独立再次启动、清洁停止/回退演练与新一次 Windows 完好记录；不因过往失败记录倒退到 EXITBS | P0：关闭证据缺口，而非重装 |
| H2 外设基本可用 | 实机键盘可用；Wi-Fi、触控板不可用 | 蓝牙、音频、亮度、电池、USB、休眠/唤醒及无线驱动需逐项核验；先审可用离线证据 | P1：当前主要工程任务 |
| H3 Intel 内屏显示 | macOS 桌面在内屏显示 2160×1440；系统报告 Intel/NVIDIA 均 No Kext Loaded，桌面卡顿 | 尚未确认实际 scanout/IOFramebuffer 提供者、持续刷新/亮度/帧率、失败停止与恢复；不能断言 Intel 自研 L1 驱动验收通过 | P1：与 H2 并行诊断，不提前硬件写入 |
| H4 GPU 硬件加速 | Nvidia B3–B10 原生链接、40/40 DMA 合同与固定 DMAR 审计、Darwin SDK API 对象编译确有证据 | NVIDIA GPU/GSP DMA 与 Metal/渲染未实机证明；新增 17 项 C++/Segment64 原生测试未运行，IOMapper ownership/安全 stop 不闭合 | P3：冻结前沿开发，留档备用 |

注意：H1「安装和首次桌面达成」与「完整 H1 验收」不同；H3「可显示画面」与「Intel 图形驱动正常或 Metal 可用」不同。当前既不宣称整机完成，也不倒退到 macOS 无法安装。

## 下一次允许实施的最短研究工作包（仅离线）

1. **H1 证据缺口**：归档 10-15 已有截图/只读报告的索引（不上传隐私原始图、EFI 或密钥），列出独立复启、主力 Windows 启动验证与回滚演练尚缺哪些事实；没有授权不重新启动或修改磁盘。
2. **H2 外设矩阵**：基于已有硬件档案和 macOS 现场记录，为 Wi-Fi AX201、触控板 I2C、键盘、声卡、蓝牙、亮度、电池、USB、睡眠编制「成功/失败/未测、驱动候选证据、风险、独立回退」表。优先选影响基本使用的 Wi-Fi 和触控板；不得盲目安装第三方 kext。
3. **H3 显示诊断**：只设计下一次经授权后的只读收集清单：macOS Build、OpenCore 信息、IORegistry 显示服务、System Profiler 两 GPU No Kext Loaded 的确切条目、WindowServer/Framebuffer 来源与刷新/唤醒症状。没有 IORegistry/日志不得臆测具体 display provider 或直接覆盖 EFI。
4. **决策门槛**：以 H1→H2→H3 实机证据决定是否投入 H4。若 Intel 46A6 缺可行显示/加速支持，必须给出可行性/止损判断；RTX2050→Intel 混合方案需独立证明 GPU 执行、跨设备复制、显示接管与安全性，不能以 NVRM 原生对象数量替代。

本阶段的交付物是**整机可用性缺口表及可授权的最小非破坏性实机观察计划**，不是新的显卡驱动，也不是新的 CPU/DMA 模型。

## H4 冻结条件、复活条件

- 现有 G1-B10、DMA/P0/DMAR、IOVM64→page-array 代码、40 项已验收测试与原生探针全部保留；新 17 项 host C++ 和 Darwin Segment64 probe **代码已提交但未获得 CI 执行证据**。
- 默认**不继续** B11/B12 编译补丁、DMA Mock 回归、ABI 清单扩展、随意下载 GSP 固件、探索非目标 PCI/GPU 变体。只有新证据能直接消除经优先级批准的 H2/H3 阻塞，或用户明确要求重启 H4 时才重新评估。
- H4 重新开放至少需要：可靠可回退的外接 macOS/Windows 基线、H2/H3 中与显示有关的准确瓶颈证据、目标 macOS Build 和核 ABI 约束、真实 IOMapper/device DMA owner 方案、RM 错误/并发/stop 回退、可信 GSP 固件来源，以及可执行的隔离实机测试计划。即便具备前置材料，实机安装/启动/加载仍逐项需用户批准。

## Codex/AI 每项任务的防偏移四问

任务开始之前必须逐项写明：(A) 服务 H1/H2/H3/H4 哪个验收点？(B) 要缩小哪个已证明的缺口、与上一项有何非重复增量？(C) 有哪些预期证据以及何种结果算失败/止损？(D) 是否会引起硬件或系统状态变化、用户对该具体动作是否已批准？

凡不能写出直接的主线受益目标，默认 `DEFER/ARCHIVE`，**不得因为代码容易写、测试容易绿、CI 可自动化而做**。外接 SSD 实验绝不能影响内置 NVMe/Windows，禁止自行触发 Actions。

## 数据源与冲突优先级

本文件 + D-17/D-18 决策 + `research/gpu-feasibility-20261015/README.md` 的实机记录 > 10-14 `.agent/CURRENT.md` / 旧 H1 EXITBS 死点。后者是历史，不能覆盖已进入桌面的事实。未来实机新证据必须逐条更新主线里程碑，再决定技术分支；旧阶段报告保留原貌。
