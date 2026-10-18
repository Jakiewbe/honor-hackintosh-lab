# 网页端只读独立审查 prompt

请审查 Jakiewbe/honor-hackintosh-lab 本次“审计Harness增量并补PCI真实调用侧”的提交。先从main提交历史找到包含HARNESS-AUDIT-20261018.md及g1-kc8-callers.yml的提交，固定完整SHA再审查；若随后有结果提交，分别固定源码SHA与证据SHA。只读，不执行Actions、不发上游消息、不改设备。

读取 research/gpu-safety-r5/HARNESS-AUDIT-20261018.md、harness-audit-evidence/、ACCEPTANCE-MATRIX-20261018.md；对照旧head2f7b2b880d2ce6568caf8b77f3a35827c5fe0cf5、run39138580661和已验收run39127772586。检查：135/988失败仍exit0是否真实、退休入口能否重新产生假绿；Mach-O解析器是否正确使用ncmds且有界，原发布物472/交集471是否仍成立；PM busy仍STANDBY是否以明确FAIL登记而未冒称已修；九实际TU是否复用有序历史参数/源码/依赖，write8是否来自真实对象导入和直接调用而非伪声明；SDK call形状是否被误称完整provider/loader/运行ABI。

核对 tools/macho_imports.py、tools/test_macho_imports.py、tools/g1_kc8_callers.py、tools/test_g1_kc8_callers.py、scripts/gpu-safety-r5/native_compile.py、tools/check-pm-exclusion.py及两个相关workflow。区分新缺陷与已登记开放项，给出文件行号、触发条件、后果、修复建议，按P0/P1/P2分级。最后列出实际驱动里程碑：完整候选编译/链接≠加载≠GPU初始化≠渲染≠正确像素≠安全结束；未知保持未知。
