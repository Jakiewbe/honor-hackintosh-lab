## 2026-10-17 GPU R4 原生对象门禁诊断（编译失败；运行 NO-GO）

R4 为 NVRMUserClient 外部方法分发、映射和关闭增加串行会话门禁；NVKMS bridge close 失败时保留 per-open 与 owner，提供显式重试；启用 PM 时预先分配 gate，PM owner 检查在 gate 锁内执行。RM users 超时仍可能进入 standby，KAPI Device owner、回调排空、完整 RM/DMA quiescence 和裸 lookup_fd 引用合同仍未闭合。

用户手动运行 [Actions #39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733)，基线为 `b7ac4b0aacf9951f6105c18e3bd5c7777e173d86`、Xcode 16.4 Build 16F6 / macOS SDK 15.5。两个 NVKAPI C 对象编译通过；五个 C++ 翻译单元的原版与候选共 10 个对象均因 `IOPCIDevice` 弃用诊断被 `-Werror` 升级而失败。NVRM 日志达到编译器错误上限，其他诊断尚未完整确认。

候选门禁脚本仅增加 `-Wno-error=deprecated-declarations`，保留弃用警告输出，其他 `-Werror` 检查不变；此修正尚未在 macOS runner 上验证，需用户手动重跑。该次运行未链接 Kext、未加载驱动、未访问设备、未运行 GPU。关闭安全仍 BLOCKED，实机加载/运行 NO-GO。详见 [R4 报告](../research/gpu-safety-20261017/DELIVERY-R4.zh-CN.md) 和 [诊断包](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733/artifacts/12104692976) (SHA-256 `e0042ef033b4e7e71f919ce61603bf51234d77315fe1d6d41ccc75ff602b4367`).

下一步仅为用户手动重新运行修正后的原生对象门禁；本记录不改变 H1→H2→H3 优先级或 H4 冻结状态。

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
