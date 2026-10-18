# 472导入的目标提供者：原生只读取证

本轮目标是把完整NVRM重建候选的472项导入，推进到有实际提供侧文件可查的状态。不是重新做1280个TU编译，也不加载驱动。用户已授权相关main快进与仅源码/编译/链接/文本诊断Actions；设备持续NO-GO，不改.agent或固定上游。

输入固定为源码c670c559cc4bd507f5efcb951dd428de250ba90c、run 39127772586的实际完整候选，SHA256 bbde79f1601ee7bc89bcef04f48dc45276d39f9dec9e3f8bbed456f157c1e1d3；已入库nm清单SHA256 0691e92bc5ef4ce537668c89a0c7b0c71238990aaeafc1c60125293e59fb9dc8。新任务不重新构建该候选，明确采用历史固定证据。

方法：只读Intel macOS runner的kernel、System.kext各插件、IOPCIFamily、IOACPIFamily；保存bundle ID/version、文件hash、精确nm命令、完整输出hash、匹配导入及诊断；另列SDK Kernel.framework Libraries/Extensions和KernelCollections元数据，为下一步选择实际导出资料。所有匹配保留Mach-O原名，只删一个ABI下划线得到源码拼写。

可证伪点：原生nm可能无符号、文件不存在或不可解析，均必须明确保留；任何局部解析失败不能转为匹配。全局定义不是内核KPI许可导出，不证明类布局、vtable、返回类型或语义ABI。未观察到也不证明目标系统缺实现。runner系统不是用户最终系统，不把SDK声明或stub当成真实目标导出。

验收：472行逐项记录、提供者文件绑定、观察失败保留、纯文本产物。目标导出/ABI验收维持NOT_VERIFIED。风险为只读CI时间与文本记录；回退只撤销本轮工具/工作流，无设备或系统修改。

## 已执行结果

源码 `1a481ba2d5a57ada56648eb7a1ae25868fc90861`；[run 39130439405](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39130439405) success。macOS 15.7.9 / 24G830、Darwin 24.6.0、Xcode 16.4 / 16F6、SDK15.5；这只是runner系统，不是用户最终目标系统。

| 项目 | 真实结果 | 层级限制 |
|---|---|---|
| 内核全局定义 | 原始nm23424项；472导入中464项有精确全局定义 | 全局定义单独不等于KPI导出 |
| 内核KPI符号集 | 464项有精确条目且实际目标全局存在；所属KPI ID均出现在固定公开NVRM Info.plist的OSBundleLibraries | 仅该runner的名称/别名证据，不接受版本区间、ABI或用户目标系统 |
| 分组（不重复计数） | bsd14、iokit324、libkern97、mach26、unsupported3，共464 | 两项也在private中，但可从已声明的unsupported找到，不新增private依赖 |
| 别名 | 14项；例如IOLockLock→lck_mtx_lock、IOMalloc→IOMalloc_external，全部核对真正目标全局 | 未把“同名函数存在”代替loader的AliasTarget |
| IO家族 | 7项IOPCIDevice在IOPCIFamily.exports，1项IOACPIPlatformDevice在IOACPIFamily.exports | 只有随系统导出名单；KC中实际二进制定义、类布局/vtable仍未验证 |
| 工具测试 | 原生采集器9/9；离线复算器Windows6/6；两项真实文本内容破坏负控均拒绝 | 复算器本轮未在Darwin执行，不是新驱动编译 |
| 历史回归 | WP1 10/10、FBClaim5/5、B2 7/7；符号身份8/8、文本发布3/3 | 本轮真实运行，不当作目标系统ABI证据 |

kernel文件SHA256 `04a501246caf768356f4090a8fd662daf5bbc949993353526c66771f5ba1d8e4`。通过当前otool读取 `__LINKINFO,__symbolsets`：offset15056896、size312666、节SHA256 `0cee84f8619a19348cbdb380ffe265252ce0450b4385fa4023f2298f79d22939`；已解码plist并另记XML重序列化摘要，不冒充原节字节。固定公开源Info.plist Git blob `d194123433b6d5cebd00cf2989f1adb6701dab87` 与本地副本一致；它是公开源码声明，完整候选目前只有链接可执行文件，不是已验收的可安装bundle。

