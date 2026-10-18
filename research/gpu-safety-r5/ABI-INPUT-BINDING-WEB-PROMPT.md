# 网页端只读复核：ABI 编译输入与真实链接绑定

项目 https://github.com/Jakiewbe/honor-hackintosh-lab 。开始时固定并报告main SHA；全程简体中文，只读，不改仓库、不触发Actions、不操作设备、不上传二进制或发送上游消息。

先读 research/gpu-safety-r5/ABI-INPUT-BINDING-20261018.md，再读 tools/g1_compile_inputs.py、tools/g1_full_abi.py、tools/g1_full_build.py、scripts/gpu-safety-r5/native_compile.py、tools/test_g1_compile_inputs.py、tools/test_g1_full_abi.py、tools/g1_input_binding_contract.py及现有原生工作流。

本轮修上次P1（头文件漂移时旧对象仍可能通过wrapper比较）与P2（未独立核对真实链接ARGV）。独立检查：-M包含系统头；编译前扫描与实际-MD集合、内容hash、逻辑/实际路径相符；11基线/3RM的快照绑定源码/对象/命令/cwd；ABI开始前及IR/宏诊断后重核；诊断集合只能是原依赖加wrapper。头文件只改不改.cpp/.o、依赖缺项/额外项、符号链接换指向、旧快照必须失败。文件前后相等不等于防恶意改还原或捕获环境/编译器二进制，不能扩大结论。

检查真实full-nvrm-link.txt ARGV是否与实际10基线、两归档顺序、后端及输出逐参数一致；不能只比较报告。独立核对链接文本篡改负例与实际成功链接命令。

取得同run原始文本artifact，核对input-binding-host/report.json：真实clang原对象i64、改头后的wrapper/提供侧i32、源码和旧对象不变但快照校验拒绝；负向编译必须无对象、无快照且未执行。再核对input-snapshots/、full-source/input-snapshots/、full-flags-abi/及各depfile/hash。未执行时明确标未执行，不用旧run补证据。

确认完整1280 C TU+5shader+独立后端、候选链接和六profile136布局/20接口仍成立，20个RM提供者实际进入最终候选。记录C侧-fapple-kext被忽略的警告。472个导入为目标导出/ABI未验收，不是472缺实现。完整ABI、GPU初始化/渲染/读回与PM关闭仍分层；实机NO-GO。

输出固定源码文件/行、真实触发条件与证据、最小建议。区分复现问题、未验证疑点和既有限制，不以单条PASS或作者报告验收。
