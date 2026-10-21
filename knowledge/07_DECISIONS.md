> **2026-10-21 内部链接集成待原生验收**：新增同 run RM-only → 配对 NVKMS → 真实 Darwin NVLink 门禁；四份固定上游补丁仅在命名候选副本应用，精确225项 modeset清单，两个RM清理对象替换。五份stock shader已解压核对与固定OGKM相等，保留原TU避免重复包装。本地74项检查和补丁往返通过；新的Darwin编译/内部差分尚未执行，旧run39526958107不覆盖本轮集成。设备NO-GO，不改.agent。见[实现与验收边界](../research/stock-v243-once-20261021/INTERNAL-LINK-20261021.md)。

> **2026-10-21 修复后原生验收通过**：run [39526958107](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39526958107) / `6c8783b`：对象目标make=0，1055/1055 RM、12/12 NVRM对象，真实编译/链接失败负控均拒绝且无旧产物；链接exit0，16185000 B，SHA256 `562b365a…`。493导入中的12 NVKMS和4 NVLink OS接口仍待集成；未加载或执行GPU，设备NO-GO。另撤回“cancel无法清除RESCHEDULE”的旧推断：固定XNU L1347–1352明确清除并返回true，文档与模型已纠正。详情见 [修复与证据](../research/stock-v243-once-20261021/GATE-REPAIR-20261021.md)。

> **2026-10-21 链接门禁审计修复**：历史12 TU+1055 RM对象链接确实成功；旧工作流失败可报绿，新门禁改为对象目标make必须0、精确清单、编译/链接失败非零、同路径负控。最终493项导入重新归属为469历史KPI+定义/8名单/12缺NVKMS/4缺NVLink OS后端；尚非可加载闭包。候选源码未改，三个工作流恢复手动，新Darwin结果待验收，设备NO-GO。详情见 [修复记录](../research/stock-v243-once-20261021/GATE-REPAIR-20261021.md)。

> **本轮决定：** 保留已验证的完整重建候选路线，退休不完整988探针；不写占位PORT层、不因部分编译失败转实机。只补PCI真实调用侧、loader/版本及PM合同。用户已授权相关main快进和源码/编译Actions，设备与.agent禁区不变。见[独立审计](../research/gpu-safety-r5/HARNESS-AUDIT-20261018.md)。

## 2026-10-18 NVLink 候选接口决定

按固定 OGKM 初值1信号量语义实现四个实际缺失接口，采用独立 Darwin TU，保持原 OGKM 归档与 NVLink 调用链。void 接口不可恢复错误 panic，不能称安全恢复；free 必须 caller quiescence，未添加恒真的 ownership 接口。采用同 run 基线/候选导入差分；仅预期新增 `_panic`，其目标导出/ABI仍未知。设备 NO-GO、不得改.agent。[报告](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)。

## 2026-10-18 用户目标修订：公开提供者的构建闭包与 ABI

用户明确要求按已定位的 35 个 OGKM 定义及 7 个本站定义继续研发；缺口归为构建闭包/跨平台 ABI，不再沿用“源码缺失、只能依靠预编译件、离线工作到顶”的判断。优先完成逐符号依赖、隔离 Darwin 对象与 altstack/NULL 栈合同核查。用户授权相关代码、测试、文档与 CI 的当前研发分支受控提交/推送及源码/编译/链接/文本取证 Actions；不得改 .agent、建分支/worktree 或强推；设备权限不变。P0-1/P0-4 保持 BLOCKED/OPEN。证据与下一步见 [当前审计](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)。

## D-23/D-24（2026-10-18）设备生命周期规则与"不可重建"的处置

- **D-23**：共享 `NvKmsKapiDevice` 的创建/绑定/释放必须满足：失败路径只回收本次绑定；最后一个使用者才 `freeDevice()`；
  拆除前必须 `nvkms_xnu_pm_running()`；孤儿在下一次 start 回收；所有状态转换持 `startLock()`。
  理由与逐条实测见 `research/gpu-safety-r5/README.md` 的 R8–R12 段。
- **D-24**：`NVRM.kext` 无法用公开源码重建（R13，符号覆盖约 2%）。因此**不得**把"我们链接出的 NVRM 产物"当作可部署
  驱动；若要走实机 GPU 验证，只能用上游预编译 NVRM，并把它当作"来源未验证的二进制"单独评估风险与回退。

