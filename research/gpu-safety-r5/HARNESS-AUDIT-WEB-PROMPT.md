# 网页端独立审查：R33实际原生验收与Device关闭边界

只读审查 github.com/Jakiewbe/honor-hackintosh-lab，先固定本文所在完整commit，再读R33-OGKM-FINAL-ROUTE-20261019.md、ACCEPTANCE-MATRIX-20261018.md及r33-native-evidence/result.json。不得修改/提交、触发Actions、发送上游消息或操作设备。

真实驱动源码固定7a5cb7188ef6477b7383f9529228bbb4426aa1fd；run39189188122、job117858001079、artifact12159721676，ZIP SHA256 bb358a648b789c07710395935d9cd55d8dfbaac0e79318491db2fd60d48b03f5。代码与后续验收文档分别固定；不要再沿用旧排队状态。

审查tools/g1_ogkm_candidate.py→g1_full_build.py→g1_ogkm_patch_route.py→g1_verify_r33_native.py。核对3871文件仅两源变化、补丁往返和编译后比较；1280官方C/C++ TU（1240C/40C++）、5shader及10 NVRM C++ TU的实际参数/快照/对象/完整ar/最终ARGV绑定；两项OGKM修复是否真被why_load拉入且最终定义存在。不得用探针对象代替官方完整参数对象，也不得用名称覆盖率代替loader/完整ABI。

独立检查1954 ZIP/1953 publication成员、固定下载receipt/ZIP身份的信任边界；本地脚本不是GitHub再次认证。检查错误run/source/status/artifact/截短清单是否必须拒绝。精选文本不是1280日志全量；若要复跑从原始Actions artifact取得完整文本。检查12限定CPU/4负控与本次快照绑定、NISO3项仅成功路径、136布局/20形状仅选定ABI。

三个安全FAIL保持：正常close eventBusy无界join；P0-4 KMS拒绝后仍RmFreeDevice/Device free；nv_xnu_pm_close忙后仍STANDBY。r33-followup-evidence/device-owner-refusal真实CPU反例编译0运行1，RM/Device各free1，不删内存，不能称观察到内核UAF。

请沿固定真实FreeDevice/KmsFreeDevice、OS wrapper/event worker、framebuffer dropKapiDevice/finishOrphanedDevice/kapiInit/creator retain链，给最小可失败关闭方案。入口须先禁止新callback并处理在途引用；拒绝须在破坏性资源销毁前传播；保留完整Device和creator，不只保wrapper；关闭中不得复用gDev；覆盖allocate失败自毁、锁序与PM线程身份。不得直接改公开表ABI却假定旧消费者匹配。

按P0/P1/P2给固定文件/行号、触发条件、后果、建议与证据局限，并回答RTX2050距离初始化/真实离屏GPU执行/正确像素/错误传播/安全结束还缺哪些实际步骤。GPU未运行、KEXT-LOAD NO-GO、Intel基础显示保持；不重复“公开源码到顶/只能上机”的旧结论。


最新再读R34-DEVICE-CALLER-CONTRACT-20261019.md、tools/g1_fb_device_close_contract.py和r34-caller-evidence/。本次没有新驱动修复。核对fixture确实提取两个完整FB方法和真实OGKM/OS函数、source hash绑定R33原生报告；5正常路径PASS、2拒绝路径FAIL且整体exit1，拒绝后gDev/creator均丢失。NISO/RM/IOKit与锁为注入边界，free只计数，不是已观察内核UAF。初始未使用变量编译失败与最终#error负控都未执行旧产物。不要把“失败已复现”写成“安全门禁通过”。审查该文档的版本化内部try-close设计，特别是入口quiesce、每阶段失败保留owner、drop/orphan/再绑定/allocate失败整链，指出仍缺的所有权或锁序约束；给出可落地的最小实现，不能把尚未实施方案当完成。
