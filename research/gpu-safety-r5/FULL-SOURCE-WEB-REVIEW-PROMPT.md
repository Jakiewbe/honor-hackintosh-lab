# 可直接转交网页端的只读审查任务

请独立审查 https://github.com/Jakiewbe/honor-hackintosh-lab 的完整 NVIDIA 核心源码构建。构建源码固定为 `30485ae65d580eb63b4b60a78c50390fad50c757`，真实原生run为 https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484 （success）。先读最新的 research/gpu-safety-r5/FULL-SOURCE-BUILD-20261018.md 和 full-source-evidence/native-result.json，再读该固定构建提交的 tools/g1_full_build.py、tools/test_g1_full_build.py、scripts/gpu-safety-r5/native_compile.py 和 .github/workflows/gpu-safety-r5-native.yml。目标是 RTX 2050 正确初始化→GPU执行→像素读回→错误传播→安全结束；本轮只到完整编译/链接，不是可用驱动。不要推送、触发工作流或操作设备。

已知结果：1280个C TU和5个shader对象全部通过，两个完整归档与NVRM候选已链接；最终仍有475导入，其中四个已知内部缺口是nvlink_allocLock/freeLock/acquireLock/releaseLock，其余471个目标导出/ABI未验收。六profile选定布局一致仅限旧probe/unified参数，不能覆盖新完整官方逐TU参数。请重点审查这两个边界是否如实保留，并根据固定 nvlink_linux.c 的计数1 semaphore合同，评估真实Darwin锁后端所需的阻塞、跨线程signal、失败与释放约束；不要直接用IOLock或空实现消掉符号。

重点核查：固定 OGKM 官方清单是否完整包含1,280个C TU及5个shader对象；make展开是否保留每TU专用参数；任何必需项失败能否偷跑部分归档/链接；有没有继承旧对象/错误哈希/错误Mach-O类型；NullMoth shader对象替换是否明确且无重复；静态归档提取是否导致必需提供者未拉入；链接成功后的未定义符号和ABI是否被错误验收。结合最新真实Actions日志列出首个实际阻塞。区分脚本潜在缺陷和已发生的失败，给出精确文件/行号/触发条件/最小修法；不要重复输出测试数量当适配进度，不要把未尝试或未穷尽的路线断言为闭源或不可行。无证据写未知。
