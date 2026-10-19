# R36：R35 独立审计与直接返回关闭结果的候选

目标仍为 RTX 2050 10DE:25A9 初始化 → 真正 GPU 执行 → 正确像素读回 → 错误传播 → 安全结束。Intel 保留基础显示。**本轮只推进源码、CPU 合同和原生构建；设备 NO-GO，GPU 未运行。**

## R35 的真实失败位置

已通过现有凭据取得 [run39207578260](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39207578260) 的文本产物。source393d00b5899c84b74309c2fd4ab16919b63f9271，job117913658369，artifact12166357598，ZIP SHA256 `a5552c7f240dbe55905824c9ae0a07436000edf2f3d1178615713e205ee7968d`，1893 个文本成员。凭据不落盘、不打印、不转交重定向主机；无驱动二进制下载。

`full-source/report.json` 明确为 `FULL_SOURCE_COMPILE_FAILED_NO_ARCHIVES_OR_LINK`：1280 个官方 TU 全尝试，1279 成功，只有 nvkms-kapi.c 失败；两处访问不存在的 `bFreeCompleted`（452/458行）。archives=[]，link=null。**本次根因不是 CHAIN，也没有进行归档或最终链接。** generic dependency_closure 注解掩盖了实际 status；本轮修正失败阶段和首条错误输出。

更关键的 P0：R35 调用 `freeDevice(fDev)` 后再用 `nvKmsKapiDeviceFreeCompleted(fDev)` 查询已释放对象。原手写夹具新增了私有字段，且 free 只计数，没有释放内存，7/7 不能证明关闭安全。保留历史夹具，仅在负控中改成真实 new/delete；ASan 编译0、运行非零，报告 `heap-use-after-free in nvKmsKapiDeviceFreeCompleted`。这是 **CPU 负控证据**，不是观察到实机内核 UAF。不能只补字段消除编译错误。

旧 `g1-r35-callers.yml` 也会上传可执行文件；本轮将工作流及工具入口退役为 exit2，不再编译/上传。原历史源码与证据保留。

## R36 候选实现与限定结论

- OGKM 新内部 `NvBool nvKmsKapiTryFreeDevice(Device*)` 直接返回本次关闭结果，不加私有字段、不更改公开函数表布局、成功释放后不再解引用 Device。
- `KmsFreeDevice` 在 FREE_DEVICE ioctl 被拒时返回 false、保留对应句柄；OS 新 `nvkms_xnu_try_close_kapi` 在 PM 不可用、callback 在途或 thread_call_free 拒绝时立即返回 false，不无界 join、不入 wrapper-only 队列、不释放 wrapper。
- try-free 自持 PM pin；两个生产 FB 调用者直接消费结果，失败保留共享 Device/creator/orphan；kapiInit 拒绝复用零使用者、尚未完成关闭的孤儿 Device。
- 旧 void FreeDevice 仅为兼容包装；allocate 失败/legacy owner 完整回收仍未闭合。没有宣称全部 P0-4 修复。

固定输入：NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393`，OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`，Mesa `17ca6174dcc6cb22059ac343bc29f8af7800f42e`；不换版本。

| 输入/输出 | SHA256 |
|---|---|
| ogkm-r36-try-free-result.patch | 0bb0bb2650b483e1002e7a5976e94f02fee1542b7d2cab20dfebe6872a753ead |
| nullmoth-r36-try-free-result.patch | 8e5a8a6003e6b010d1648da4efcb365f02249c3c4e2855d4e8850dce51fc135a |
| 最终 OGKM KAPI | 895de47ae03abc08d9a032f8f083db0be76aa5aa45317ebe37d7720a54c657cb |
| 最终 OS | d9a8330d324cb90ad063603feb27206ef7fc0a13530924278b1e6f57a3ef8a1e |
| 最终生产 FB | f5e0f84db0c321739d8477bf81af5c96943e7e748b11763fce2a65269fab56dd |

OGKM 在 R3 后叠 R36，替换 R35 CHAIN，NISO 补丁不变；NullMoth 保留前31项，序列第32项改为 R36，不叠 R35。原始 upstream 未改。OGKM 正向/反向/重放9步逐步哈希验证，3871文件仅两源变化，候选树 `7dc645d37242e7d4d1c843be688e8a498ff98ec9a5591548c14471e7bc5c5eb8`。NullMoth 32补丁往返通过，611原始文件、614候选文件，候选树 `a82fc913d858aee357843c698597fa05a1670bda8e8dc12c5802a7de087fcf7c`。

正式完整编译仍使用官方逐TU参数和原cwd；只替换精确候选源。route 检查器分别接受精确历史 R33 或当前 R36 清单，检查最终源哈希、实际编译ARGV、完整ar、why_load及最终 `_nvKmsKapiTryFreeDevice` 定义，拒绝漏链/错中间哈希/旧最终源/漏归档成员/错定义。历史 R33 SPECS 不变。

## 实际验证与未运行事项

| 层级 | 本轮事实 |
|---|---|
| CPU 实际函数提取＋ASan | 12/12，真实 heap/delete；pin/共享者/FREE_DEVICE拒绝/per-open关闭拒绝/callback在途及重试/成功恰好一次/null |
| 负控 | R35真实free触发ASan UAF；R36 #error编译失败，无二进制/无场景执行 |
| 工具回归 | 40/40；精确链与缺失最终定义等负控包含其中 |
| 历史三组回归 | 10/10＋5/5＋7/7 |
| R33历史原生证据 | 当前检查器重新复算通过，1280TU＋5shader＋完整链接证据保留 |
| R36 Darwin对象/完整链接 | **尚未执行，待本次提交后触发原生门禁** |
| R36导入数量/选定ABI | 未取得新原生证据，数量未知，不沿填472 |
| KEXT加载/GPU初始化/渲染/像素/结束 | 未执行，NO-GO |

ASan 工具固定三份源哈希并提取完整生产函数；IOKit/锁/NISO/RM/backend 为注入边界，没有真实 NISO 失败或内核调度证明。原生门禁将绑定同次 native-report 的 FB/OS 源，但仍是 CPU 合同。精选文本见 [r36-local-evidence](r36-local-evidence/)，失败原报告的完整内容保留在原 Actions 文本产物，精选摘要不冒充全量。

## 保持开放的阻塞与下一断点

1. callback quiescence **必须早于破坏性 NISO 清理**的完整合同尚缺；当前 try-close 检查在 KmsFreeDevice 后段。NISO 注销/解映射/RM free 错误传播也未修。
2. legacy void/allocate失败路径的完整owner及重试回收未闭合；legacy正常close的无界join仍在。
3. RM门忙超时后仍进入STANDBY；容量64/rollback/完整ABI/loader/卸载安全仍开放。
4. 先读 R36 原生门禁真实文本结果，按 source→object→archive→final 定位失败或验收构建；之后只做“先静默callback、再破坏资源”的完整关闭合同，不能以本轮局部通过放行设备。

复盘：先读真实 report，注解只作索引；夹具的 free 必须检验真实内存释放语义。源/编译/链接/CPU合同与设备运行证据分别登记。回退采用后续普通提交恢复历史构建路线，不改历史、不强推；R35旧验收路径保持退役。未修改.agent、未安装/签名/加载驱动、未操作设备。
