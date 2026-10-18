> **2026-10-18 NVLink 实际结果：** [run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329) 在源码 `0dcc527` 上真实通过。四个真实 Darwin semaphore 接口已编译并进入完整 NVRM 重建候选，同 run 无/有后端对照精确消除四个 NVLink 导入，新增 `_panic` 已登记；仍有 472 个目标导出/ABI 未验收导入。CPU 合同17/17及编译失败负控通过；1280 C TU、5 shader 与独立后端对象、完整归档及候选链接通过。**GPU初始化、渲染、像素读回未执行，设备NO-GO。** 下一步用完整官方逐TU参数核对共享ABI与目标导出，不再重复解决这四个链接缺口。[报告](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)｜[网页端审查prompt](../research/gpu-safety-r5/NVLINK-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 实际构建进展：** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) 已成功执行源码提交 `30485ae`：全部1,280个C TU和5个shader对象通过，RM/modeset完整归档及NVRM重建候选已链接。先前九项UNKNOWN均在最终nm中观察到定义；仍有四个已知NVLink锁内部导入，其余471个目标导出/ABI未验收。六个旧profile选定布局一致不覆盖本轮完整逐TU参数。**初始化、GPU渲染、像素读回均未执行，驱动尚不可交付，设备NO-GO。** 下一步是四个真实Darwin锁接口、完整参数ABI与目标导出核验。[结果与证据](../research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)｜[网页端只读复核prompt](../research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 R80 符号身份与来源：** 修正 Mach-O 转 C 名称时删光下划线的问题；九项 UNKNOWN 已逐项定位为六项数据、一项函数、一项宏数据及一项生成配方候选。已接入本轮显式对象哈希/精确导出取证，47项工具测试及三组历史回归通过。新 Darwin/对象提供者/链接/ABI 尚未运行，完整闭包与设备仍 NO-GO。[报告](../research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)｜[网页端复核 prompt](../research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 R79 审计纠错：** 已撤回“45个符号闭源”与“351→667证明增量闭包不收敛”；索引及同基线显式链接清单已修。固定346符号新扫描为337个词法候选、9个UNKNOWN，尚非对象闭包。27项工具测试和三组历史回归通过；加入六TU选定ABI布局诊断与严格文本发布。新Darwin/链接/ABI尚未执行。见 [本轮报告](../research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)。完整闭包与实机继续NO-GO。

> **R28 接手补充：** [真实事务错误传播](../research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md) 已完成源码/CPU 合同候选，待新 head 的 Darwin 门禁。运行 `gpu-safety-r5-native.yml` / `Xcode_16.4` 后同时读取 `r28-host/report.json`、`r28-series/report.json` 和 `g1-probe-inventory.json`；不能用旧成功 run 验收。完整闭包与 ABI 优先级不变。

> **2026-10-18 接力入口：** 读取 [G1 构建闭包与 ABI 审计](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)。先验收新的 `g1-probe-inventory.json`、五单元宏表/传递 include/真实对象定义，再扩展 RM/modeset 核心闭包并核对 Darwin ABI。不要重复“找不到 35 个定义”或已通过的五单元首次编译。用户已授权本任务相关 main 快进推送与 compile-only Actions；实机仍 NO-GO，不改 .agent。

## 2026-10-18 收尾交接（第 24 轮）

### 一条命令复现全部离线证据

```bash
python tools/verify-all.py --workspace <工作区>
```

11 个步骤全绿：bundle 30/30、structure-nvidia 60/60、structure-intel 30/30、补丁应用与正反向复原
（树哈希 `ea9467f4cca9c823`）、publish 7/7、ASan 主机测试。命令末尾固定打印
**"not covered: KEXT-LOAD and above (needs the machine)"**，防止把离线全绿读成驱动可用。

### 已经证到的（离线）

| 层 | 结论 |
|---|---|
| PRE-LOAD | 6 个 bundle 的 plist 与链接产物一致；标识符唯一；**加载顺序 NVRM → NVRMFB/NVAccel** |
| PATCH-APPLIED | 20 个补丁正反向，完整 611 文件树还原 |
| HOST-TEST | 38/38（ASan，含"改前会 UAF"的对照） |
| SOURCE-STRUCTURE | NVIDIA 60/60、Intel 30/30 |
| DARWIN-COMPILE | 16/16 单元，告警零增量（真实 Xcode 16.4） |
| KEXT-LINK | NVAccel 248584 B、NVRMFB 315848 B、NMIntelFB 44824 B、Intel 虚拟 58752 B |

### 没有证到的（需要机器）

`KEXT-LOAD`、`GPU-RUNTIME`、`DISPLAY-RUNTIME`、`ACCELERATED-DESKTOP` 全部未做。
**任何继续改源码的动作都是在猜**，因为下一次观测必须来自实机。

### 三个决定点（只能由用户选）

1. **授权一次隔离的 NVRM 加载**：脚本已默认禁用（`exit 90` 守卫），恢复需你明确同意；
   它验证的是**上游预编译件在你机器上能否起来**，不是我们的代码。
2. **跑一次只读采集**：`tools/gpu-forensics/collect.sh`，不装任何东西，回答"内屏当前由谁驱动"。
3. **接受上游预编译件**：正式关闭 2050 的自建路线（REA 已证明发行版含 7.93 MB 不透明载荷，无法从源码重建）。

### 已知的、无法在本项目关闭的事项

- `nvKmsClose`/`FreeDevice` 是 `void`：拒绝关闭**无法向上传播**（R21 已做到可计数、可分类、可事后判定）。
- NVRM.kext 不可从公开源码重建（符号覆盖 3.7%、体积 2.15%，且含不透明载荷）。
- i915/eDP 自研线停在 `BLOCKED_FREEBSD_BASE_SELECTION`，R16–R20 未改变其前提。

## 2026-10-18 交接：按验收矩阵推进，不要再写第 20 个补丁

[验收矩阵](../research/gpu-safety-r5/ACCEPTANCE-MATRIX-20261018.md) 是当前唯一入口。两条轨都到了
"源码侧无已知缺陷、只剩运行证据"的位置：

- NVIDIA：加载实验脚本默认禁用（P0-3），恢复需要用户重新授权；NVRM 不可重建已由 REA 定量证明。
- Intel：需要一次只读采集（`tools/gpu-forensics/collect.sh` 的 50–54 项）确认内屏由谁驱动。

只有在实机证据或新的上游材料出现后才考虑新增源码改动。

**2026-10-18 交接单：** [research/gpu-safety-r5/HANDOFF-20261018.md](../research/gpu-safety-r5/HANDOFF-20261018.md) —— 现状、复现命令、门禁运行方式、仍需实机的项、以及需要用户决定的三件事（A 取证实验 / B 是否接受上游 NVRM / C 是否止损）。

## 2026-10-18 GPU R8–R13 交接：离线工作已到边界，下一步需要用户决定

R7–R12 把 NVIDIA 侧设备生命周期修到"失败即保留、最后使用者释放、PM 不可用不拆、孤儿下次回收、状态转换串行化"，
全部有主机测试与结构合同，并在 Xcode 16.4 上编译（16/16 对象）。R10 纠正了"改错文件"（生产 NVRMFB 在
`kexts/NVRMFB/fb/`）。R13 是负结果：`NVRM.kext` 无法用公开源码重建。

**下一步只有三种：**
1. 用户授权一次隔离的 `KEXT-LOAD` 取证实验（自有 NVAccel/NVRMFB + 上游 NVRM，采日志后立即回退）→ 才可能进入
   `GPU-RUNTIME`；
2. 用户不接受用无构建证据的 NVRM → 记为"不可验证"，停止 NVIDIA 方向；
3. 实验显示 RM/GSP 无法初始化 → 出技术止损结论。

判断依据与条件见 [FEASIBILITY-STOPLOSS-20261018.md](../research/gpu-safety-r5/FEASIBILITY-STOPLOSS-20261018.md)。
不再新增离线补丁，除非它直接服务于上述三者之一。

## 2026-10-18 门禁已通过（DARWIN-COMPILE + KEXT-LINK），下一步是加载前的对称销毁与内存 owner

[Run 39048772269](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39048772269) 首次通过：12/12 对象、告警零增量、NVAccel kext 链接成功（244400 B，
`sha256 89f9839e…`）。**这证明的是"能编译、能链接"，不是"能加载、能跑 GPU"。**

按顺序的下一步：
1. **R8（源码）**：补 F5b——`super::start()` 在 `kapiInit` 成功后失败时用同一 RAII 回滚回收自建 Device；
   最后一个 framebuffer 停止 / kext 卸载缺对称销毁，必须先定义"共享 Device 的最后使用者"判定（引用计数或
   owner 移交），不得在单个 framebuffer 的 `stop()` 里直接 `freeDevice()`。
2. **门禁修正**：链接行补 `-mmacosx-version-min=15.5`，消除三条部署目标不一致的 ld 警告。
3. R8 合入后重跑门禁；通过后才讨论 KEXT-LOAD（需要用户对实机逐项授权）与 GPU 运行。
4. 单一内存 owner（`NVRM.cpp` + `nvrm_gpuva.cpp`）仍排在 F5b 之后。

## 2026-10-18 GPU R5–R7 交接：下一个动作是手动运行原生门禁，不是继续写补丁

有效序列 R1→R2→R3注释→R4→R5→R6→R7，完整源码 7 补丁正反向验证通过；R5 修关闭路径 UAF，R6 给它可观测
回收者，R7 修初始化失败留下的半初始化共享 Device。三者均有主机测试或结构合同，但**没有任何一条经过
Darwin 编译**。

1. 在 [HONOR GPU safety R5 native object and kext link gate](../.github/workflows/gpu-safety-r5-native.yml)
   手动选择 `main`、`xcode=Xcode_16.4` 运行；核对真实 `head_sha`、`native-report.json` 与逐对象日志。
   **本门禁已改为上游 `build/accel_build.sh` 口径**（去掉自加的 `-Wextra -Werror`），并新增"候选不得比原版
   多告警"的差分检查与 NVAccel kext 链接步骤。
2. 若失败：先比 original/candidate 同一 TU；共有错误属构建环境/参数/头文件问题，仅候选失败才追 R1→R7 diff。
3. 拿到原生结果后：F5b（`super::start` 失败与最后一个 framebuffer/kext 卸载的对称销毁）→ 单一内存 owner
   （`NVRM.cpp` + `nvm_gpuva.cpp` 中的 GPUVA 路径）→ modeset ownership 与 Device 生命周期解耦 → 才谈
   GSP/DMA/Metal/桥接。

## 当前执行断点｜R4 原生对象门禁与 KAPI owner（覆盖下文旧 H2/H4 冻结任务）

1. 用户下一步手动在 [HONOR GPU safety R4 native object gate](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/gpu-safety-r4-native.yml) 选择 `main`，输入 `xcode=Xcode_16.4` 运行；核对实际 `head_sha`、`native_compile.py` 的 Git blob、`native-report.json` 与所有对象编译日志。**不由代理代触发。**
2. 若出现新的原生编译错误，先比较 original/candidate 同一 TU：双方共有的错误是构建环境/编译参数/头文件候选问题；仅候选失败才追 R1→R4 diff。完整 obj 编译仍非 Kext 链接。
3. 并行 SOURCE-REVIEW P0：`gpuSuspend` busy 后仍 STANDBY；KAPI `kms_close_common` 的失败无法通过 void `nvkms_close_from_kapi` 传入 OGKM `KmsFreeDevice/FreeDevice`；`nv_xnu_lookup_fd` 的裸指针锁外生命周期未证明。未确认 XNU PM/veto 和 per-open callback/drain/owner 之前**不提交危险运行时补丁**。详见 [R4 源码审计](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)。
4. 固定 NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393` 与 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`，顺序应用四个 NullMoth 补丁与一个 OGKM 补丁。任何新补丁须独立编号、最小作用域、实测验证等级与回退。系统实机仍 NO-GO。

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

## 2026-10-17 最新 GPU 接手断点（用户明确选择，待审阅）

先读research/gpu-safety-20261017/。输入ac55984完整源码上仅应用gpu-safety-r1.patch，不混用2.3.3发行kext、旧B3-B10或缺失BRIDGE-01～06。CPU/补丁应用证据已有，不重复刷同质模型。下一项：审阅并按需提交manual native对象门禁，由用户网页运行；之后先解决os-nvkms-xnu.cpp:kms_close_common自等待/可失败关闭，再把Device唯一owner置于NVRM，VRAM/GPUVA脱离显示器。当前NMIntelFB裸kva/stop与真实DMA/GSP仍NO-GO，不启用Head4或实验功能。没有推送/触发/设备授权；此前H1进入桌面事实不变。

# 10｜Codex 正式交接单：现在接手做什么

## 2026-10-17 最新 Codex 唯一优先交接：H1→H2→H3；H4 冻结

**先读 [主线复位与防偏移门禁](12_MAINLINE_ALIGNMENT.md)**。本文件下面的 NVIDIA DMA 技术增量留作 H4 历史，**不是当前下一步任务**。最后实机：外接 SSD 安装完成并进入 2160×1440 桌面；键盘可用、Wi-Fi 和触控板不可用，两块 GPU 为 No Kext Loaded，桌面卡顿；音频/亮度/蓝牙/睡眠尚缺实测。H1 仍需独立复启/Windows 与回退验证，H2 基础外设矩阵优先，H3 Intel 显示提供者调查随后或并行。

**本轮及下一轮允许的最小代码/文档工作**：离线整理 H1 不足证据、H2 每项外围驱动候选及回退风险、H3 的 IORegistry/WindowServer/Framebuffer 下次只读采集清单；不得自行重启电脑、修改 EFI/SIP/BIOS、安装/加载 kext 或触发 Actions。只有这些交付对真实使用状态有增量后，再决定是否要恢复 H4。**不继续编写新的 NVIDIA DMA/Page-array/ABI 模型**。

## 2026-10-17 P0-DMA 新增 IOVM64→RM page-array C++ 合同（未运行新 CI）

源码提交 410ad56：新增两轮地址段转换器、17 项 CPU-only C++ 用例和 Apple IODMACommand Segment64 的 compile-only 桥接源。提交 71e6b5d 扩展 macOS 15 Intel/Xcode16.4 探针，只保存编译器/nm/散列文本。两个新增测试均未运行，不能承袭 40/40 旧测试或旧 native SDK 的 PASS。完整合同在 scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md。真实 mapper 资源、nv_xnu_alloc::md prepare 兼容、RM pOsData ownership、GSP DMA/quiescence 与 KDK ABI 全部 NO-GO。

下一步：在 main 手动验收 DMA workflow 新增 17 项 C++ host 断言，以及 Darwin SDK 新原生对象 compile-only。随后针对 md->prepare 已存在的前提、IOMapper provider 与双资源 owner 的错误回滚设计证据合同；不动主力 Windows/EFI/BIOS。


## 2026-10-17 接手验证节点已转换（不需要重复 CI）

`P0-DMA Contract` [run #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741) 已取得 40/40 PASS 与三份原始 JSON 的 SHA256，固定 DMAR 显示 2 个 DRHD（核显专用、第二组 include-all）及核显 RMRR；归档于 [专题](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)。[Darwin SDK Probe #38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) 亦已原生编译 PASS，无需重复。**下一项仅源码/隔离环境工作：** 对照 NVIDIA `nv_dma_map_alloc` 的 RM `pPriv/pOsData` 双层归属，设计 macOS 真实 IODMACommand 资源状态机和失败时句柄保留合同；单独核查目标 Build/KDK、IOMapper provider 与 `01:00.0` 运行态 IOMMU 配置。不可将静态 DMAR include-all 当成已映射运行态证据；NO-GO。


## 2026-10-17 P0-DMA 下一步单项验证任务

已拿到 Xcode 16.4/macOS SDK15.5 `IODMACommand` compile-only 成功证据（run 38931389598），**无需再重复运行该 SDK 探针**。手动运行更新后的 [P0-DMA contract](../.github/workflows/g1-dma-contract.yml) 于 `main`（必须包含提交 `636ac9a`）：期望原 10+13、修复后的 RM 11、ACPI DMAR 6，共 40 个单元测试，并产生 `dma-source-contract.json`、`dma-rm-path.json`、`dmar-topology.json`。注意前一运行 38931378828 两个负例 fixture 的 `//` 吃掉了同行 `}`，导致无效 C 样本；新提交用 block-comment 修复而未降低检测要求。**在新 CI 结果返回前不允许宣告 PASS。** DMAR 固件静态拓扑即使可解析，也不能证明 OS runtime VT-d/DMA 页表/RTX2050 GSP 已工作，NO-GO。


## 2026-10-16 P0-DMA 新交接重点：验收真实 DMAR + 修复后的 RM 调用链审计

1. 在 `main` 手动运行 [G1 P0 DMA contract](../.github/workflows/g1-dma-contract.yml)：应跑既有 23 + 最新 RM 11 + 新 DMAR 6 共**40 项预期合成测试**；确认两个固定来源及仓库实机 `fw_DMAR.bin` 的 SHA256。下载两个映射源合同 JSON 与新增的 `dmar-topology.json`，核对 DRHD 的 segment/include_all、各 PCI device scopes/RMRR。**目前新 CI 未运行，切勿提前标记通过**。
2. 仍待运行 [Darwin DMA SDK API compile-only](../.github/workflows/g1-darwin-dma-sdk.yml)：验证真实 Xcode16.4 `IODMACommand` API 类型、编译和未定义符号，不链接/加载 kext。
3. 之后以真实 Windows BIOS/ACPI PCI BDF 与 DMAR device scopes 做静态相关性分析，再审查 macOS IOMapper 与 allocation mapping ownership；DMAR 存在或 DRHD include_all 不是运行时 IOMMU 证明。不修改 Windows/EFI/BIOS，不启动 GPU，维持设备 **NO-GO**。


## 2026-10-16 P0-DMA 新交接：两项可证伪门禁

(1) 手动运行 [DMA source contract](../.github/workflows/g1-dma-contract.yml) 以验收新增 `test_dma_rm_path.py` 的 7 个负向用例、真实固定源码 `dma_rm_path.py` 及 `dma-rm-path.json`，重点观察系统内存 DMA 路径被 `pOsData=NULL` 分类为 peer，以及失败时丢弃映射记录的控制流。它只能证明**源码分支可达条件**，没有 GPU 执行。

(2) 运行已存在的独立 [Darwin DMA SDK compile-only](../.github/workflows/g1-darwin-dma-sdk.yml) 检验 Xcode 16.4 的真实 API 类型；该流程尚未实际运行，须手动触发，无论是否编译成功均保持硬件 NO-GO。

之后再审查 `pOsData` 与 `memdescGetMemData` 两套独立资源的合法释放顺序、`bReadOnlyDeviceMap` 的传递，以及真正的 IOMMU/provider 原生接口；在此之前禁止以非空假句柄、identity 地址或成功 Stub 解锁实机加载。


## 2026-10-16 新交接（只读、手动）

已经固定 P0-DMA 23/23 合成测试，不再重复。[手动执行 G1 Darwin DMA SDK API compile-only](../.github/workflows/g1-darwin-dma-sdk.yml)：运行 `main`，核对 `toolchain.txt`、`compile.log`、`undefined-symbols.txt` 和临时 x86_64 Mach-O `MH_OBJECT` 证据；不要下载/上传可加载驱动，不修改 HONOR 主机。若编译失败，定位 Xcode16.4 实际 Kernel.framework 头文件与固定公开 XNU 声明差异，修正最小 probe；**不能绕过 SDK 编译后伪称可用**。无论通过与否，RUNTIME_NO_GO；后续分析具体 macOS Build/KDK、IOMapper provider 归属、rm `nv_dma_map_alloc` 来源及 DMA 停止合同。


## 2026-10-15 最新增量：已进入桌面，显卡加速仍未验证

用户通过 H1-COUNT 越过 EXITBS，完成外接 SSD 安装并进入正式桌面；内屏 2160×1440 可显示。两块 GPU 的系统报告均为 No Kext Loaded，桌面卡顿，尚无硬件加速验收。用户已关机，本阶段只做显卡驱动可行性调研；没有安装或加载新驱动、修改 BIOS 变量或触发 CI。

本轮[调研归档](../research/gpu-feasibility-20261015/README.md)含路线比较、固定源码版本与检查记录。RTX2050 渲染到 Intel 内屏桥接是待验证方案。此前记录的 31 项通过、0 项失败仅为源码/文档检查；没有新原生构建或硬件测试。本次上传已获用户明确授权。原始照片、设备日志、EFI 和驱动二进制不上传。

**以下保留历史记录；其中“仍卡 EXITBS”“尚未进入 macOS”等描述已不代表最新用户实测。旧自主驱动的未验收结论仍成立。.agent/ 本轮未迁移，接手时请先读上述增量。**

---


**交接时点：2026-10-12。仓库主分支 main；依据 R1.4-B 审核后的方案。此文档是执行任务说明而不是“驱动已实现”。**

**最新断点：** R1.4-C0 首轮台账和负向静态检查已交付，base 候选 `release/14.3.0 / 8c9ce319fef765890ce518cab85d3a470b669849` 已固定；完整 B0/B1 闭包仍 BLOCKED。下方保留原任务定义，当时“base 待查”不代表现在未取得 SHA。见 [结果](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)。

**最新增量 R1.4-C0.1：** [正式报告](../docs/R1.4-C0.1_PCI与电源井接口合同.md)：实际固定生成规则/输入，真实提供者与电源失败传播；21通过0失败。没有完成实际配置展开/预处理闭包。Power Well 超时缓存仍置真，XNU setPowerState 负值仍确认；四项合同未实现。

**Next Task R1.4-C0.2：** 固定 macOS15.5 IOPCIFamily 原始来源/commit，查 PCI BAR、PM、IRQ 与释放生命周期，对照 PCI_MMIO_OWNER/PM_ACK_SEMANTICS；补 XNU 四源树核验。必要语义缺证据即停止，不进入 B2/B3 或 kext。

## R1.4-C0-pre最新平台输入与下一步

[本机ACPI静态结果](../research/acpi-static-20261012/README.md)已给_DSM位图、PEGP_DOD、DD节点条件和IGDM布局；同一iasl20250404按两组冲突选外部代表，逐表16通过0失败；PEG1._S0W/HS10.SADX及触摸板电源重复已有精确记录，与MUX/内屏/OpRegion结论无关；DSDT仍有外部方法警告，EDMX仍UnknownObj，不冒充完整External闭包或运行成功。OpRegion/VBT内容仍未取得，MUX三选一为无法判断。固定BSD的intel_acpi两个桥接函数为空，不能当XNU成功实现。

**下一步仍为R1.4-C0 T0→T4**：T0复用选表-e成功与原冲突诊断/不重复硬件归属调查；T1复用原表、工具与上游锁；T2将ASLB/SANV、IGDM/ASLS、_DSM/_DOD/_ADR和ASLE背光声明输入VBT/OpRegion节点，保留真实内容/ACPI evaluator/PCI映射/消费者/失败清理缺口；T3失败停止；T4证据交付。IOPCIFamily和C0.1配置闭包仍须完成，但本次不进入native/kext或硬件读取。

## 先读清楚底线

1. 执行 [`AGENTS.md`](../AGENTS.md)，再读 [当前状态](02_CURRENT_STATE.md)、[目标](00_PROJECT_CHARTER.md)、[版本锁](05_SOURCE_LOCKS.md)、[技术风险](06_ARCHITECTURE_AND_RISKS.md)、[决策](07_DECISIONS.md)。
2. 主力 Windows 禁止改动；不运行/安装 kext/EFI/BIOS/SIP；不自己启动/rerun Actions，不发重复上游 Issue。
3. 已知内屏接 Intel `8086:46A6`；RTX 为 `10DE:25A9` 的 **2050**，不是 3050。**已经确认的硬件不要再让用户重复测**。
4. `RUNTIME_NO_GO`，R1.2-C 旧候选虽 real+virtual BUILD-PASS，但**我们的自主驱动没有任何 native build**。不要混淆。

## 推荐 Codex 首个工作包（R1.4-C0：B0 + B1，不允许先做内核部署）

**任务目标：** 将“FreeBSD drm-kmod 6.1-lts + Linux v6.1 可作为独立 Intel 46A6 KMS 研究输入”的假设落实为**有证据的版本和最小函数/对象依赖闭包**。**本工作包优先交付原始源码追溯、C ABI 合同和可证伪依赖矩阵，不应声称产出可加载 AlderFB.kext。**

### 已固定输入候选（不得暗换）

- Linux v6.1 commit `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`
- FreeBSD drm-kmod 6.1-lts commit `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`
- Apple XNU macOS 15.5 commit `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`
- Apple IOGraphics macOS 15.5 commit `4d3fd008c80d1414c9da8f02ea67d534b47158c2`
- **FreeBSD base LinuxKPI 对应版本与 commit 待查，不能编造。** 先从 FreeBSD drm-kmod 6.1-lts 真实构建说明、Makefiles、includes 和 FreeBSD Release 分支选择一个可审查 SHA。

### 允许 Codex 立即实施的步骤

**T0｜仓库复核/任务约束**

- 逐一列出 [历史/验收账本](03_RESEARCH_HISTORY.md)、[证据台账](04_EVIDENCE_LEDGER.md) 中与 B0/B1 重复的工作；**不再运行这些旧任务**。
- 如果现有仓库还有外部用户修改，先报告冲突，不覆盖。

**T1｜源版本/许可证闭包**

- 在 `research/independent-i915/` 建立文本形式 `README.md`、`source-lock.json`、`license-manifest.csv` 和 `compat-notes.md`。
- `source-lock.json` 每项至少含 `repo`、`commit`、`path`、`blob_sha`、`role`、`status`；缺失 commit 标为 `BLOCKED`，**不能填一个“看起来差不多”的哈希**。
- 选择 FreeBSD base/LinuxKPI **具体可公开核实的版本**，检查 DRM 6.1 includes 是否确实存在与之匹配的接口和 licensed symbols；展示缺口。
- 对 GPL/dual-license/MIT/BSD 等逐文件标注 SPDX/许可来源、是否允许后续重分发。没有许可证明不可默认合并为可分发闭源 kext。

**T2｜针对 46A6 的真正最小调用图**

- 从 FreeBSD `i915_pciids.h:INTEL_ADLP_IDS`、`i915_pci.c` 到 ADL-P display/eDP 相关核心函数，构造 **`pci-probe → VBT/OpRegion → Power Wells/CDCLK/PLL → eDP AUX/link training → GEM/GGTT plane backing → IOFramebuffer publication`** 的带版本来源图。
- 输出 `callgraph.md`、`symbol-inventory.csv`、`required-apis.md`。每条记录写出提供定义的具体源码/对象以及内核线程/中断上下文；目前未识别的明确标注 `UNRESOLVED`。
- 不直接按固定的 `intel_edp.c`、`i915_gem_gtt.c` 名称搜索不存在的 Linux v6.1 文件：eDP 在 DP/panel，GGTT 在 `gt/intel_ggtt.c`。
- `IOFramebuffer::getInformationForDisplayMode` 是模式信息 API，不是物理 frame buffer 基址映射 API；用 `getApertureRange` 等 pinned API 审核桥接。

**T3｜机读负向检查（仅当确有信息增量）**

- 如需写脚本，只做**不下载/执行上游二进制、不读写硬件**的 manifest/schema 校验：包括源 commit 必填、路径/blob 唯一、source-object mapping 不遗漏、许可缺失 fail-closed、关键 API 不允许“未实现但返回成功”。
- 本地离线测试应包含：缺文件/缺许可/重复对象/版本不对应→**退出非零且输出具体诊断**；不能用假数据证明真实上游闭包。
- **不创建或运行没有新增验证能力的 GitHub Actions**；即使创建了手动 workflow，也要等用户通过 GitHub UI 自行触发。

**T4｜提交和交接报告**

- 给出 **真实改动文件、Git 提交、外部固定 SHA、实测过的本地命令与输出、明确尚未运行的步骤、未解决符号和许可证**。
- 根据实际结果更新 `knowledge/02_CURRENT_STATE.md`、`knowledge/04_EVIDENCE_LEDGER.md`（有实际验证才改）、`knowledge/07_DECISIONS.md`（若需要变更）、本文件的 Next Task。
- 若连 FreeBSD base 版本都无法证明，应在该处停下报告 `BLOCKED_FREEBSD_BASE_SELECTION`，而不是为了推进插入大规模缺实现的 Stub。

### 本工作包**不做**

- 不复制整套 6.1 内核到仓库、不开启大规模源文件硬剪裁；不尝试一次建好最终 `AlderFB.kext`。
- 不写入 `BDSM + 0`、`GGTT 0`、未知 Stolen Memory，不从主力机访问 PCI config/MMIO。
- 不允许用空返回函数替代必需 Power Well、DMC/固件、DMA/页映射、锁和 eDP link training。
- 不研究 Metal shader/RTX 混合显卡，不修改 OpenCore/EFI，不更改主力 Windows。

## 验收与下一跳

第一份 PR/commit 应在 **T1/T2 文本源闭包** 上有真实信息增量，明确适配 Intel `8086:46A6` 的 PCI/display/eDP 路径，能复核每个 external commit 和许可。**不要为了“代码量”制造无法证明的 kext Stub**。

只有 B0/B1 验收并解决必要的接口与许可阻塞，才允许规划 B2/B3 的真正 macOS hosted native compile（仅静态）和 B4 GGTT/scanout memory contract。

**交接时的下一句提示（供 Codex 直接使用）**：

> **2026-10-13 附注**：另有用户授权的 1401 只读审计支线（D-16），其断点和续做方式在 [`logs/RESEARCH_LOG.md`](../logs/RESEARCH_LOG.md) 顶部，不影响下方 R1.4-C0 交接内容。用户未指定支线时，以下方主线为准。

> 阅读根目录 AGENTS.md、knowledge/README.md、knowledge/02_CURRENT_STATE.md、knowledge/10_CODEX_HANDOFF.md 及所引原始文档。按 R1.4-C0 的 T0→T4 执行：先在 GitHub 核对既有成果避免重复，追溯 FreeBSD drm-kmod 6.1-lts 需要的 FreeBSD base/LinuxKPI 固定 commit，建立最小 Intel 8086:46A6 i915/eDP 的源/符号/许可证/接口依赖清单与 FAIL-CLOSED 检查。不得加载、安装或签名内核驱动，不触碰主力 Windows/EFI/BIOS，不自行启动 Actions，不写假成功 Stub。提交代码与报告，标明真实测试和未关闭阻塞，保持 RUNTIME_NO_GO。


