# 04｜可核实证据账本：正式 CI、脚本与限制

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

## 2026-10-13 离线测试维护（不是新的硬件或源码研究成果）

输入 main `9b2093c`，两个上游克隆沿用 A1401 固定 SHA；[命令与结果](../tests/cache-fixture-verification.json)、[缓存条件](../tests/README.md)。全部测试：完整缓存151通过0失败0跳过；干净检出137通过0失败14跳过。1401分别13通过0跳过、3通过10跳过；缺缓存的生产结构校验均退出1。未触发 Actions，原硬件调查和 `.github/` 不变；保持 `RUNTIME_NO_GO`。跳过不计通过，不提升 SOURCE-STATIC/运行等级。
