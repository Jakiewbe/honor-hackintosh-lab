# 网页端只读独立审查：R32b限定关闭路径及Device边界

只读审查 github.com/Jakiewbe/honor-hackintosh-lab。定位包含 nullmoth-r32-close-retry.patch 的源码提交，固定完整SHA；后续CI证据提交另行固定。不要修改/提交、触发Actions、发送上游消息或操作设备。

先读 R32-CLOSE-RETRY-20261019.md、ACCEPTANCE-MATRIX-20261018.md、R31-NATIVE-AND-CLOSE-CONTRACT-20261019.md。对照R31失败证据与R32补丁，核对：

1. 真实kms_close_common是否在nvKmsClose成功后，以NULL data转交唯一队列所有者；所有失败路径是否可追踪；重复调用的有效指针前提是否明确。不要把只计数的CPU free当真实内存回收。
2. 实际try_free是否在eventBusy时立即保留而不等；thread_call_cancel/free的XNU语义、closing阻止重入、callback最后一次popen访问能否支持wrapper寿命；上层KAPI Device寿命是否仍有缺口。
3. 独立ONCE worker是否确实预分配、100ms重试、保留未完成节点、不重复backend close；新节点是否重置deadline造成饥饿；suspend pending/commit/abort、resume LOST、旧已排队worker是否正确拒绝；RM gate重开之前是否可能抢KMS lock进入RM。
4. deferredCounted是否只递减所属backend拒绝计数；全局差值计数合同仍有什么风险。容量64溢出与open rollback漏队列是已登记OPEN，不应误称本轮已修。
5. 12个限定通过场景与单独normal-busy FAIL是否来自真实11函数、实际声明/ops/queue；编译失败无二进制不运行、三个语义变异均非零失败是否真实；检查注入边界和未覆盖实际XNU并发。四项源码结构检查不能当执行证据。
6. 若有新CI，核对run的源码SHA、31个NullMoth补丁加OGKM适配、完整序列反向恢复、10 NVRM C++ TU、官方1280 C/C++ TU（1240C/40C++）+5shader与NVLink、真实链接、472导入；CPU合同必须绑定本次原生依赖快照。没有run不得报告Darwin通过。136布局/20形状不是完整ABI。

按P0/P1/P2给固定文件行号、触发条件、后果、建议、证据局限。RM busy→STANDBY保持FAIL，P0-4/Device生命周期/容量耗尽仍OPEN。按源码→CPU→Darwin对象→候选链接→完整ABI/loader→初始化→真实GPU执行→像素→安全结束分层；设备仍NO-GO，Intel基础显示保持。不要重复“公开源码到顶”或要求设备部署来替代可继续的源码工作。

必须独立检查R32b纠正：0d4c329初稿/run39186159503不能作为整条close设计验收。固定OGKM KmsFreeDevice446调用void close后，FreeDevice629-643继续释放Device，而event handler3827可能仍读Device。当前恢复正常close原有无界join，--open-normal-busy必须真实exit1；只修正常free拒绝漏队列与deferred try_free不等待。不得把12项通过合并为13/13，也不得悄悄丢弃正常busy失败。查看r32b-close-evidence/binding.json和kapi-device-boundary.txt；旧r32-close-evidence是被取代初稿历史。

再查tools/g1_kapi_close_owner_contract.py及r32b-close-evidence/device-owner-contract：是否确实提取固定OGKM完整FreeDevice/KmsFreeDevice/事件函数；两份编译0、运行1的证据有无准确区分初稿提前Device free与修订版无界join。这里是注入交错与替身类型，未真实删除内存，不能升级为已证内核UAF/死锁。CI驱动源码固定051651ec0dfc43cfbb9c39534895a8fe4288f035；文档证据后续提交单独固定。


最新优先审查 R32B-NATIVE-ROUTE-NISO-20261019.md。原生驱动源码固定051651ec0dfc43cfbb9c39534895a8fe4288f035/run39186519502/artifact12158179549，证据文档后续提交另固定。1937纯文本ZIP成员、1936publication成员；1280真实编译日志、10 NVRM C++ TU、31 NullMoth补丁完整反向、12限定CPU绑定本次快照、4负控及候选链接是否可复算。正常busy/P0-4/PM FAIL不得合并进绿色CPU数量。

重点独立复核新P1：native_compile对OGKM R3打补丁的候选探针源7e5492e0...，full build实际KAPI源66437bc3...，why_load从完整modeset归档选中真实原始KAPI对象。g1_ogkm_patch_route.py必须exit1；不能撤销1280完整构建事实，也不能说32条native补丁全进入最终候选。给出把明确候选源纳入官方逐TU命令、保留原始/候选双哈希和实际对象归档来源的最小改法，禁止用不同参数的探针对象替代。

再复核NISO两行候选：固定nvkms-kapi-notifiers.c在清semaphore时误清device->notifier字段；同真实函数CPU原始3 FAIL、候选3 PASS、编译负控无二进制不执行，重复清理断言是否比较前后差值而不被其他漏清理抵消。ogkm-niso-surface-owner.patch尚未接入原生/最终链接；只成功路径参数身份，不是注销失败/整体Device关闭已修。

P0-4补强：backend-refused注入真实FreeDevice仍RM free1/Device free1、backend close0/queue1，编译0运行1；CPU边界不删除内存，不能称已证内核UAF。当前源码绝不放行设备。请按P0/P1/P2、固定行号、触发/后果/证据局限给出结论；下一步先补最终OGKM源选择，再推进完整Device生命周期，不重复“源码是否存在”。


当前优先复核 R33-OGKM-FINAL-ROUTE-20261019.md 及本prompt所在固定提交。沿g1_ogkm_candidate.py → g1_full_build.py → g1_ogkm_patch_route.py逐行检查：两项固定补丁/两源变化、3871文件正反向/编译后完整比较，候选放在文本发布目录之外；只替换两个源操作数、保持官方逐TU flags/cwd，不混入探针对象；逐项验证真实编译日志、完整归档ARGV、最终链接ARGV、why_load和实际全局定义。新增门禁是否在真实错误源/漏成员/缺定义时非零退出。R33原生若尚未登记，禁止用R32b成功顶替。

已排除队列遗漏：源051651e的BASELINE_CPP包含kms_deferred.cpp，R32b实际队列snapshot/object/finalARGV与四个最终定义已复算。避免将本地过时脚本当runner源码。历史R32b OGKM route仍exit1，不撤销完整编译事实。NISO候选只有成功路径参数身份修复，不得说完整错误传播/Device释放已修。

报告应回答：距离RTX2050真实初始化/离屏GPU执行/正确像素/错误传播/安全结束还缺什么；将源码、CPU合同、原生对象、最终候选链接、loader/完整ABI及实机分层。正常busy join、P0-4和RM busy→STANDBY三项FAIL不得混入绿色总数。给出下一项能推进真实调用链的最小修改，不制造“源码到顶/只能上机”的结论。只读审查，不运行设备，不发送Issue/PR。
