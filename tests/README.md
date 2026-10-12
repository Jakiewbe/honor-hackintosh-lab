# 离线测试与可选源码缓存

在仓库根目录运行 `python -B -X utf8 -m unittest discover -s tests -v`。`-B` 避免在只读上游克隆中生成字节码。

以下4项需要 `.cache/` 中与 source-lock.json 完全匹配的上游文本源码。干净检出或缓存缺文件时，它们明确显示 `skipped`，原因列出缺文件数量、首个相对路径和“Source verification NOT RUN”；不要把跳过计入通过数量。测试不会自动下载源码。

- `DependencyGateTests.test_recorded_slice_valid_but_closure_blocked`
- `DependencyGateTests.test_cli_closure_fails_and_structure_passes`
- `PowerEvidenceGate.test_real_structure_stays_blocked`
- `PowerEvidenceGate.test_closure_exit_is_two`

预检查先核对所有已存在文件的 SHA256 与 Git blob。任何文件不匹配、路径不安全或文件读取错误仍然失败，即使其他文件缺失；不以“缺缓存”掩盖损坏内容。缓存完整时4项正常执行，实际源码 gate 继续检查其他清单/符号/接口。

本次只为上述4项正向缓存测试新增跳过条件，缺源码/损坏字节等负向测试仍执行。生产校验脚本不做跳过或降级：缺失、版本/哈希错误仍返回失败，闭包未完成仍拒绝放行。跳过不提供SOURCE-STATIC增量或硬件证据，保持RUNTIME_NO_GO。

`test_1401_static_audit.py` 沿用其既有规则：没有 `upstream/1401` 或 `upstream/nvidia-macos-driver` 克隆时，10项上游审计显示跳过；3项原始硬件材料检查仍执行。克隆存在时检查固定提交并执行上游审计，不能用跳过表示版本匹配。重建固定克隆的方法见 [upstream/README.md](../upstream/README.md)，测试本身不会联网或运行安装器。

验收分两种输入：完整缓存包括两个 i915 阶段的锁定源码及两个固定版本的上游克隆；干净检出只包含本仓库入库文件，没有 `.cache/` 或这两个克隆。两次都运行上述全部测试并分别统计通过、失败和跳过，不能把两个环境的结果混写。
