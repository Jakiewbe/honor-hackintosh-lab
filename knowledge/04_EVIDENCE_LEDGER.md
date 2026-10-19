> **2026-10-19 R31原生已验收：run39184119617通过，十个NVRM C++ TU、31个native补丁记录、官方1280个C/C++ TU+5shader和完整候选链接，472导入，选定ABI通过。队列去重/唯一drain的CPU合同与本次原生快照绑定。新增真实关闭函数合同2/4通过，正常close回调释放失败未入队及eventBusy无界等待两项保持FAIL；RM busy→STANDBY仍31/32 FAIL。完整ABI/loader、设备初始化/渲染/像素/安全结束未验收，设备NO-GO。** [原生证据与下一断点](../research/gpu-safety-r5/R31-NATIVE-AND-CLOSE-CONTRACT-20261019.md)。

> **2026-10-18 Harness 独立审计更新：** 已否定“988 探针证明源码构建到顶”的推断：最新 run39138580661 只编过135/988，部分链接后仍exit0。此前 run39127772586 的1280官方C TU、5 shader及完整NVRM重建候选链接证据保持有效。错误探针已退休并非零退出；Mach-O解析器修正后发布版472/候选交集471复算成立。PM结构合同不再把“RM门忙仍STANDBY”当PASS，真实候选现为31/32、exit1；风险未修。新增九个实际NVRM TU的PCI调用侧原生诊断，待本轮CI。完整ABI、loader/版本、初始化、GPU渲染/读回/安全结束仍未验收，设备NO-GO。 [审计与真实断点](../research/gpu-safety-r5/HARNESS-AUDIT-20261018.md)。

> **2026-10-18 KC8实际进展：** P1/P2门禁修复已在[run39133232412](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39133232412)通过，真实失败注入exit2且报告保留、外部身份跨run替换被拒。[KC最终run39134085153](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39134085153)观察到余下8项runner真实外部节定义（6函数+2数据），58项文本交叉核对；SDK六方法真实编译，5项与历史调用IR形状一致，write8调用侧仍未知。**未重新编完整驱动；472名称已有实际定义观察，不等于loader导出/完整ABI/最终用户系统通过；GPU初始化/渲染/读回/安全结束未执行，设备NO-GO。** 下一步定位write8实际TU/对象做单TU诊断，再补family loader/版本/提供侧ABI与PM关闭集成；不重复1280TU或本轮八符号首次取证。[结果](../research/gpu-safety-r5/KC8-20261018.md)｜[网页端审查prompt](../research/gpu-safety-r5/KC8-WEB-PROMPT.md)。

> **2026-10-18 目标提供者新证据：** [run 39130439405](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39130439405) 只读取证成功；在runner macOS15.7.9/24G830内核中，464项有精确KPI条目且实际目标全局存在，14个别名目标已核对；其余8项仅有IOPCIFamily/IOACPIFamily随系统导出名单。完整候选仍是上轮固定字节，本轮未重新编译驱动。**8项实际二进制/C++ABI、完整ABI、最终用户系统、GPU初始化/渲染/读回/关闭仍未验收；设备NO-GO。** 下一步只读检查KC中的这8项，不重复1280TU构建。[报告](../research/gpu-safety-r5/TARGET-PROVIDERS-20261018.md)｜[网页端prompt](../research/gpu-safety-r5/TARGET-PROVIDERS-WEB-PROMPT.md)。

> **2026-10-18 ABI输入绑定实测：** [run 39127772586](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39127772586) 在源码 `c670c55` 上成功。11个NVRM基线与3个RM对象的传递依赖快照、六profile诊断前后校验、真实链接ARGV核对通过；真实clang的头文件i64→i32漂移反例被拒，编译失败负控无对象/快照、未执行；Darwin工具80项通过。完整构建/候选链接及136布局/20接口形状重新通过。**仅P1/P2选定证据绑定闭环；完整ABI、472目标导出、GPU初始化/渲染/读回仍未验收，设备NO-GO。** [报告](../research/gpu-safety-r5/ABI-INPUT-BINDING-20261018.md)｜[网页端prompt](../research/gpu-safety-r5/ABI-INPUT-BINDING-WEB-PROMPT.md)。

