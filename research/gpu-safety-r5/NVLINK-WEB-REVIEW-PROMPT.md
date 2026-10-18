# 可转交网页端的独立审查 prompt

请只读审查 https://github.com/Jakiewbe/honor-hackintosh-lab 当前 main 的 NVLink Darwin 锁后端。先记录实际审查提交 SHA；不要引用不同提交的行号或把旧 run 当新证据。

目标是 RTX 2050 10DE:25A9 的完整源码驱动构建、初始化、真实离屏 GPU 渲染、正确像素读回、错误传播及安全结束。Intel 46A6 显示所有权不变。目前只在推进构建闭包，所有设备运行仍 NO-GO。

先读 `research/gpu-safety-r5/NVLINK-DARWIN-LOCKS-20261018.md`、`nvlink-inputs.json` 和知识库02/04/10最新段落，再审：

1. `research/gpu-safety-r5/darwin/nvlink_locks.cpp` 是否遵循固定 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` 的 `nvlink_os.h` 与 `kernel-open/nvidia/nvlink_linux.c` 初值1 semaphore 语义，支持跨线程 signal，没有空桩、虚构声明、删除调用或禁用 NV_LINUX。
2. 按固定 XNU `a1e26a70f38d1d7daa7b49b258e2f8538ad81650` 的 `osfmk/kern/sync_sema.c` 检查 KERN_ABORTED 重试、terminated/invalid 等错误、signal prepost、destroy reference 消费。特别判断无限 abort 重试、void 契约 panic 的风险是否如实登记，不把它称为安全运行或可恢复失败传播。
3. free 的 caller-quiescence 前提是否真实满足？本轮只关闭链接接口，不能把 semaphore_destroy 当作并发销毁协议；没有新生命周期证据就保持该风险开放。不要补恒真的 nvlink_isLockOwner。
4. 审 `tools/g1_full_build.py` 的 source→object→symbol 哈希、四个精确导出、同 run 原始/候选链接及导入集合差分；必须真正失去四个导入且最终有对应定义。新增 `_panic` 是明确候选行为，其目标系统导出/ABI仍待验收。其他新增导入应失败，不能靠宽泛的“所有剩余均为KPI”放行。
5. 审 `tools/g1_nvlink_contract.py` 和 `darwin/tests/`：使用真实生产 TU，仅系统边界模拟；互斥/阻塞/跨线程signal/分配失败/中断重试/不可恢复错误与编译失败负向控制是否有意义，是否有陈旧二进制、数据竞争、漏跑或虚假PASS。CPU测试绝不等于XNU runtime。
6. 审原生 workflow 实际新 run（有则固定 run/head/job/artifact digest），读取 nvlink-host/report.json、full-source/report.json、nvlink-compile/defined、before-nvlink-undefined、full-nvrm-defined/undefined。只读文本证据；不要运行驱动、触发Actions、推送、发上游Issue/PR或访问硬件。

输出按严重度排序的实质问题，给精确提交、路径、行号、触发条件和建议。没有运行证据就写未验证；不要把旧probe的ABI布局MATCH扩展到完整官方逐TU配置，不把链接成功当作GPU可用。最后用三句话说明：新增了哪项真实驱动能力、离真正GPU渲染还缺什么、下一项最小开发动作是什么。

本轮实际结果入口：源码 `0dcc527c1e2fa44867b55d70a2e387bcd5703be4`，[run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329)；17/17仅CPU合同，完整候选导入475→472。请独立验证，不把本句作者报告当验收。
