# 网页端只读独立审查：R32真实关闭路径

只读审查 github.com/Jakiewbe/honor-hackintosh-lab。定位包含 nullmoth-r32-close-retry.patch 的源码提交，固定完整SHA；后续CI证据提交另行固定。不要修改/提交、触发Actions、发送上游消息或操作设备。

先读 R32-CLOSE-RETRY-20261019.md、ACCEPTANCE-MATRIX-20261018.md、R31-NATIVE-AND-CLOSE-CONTRACT-20261019.md。对照R31失败证据与R32补丁，核对：

1. 真实kms_close_common是否在nvKmsClose成功后，以NULL data转交唯一队列所有者；所有失败路径是否可追踪；重复调用的有效指针前提是否明确。不要把只计数的CPU free当真实内存回收。
2. 实际try_free是否在eventBusy时立即保留而不等；thread_call_cancel/free的XNU语义、closing阻止重入、callback最后一次popen访问能否支持wrapper寿命；上层KAPI Device寿命是否仍有缺口。
3. 独立ONCE worker是否确实预分配、100ms重试、保留未完成节点、不重复backend close；新节点是否重置deadline造成饥饿；suspend pending/commit/abort、resume LOST、旧已排队worker是否正确拒绝；RM gate重开之前是否可能抢KMS lock进入RM。
4. deferredCounted是否只递减所属backend拒绝计数；全局差值计数合同仍有什么风险。容量64溢出与open rollback漏队列是已登记OPEN，不应误称本轮已修。
5. 13场景是否来自真实11函数、实际声明/ops/queue；编译失败无二进制不运行、三个语义变异均非零失败是否真实；检查注入边界和未覆盖实际XNU并发。四项源码结构检查不能当执行证据。
6. 若有新CI，核对run的源码SHA、31个NullMoth补丁加OGKM适配、完整序列反向恢复、10 NVRM C++ TU、官方1280 C/C++ TU（1240C/40C++）+5shader与NVLink、真实链接、472导入；CPU合同必须绑定本次原生依赖快照。没有run不得报告Darwin通过。136布局/20形状不是完整ABI。

按P0/P1/P2给固定文件行号、触发条件、后果、建议、证据局限。RM busy→STANDBY保持FAIL，P0-4/Device生命周期/容量耗尽仍OPEN。按源码→CPU→Darwin对象→候选链接→完整ABI/loader→初始化→真实GPU执行→像素→安全结束分层；设备仍NO-GO，Intel基础显示保持。不要重复“公开源码到顶”或要求设备部署来替代可继续的源码工作。
