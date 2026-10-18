# G1 审计纠错与闭包门禁 R79（2026-10-18）

## 目标和输入
本轮承接独立验收发现，先修复证据生产链，再继续公开源码构建闭包与跨平台 ABI。基线 main 为 8a82d8851015809ec168542815b6e828e8684b77；NullMoth ac55984c473e746c2a8ebea7ba0913461aa7c393，OGKM e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb，版本未变。不修改驱动行为、.agent、设备或原始取证树。

## 明确撤回的结论
1. R74 的“剩余45符号都是闭源依赖”撤回。固定公开源码中已有 RmInitRm（src/nvidia/src/kernel/core/system.c:609）、RmPowerManagementTegra（arch/nvalloc/unix/src/power-management-tegra.c:31）、gpumgrGetGpuFromUuid（src/kernel/gpu_mgr/gpu_mgr.c:2431）。旧索引漏掉跨行返回类型，且把 return f16_to_f32(fa).v 当定义。其他未解析符号没有因此获得闭源定性。
2. R77/R78 的“351→667证明增量闭包不收敛”“必须整层构建，否则依赖闭源二进制”撤回。前者为9个NVRM对象+15探针，后者为87批对象+15探针，缺少同一组9个NVRM对象；对象集合不可直接比较。一轮边界增长也不能证明依赖闭包不收敛。
3. 12–15分钟只是一项未经完整构建验证的估算，不能当作完成时间或可构建性结论。整层构建仍可作为后续实验，与按依赖闭包扩展并不矛盾。

## 本轮实现
- 索引器用平衡参数/函数体和声明前缀识别词法定义，忽略注释、字符串、预处理指令及函数内部调用。保留条件分支的所有候选；不把 static/header 内联定义当独立可链接C对象。数据、宏及未支持语法只标 UNKNOWN。
- 固定346个符号输入保存在 rm-gap-symbols.txt。完整扫描结果由命令生成，包含全部候选定义、非注释命中和3824个源码文件的哈希。小型构建输入 rm-gap-index.json 保存所有定义位置及完整证据的规范JSON哈希；CI会重新生成全文并逐字节比较摘要。
- 新扫描：337个符号有词法定义候选，9个 UNKNOWN，88个外部C定义候选文件。这不是337个对象提供者，也不是完整依赖闭包。原45个“未解析”并未都属于同一种性质。
- 对象命名在批构建/抽样中包含完整相对源路径哈希。探针与批链接只采用本轮明确记录的成功对象，不再glob磁盘上的旧对象。build_manifest记录 source→object、源/对象哈希及编译退出码。
- 批量候选现在包含同一组9个统一配置NVRM对象+本轮探针，再加入成功批对象；记录完整导入集合的新增/消失项。缺文件、编译失败、裁剪均显式登记；闭包验收始终独立于选定对象门禁。
- gap_symbols_left 改为 selected_prefix_gap_symbols_left，仅表示 _nvKms/_rm_/_nvrm_ 三类，不能表示所有内部导入归零。
- 新增6个真实TU上下文的选定布局观察：三个RM C文件与统一配置NVRM.cpp、os-nvkms-xnu.cpp、os-xnu2.cpp。按实际成功编译ARGV生成LLVM文本，保留宏/include/目标参数，只去掉原对象和依赖文件输出动作。比对5类型、42选定字段、136数值；采集altstack宏。诊断不链接、不运行设备代码。
- 文本发布采用扩展名白名单、UTF-8/内容验证，排除.dSYM与对象。旧诊断包两份CPU dSYM的继承遗漏已复现；新发布集在旧包上过滤通过。不是驱动二进制发布事件。

## 已运行
- 索引反例8项、原生清单5项、文本发布3项、ABI工具11项，共27项通过。
- 历史回归：WP1 10/10、FBClaim 5/5、B2 7/7。
- Python语法与17个工作流YAML检查通过；所有触发仍仅workflow_dispatch。
- 对固定OGKM全树重新扫描；本地源文件CRLF计数0，排序按相对POSIX路径，避免Windows与Darwin路径排序差异。
- 新ABI源码扫描：20个runtime目标、31处NULL字面调用命中。未预处理，不表示每处都活跃。
- 上述检查及真实旧包过滤记录见 r79-evidence/validation.json 与测试文本。

## 尚未运行与验收边界
新Darwin门禁、同基线批链接、六上下文布局诊断尚未执行。布局工具自测中的合成IR仅测试解析器，不是驱动ABI证据。LLVM wrapper包含完整原TU，但include level/base file与直接编译不同；选定布局一致也不能证明完整签名、调用约定、原子语义与生命周期正确。

沿用已独立核验的run 39102081484：16对象成功、15探针成功、175抽样成功、旧批87/94；R28 CPU合同15/15，基线6个预期失败，编译失败负控无二进制且未运行。旧统一候选829个未定义符号，指定前缀为0；不能用于新批链接或完整闭包验收。

## GO/NO-GO及断点
源码/离线工具检查允许继续；完整RM/modeset构建、完整ABI、KEXT-LOAD/GPU-RUNTIME/像素读回/安全结束仍未验收。P0-1/P0-4维持BLOCKED/OPEN。设备NO-GO。

下一步：提交本轮相关文本与门禁，运行本轮head的gpu-safety-r5-native.yml。先读rm-gap-index-full.json、native-report.json、nvrm-rmbatch-link.txt、rm-abi/rm-abi-report.json及diagnostic-publication.json。编译或链接失败按首个真实诊断处理；ABI差异或缺字段保持失败，不删字段/改宏制造一致。原生门禁通过后才决定下一批闭包或整层实验的最小输入，禁止重新沿用已撤回结论。
