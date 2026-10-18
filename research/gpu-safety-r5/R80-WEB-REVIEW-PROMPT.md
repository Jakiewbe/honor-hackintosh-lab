# 可交网页端的只读复核任务

请独立审计公开仓库 https://github.com/Jakiewbe/honor-hackintosh-lab 的 R80 符号身份与来源取证。先记录实际读取的完整 commit SHA，确认包含 `R80-SYMBOL-IDENTITY-AND-SOURCES-20261018.md`，不要将 main 的后续更改混入本轮结果。

目标是 RTX2050 `10DE:25A9` 完整构建→初始化→真实GPU离屏渲染→像素读回→错误传播→安全结束；Intel46A6显示所有权不变。本次仅源码只读复核，不触发Actions、不改仓库、不部署设备。

重点检查 `tools/g1_symbol_identity.py`、`classify-imports.py`、`g1_special_symbol_sources.py`、`g1_special_object_providers.py` 及测试、`rm-special-undefined.txt`、`rm-special-sources.json` 和原生工作流：

1. Mach-O `___nvoc_dynamicCast` 是否精确转换为 C `__nvoc_dynamicCast`，并保留C++ mangling；nm定义/未定义命令是否正确，失败/截断日志能否被误读为成功。
2. 固定 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` 的九项来源，特别是 tentative data、`GUID_CONST`、`GENERATE_NVIDSTRING`；区分声明、宏、生成配方和真正对象导出，不凭首个文本命中定性。
3. 对象观测是否只来自本轮显式清单，是否校验源码/对象哈希、Mach-O架构、精确导出名，缺失和失败是否保持可见。
4. 有没有把47项工具测试、R79的337/346词法候选、旧run39102081484或任何report-only绿色状态冒充新原生/完整闭包/运行验收。

只报告能引用固定文件及行号的实际缺陷，按严重性排序，说明触发条件、影响和最小修正。未亲自执行的测试明确写“未执行”。不推断闭源，不生成驱动空实现，不宣称设备可加载。输出审计结论、可复现反例、剩余证据缺口。
