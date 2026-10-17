# 最新交付：GPU 源码候选 R3（2026-10-17）

[完整报告](reports/DELIVERY-R3.zh-CN.md) · [验证证据](evidence/r3/verification.json) · [网页独立审查 WEB004](WEB-REVIEW-004.md)。

修复 OGKM 首次分配失败的 FreeDevice(NULL) 崩溃；主机完整 KAPI 原版/候选编译通过，实际释放函数三项候选测试通过。纠正 R2 thread_call_free 解释，未宣称安全关闭已解决。原生十对象门禁已准备、未运行；Kext 链接 BLOCKED，实机加载/渲染 NO-GO。PM busy 后仍 standby 阻塞 pre-quiesce 合同。

手动 Actions：HONOR GPU safety R3 native object gate，首次 Xcode_16.4；不自动触发。NullMoth 源码顺序 R1→R2→R3注释，OGKM 单独应用 R3 NULL 补丁。重建 profile 不解释 Makefile 条件块，不代表上游实际配置或发布物复现。

## 已发布与协作方式（2026-10-17）

用户要求以后由本地 Codex 将网页端所需材料发布到实验仓库，给出具体 GitHub 链接与可复制 prompt，不要求上传附件。此次已按新授权提交到 main：47b344033e15bf7cb4d07d1e598e6cf5e039b65e，共59个文本文件；.agent树哈希不变、未使用旧检出、未触发Actions。前面的历史报告未提交/未推送声明对应当时生成状态。

[网页端任务 WEB-REVIEW-003](https://github.com/Jakiewbe/honor-hackintosh-lab/blob/47b344033e15bf7cb4d07d1e598e6cf5e039b65e/research/gpu-safety-20261017/WEB-REVIEW-003.md)。本次发布不授权设备部署、Actions运行或网页端自动写仓库。

# 最新交付：GPU 源码候选 R2（2026-10-17）

[本轮文本审阅包](honor-gpu-safety-r2-review.zip) · [原生门禁导入说明](reports/R2-NATIVE-IMPORT.zh-CN.md)

[本轮报告](reports/DELIVERY-R2.zh-CN.md) · [R2 源码增量](patches/gpu-safety-r2-kms-open.patch) · [完整应用/回滚证据](evidence/r2/verification.json) · [实际函数故障注入日志](evidence/r2/r2-results.txt) · [R2 原生门禁](ci-export-r2/.github/workflows/gpu-safety-r2-native.yml)。

修正 NVKMS worker 分配失败、无 Device bridge 事件轮询、call-free 失败后的 wrapper 释放分支。源码有效顺序 R1→R2，完整应用/双向回退通过；真实函数注入测试 13/13（不是平台并发或 GPU 验证）。原生八对象门禁未运行，链接 BLOCKED，运行 NO-GO。PM/close 自等待/在途调用/void Device teardown 合同仍阻塞。文档导出用 project-status-r2.patch 替代 R1 文档 patch，不叠加。

以下保留 R1 交付入口，历史材料不修改。

# HONOR GPU 主线：2026-10-17 源码候选 R1

已交付最小源码补丁、完整源码应用/回滚验证、真实 CPU 复制测试和待手动运行的原生对象门禁。**新 Darwin 编译未运行，Kext 链接 BLOCKED，实机加载/GPU/内屏加速仍 NO-GO。**

- [完整交付报告](reports/DELIVERY-R1.zh-CN.md)：改动、测试、阻塞、回退及下一源码文件。
- [有效源码补丁](patches/gpu-safety-r1.patch)：仅用于固定 v2.3.3/ac55984，不叠加缺失的旧 BRIDGE 补丁。
- [应用与反向恢复证据](evidence/patch-application.json)、[真实 CPU 测试日志](evidence/host-copy/results.txt)。
- [三版本源码/发行物身份](evidence/release-audit/release-source-identity-report.zh-CN.md)。
- [无头 Device owner 设计](reports/headless-device-owner.md)：尚未实施，下一先审修 os-nvkms-xnu.cpp:kms_close_common。
- [待手动导入的原生工作流](ci-export/.github/workflows/gpu-safety-r1-native.yml)及同目录导出资产。
- [来源/对象/符号/许可清单](evidence/verification.json)和 [最终一致性检查](evidence/final-consistency.json)。
- lab-overlay/knowledge 与 patches/project-status-r1.patch：待审阅状态文档，未应用。

完整实验仓库只读快照 bb523a58757c9a4d1721f8f1f1cc98b89dc9bdbc；源树输入见 evidence/source-lock.json。当前 GPU 优先、外设暂缓来自本轮用户指令。没有提交、推送、建分支/worktree、触发 Actions、改 .agent 或设备操作。

文本审阅包：[honor-gpu-safety-r1-review.zip](honor-gpu-safety-r1-review.zip)。包内 ci-export 保持仓库导入布局，research/gpu-safety-20261017 包含本轮研究记录。包不包含驱动二进制、固件、host ELF 或完整上游镜像。
