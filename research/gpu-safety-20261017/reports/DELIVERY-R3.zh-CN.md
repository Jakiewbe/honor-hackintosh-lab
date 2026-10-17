# GPU 源码候选 R3：KAPI 初始化失败保护与原生 C 门禁

本轮只解决一个确定的初始化失败空指针，并纠正 thread_call_free 的解释。安全关闭、Darwin 编译、Kext 链接、GPU 执行均未验收。运行 NO-GO。

## 固定输入和改动

- NullMoth v2.3.3：ac55984c473e746c2a8ebea7ba0913461aa7c393。完整候选顺序 R1 → R2 → nullmoth-r3-thread-call-comment.patch；R3 此处只改注释。
- OGKM：e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb。ogkm-r3-kapi-null-free.patch 仅在 FreeDevice 入口对 NULL 返回。AllocateDevice 首次 calloc 失败会进入该路径；此时没有 Device 可释放。
- 原始缓存只读；OGKM 修改保存在明确命名的单文件候选；NullMoth R3 完整候选独立保留。

## 实际验证

1. 原版完整 nvkms-kapi.c 和候选完整翻译单元各用真实固定头文件 GCC 编译，均 exit 0；定义/未定义符号提取均成功，未定义符号集合完全相同。对象为主机 ELF，不是 Darwin 对象，未执行/加载。证据 evidence/r3/kapi-host-compile.json 与 *-kapi-{defined,undefined}.txt。
2. 抽取真实 FreeDevice/KmsFreeDevice 函数体并注入平台释放依赖：原版 NULL 输入 UBSan 复现空指针成员访问（exit 1）；原版 populated/partial 均通过；候选 null/populated/partial 三项通过。不是硬件、真实 RM 或并发释放证明。证据 free-device-fixtures.json 与六组 *-results/exit.txt。
3. NullMoth 完整 611 文件按三补丁实际应用、与候选逐文件核对、逆序回退均通过。OGKM 完整固定树仅 git apply --check；单文件副本实际应用/回退及候选 hash 对照通过。证据 verification.json。
4. R3 workflow 仅 workflow_dispatch、contents:read、macos-15-intel，shell/Python 语法检查通过；实际 Makefile 提取器与主机编译的 27 个 include / 15 个 definition 一致。原生执行 NOT_RUN。

## 重建 profile 的限制

主机与新原生 KAPI profile 均提取固定 modeset Makefile 的字面 -I/-D，展开已知 SRC_COMMON；不解释条件块，可能过宽。NV_UNIX/NV_LINUX 等平台宏是明确的候选推断，不是上游 Darwin 实际配置或发布物复现。原版/候选始终使用相同 profile；新原生 C 编译使用 clang/gnu11，C++ 对象使用 clang++/c++17。不能用 host PASS 预测 Darwin PASS。

## 对 R2 的纠正

Apple 公开 XNU xnu-11417.140.69，对应源码 commit 43a90889846e00bfb5cf1d255cdc0a701a1e05a4：thread_call_free 在 queued / RESCHEDULE 时拒绝；运行中的 callback 不天然导致失败，并允许自身 callback 释放。它不是 callback join，不能用 TRUE 证明外部参数已静默。R2 的失败时保留 wrapper 防御逻辑保留，只修正错误注释。公开 XNU 仅源码比较依据，目标内核 Build 与 SDK ABI 未闭合。摘录见 xnu-thread-call-contract.json。

## pre-quiesce 的新增阻塞

固定 NVRM.cpp:1367 起 gpuSuspend 先进入 NVKMS suspend，再关闭 RM gate；注释记录反序会因持 gKmsLock 进入 RM 而死锁。nv_xnu_pm_close(10000) 超时仍记录 suspending anyway，并继续 rm_stop_user_channels 和 rm_power_management(STANDBY)。因此现有 RM users pin 不能证明期间 GPU 保持运行。不能只检查一次 RUNNING 再释放，不能未经证明交换锁序。

eventCallback 自释放等待、在途 ioctl、PM 等待释放 gKmsLock 期间的对象生命周期、void freeDevice 的失败传播、DMA/IOVA/GSP 静默仍未闭合；没有新增可失败安全关闭 API。独立审查见 WEB-REVIEW-004.md；WEB003 仍可并行审 R2。

## 原生门禁、回退与断点

仓库根 .github/workflows/gpu-safety-r3-native.yml：HONOR GPU safety R3 native object gate。用户手动运行，首次 xcode=Xcode_16.4。共原版/候选各四个既有 C++ 翻译单元 + 完整 KAPI C，共十对象；成功才允许报告对象编译通过。只上传文本日志，不上传对象/驱动。若错误，按实际 *-compile.txt 和 native-report.json 修复，禁止删功能/假符号绕过。

本轮源码修复的回退是撤销 OGKM R3 补丁，注释修正可单独回退；R2 workflow 保留不变。下一步读用户手动 CI 日志与 WEB004 锁序审查，继续实现前先闭合 PM/owner/关闭失败合同；链接 BLOCKED，加载/渲染/内屏加速 NO-GO。

## 本轮复盘

有效增量是原版负例复现、实际函数释放顺序回归、完整 C 对象编译和无新增依赖，而非增加 PASS 标签。审查发现 Makefile 的 -I 参数分隔与变量展开需显式处理，已用真实固定 Makefile 对照主机 profile 验证。安全关闭需要跨 PM 与生命周期合同，局部 NULL 修复不代表完成关闭。没有修改 .agent、旧检出、系统、设备或原始缓存，没有执行 Actions。
