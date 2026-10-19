# G1：真实调用链、R30 产物审计与 R31 队列所有权候选

当前实现已能从固定输入完成完整 Darwin 重建候选。RTX2050 初始化、GPU 渲染、正确像素读回、设备安全结束仍没有实测证据，设备运行保持 NO-GO。

## 六个 PCI 调用侧：已补齐，范围固定

源码 `9015c246bdfd119c5f13a64b34c170533694ea92`，[run39140902850](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39140902850)，artifact12141348433，ZIP SHA256 `60dc6f46f5ee0a38fd3936d0c7363800f5136da8703edfcdc110a2be206470b7`。145 个纯文本成员已校验。

九个真实 NVRM TU 的对象、诊断 IR 全部编译成功；九份依赖快照与既有完整构建快照逐字节一致，包含有序命令、源码与对象哈希、传递头文件。复用已提交快照，不复制重复证据。六个 PCI 方法都有对象导入、函数内真实直接 call、SDK 声明/参数扩展形状一致的证据。`write8` 来自 `os-xnu.cpp:253` 的 `os_pci_write_byte()`，经 SDK `configWrite8()` 内联，最终调用 `extendedConfigWrite8`，形状为 void / ptr,i64,i8 zeroext。

这是选定调用侧 ABI 形状；不等于 provider 实现语义、完整 ABI、loader/依赖版本或运行验收。它绑定 R30 之前的九 TU 源码，不能据此声称已验收 R30 新增 TU。源码/证据与独立复算见 [pci-caller-evidence](pci-caller-evidence/)。

## IOUserClient::free：撤销 R104/R105 的推断

精确发布物 SHA256 `cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb`，16,787,920 字节。只读重新解析真实 LC_DYSYMTAB：**3397 条外部重定位**；`__ZN12IOUserClient4freeEv` 是 nlist33915，两条外部 UNSIGNED/64 位/非 PC 相对重定位为：

| 地址 | 符号区间 | 区间内偏移 |
|---|---|---|
| `0xd81380` | `__ZTV14NVRMUserClient` | `0xa0` /160 |
| `0xd81df0` | `__ZTV17IOAccelNVRMBridge` | `0xa0` /160 |

它们处于 `__DATA,__const`，是**虚表数据引用**，不是已反汇编确认的直接 call。两边都导入基类虚表，不能排除派生虚表还独立导入某个方法。

候选真实 `NVRM.cpp` 原生 IR（SHA256 `de4904a8e0118229c5af5bbcb76b502b87f567a312d795d2543e909578136396`）显示两张派生虚表的原始索引20（含 Itanium 两项头，字节偏移160）均指向 `NVRMUserClient::free`。该函数从导入的父类 `_ZTV12IOUserClient+160` 加载指针，再通过同一指针间接调用，因此候选无需直接导入父类 `IOUserClient::free`。

这解释了选定导入差异；不据此反推发布物精确 TU、编译器或完整构建配方，也不声称观察到调用执行。未跳到 `IOService::free`。原 `tools/macho_xref.py` 把 filetype 当 ncmds，又把“kext 无重定位”当起点，其“无法静态追踪”结论无效。现替换为有界、精确名称匹配的外部重定位读取器；不使用字节扫描冒充指令解码。7项解析器测试通过，导入解析器12项回归通过。[完整原生 IR 与复算](free-chain-evidence/recompute.py) 可不接触设备运行；可选 `--binary` 重新读本地同哈希取证副本，不上传二进制。

## R30：完整门禁真实，但 PM 还不能关闭

源码 `195f5335563bc78f4800756473490f3dd6d86d90`，[run39143508201](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39143508201)，artifact12143225527，ZIP SHA256 `e8f6ee5d9697b4cb64afee369f2f6d5a74bf5724c681744597f463aec937cc50`。1845 个纯文本成员、1844 个 publication 成员已逐项验哈希。

