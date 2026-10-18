# 网页端只读审查：完整构建参数下的 RM/NVRM ABI

项目：Jakiewbe/honor-hackintosh-lab；开始时固定并报告当前 main SHA。全程简体中文。只读审查，不推送、不触发 Actions、不向上游发送信息，不安装/签名/加载/运行驱动，不上传二进制。

先读 research/gpu-safety-r5/FULL-FLAGS-ABI-20261018.md，再读 tools/g1_full_abi.py、tools/g1_rm_abi.py、tools/g1_full_build.py、tools/test_g1_full_abi.py 和 .github/workflows/gpu-safety-r5-native.yml。本轮新增工具检查三份真实RM逐TU参数与三个已链接NVRM C++ TU；没有改变生产驱动参数或链接输入。

请独立核对：1）report、compile cwd、官方argv转换、compile log、源码/对象hash和最终链接输入是否确实属于同run，能否误用旧probe；2）LLVM解析是否保留返回/参数宽度、扩展属性和调用约定，未知语法是否拒绝，是否把优化属性错当ABI；3）wrapper是否只包含完整原TU并追加真实typeof引用/布局表，20个提供侧是否真实define；4）altstack实际宏、NULL实参扫描与真实函数IR证据是否足够支撑限定结论；5）失败、缺profile、篡改和编译负面证据有无假通过空间。

原生run尚未执行时明确写“未执行”，不可用旧run或本地parser测试代替。新run出现后逐项复核full-flags-abi/full-abi-report.json、source-inputs.json、.ll、macros与full-source/report.json。即使MATCH也仅为选定合同：opaque ptr指向类型、callback深层签名、嵌套/未列字段、原子与volatile内存序、对象生命周期及目标系统导出均未验收。472个导入不是472个缺失实现。CPU/对象/候选kext链接与设备初始化、GPU渲染、正确像素读回、安全结束分层报告。

输出可复现问题：严重程度、固定提交的文件/行、触发条件、真实证据、最小修复建议；没有证据的疑点标“未验证”。不把加载NO-GO改为GO。

本轮实际证据：固定源码 `0308ed4f93cba2bfa7ddccf6c1dc0bf08f3e63b2`，[run 39122635883](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39122635883) success。full-abi-evidence/native-result.json及原始ABI报告已入库；6profile、136布局值、20接口形状一致只是待你独立复核的作者结论。检查精确IR/macros行摘录与原始hash；不要据此宣称完整ABI、加载、GPU初始化或真实渲染通过。