## D-20/D-21/D-22（2026-10-18）关闭失败一律"保留"，隔离态必须可观测回收，失败路径只回收本次创建的共享资源

- **D-20**：一次关闭只有在 `nvKmsClose()` 真正执行后才允许释放 wrapper 与 per-open；PM 等待失败、GPU LOST、
  线程调用释放失败一律保留资源、置 `closing`、原样返回失败。代价是有界泄漏，由 D-21 回收。
- **D-21**：隔离态必须有明确回收时机（resume 成功后、PM 线程、非回调、非持 `gKmsLock`），集合大小以只读
  sysctl 暴露；回收失败不得递减计数。回收路径必须对服务自身取引用。**禁止**为让测试通过而在
  `sKms`/`sKmsEvents` 内再加 `fKmsLock`——`externalMethod` 已持非递归 `IOLock` 再分发，会死锁。
- **D-22**：共享 Device 由首个 framebuffer 创建；该 framebuffer 之后失败时必须释放自己创建的 Device 并清
  `gDev`，复用他人 Device 的实例在任何失败路径上不得销毁它（但归还自己占用的 head 位）。`freeDevice()`
  返回 void，只允许在确认无人引用、且尚无显示/内存资源的初始化失败点调用，不得替代正常停止路径。

## 2026-10-17 GPU R4 当前接手核查（用户最新 GPU 优先；运行 NO-GO）

用户明确恢复 RTX 2050 `10DE:25A9` GPU 驱动优先，H2 外设暂缓，Intel `8086:46A6` 保留现有基础显示；不扩展到 Head 4/Intel Metal/G2/G3。D-17/D-18 的历史决策不删除，本指令覆盖其中 H4 冻结优先级而不覆盖设备安全权限。

