# R1.4-C0.1｜PCI、probe 与 Power Well 的配置/接口合同

执行起点：`027bd7c9ce3fe9fe5615186aa864484752eb1986`，2026-10-12。

复用 C0 的版本与函数证据，不重新运行旧构建、VBL、发行包或硬件调查。本轮仅收窄 PCI→probe→Power Well 路径，审查固定 FreeBSD base 的构建规则、生成接口、真实头文件提供者及电源失败传播。

输入 commit 不变：drm-kmod `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`；base `8c9ce319fef765890ce518cab85d3a470b669849`；XNU `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`。

验收：新增原始源逐项 commit/blob/许可可追溯；生成规则与未生成产物分开；接口引用定位实际定义或明确 BLOCKED；电源操作的后置条件、错误传播和停止清理合同具有源码依据。静态负向检查验证缺源/错误配置/假成功不能放行。仅 SOURCE-STATIC，未满足真实预处理/对象闭包不进入编译。

可证伪点：BSD 默认配置或 include 次序是否被旧台账错误推定；Power Well poll 超时是否真正传到 probe；always-powered 的 PM 空接口是否具有可继承的 XNU 语义。

风险与回退：文本图不证明 ABI 或硬件成功；无 FreeBSD 构建环境时不生成假的头文件/编译参数。仅新增本轮文件和更新最新状态，历史 C0 输出保持原貌；本地提交可独立审查，禁止推送、触发 Actions 和部署。

交付：[构建、提供者、调用与失败合同](build-and-providers.md)；[源锁](source-lock.json)、[build-contract](build-contract.json)、[power-contracts](power-contracts.json)、[实际验证](verification.json)。55源锁（相对C0新增26文件）、32词法定义/14直接调用、七组生成输入，21通过0失败；闭包退出2。

复用原fetch脚本的--lock参数；复验命令与证据限制在构建说明中。四项XNU合同未实现，真实make/预处理/ABI/硬件未验证。
