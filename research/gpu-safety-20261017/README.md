# HONOR GPU R1/R2 源码候选与网页端协作入口

2026-10-17：用户授权将本轮材料直接提交到实验仓库。只发布文本源码补丁、必要源码上下文、测试与诊断、报告、手动对象编译门禁；不改 .agent、不运行 Actions、不部署驱动。

**网页端下一项工作：[WEB-REVIEW-003：关闭协议独立审查](WEB-REVIEW-003.md)。** 直接按该文件执行，不需要上传附件。

- [R2报告](reports/DELIVERY-R2.zh-CN.md)、[R1报告](reports/DELIVERY-R1.zh-CN.md)、[无头owner设计](reports/headless-device-owner.md)。报告中的“未提交/未推送”反映当时生成状态，本次发布授权发生在其后。
- [R1补丁](patches/gpu-safety-r1.patch) → [R2补丁](patches/gpu-safety-r2-kms-open.patch)，只适用固定 ac55984；完整应用与逐层回退见 [R2验证](evidence/r2/verification.json)。
- [R2完整候选wrapper](source-context/candidate-r2/os-nvkms-xnu.cpp)、[原版wrapper](source-context/original/os-nvkms-xnu.cpp)、[跨文件关闭链](source-context/CLOSE-CALL-CHAIN.md)。
- [实际函数故障注入日志](evidence/r2/r2-results.txt)：13/13；平台依赖为单线程测试注入，**不证明原生/并发/GPU安全**。
- 原生工作流位于仓库根 .github/workflows/gpu-safety-r2-native.yml；脚本 scripts/gpu-safety-r2/native_compile.py；CI资产 research/gpu-safety-r2/ 下两份补丁。它们已按可运行的仓库布局纳入，不需要再从本机ci-export-r2复制。

**DARWIN-COMPILE 未运行；KEXT-LINK BLOCKED；KEXT-LOAD / GPU-RUNTIME / 内屏加速仍 NO-GO。** PM失败、回调自等待、在途ioctl引用和void Device teardown合同仍未闭合。下一先审freeDevice释放任何资源之前的可失败pre-quiesce，不在此时迁移唯一owner或补共享Device释放。

固定输入、许可、source→object→symbol见 [来源清单](evidence/verification.json)、[R2清单](evidence/r2/source-object-symbol.json)。必要源码上下文保留原许可声明，完整许可文本在licenses/。没有发行驱动、固件、完整上游镜像、host ELF或EFI序列号。

work/ 中主机脚本保留当时研发目录与命令以复核既有记录；跨环境重跑须先调整隔离路径，不是安装脚本。旧R1 CPU拷贝、DMA等测试不因本次发布而自动重跑或升级证据层级。