远端 `main` 在核查时为 `7c9f50dee8b5d940cf6726c31f6fd236fb3857ca`，暂无基于这一提交的新 Actions。最近 R4 [#39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733) 使用 `b7ac4b0`：NVKAPI C 两对象通过；原版/候选共十个 C++ 对象失败。修复 `-Wno-error=deprecated-declarations` 尚待用户手动原生验证；不能宣称新错误或构建成功。

新增固定源码 SOURCE-REVIEW：`NVRM::gpuSuspend` 在 PM users 非零后仍进入 RM STANDBY；`kms_close_common` 的 KAPI per-open 保留失败无法向 OGKM `KmsFreeDevice/FreeDevice` 的 void 释放链传播；`nv_xnu_lookup_fd` 脱锁返回的内嵌裸指针尚无引用合同。详见 [精确调用链与 NO-GO 审计](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)。**无新的 DARWIN-COMPILE、KEXT-LINK、LOAD、GPU 或像素运行成功证据。**

## D-20｜2026-10-17 最新 GPU 优先与受控提交权限

用户本轮再次明确 RTX 2050 GPU 研发为唯一 P0，H2 外设暂缓；Intel 显示所有权不改变，不推进 Head 4/WindowServer/Intel Metal/G2/G3。D-17/D-18 原有时间点、实机事实不变；该新决定明确覆盖 D-18 的 H4 冻结优先级。主力 Windows/NVMe/EFI/BIOS/NVRAM、Kext 安装加载及 Actions 仍不获授权。用户允许对**实验 GitHub 仓库**已检查的相关文本与门禁脚本进行受控 main 快进提交，条件是先核查全部 workflow 不因 push 自动启动、检查 main SHA 及并发更新；不建 branch/worktree/PR，不强推，不代跑 Actions。

## 2026-10-17 GPU R4 原生对象门禁诊断（编译失败；运行 NO-GO）

R4 为 NVRMUserClient 外部方法分发、映射和关闭增加串行会话门禁；NVKMS bridge close 失败时保留 per-open 与 owner，提供显式重试；启用 PM 时预先分配 gate，PM owner 检查在 gate 锁内执行。RM users 超时仍可能进入 standby，KAPI Device owner、回调排空、完整 RM/DMA quiescence 和裸 lookup_fd 引用合同仍未闭合。

用户手动运行 [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)，基线为 `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`、Xcode 16.4 Build 16F6 / macOS SDK 15.5。两个 NVKAPI C 对象编译通过；五个 C++ 翻译单元的原版与候选共 10 个对象均因 `IOPCIDevice` 弃用诊断被 `-Werror` 升级而失败。NVRM 日志达到编译器错误上限，其他诊断尚未完整确认。

候选门禁脚本仅增加 `-Wno-error=deprecated-declarations`，保留弃用警告输出，其他 `-Werror` 检查不变；此修正尚未在 macOS runner 上验证，需用户手动重跑。该次运行未链接 Kext、未加载驱动、未访问设备、未运行 GPU。关闭安全仍 BLOCKED，实机加载/运行 NO-GO。详见 [R4 报告](../research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) 和 [诊断包](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976) (SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`).

下一次 R4 原生对象验证仍仅由用户手动触发。本段 `H4 冻结` 是 D-18 的旧优先级，已被用户当前 GPU 优先指令覆盖；不改变原有实机事实或系统、设备、Actions 权限。

## 2026-10-17 GPU R3 增量（源码/主机验证，运行 NO-GO）

修复 OGKM 首次分配失败的 FreeDevice(NULL) 崩溃；主机完整 KAPI 原版/候选编译通过，实际释放函数三项候选测试通过。纠正 R2 thread_call_free 解释，未宣称安全关闭已解决。原生十对象门禁已准备、未运行；Kext 链接 BLOCKED，实机加载/渲染 NO-GO。PM busy 后仍 standby 阻塞 pre-quiesce 合同。

手动 Actions：HONOR GPU safety R3 native object gate，首次 Xcode_16.4；不自动触发。NullMoth 源码顺序 R1→R2→R3注释，OGKM 单独应用 R3 NULL 补丁。重建 profile 不解释 Makefile 条件块，不代表上游实际配置或发布物复现。


完整报告：[R3](../research/gpu-safety-20261017/reports/DELIVERY-R3.zh-CN.md)。新增门禁尚未运行，PM/在途调用/关闭失败传播仍阻塞；R2 thread_call_free 失败原因解释由 R3 公开 XNU 证据纠正。以下保留历史记录。

## 2026-10-17 本轮发布授权补记

用户要求将网页端协作材料直接提交到本实验仓库并提供具体链接。本次纳入 GPU R1/R2 源码补丁、测试与证据、R2 手动对象门禁及独立审查任务；不触发 Actions，不改 .agent，不扩大为设备部署。完整入口见 [GPU R2 研究记录](../research/gpu-safety-20261017/README.md)。下方“未提交/未推送”是生成候选时的历史状态，不能据此否认本次发布。

## 2026-10-17 GPU 候选 R2 增量（待审阅，运行 NO-GO）

在完整 ac55984 上按 R1→R2 顺序应用并反向恢复均通过。R2 仅修改 os-nvkms-xnu.cpp：KAPI worker 分配失败不再返回成功 open；无 KAPI Device 的 kernel bridge 改走已有事件轮询；thread_call_free 拒绝时报告并保留 wrapper。实际函数平台依赖故障注入 R2 13/13，旧实现按新合同 7/13（预期负向对照）；单线程 HOST-TEST，不是原生/并发/GPU 证据。原生八对象手动门禁 ci-export-r2 已准备、未运行。PM 失败、close 自等待、在途 ioctl 引用和上层 void freeDevice 继续释放仍阻塞；不宣称 stop 安全。下一先审跨 OGKM/XNU 的 freeDevice 前可失败 pre-quiesce 合同。详情 research/gpu-safety-20261017/reports/DELIVERY-R2.zh-CN.md。未提交、推送、触发 Actions、改 .agent 或设备。

## D-19｜2026-10-17 用户明确恢复 GPU 优先（待审阅记录）

用户粘贴的新接管任务明确要求GPU优先、外设暂缓，允许隔离源码开发和本地测试；依次锁完整输入、原生门禁、无头owner、桥接验收。此明确意图覆盖D-18优先级冻结，并不授权推送/远端分支/PR、Actions触发、系统修改、驱动部署或实机GPU测试。Windows/EFI/BIOS/磁盘保护继续有效。BRIDGE-06未取得不伪造，旧0002租约设计不纳入有效序列；原始主线资料保留，不写.agent。

# 07｜关键技术决策和被否决的捷径

> 按时间追踪决策；**不是删除历史实验**。变更需写出新证据、源码 commit/运行日志和可能的回滚路径。

| 决策 | 采用/拒绝及原因 | 需要什么证据才能重新审议 |
|---|---|---|
| **D-01 主力机保护** | **长期强制**：先只读和托管 CI，不动主力 Windows/EFI/BIOS/分区/安全设置，不执行安装/加载 kext。 | 完整备份/恢复演练、独立硬件环境、用户对具体操作单独授权 |
| **D-02 使用真实 PCI ID** | **采用** GLO-FX6P i5-12500H + Intel `8086:46A6` + RTX2050 `10DE:25A9`，不再写 RTX3050。 | 后续新硬件枚举，且明确记录环境 |
| **D-03 内屏 GPU 归属** | **采用** Windows 当前内屏连接 Intel；不再重复索取截图。**不推断 MUX 永不存在**。 | 电路图/经授权的新模式实测可补充“物理拓扑”，不能取消已核实的当时结果 |
| **D-04 旧 NVAccel 发布源** | NVIDIA r610.57.04 缺 Darwin `compile_cmds.sh`，**只认可 prerequisite gate PASS，不认 NVAccel build PASS**。 | 与目标版本匹配的生成元数据和独立编译/链接记录 |
| **D-05 R1.2 VBL 安全** | R1.2-C real+virtual BUILD-PASS 留存；R1.2-D～G 发现 callback/SYS-FB 生命周期风险。**冻结新 VBL 补丁，不为了 CI 重复微调**。 | 完整 lock-order/lifetime/stop 同步语义闭合及硬件显示路线价值证明 |
| **D-06 研究优先级调整** | R1.2-H 后**先 Intel 内屏，而非先 RTX Metal**。NVIDIA 识别/Metal 信息不等于内屏可用。 | 可信物理 MUX/显卡直连证据或替代方案被实机验证 |
| **D-07 NMXGPU 优于旧 handoff 的研究价值** | 新 i915/DRM 有主动 mode setting 路径；旧 NMIntelFB 依赖固件活动 plane。两者都**未实机验证**。 | 真实 Alder Lake-P macOS eDP、GGTT、WindowServer 记录 |
| **D-08 上游构建证据缺口** | R1.3-C/D 证明**我们不能由发布包的已知路径追溯全部 NMXGPU 输入**，并非证明预编译驱动有缺陷。Issue #146 已索取，不再重复发问/刷 CI。 | 上游提供具体 commit、编译 flags、source/object manifest 或对应源码归档 |
| **D-09 转为自主驱动** | **采用**：自选公开 FreeBSD/Linux/XNU 候选，建立独立版本锁与依赖闭包。**不等待 NullMoth 私有输入**才开始研发，也不冒充复现其发布二进制。 | 自研符号依赖/许可证失败则重新评估可行边界 |
| **D-10 第一目标仅 L1** | **采用研发优先级**：Intel 46A6 基本内屏持续刷新，允许无 3D 加速；不是保证 macOS WindowServer 一定接受无加速接口。 | 隔离实机证实/否证 WindowServer 基础显示 |
| **D-11 否决 BIOS Stolen Memory 直接写** | **拒绝** `BDSM base == GGTT 0 == scanout plane` 的未经证实假设。Host bridge `BDSM` 只给保留物理基址，不能直接跳过 GEM/GGTT。 | 具体真实活动 plane surface/pitch/format、GGTT→CPU physical 映射与资源所有权证明 |
| **D-12 否决关键功能假成功 Stub** | **拒绝** 为便于编译把 DMC/电源/MMIO/内存/同步直接 `return 0`；无法完成必需操作应 fail closed。GuC/HuC/DMC 分别证明。 | 证明对应操作非必需且调用方显式支持关闭 |
| **D-13 源码裁剪以真实调用图为准** | **采用** FreeBSD DRM `6.1-lts` + Linux v6.1 **候选版本对齐**，不能按网上固定文件矩阵删除（v6.1 无独立 `intel_edp.c`；GGTT 在 `gt/intel_ggtt.c`）。 | 完整 LinuxKPI FreeBSD base commit、符号/对象闭包和许可证台账 |
| **D-14 CI 成功分级** | **强制**：编译/链接/静态 ABI ≠ kext 可加载 ≠ 真实 scanout ≠ Metal ≠ 可安全安装。 | 每级独立实测证据 |
| **D-15 1401 并非 46A6 显示驱动** | 用户早期称“1041”的工具可核对为 [NullMoth 1401](https://github.com/nullmoth/1401) OpenCore/USB 配置工具支线；禁在主力机执行。早期错引 [Issue #26](https://github.com/nullmoth/nvidia-macos-driver/issues/26) 的情况已经在 [11](11_EARLY_RESEARCH_AND_1401.md) 明确纠正。 | 需要隔离环境的完整启动/显示/恢复证据才能讨论实际部署 |
| **D-16 1401 只读审计支线（2026-10-13）** | **采用**：用户明确授权对 1401 v1.14.2 / 驱动 v1.14.2 做源码审计、只读环境检测、`%TEMP%` 沙箱内经审查的单元测试，模式 `READ_ONLY_RESEARCH`。**仍禁止**运行 `1401.exe`、生成/写入 EFI、制作 U 盘、上传日志、管理员操作。不改变 D-10 的 L1 优先级。结论见 [INITIAL_AUDIT](../reports/INITIAL_AUDIT.md)。 | 用户对具体高风险步骤单独授权；独立测试硬件与恢复能力就绪 |
| **D-17 整机分阶段适配（2026-10-13）** | **采用**：用户批准把目标从“仅 L1 纸面研究”扩展为整机分阶段适配（H1 外接 SSD 引导安装 → H2 外设 → H3 内屏基础显示 = L1 → H4 加速后置），允许在**外接 SSD** 上做实机测试。内置 NVMe、Windows、其 ESP/BCD/启动项**永远不动**；改 BIOS/Secure Boot、写 U 盘/外接 SSD、引导、kext 加载**逐条批准**。用户已有 U 盘、外接 SSD、USB 鼠标。D-10 的 L1 技术约束（不猜 MMIO、不假成功 Stub）对 H3 全部继续有效。 | 用户撤回；或实机出现固件/内置盘异常时立即停止并回滚 |

### 当前冻结/允许范围

**2026-10-12 R1.4-C0 证据修订：** base 14.3.0 候选已有测试配置依据与精确 SHA，组合 ABI 未验收；禁止直接继承 PM 空成功到 XNU。DMC 缺 payload 的上游路径保留电源引用并禁用 runtime PM，可研究受限状态的真实合同，不能假报加载。完整 probe 仍触及 GT/uc，裁剪须先完成预处理/接口闭包。见 [首轮报告](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)，不回写旧报告。

**冻结**：旧 `patches/r11_...`、`r12b_...`、`r12c_...` 的继续 VBL 微调；旧 R1.2-F/G 同质模型重复 CI；R1.3-D 发行包 172 路径重新下载。历史代码仅保留研究、对照使用。

**允许立即做**：审查 GitHub 资料、选取对齐的 FreeBSD base SHA、整理候选 i915 依赖/许可证/符号图，编写纯离线 fail-closed 检查；未来如有新可证伪假设，可设计仅手动的托管 CI。**不允许任何宿主硬件内核部署**。

当前最高优先级：下一阶段自主 Intel-only **最小源码/符号/许可闭包**。详见 [10](10_CODEX_HANDOFF.md)。

## 2026-10-12 R1.4-C0.1 电源失败不能依赖返回值名称
按真实源码，ADLP选择xelpd表，power void链吞掉poll失败而缓存置真；XNU PM负返回值也被当作确认完成。独立接口必须有真实后置条件/故障状态/所有权及有限时退出合同；不能只返回Linux errno，也不能无限等待。四项合同BLOCKED，必要语义未闭合前不写kext。见[证据](../research/independent-i915/c01/build-and-providers.md)。


## D-18｜2026-10-17 回归 H1–H4 主线（用户要求防止目标偏移）

**决定（对 D-17 的优先级重申，不修改其安全权限）：** 以外接 SSD macOS 可用、可复现、可回退为唯一工程目标；已通过 H1-COUNT 进入 macOS 桌面的 2026-10-15 实机事实覆盖 10-14 EXITBS 失败旧断点。接下来 H1 证据收尾、H2 外设（尤其 Wi-Fi/触控板）、H3 Intel 内屏真实显示链优先；H4 NVIDIA NVRM/GSP/DMA/Metal 暂时冻结，不再用增加原生对象/Mock/CI 数量替代实际整机进度。旧 H4 代码/40 项 CI/DMAR 与新 17 项未运行验证均保留原样，只在新证据或用户明确选择 H4 时重新启动。每项任务必须对应主线验收、独立证据、风险和回退，否则 DEFER。**本决定不授权新的重启、写盘、变更 BIOS/EFI 或加载 KEXT。** 详见 [12_MAINLINE_ALIGNMENT.md](12_MAINLINE_ALIGNMENT.md)。


