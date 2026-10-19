# G1 当前验收矩阵（独立审计修正）

本表替代旧矩阵的“源码到顶/不可重建/只剩加载”判断。历史矩阵保留于Git历史；不得混用不同对象集合。RTX2050 10DE:25A9目标仍为初始化→GPU执行→正确像素读回→错误传播→安全结束，Intel基础显示所有权保持。

| 层级/合同 | 当前事实 | 证据/缺口 |
|---|---|---|
| 完整源码重建候选 | 已完成1280官方C/C++ TU（1240C/40C++）、5shader、独立NVLink后端、完整归档与NVRM链接 | run39127772586；R30 run39143508201独立复核同集合与472导入；不是复现上游发布物 |
| 988目录探针 | 135/988成功、853失败；部分链接后脚本exit0，不能作验收 | run39138580661；入口已退休、exit2 |
| 选定RM ABI | 六profile136布局值/20接口形状已通过 | 完整ABI未验收 |
| 472提供者名称 | 464精确KPI+实际全局、其余8项runner KC实际外部节定义 | loader导出/依赖版本/用户系统/完整ABI未验收 |
| 发布物导入对照 | 修正有界解析器后472项、与候选交集471 | 候选独有panic；发行独有IOUserClient::free来自两张派生虚表+160数据重定位，候选经父类虚表间接调用；完整发布配方仍未知 |
| PCI调用侧 | 六方法真实对象导入/直接调用/SDK形状一致 | run39140902850、固定source9015c246；九TU参数/源码/依赖与历史逐字节一致；不是R30/完整provider ABI验收 |
| NVLink四锁 | 真实后端与17项CPU合同及原生链接已验证 | 不能据此关闭freeDevice/PM问题 |
| P0-4 freeDevice关闭拒绝 | FAIL；R34两个真实FB调用者反例均exit1 | 拒绝后RM/Device/creator各释放一次，gDev也被清空；新可失败接口尚未实现 |
| RM门忙仍STANDBY | OPEN，当前结构审计31/32，exit1 | nv_xnu_pm_close超时后仍继续；不能以IOPM ack要求证明其安全 |
| 延迟KMS close回收 | OPEN；R32b局部源码/CPU候选通过 | R32b run39186519502原生/完整链接与12限定CPU通过；正常busy仍无界join、单独FAIL。容量耗尽、open rollback、上层Device生命周期/PM交错仍未闭合 |
| 延迟队列单一所有权 | R30 CPU两项FAIL，R31同合同PASS | R31 run39184119617原生/完整链接通过；真实close合同2/4、两项FAIL，不作为PM安全放行 |
| OGKM补丁进入最终对象 | R33原生及最终来源独立验收PASS；R32b历史FAIL保留 | run39189188122，双源候选/官方参数/完整ar/真实why_load/最终定义；非完整ABI或运行验收 |
| NISO参数身份 | R33候选真实函数原生CPU 3/3、官方参数对象及最终链接通过 | 只修成功路径参数身份与重复清理；注销/解映射失败及完整Device安全仍OPEN |
| Kext加载 | 未执行、NO-GO | 未签名/安装/加载/卸载 |
| GPU初始化/渲染/正确像素/安全结束 | 未执行 | 编译/链接/CPU检查都不替代这四层证据 |
| Intel基础显示 | 保持现状，不扩大显示所有权 | 不进入G2/G3/WindowServer/Intel Metal |

当前动作是推进真实close未回收/无界等待及PM集成合同，并继续family loader/版本边界；无需重复完整构建、无需新写占位PORT层，也不转设备部署。详见[审计](HARNESS-AUDIT-20261018.md)。

2026-10-19更新证据：[PCI/free链、R30独立审计、R31候选](CALLERS-FREE-R30-R31-20261019.md)。

R31后续验收：[原生证据与真实关闭函数失败合同](R31-NATIVE-AND-CLOSE-CONTRACT-20261019.md)。

R32局部候选：[关闭重试与未解决项](R32-CLOSE-RETRY-20261019.md)。本轮CPU通过不撤销R31历史2/4失败记录。

当前主断点与实测：[R32B-NATIVE-ROUTE-NISO-20261019.md](R32B-NATIVE-ROUTE-NISO-20261019.md)。官方完整构建仍成立；不将探针补丁记为最终产物已含补丁。

2026-10-19 R33：原生队列路线已排除遗漏；R3+NISO官方参数双源候选和最终归档/定义门禁已实现，R33 Darwin未运行前保持待验收。R32b历史OGKM route FAIL不改写。[实现与下一断点](R33-OGKM-FINAL-ROUTE-20261019.md)。

R33最终验收：run39189188122 / source7a5cb71 / artifact12159721676，1954文本ZIP成员已核验，1280官方TU及完整候选来源PASS。历史排队段仅为当时记录；P0-4、normal busy join、RM busy→STANDBY继续FAIL，GPU未运行、设备NO-GO。

R34：[真实调用者合同及可失败关闭设计](R34-DEVICE-CALLER-CONTRACT-20261019.md)，五条正常路径PASS、两条拒绝路径FAIL，整体exit1；未新增驱动补丁，不改变R33原生结果。