> **2026-10-18 完整参数 ABI 实测：** [run 39122635883](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39122635883) 在源码 `0308ed4` 上成功。三个完整官方RM逐TU命令与三个已链接NVRM C++ TU的 136 项选定布局值、20个接口LLVM ABI形状一致，六profile均未定义altstack，20个提供侧定义未观察到直接栈寄存器内联汇编。1280 C TU、5 shader与独立Darwin后端、完整候选链接再次通过。**只关闭这组选定合同，完整ABI及472个目标导出未验收；初始化/渲染/像素读回未执行，设备NO-GO。** [报告](../research/gpu-safety-r5/FULL-FLAGS-ABI-20261018.md)｜[网页端prompt](../research/gpu-safety-r5/FULL-FLAGS-ABI-WEB-PROMPT.md)。

> **2026-10-18 NVLink 实际结果：** [run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329) 在源码 `0dcc527` 上真实通过。四个真实 Darwin semaphore 接口已编译并进入完整 NVRM 重建候选，同 run 无/有后端对照精确消除四个 NVLink 导入，新增 `_panic` 已登记；仍有 472 个目标导出/ABI 未验收导入。CPU 合同17/17及编译失败负控通过；1280 C TU、5 shader 与独立后端对象、完整归档及候选链接通过。**GPU初始化、渲染、像素读回未执行，设备NO-GO。** 下一步用完整官方逐TU参数核对共享ABI与目标导出，不再重复解决这四个链接缺口。[报告](../research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md)｜[网页端审查prompt](../research/gpu-safety-r5/NVLINK-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 实际构建进展：** [run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) 已成功执行源码提交 `30485ae`：全部1,280个C TU和5个shader对象通过，RM/modeset完整归档及NVRM重建候选已链接。先前九项UNKNOWN均在最终nm中观察到定义；仍有四个已知NVLink锁内部导入，其余471个目标导出/ABI未验收。六个旧profile选定布局一致不覆盖本轮完整逐TU参数。**初始化、GPU渲染、像素读回均未执行，驱动尚不可交付，设备NO-GO。** 下一步是四个真实Darwin锁接口、完整参数ABI与目标导出核验。[结果与证据](../research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md)｜[网页端只读复核prompt](../research/gpu-safety-r5/FULL-SOURCE-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 R80 符号身份与来源：** 修正 Mach-O 转 C 名称时删光下划线的问题；九项 UNKNOWN 已逐项定位为六项数据、一项函数、一项宏数据及一项生成配方候选。已接入本轮显式对象哈希/精确导出取证，47项工具测试及三组历史回归通过。新 Darwin/对象提供者/链接/ABI 尚未运行，完整闭包与设备仍 NO-GO。[报告](../research/gpu-safety-r5/R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md)｜[网页端复核 prompt](../research/gpu-safety-r5/R80-WEB-REVIEW-PROMPT.md)。

> **2026-10-18 R79 审计纠错：** 已撤回“45个符号闭源”与“351→667证明增量闭包不收敛”；索引及同基线显式链接清单已修。固定346符号新扫描为337个词法候选、9个UNKNOWN，尚非对象闭包。27项工具测试和三组历史回归通过；加入六TU选定ABI布局诊断与严格文本发布。新Darwin/链接/ABI尚未执行。见 [本轮报告](../research/gpu-safety-r5/R79-AUDIT-CLOSURE-GATE-20261018.md)。完整闭包与实机继续NO-GO。

> **R28 SOURCE / CPU-CONTRACT / PATCH-APPLIED：** [报告与完整文本证据](../research/gpu-safety-r5/R28-OWNER-COPY-ERRORS-20261018.md)。g++ 13.3 / ASan+UBSan，完整真实事务候选 15/15，R27 基线预期失败 6 项，编译失败负控无产物/未执行；27 个 NullMoth 补丁完整正反向恢复，另有既有 OGKM 补丁。Darwin/链接未执行，无 GPU 或设备证据。

> **2026-10-18 新增 SOURCE-LEXICAL 证据：** [35 符号依赖及 RM 栈 ABI 审计](../research/gpu-safety-r5/G1-CLOSURE-ABI-AUDIT-20261018.md)，含全部词法命中、固定输入哈希、71 个 Darwin 源 blob 核验和九项工具回归。旧 run [39090712869](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39090712869) 的五单元编译/混合链接已以 artifact `12123001015` 的 SHA256 绑定复核；不是新的构建通过。新增精确预处理/对象提供者取证尚未运行。无实机证据。

| R8–R12 设备生命周期 | HOST-TEST / SOURCE-STRUCTURE | 22/22、36/36（两源文件各自期望值） | `research/gpu-safety-r5/README.md` |
| R10 生产文件修正 | DARWIN-COMPILE | 16/16 对象（含生产 NVRMFB 与遗留副本），告警零增量 | run 39050580870 |
| R11 孤儿回收 | DARWIN-COMPILE | NVRMFB kext 311376 B / 174 导出 | run 39051079369 |
| R12 串行化 | DARWIN-COMPILE | NVRMFB kext 311488 B / 174 导出 | run 39051324224 |
| R13 NVRM 链接 | 负结果 | 361768 B / 649 符号 vs 发行版 16787920 B / 34302（约 2%） | run 39051715396 |
| 目标 GPU 在 OGKM 支持表 | SOURCE-REVIEW | 610.57.04 `README.md` 列有 `RTX 2050 / 25A9` | `reference/OGKM-README.md` |

| R5–R7 原生对象门禁 | DARWIN-COMPILE | 12/12 对象 exit 0（original+candidate 各 6 TU），告警零增量 | run 39048772269 |
| R5–R7 NVAccel kext 链接 | KEXT-LINK | exit 0，244400 B，`sha256 89f9839e…5e6cf1` | run 39048772269 |
| 签名 / 加载 / GPU 执行 | — | **未运行，NO-GO** | — |

| R5–R7 全序列往返 | PATCH-APPLIED | 7 补丁正向/反向 exit 0；树哈希 `ea9467f4…` → `adbad235…` → `ea9467f4…`（611 文件） | `research/gpu-safety-r5/README.md` |
| R5 关闭合同 | HOST-TEST | 候选 40/40；改前对照 heap-use-after-free（释放栈在 `kms_close_common`） | 同上 |
| R6 bridge-owner + 隔离计数 | HOST-TEST | 9/9 | 同上 |
| R7 回滚析构器 | HOST-TEST | 15/15 | 同上 |
| R6/R7 结构合同 | SOURCE-STRUCTURE | 12/12、14/14 | 同上 |
| R5–R7 原生编译/链接 | — | **未运行** | `.github/workflows/gpu-safety-r5-native.yml`（仅手动） |

## 2026-10-17 GPU R4 当前接手核查（用户最新 GPU 优先；运行 NO-GO）

用户明确恢复 RTX 2050 `10DE:25A9` GPU 驱动优先，H2 外设暂缓，Intel `8086:46A6` 保留现有基础显示；不扩展到 Head 4/Intel Metal/G2/G3。D-17/D-18 的历史决策不删除，本指令覆盖其中 H4 冻结优先级而不覆盖设备安全权限。

远端 `main` 在核查时为 `7c9f50dee8b5d940cf6726c31f6fd236fb3857ca`，暂无基于这一提交的新 Actions。最近 R4 [#39043997733](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39043997733) 使用 `b7ac4b0`：NVKAPI C 两对象通过；原版/候选共十个 C++ 对象失败。修复 `-Wno-error=deprecated-declarations` 尚待用户手动原生验证；不能宣称新错误或构建成功。

新增固定源码 SOURCE-REVIEW：`NVRM::gpuSuspend` 在 PM users 非零后仍进入 RM STANDBY；`kms_close_common` 的 KAPI per-open 保留失败无法向 OGKM `KmsFreeDevice/FreeDevice` 的 void 释放链传播；`nv_xnu_lookup_fd` 脱锁返回的内嵌裸指针尚无引用合同。详见 [精确调用链与 NO-GO 审计](../research/gpu-safety-20261017/PM-R4-REVIEW-20261017.zh-CN.md)。**无新的 DARWIN-COMPILE、KEXT-LINK、LOAD、GPU 或像素运行成功证据。**

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

## 2026-10-17 GPU 主线 R1 新增证据（待审阅，未推送）

完整v2.3.3源树611文件的 git apply --check=0；实际应用后612文件与候选全量哈希一致，反向应用恢复全部原始文件。v2.3.1/2.3.2检查明确失败，不能跨版本盲用。实际C++ CPU拷贝函数用GCC严格警告、ASan/UBSan运行，2160×1440和257×131像素、padding、边界与拒绝分支通过。新Darwin工作流只做原版/候选真实翻译单元对象编译设计，尚未运行；不能继承旧NMIntelFB或B10的成功。发行包静态成员哈希与版本字段核对属于SOURCE-REVIEW，非驱动运行。细项/原始日志见research/gpu-safety-20261017/。

# 04｜可核实证据账本：正式 CI、脚本与限制

## 2026-10-17 证据范围与主线修订

主线依据 2026-10-15 [实机阶段报告](../research/gpu-feasibility-20261015/README.md)：H1 已进入外接 SSD macOS 桌面，Wi-Fi/触控板未工作，显卡驱动/加速未验证。H4 的 [P0 DMA 40/40 CI](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)、原生 B10 链接和旧 SDK 原生 API 编译均为不同级别的技术证据；不能作为 H2/H3 验收。2026-10-17 新 IOVM64 C++/SDK 验证仅存在代码，**未实际运行**。主线优先级见 [12](12_MAINLINE_ALIGNMENT.md)，本轮仅调整工作流治理与知识库，不声称新增硬件或 GPU 测试。


## 2026-10-17 P0-DMA 新增 IOVM64→RM page-array C++ 合同（未运行新 CI）

源码提交 410ad56：新增两轮地址段转换器、17 项 CPU-only C++ 用例和 Apple IODMACommand Segment64 的 compile-only 桥接源。提交 71e6b5d 扩展 macOS 15 Intel/Xcode16.4 探针，只保存编译器/nm/散列文本。两个新增测试均未运行，不能承袭 40/40 旧测试或旧 native SDK 的 PASS。完整合同在 scripts/g1/IOVM_PAGE_ARRAY_CONTRACT.md。真实 mapper 资源、nv_xnu_alloc::md prepare 兼容、RM pOsData ownership、GSP DMA/quiescence 与 KDK ABI 全部 NO-GO。


## 2026-10-17 实际 P0-DMA 三份 JSON 证据

[Actions #38939252741](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38939252741)（`791ba38`）工作流/Job SUCCESS：10/10+13/13+11/11+6/6。Artifact 12062915390 ZIP SHA256 `c9385ac96e52e24767b562cf1dd29ac8767f02388f2e14e2bca02e3affca80a1`；详见 [P0 DMA 2026-10-17 专题](../scripts/g1/P0_DMA_20261017_EVIDENCE.md)，包含三份 JSON SHA、固定来源 blob、两个 DRHD 与 RMRR，和明确的 OS runtime NO-GO。无硬件加载。


## 2026-10-17 云端原生 SDK 和 DMA CI 最新实际验收

- Xcode 16.4 Build 16F6 / macOS SDK 15.5；[run 38931389598](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931389598) SUCCESS，`CLANG_RC=0`、`Mach-O 64-bit object x86_64`；Artifact `honor-g1-darwin-dma-sdk-evidence` ID 12059785493，ZIP SHA256 `a9552330c2b26b353617f358d843bffa0f5b47f94c31fdcd67648cf73e06d65b`。探针源 SHA256 `9362ff4c0cb8ccf712a9abdcaf0e383ea5e94e5fd6e96541e93365aa2c1773bb`，临时 `.o` SHA256 `e9bc99109f81904b80137155d0872b79b236f12494334284fd2c3dd267b45018`。nm undefined 导出为 `IODMACommand::OutputHost64` 和 `IODMACommand::withSpecification` 两个 C++ 符号；virtual lifecycle 调用不应被误解为这两个名字覆盖了全部 ABI/运行时接口。**编译通过不等于链接或可加载性。**
- [run 38931378828](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38931378828) FAILED：首两组 10+13 项均 PASS；`test_dma_rm_path.py` 11 项中 2 项 FAIL，日志报 `unterminated function body`，根因是测试构造了非法 line-comment fixture，非实际固定源码错误。随后 upstream 和 DMAR 取证未执行，上传 artifact 为空。仅修复测试 fixture 的提交 `636ac9a` 已推送、**尚未重新验收**。下次应对 40 项测试、两个 DMA 合同 JSON 与 `dmar-topology.json` 取得完整证据。


## 2026-10-16 P0-DMA 增量证据（RM 正则与 ACPI DMAR）

- 固定上游 NullMoth/NVIDIA `osIovaMap/osIovaUnmap` 源码数据流仍为 P0：系统 DMA 返回 `pOsData=NULL` 会与 peer 映射判别冲突，且错误路径可能丢失 mapping owner；并非已执行硬件故障。原本的审计器存在注释假阳性；提交 `479e3459ef17e99e8f459219dd963b781ec13d5e` 改为清理注释/字符串并加入 4 项反例，测试共 11 项。隔离环境对应逻辑 11/11 PASS；**当前主线新 CI NOT RUN**。
- 先前已采集的 P40 ACPI DMAR：实机 HONOR/ADL-P-M，长度 136，revision 2，`checksum_ok=true`，SHA256 `e84c886dfcc89640faf9c3386d5fbb4dc77483901c816eb38fdcb22a6c298f86`。提交 `444e959421edaa61beac09ffc1dd0360cff58e67` 增加只读 `dmar_evidence.py` / 6 项合成测试，并让下一次手动 [P0-DMA Contract](../.github/workflows/g1-dma-contract.yml) 自动生成 `dmar-topology.json`。此报告尚未运行；尚未从真实 136 字节表中获取 DRHD/PCI device scope 结论。
- DMAR 的 MMIO base、PCI scope、RMRR 是固件静态声明，不能证明 Intel IOMMU 在目标 macOS 中开启、实际翻译域或设备页表可达，更不能证明 NVIDIA 10DE:25A9 的 GSP DMA 静默。所有设备激活依然 **NO-GO**。


## 2026-10-16 P0-DMA RM 映射所有权与分类门禁

- 已实际通过：[Actions #38903242709](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709)，原有 10+13 项主机端模型/源码合同测试 PASS；不能推出真实 GPU DMA。
- 新的源码事实：NullMoth `nv_dma_map_alloc()` 为 `*priv=NULL; return NV_OK`。固定 NVIDIA `osIovaMap()` 用 `&pPriv` 调该回调，然后 `pIovaMapping->pOsData=pPriv`；`osIovaUnmap()` 用 `pOsData==NULL` 区分 peer 路径，且错误时仍清空该字段。固定 NVIDIA `os.c` Git blob `b441a66fe735e834f830bae9344333c31b16c1f2`，固定 NullMoth `os-xnu2.cpp` blob `c1fe41e9ff30649c6d02827aee5995f8eaa944b3`。
- [`dma_rm_path.py`](../scripts/g1/dma_rm_path.py) 与 [`test_dma_rm_path.py`](../scripts/g1/test_dma_rm_path.py) 已提交，人工触发 [G1 P0 DMA contract](../.github/workflows/g1-dma-contract.yml) 后将输出 `dma-rm-path.json`。**NOT RUN**，不能将源码意图审计视作真实 GPU 错误重现。JSON verdict 固定 `BLOCKED_RM_IOVA_OWNER_AND_DMA_UNVERIFIED`。
- `osFreePagesInternal` 通过 `memdescGetMemData` 回收的是不同的分配句柄，不应混淆其与 `pOsData` DMA 映射句柄。后续必须保留两套独立所有权并验证不同的生命周期。
- [Darwin Xcode 原生 SDK Probe](../.github/workflows/g1-darwin-dma-sdk.yml) 仍 **NOT RUN**；不把 Apple API 源码声明冒充原生构建或目标机兼容。


## 2026-10-16 P0-DMA 新的原生接口验证门禁

- 实测源合同 / 模型：[Actions #38903242709](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38903242709)，10+13 Python tests PASS；静态 7 项来源断言 PASS，实际设备 DMA 未测试。
- 新增 `scripts/g1/dma_sdk_probe.cpp` 和 [只编译手动工作流](../.github/workflows/g1-darwin-dma-sdk.yml)：**NOT RUN**。固定 Apple XNU macOS15.5 `a1e26a70f38d1d7daa7b49b258e2f8538ad81650` 的 `iokit/IOKit/IODMACommand.h`，blob `c9e75dc4df8b6446788c154a893a7c670d063fd1`。源码声明级证据已核对：`withSpecification` 返回 `OSPtr<IODMACommand>`，`setMemoryDescriptor` 默认 `autoPrepare=true`，`prepare` 可阻塞；`gen64IOVMSegments` 是 64 位 I/O 地址段接口。待 CI 提供真实 SDK C++/Mach-O 对象级证据。
- 绝不把 Xcode 源码探针编译成功等同于真实 DMA/GSP/设备 IOMMU；该工作流不上传/运行二进制。


## 2026-10-15 最新增量：已进入桌面，显卡加速仍未验证

用户通过 H1-COUNT 越过 EXITBS，完成外接 SSD 安装并进入正式桌面；内屏 2160×1440 可显示。两块 GPU 的系统报告均为 No Kext Loaded，桌面卡顿，尚无硬件加速验收。用户已关机，本阶段只做显卡驱动可行性调研；没有安装或加载新驱动、修改 BIOS 变量或触发 CI。

本轮[调研归档](../research/gpu-feasibility-20261015/README.md)含路线比较、固定源码版本与检查记录。RTX2050 渲染到 Intel 内屏桥接是待验证方案。此前记录的 31 项通过、0 项失败仅为源码/文档检查；没有新原生构建或硬件测试。本次上传已获用户明确授权。原始照片、设备日志、EFI 和驱动二进制不上传。

**以下保留历史记录；其中“仍卡 EXITBS”“尚未进入 macOS”等描述已不代表最新用户实测。旧自主驱动的未验收结论仍成立。.agent/ 本轮未迁移，接手时请先读上述增量。**

---


> 最危险的错误是把 Actions SUCCESS 写成真实 GPU 已适配。此表专门记载**什么实际运行过、什么仅为模型、什么还没跑**。现有报告中的部分“待运行”是历史时点，不能覆盖后续正式运行记录。

## 已正式运行的云端证据

| 运行 | 实际完成内容与观测 | **不能推出** |
|---|---|---|
| [R0.8 #38197014657](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38197014657) | 旧 `NMIntelFB` x86_64 对象和链接成功；有 SDK min target mismatch 警告 | 驱动可加载 |
| R0.9（见[报告](../docs/R0.9_results_and_R1.0_gates.md)） | 原始 Intel kext 静态格式、plist、设备表 `46A6`、链接目标 15.5 检查 | 真机有效扫描 |
| [R1.1 #38199566264](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38199566264) | Intel 边界/MMIO 补丁候选原生编译链接与约束检查 | `NVAccel` 编译成功 |
| [R1.2-C #38202526277](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202526277) | 整次 **FAILURE**，源/补丁检查与 37/37 模型通过；native build 步骤 CI 脚本参数冲突 | 不能当成驱动源代码失败或 dual build-pass |
| [R1.2-C #38202869877](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38202869877) | 整次 **FAILURE**，real native object+kext 链接成功，随后 Bash 3.2 大小写扩展 `${variant^^}` 不兼容，virtual 未运行 | 不能说 virtual 失败或整次 SUCCESS |
| **[R1.2-C #38205791450](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38205791450)** | **SUCCESS**，`macos-15-intel` Xcode16.4/SDK15.5，real+virtual 两种旧 NMIntelFB native 编译/链接；37/37 离线参考测试 | kext 在目标机可加载，显示或加速 |
| **[R1.2-F #38209066259](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38209066259)** | **SUCCESS**，macOS 15.5 Apple 源码正式锁定，5 blob、12 结构项和 R1.2-D/E 24/24 参考模型，113 状态 | 发行内核二进制行为证明、死锁已消除 |
| **[R0.7 #38210653466](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38210653466)** | **SUCCESS（只在 prerequisites 模式）**，SDK smoke + NVIDIA r610.57.04 构建条件调查，发现公开源码缺失 `Darwin_x86_64/compile_cmds.sh` | NVAccel 进行了 Darwin native 编译 |
| **[R1.2-G #38211816141](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38211816141)** | **SUCCESS**，Apple `handleVBL` 10/10 源码结构谓词；D12/E12/G16 共 **40/40 参考模型**，E113/G363 状态；只生成文本 | 回调派发/停止与真实内核对象并发安全 |
| **[R1.3-D #38217837373](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/38217837373)** | **SUCCESS**，发布 `v1.14.2` `nullmoth-nvidia-1.14.2.tar.gz` SHA256 匹配 `7c7f7ac97dbcdd48786d4384ffcb2d19199b6d3bc0fb013c71f63b766dea6be5`；**172** 路径，**1** NMXGPU binary；已知名称的 `amd.flags`、`srcs-i915`、编译对象/源树/manifest 匹配均 0 | 二进制真的缺源码/出错；完全无其他名称的清单；内屏工作 |

## 仅静态/离线而非正式云端硬件测试

- [R1.4-C0 首轮](../docs/R1.4-C0_独立i915源码与接口依赖基线.md)：Windows/Python 3.11，156 条固定公开文本源记录，92 定义/79 关系；结构核验通过；新增负向测试 **25 通过、0 失败**。完整闭包门禁 **退出 2、拒绝放行**。实际 [命令/输出](../research/independent-i915/verification.json)。仅 SOURCE-STATIC，无 Actions/native/kext/hardware。

- [R1.3-A](../docs/R1.3-A_IntelXe46A6显示输出双路线源码核验.md)：直接核对 7 份固定 NullMoth Git blob 和 18/18 源码结构条件；`scripts/r13a_intel_scanout_source_audit.py` 已提交，**没有标为 CI PASS**。
- [R1.2-D/E/G](../docs/R1.2-G_VBL门锁外派发与生命周期审查.md)：锁序/状态机是参考模型，不能模拟真实的 Apple 内核锁、对象析构或 GPU 中断。
- [R1.4-B](../docs/R1.4-B_方案批判性审查与独立源码基准.md)：Linux/FreeBSD 候选源码已核实接口位置，**没有**自己的 Intel-only native object、完整 kext 或实物测试。

## 本机 Windows 只读实测（非 CI）

| 记录 | 实际完成内容与观测 | **不能推出** |
|---|---|---|
| [2026-10-12 硬件调查](../docs/hardware-survey-20261012/REPORT.md) | 普通权限 PowerShell 5.1 在 GLO-FX6P 主力机上执行 `collect.ps1`：26 项采集，成功 22 / 部分成功 1 / 失败 3（Secure Boot cmdlet、manage-bde、reagentc 需管理员）；`selfcheck.ps1` 41/41 通过；`FILES_SHA256.txt` 覆盖 74 个文件。当前模式 NVIDIA 无显示源/目标，内屏由 Intel 扫描输出；ACPI DSDT/SSDT 原表已保存 | MUX 有无、外接口归属、VBT/eDP 参数、BitLocker/恢复条件；任何 macOS 层级（不属于 `SOURCE-STATIC` 以上任何分级） |

## 所有实验的终点分级

`SOURCE-STATIC` → `MODEL` → `OBJECT-COMPILE` → `KEXT-LINK-FORMAT` → `KERNEL-LOAD` → `PANEL-SCANOUT` → `METAL-RENDER` → `RECOVERY-VERIFIED`

任何新报告必须同时写明：**输入 commit + macOS SDK + 实际执行命令（或明确没有执行）+ 成功/失败日志 + 结果分级 + 不证明的项目**。新增 CI 仅在能独立回答当前 P0 问题时考虑，且须用户手动发起，默认上传纯文本。

**当前历史最高层级仅覆盖旧 NMIntelFB 的 KEXT-LINK-FORMAT；没有我们的自研 kext link，更没有任何目标实物运行。**

## R1.4-C0.1 本地实际验证
[source/运行记录](../research/independent-i915/c01/verification.json)：55锁源字节核验；21通过0失败；结构退出0，闭包退出2。仅SOURCE-STATIC；XNU四项固定raw源尚缺独立树核验。无Actions/native/硬件。

## R1.4-C0-pre｜本机原表静态解析
等级SOURCE-STATIC，非运行时证据。[记录](../research/acpi-static-20261012/README.md)：36表SHA/长度/checksum一致；6离线测试通过0失败；iasl单表16通过0失败，20200925/20250404联合16表均退出255（0通过2失败）。2026-10-13同一20250404工具改用-e全部其余15表逐表解析，0通过16失败、均255；重复_S0W两处已定位（SaSsdt/SSDT9，PEG1.PEGP），35项findings见external-review.md。全外部引用仍BLOCKED，DSDT单表有外部方法警告；没有执行AML/触发Actions或访问硬件。

## 2026-10-13 C0-pre选表-e修订
同一ACPICA20250404/包20250404-1，无网络非root无宿主挂载容器。第一选择2通过14失败，精确新对象为DSDT/SSDT9的I2C0.TPD0._PS0/_PS3；仅改变两组内代表后16通过0失败。每目标13外部表及两项排除见selected-external-runs.json；原16张表全部仍作目标且不改。38项findings，NV/Igfx方法体未变，TCSS新增PCIC(1)/PCID(4)声明。DSDT外部方法警告及EDMX UnknownObj不因退出0消失；仅SOURCE-STATIC，RUNTIME_NO_GO。原调查目录/workflows不变，没有执行AML或硬件操作。



