# HONOR G1｜门禁修复与KC八符号独立复核

请对 https://github.com/Jakiewbe/honor-hackintosh-lab 做只读独立审查，先固定当前main SHA；不要修改仓库、触发Actions、上传二进制或操作设备。报告中文，分别写已证事实、缺陷、未知与下一最小动作；不要只复述作者计数。

1. 先读research/gpu-safety-r5/PROVIDER-GATE-FIX-20261018.md及KC8-20261018.md。P1/P2修复源码ab772c6842b34947aacec3f4edd49730eff076a5，原生run39133232412。KC最终源码4c36e828edc62bec765e89e149b475d11799c7c5，run39134085153。核对API source SHA、job步骤与artifact身份，纯文本ZIP摘要分别dba65036eecbc4f6279669da903d67bffe79934770678ba648a1e436eba90c38（artifact12138563353）和7d569be4fda4145a2eb45457189a75dddb05857f1802bdaa748c4128ea9bd0a8（artifact12138578202）。
2. P1：检查tools/g1_target_providers.py及g1_provider_negative_control.py。kernel nm、symbolsets、两份必需family名单任何失败是否必退出非零，并保留报告/always()文本产物？真正的原生负控是否真实collect子进程exit2，而非旧二进制或单纯模型？缺独立family binary不应误判必失败，因为它在KC中。
3. P2：检查tools/g1_provider_evidence.py是否必须由调用方传外部run/commit/artifact ID/ZIP摘要，验证下载绑定及成员，再核对原生source身份。核查真实跨运行替换反例及单元负例。离线只核对下载见证，不存在原ZIP时不能声称重新hash ZIP；无法独立认证恶意伪造的本地见证，这一边界是否诚实。
4. 检查tools/g1_kc8.py的thin x86_64 fileset、成员绝对offset、__LINKEDIT/symtab/strings、N_EXT|N_SECT、N_PEXT/STAB、节ordinal与VM/file映射边界。逐项核对6函数与2数据定义、成员UUID和实际kmutil输出，不能以.exports或同名未定义引用冒充定义。8项声称应为runner实际外部节定义，不能自动变成loader导出或完整ABI验收。
5. 从kc8-evidence/native原始10个文本文件、manifest与绑定复算交叉检查；检查kmutil三个显示flag必须独立查询。load-address视图没有数值应记NOT_OBSERVED；fileset vmaddr不等于实时ASLR加载地址。KC原始字节没有上传，二进制hash/原始nlist/节解析由原生采集器见证；网页复核仅能验证文本/代码/元数据，不能伪称独立重算KC全文件。尝试推翻58/58检查的意义，而非只比较该数字。
6. tools/g1_kc8_sdk.py真实SDK15.5编译的6方法IR，与kc8-caller-selection.json（绑定历史run39127772586、原IR SHA256 b829f38ea146c03cdc6d10f413f1b7e837df9e89752e3987348ec765515138e3、artifact12136159692）比较返回宽度、zeroext/signext、参数/调用约定。该历史IR来自完整原TU诊断，不是最终二进制反汇编。应为5项匹配，write8历史调用未知；两个metaClass是数据。检查是否错称6/6或完整C++ABI。必要时独立取得原artifact的IR核对155条摘录，别只信摘录自己声明的hash。
7. 读取主线现状并给出具体下一步：定位write8所属真实TU/对象，只做对应单TU调用诊断；补family loader导出/版本合同/提供侧ABI，随后回到PM/关闭集成。不要建议重复1280TU或八项首次KC取证；没有必要转向设备加载。

已知真实运行：provider Darwin13+11；KC工具Windows/Darwin7项；原三组回归10+5+7。首次KC run39133800833只有组合显示选项的fileset视图，最终run才补足独立UUID视图；保留失败/不足历史。目标是RTX2050正确初始化→GPU渲染→正确像素→错误传播→安全结束，Intel基础显示所有权保留。当前没有GPU执行证据，完整ABI/用户最终系统/PM关闭集成未验收，设备NO-GO。

请将新发现按严重性列出精确固定源码链接、触发条件、证据和最小修正；没有缺陷也须列清未验收项。别为编号而制造新轮次。
