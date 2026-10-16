# 04｜可核实证据账本：正式 CI、脚本与限制

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