- 30 个补丁；NVRM 十个 C++ TU（包括 `kms_deferred.cpp`）均 exit0。
- 官方清单实际是 **1280 个 C/C++ 编译单元：1240 C、40 C++**，另有五个 shader payload 对象与独立 NVLink 后端。历史“1280 C TU”措辞不精确，本轮修正；没有减少编译集合。每组件含一份生成的 nvidstring，不能仅按仓库文件名清单计数；同源文件可能按不同 component 参数各编一次。
- 官方1280条有序命令与 run39127772586 一致；1285个官方/五shader对象哈希均一致。R30 改的是适配侧队列，没有重写 OGKM 固定输入。
- 完整候选链接 exit0，SHA256 `74ce9fe05c9a10f8a55fa39ce2e0a097e4b436e4c9e0298fabecca0b8a5f561b`，472导入。六profile136布局值/20函数形状通过；完整ABI/loader未验收。
- 同 CI 源码哈希的局部审计副本重跑 PM 结构合同：**31/32、exit1**。RM门忙仍继续stop channels/STANDBY，仍是FAIL。

证据与可带完整产物目录复算的脚本见 [r30-audit-evidence](r30-audit-evidence/)。未重新运行1280构建来冒充新增进展。

## R30 新发现与 R31 的实际修复范围

对与 R30 CI 精确同哈希的 `kms_deferred.cpp/.h`，编译运行真实队列单元，回调仅计数、不真实释放内存：

| 合同 | R30 真实单元 | R31 候选 |
|---|---|---|
| 同一 node 重复入队只能有一个关闭义务 | FAIL：2 entries、2 close、2 free | PASS：1 entry、1 close、1 free |
| try_free 回调重入 drain 时节点只释放一次 | FAIL：1 close、2 free | PASS：1 close、1 free |
| 第65个不同节点入队失败可见 | PASS：返回失败；只排空64个 | 同样返回失败；未修调用侧兜底 |

这是两个**队列合同缺陷**的 CPU 复现，不直接证明内核中重复close或嵌套resume一定可达。集成中 `kms_deferred_try_free_impl()` 会在 `IOLockSleep()` 期间释放 `gKmsLock`，因此不能只凭函数入口持锁就认定整个 drain 不会交错；实际 PM owner/回调交错仍需集成合同。

R31 补丁只改 `kms_deferred.cpp/.h`：先查已有 node 再选空槽；未关闭节点的数据指针冲突返回失败；保留 closed 状态；`gDraining` 在整个 drain 回调期间持有唯一执行权，嵌套 drain 返回等待下次。模块仍要求调用侧锁串行化，并未宣称无锁线程安全。初始化 reset 只能在静止状态使用。

补丁 SHA256 `921a3d948047c7417cca238004acda9f2b81c1f1862badb325332f0fcb5aa48a`，显式追加在 R30 后。CPU 相同合同通过；独立负控注入 `#error`，compile exit1、无二进制、run=NOT_RUN。原生门禁增加该 CPU 合同，输入绑定到本次真实原生对象的依赖快照。**R31 Darwin/链接尚未执行，等待提交后的新门禁。**

仍开放：容量耗尽只计数而无独立回收路径；正常close的thread_call_free失败未入队；drain内无界eventBusy等待；PM状态跨等待变化与重入；`gKmsCloseDeferred`从累积观测变成可递减积压与旧调用者差值合同是否兼容；P0-4释放拒绝传播。上述未验证风险不可当成已复现UAF，也不可因R31 CPU通过而关闭。RM busy→STANDBY是已确认未修失败。

## 下一断点与复盘

先以新提交执行原生门禁，核实 R31 补丁、实际对象依赖、CPU合同和完整候选链接；失败按日志修。随后推进真实close/resume/PM门合同，优先解决未回收路径及等待中的生命周期，而非重复公开源码存在性或1280首次构建。

同一导入可以来自虚表数据；同一源码可因component不同编成两个对象；green Actions也不能替代PM或GPU证据。项目已进入完整重建候选及选定ABI验收阶段，尚未到可用驱动阶段。未安装/签名/加载/卸载kext，未执行GPU或改变Intel显示。