原生artifact `12138280225`，ZIP SHA256 `ae5d224625284086bdb03ab81e3d098739082d5e3940e6f1d11b1fbb937ae4aa` 已验证。入库的 `target-provider-evidence/native/` 保存原始nm、otool、符号集解码及绑定、两份原始family.exports、报告及原始发布清单；大约7MB的无关KC完整元数据留在原artifact，本地完整副本也已保留。复算器只要求并核验实际消费文件，输出明确列出未复制且未消费的原始成员，不宣称仓库包含整个artifact。KC相关七个bundle的版本/UUID/集合位置保存在kc-selected-metadata.json，只用作元数据。

## 可复算入口

```bash
python tools/g1_provider_evidence.py --native-text research/gpu-safety-r5/target-provider-evidence/native --imports research/gpu-safety-r5/input-binding-evidence/full-source/full-nvrm-undefined.txt --source-info-plist research/gpu-safety-r5/target-provider-evidence/fixed-source-NVRM-Info.plist.txt --expected-run-id 39130439405 --expected-source-commit 1a481ba2d5a57ada56648eb7a1ae25868fc90861 --expected-artifact-id 12138280225 --expected-artifact-sha256 ae5d224625284086bdb03ab81e3d098739082d5e3940e6f1d11b1fbb937ae4aa --out provider-name-analysis.json
```

实际在Windows执行该等价命令，结果为464项KPI精确条目/目标全局、8项family allowlist、14项别名目标均存在。结果、每项记录和消费文件绑定见provider-name-analysis.json；native-result.json记录本轮身份与原始摘要。

## 纠错与证据边界

首轮[39129690581](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39129690581)采集job成功，但内核观察失败：解析器不接受真实 `.constructors_used` 名称，464项当时尚未证到；报告明确保留OBSERVATION_FAILED，没有把它填为匹配。修正后[39129864765](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39129864765)才观察到464个全局；[39130108301](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39130108301)补齐两份family导出名单。原生kmutil的show-prelink-info忽略bundle过滤，重复返回整份元数据；现改为只读一次，未把过滤参数当成已经过滤的证据。早期run身份、artifact摘要与内核失败原因保存在earlier-observations.json。

真实iokit符号集中还有一个与本候选无关的 `__ZN9IOService9resourcesEv ` 条目带尾部空格。复算器保持原始字符串，不strip成另一个符号；12条private SymbolPrefix仅登记前缀元数据，不伪造精确导出。该异常和前缀均未贡献本轮464计数。首个本地复算因尾空格被保守拒绝，修正为保留不规范原名并加入回归后才产生最终结果。

本轮使用既有原生工具与Python做普通静态取证，遵循REA技能的原始字节/推断分离原则；没有REA服务输出，不称REA Evidence，也未安装分析工具。没有新增构建输入或换上游版本，因此未重生成旧work/write_inputs.py清单。

## 结论与下一断点

“472目标导出未知”已细化为：**runner内核464项的精确KPI条目和实际目标全局已证；8项仅family名单；全部的完整ABI/最终用户系统仍未验收。** 不把它写成缺472个实现，也不把472个名称有线索写成全闭包通过。

下一最小动作：继续只读检查KC中的IOPCIFamily/IOACPIFamily实际导出/符号与SDK C++合同，优先这8项；同时保留版本区间/最终目标系统差异。完成本轮名称取证后不重复1280TU构建，除非源码或构建参数改变。完整共享ABI和PM/关闭集成仍开放。GPU初始化、真实渲染、像素读回、安全结束未执行；当前驱动仍不可交付，设备NO-GO。

改动为两个采集/复算工具、对应测试、只读workflow、证据和项目文档；没有改驱动行为。回退仅撤销这些文本文件，不需要设备回滚。复盘：全局名字、KPI符号集、别名目标、family allowlist和ABI必须分别核对；先观察系统实际布局，再选择最小资料，避免把不存在的独立文件误判成缺实现。
