# 网页端只读独立审查 prompt：真实调用链与R31队列所有权

请只读独立审查 github.com/Jakiewbe/honor-hackintosh-lab。先从main历史定位同时包含 `CALLERS-FREE-R30-R31-20261019.md` 与 `nullmoth-r31-deferred-single-owner.patch` 的提交，固定完整SHA。后续CI结果提交与驱动源码提交分开固定。不要改文件、触发Actions、发上游消息或执行设备操作。

先读 research/gpu-safety-r5/CALLERS-FREE-R30-R31-20261019.md、ACCEPTANCE-MATRIX-20261018.md；再读 pci-caller-evidence/、free-chain-evidence/、r30-audit-evidence/。已有假绿审计见HARNESS-AUDIT-20261018.md，不重复“源码是否存在”的历史循环。

核查四组相互独立的证据：
1. PCI：source9015c246bdfd119c5f13a64b34c170533694ea92、run39140902850、artifact12141348433。九TU快照是否逐字节匹配历史命令/源码/对象/依赖；六PCI方法是否同时有真实对象导入与函数内call、SDK ABI形状；write8是否真实源于os_pci_write_byte而不是合成调用者。不能把该历史九TU证据挪作R30十TU验收。
2. free：发布物SHA256 cb3775fa7f8261641cc08328e12793aa7c3698d12a3264c443a68c4f55fb1bdb；LC_DYSYMTAB有3397外部重定位，目标nlist33915在0xd81380/0xd81df0，两张派生虚表区间+160。验证数据重定位而非直接call；候选原生NVRM.cpp IR是否由派生slot20指向NVRMUserClient::free，再加载父类vtable+160且通过同一SSA指针调用。检查tools/macho_xref.py有界读取、精确Mach-O名称、非零失败及7测试；不得以词法/字节扫描猜执行来源。
3. R30：source195f5335563bc78f4800756473490f3dd6d86d90、run39143508201、artifact12143225527。完整官方编译集合实际1240C+40C++（两component各含生成nvidstring）与五shader；十NVRM C++ TU、实际链接和472导入；136布局/20形状只是选定ABI。检查独立复算脚本的默认文本验证与可选完整产物验证是否诚实区分。
4. R31：对照R30单元的重复node入队与try_free回调重入反例（不真实释放内存），核实基线失败、新候选通过和编译错误负控不执行。审查补丁去重/数据冲突/closed保留、gDraining跨回调独占，以及外部锁前提；该CPU反例不自动证明内核可触发double free。核对native_compile在R30后追加补丁，workflow基于本次真实依赖快照编译测试实际单元；若已有新run，核对其source SHA与产物，未执行不得报通过。

重点挑剩余真实问题：容量64溢出后仅计数；正常close thread_call_free失败是否仍无队列；drain IOLockSleep无界等待、等待释放锁后的PM状态与生命周期；累积deferred计数被递减与旧调用者差值合同的冲突。RM busy仍进入STANDBY必须保持31/32 FAIL；P0-4仍开放。不要把已登记风险当新发现，不把未知写成已证UAF。给出P0/P1/P2、固定文件行号、触发条件、后果、建议和证据局限。

最后按层级报告：源码→CPU合同→Darwin对象→候选链接→loader/ABI→设备初始化→真实GPU执行→正确像素→安全结束。目前设备层全NO-GO，Intel基础显示保持。不要把编译、CPU拷贝、标签或单条PASS写成显卡适配完成。
