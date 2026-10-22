最新补充（2026-10-22）：先读AUDIT-PROMPT-20261022.md和AUDIT-RESULT-20261022.md。
审计7fa7fdc的离线链问题已整改；原生合同run39752747199 / ea9c688e216f753ec030f3db2f7ba99d54c9cdc1
已验收：Python3.9.25/Bash3.2.57，合同16/16、回归128/128无跳过（两组有重叠），144源码blob SHA一致。
先运行python research/stock-v243-audit-20261021/verify_offline_evidence.py与verify_device_text.py复算归档文本。
第一轮run39749482514的路径断言失败保留；导出探针run39749607753正反控通过，但运行时解析仍未知。
不得重复无新增信息的合同CI，也不要用此前原生整包run替代目标机完整离线构建。
菜单和直接入口共用offline_build.py；必须提供外部已审完整G1_EXPECTED_COMMIT，
不能自动把当前HEAD当期望值。所有14项通过才可进入编译；新建run目录，不删除旧数据，不联网兜底。
当前工具合同已关闭；下一断点是目标机CLT完整离线编译链的独立验收。先只做preflight，失败即停；
本轮没有执行设备构建，不要求立即跑30分钟。不得把合同成功或旧整包证据写成目标机驱动构建成功。
安装/rollback入口已禁用；不得重新加入sudo/KC/NVRAM命令或原Recovery稿。
-nvrmnogo不是硬件只读保证。27项导出结论仅限所查静态形式，不能认定运行时一定不可用。
继续保留下面主目标与安全限制；最新阶段按本补充和实际CI产物判断。

继续HONOR GLO-FX6P / RTX2050 10DE:25A9首次真实离屏计算与渲染主线，全程中文。
先读README顶部及research/stock-v243-audit-20261021/REVIEW.md、local-only-binding.json、
enum-native-binding.json，再读最新同SHA原生门禁的文本产物；不要按旧DEVICE-RUNBOOK执行。

固定NullMoth272ccd9、OGKM e4a5faa、Xcode16.4/SDK15.5/x86_64，既有ONCE/PM候选保持分开。
最新已验收run39609383942 / da20a569b622a71b26ae91675c70e3899bbf0b3a，实际workflow_dispatch，全部success。
三组件导入478/478/884，NVAccel27个local-only名称绑定78条nlist，部分多地址，外部导出未知。
原20项加7项曾被错误用vtable观察替代提供者分类；NVAccel字节SHA和884导入未变，不是新增二进制退步。
历史120hits不是单个类完整vtable。新逐类观察已绑定KC SHA和成员UUID；七个enum方法在各自类
候选槽位Surface322-325、GLContext2 366、DisplayPipe308、DisplayMachine286，与真实导入配对。
原始字数328/374/319/299只是在保守具名边界内的观察量，不是完整ABI或完整指针链解码。
先运行python research/stock-v243-audit-20261021/verify_native_evidence.py复算归档文本，再继续。

本轮门禁验收已完成：生产路径负控、确切三候选路径及可执行/plist哈希、完整声明依赖检查、
实际坏bundle的缺executable/缺依赖拒收及同run四类观察都有真实结果，不再重复整包编译。
三个kextutil诊断exit0，但它也接受两个坏bundle，始终只能信息性使用。
IOGraphicsFamily版本未知；PM保护合同8/8、基线2/8及原生唯一对象替换重链通过，不是安全睡眠验收。
不能通过删virtual、伪造导出、复制判定逻辑测试自身、
PASS前缀放宽或把kextutil能力不足改写成验证成功来刷绿。
kextutil只能作为信息性诊断，认证和排他依赖绑定始终未证；缺家族版本不能填0。

设备通路未就绪时，可对27项导出或七方法对应ABI缺口做有明确可证伪点的定向取证。
优先查找加载器实际消费的导出/链接元数据，先固定输入、解析合同、反例和最小只读验证；
无输入或不能证明其含义就保留UNKNOWN，不按局部nlist或槽位命中发明外部导出证明。
复用已存在KC文本和完整链接，不重复盲编1280TU，不合入旧R43整链。
stop准入/全部使用者与回调排空、PM、GPU在途工作退出、用户态Metal/NVK/GSP配对和恢复能力
均仍阻塞。没有足够静态证据时如实保留未知，不能宣称只差加载或源码全部安全。

A只读环境脚本已准备但未在设备执行；B/C暂停。任何加载可自动匹配并初始化GPU，
睡眠/唤醒不是首次初始化的默认前置项；清staging和复制KC不是完整恢复证明。
无设备通路就交付可审查的方案及明确缺少的证据，不假装实机验收或要求用户改主力系统。

允许相关已验证文本代码/证据受控main快进提交及compile/link/read-only手动Actions。
所有工作流只workflow_dispatch，不加push/schedule；不建分支/worktree、不强推、
不上传驱动/固件二进制、不改.agent/旧检出/取证缓存，不装软件，不联系上游。
不得签名、安装、加载、卸载、运行驱动或GPU程序，不写KC，不改Windows/磁盘/EFI/BIOS/SIP/NVRAM。
当前里程碑PRE-DEVICE STATIC INTEGRATION—CONDITIONAL PASS；设备NO-GO。
每步更新真实证据、层级和断点；本轮编译/链接或检查器通过不等于真实GPU执行。
