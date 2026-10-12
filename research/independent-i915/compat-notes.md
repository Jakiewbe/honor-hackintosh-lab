# 版本、许可证和兼容性边界

**2026-10-12；SOURCE-STATIC；DEPENDENCY_CLOSURE_BLOCKED；RUNTIME_NO_GO。**

## FreeBSD base 选择依据

固定的 drm-kmod `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4` 的 [test.yaml](https://github.com/freebsd/drm-kmod/blob/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4/.github/workflows/test.yaml) 明确列出 `main`、`release/15.0.0`、`release/14.3.0`。因此选择 **14.3.0 发布标签**作为可复核、非浮动的 base 审查输入，而非凭版本名猜测。

`release/14.3.0` → annotated tag `ab74684c4debaec81dd8a1e57116cbd47f593e04` → **commit `8c9ce319fef765890ce518cab85d3a470b669849`** → tree `source-lock.json`。API 原始选择记录见 [upstream-provenance.json](upstream-provenance.json)。[sys/sys/param.h](https://github.com/freebsd/freebsd-src/blob/8c9ce319fef765890ce518cab85d3a470b669849/sys/sys/param.h) 定义 `__FreeBSD_version 1403000`。

**已确认的是上游测试设计采用此标签，不是该固定组合实际 CI 成功。** 未读取上游相应运行日志，未运行其 workflow（其中有 install/kldload，禁止在本机执行）。更不代表 XNU ABI 相容。FreeBSD base 版本“无法定位”的旧阻塞已收窄为“候选已固定，构建/接口/ABI 未闭合”。

## 不可混用的输入

|组件|精确版本|用途与未验证事项|
|---|---|---|
|Linux|v6.1 `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`|比较参考，不替换 FreeBSD 修改后的文件|
|drm-kmod|6.1-lts `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`|主要调用证据；包含后续回移和 BSD 分支|
|FreeBSD base|release/14.3.0 `8c9ce319fef765890ce518cab85d3a470b669849`|LinuxKPI 候选；不是 XNU shim|
|XNU|`a1e26a70f38d1d7daa7b49b258e2f8538ad81650`|继承 R1.2-F；未实现当前必需接口|
|IOGraphics|`4d3fd008c80d1414c9da8f02ea67d534b47158c2`|继承发行版本；阅读 IOFramebuffer.h 做新接口契约，不重跑旧锁序检查|

本轮比较 **49 个同路径源码文件，39 个 blob 不同**，见 [source-delta.json](source-delta.json)。这只证明源内容不同，不把差异数量当 ABI 缺陷数量。例：FreeBSD `i915_pci.c` 已用 `__runtime.display.ip.ver`，有较新的平台回移；不能把 Linux v6.1 原版结构与此 port 直接混编。

## 构建配置与真实依赖

[i915/Makefile](https://github.com/freebsd/drm-kmod/blob/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4/i915/Makefile) 包含 `kconfig.mk`、`bsd.kmod.mk`、`linuxkpi_version.mk`、`compiler_flags.mk`，以及 GPLv2/BSD LinuxKPI、base common/dummy include 和 DRM include。`LINUXKPI_VERSION=60100` 是编译配置，不能替代 FreeBSD commit、完整头文件集合或 ABI 证明。

未固定 BSD 内核配置、`opt_*.h`、`*_if.h` 生成过程、XNU include 选择、SDK/工具链与 C ABI 布局。原生对象编译数为 **0**。`source-lock.json` 中 `object_target` 是按源路径限定的**待审翻译单元候选标识**，不是已经存在的 `.o`；头文件的实际消费者明确 `UNRESOLVED_HEADER_CONSUMER`。既有 Makefile 中含多代 GPU、GT、调度模块；本轮不修改或裁剪。

[include-inventory.csv](include-inventory.csv) 记录 **2216 个字面 include，2028 个在当前小型审查集合内没有 provider**。它们不是“上游缺失 1957 个文件”：其中包括未下载的系统/生成/本地头文件，以及条件分支。已有 provider 也仅为路径候选；未做预处理，不证明宏条件和 shadowing。当前绝不能宣称完整依赖闭包。

## 一个不可直接继承的电源语义

base [pm_runtime.h](https://github.com/freebsd/freebsd-src/blob/8c9ce319fef765890ce518cab85d3a470b669849/sys/compat/linuxkpi/common/include/linux/pm_runtime.h#L26) 的 `pm_runtime_get_sync()` 直接 `return 0`，其他 PM 操作多为空宏；i915 `__intel_runtime_pm_get()` 真正调用它。

这不证明 FreeBSD 驱动错误：FreeBSD 的非运行时休眠策略需要结合 host PM 管理判断。但**它不能证明 XNU 设备已被恢复、MMIO 已供电或引用会阻止休眠**。XNU 移植必须实现可审核的 always-powered 或真实 PM 协议，否则 `POWER_RUNTIME_PM=BLOCKED`。不能复制空成功返回并标记实现完成。

## DMC、GT 与 L1 的取舍仍有条件

ADLP [intel_dmc.c](https://github.com/freebsd/drm-kmod/blob/dba60e1e9465d4d6b2d4e7916174f7b915c35fb4/drivers/gpu/drm/i915/display/intel_dmc.c) 指定 `i915/adlp_dmc_ver2_16.bin`、2.16。`intel_dmc_ucode_init()` 先取得 `POWER_DOMAIN_INIT` 引用；worker 无 payload 时保留引用，并报告禁用 runtime PM，只有 payload 成功才释放该引用。**没有 DMC 不必然在源代码层立即终止所有显示**，但相应电源限制必须真实成立；本轮无 firmware bytes/hash/许可，更无硬件证明。禁止伪报加载成功。

完整 `i915_driver_probe()` 会调用 `i915_gem_init()`，后者调用 `intel_gt_init()`，再经 `intel_uc.h` 宏包装调用 ops。GT、GuC/HuC 与显示 DMC 分开；未完成预处理/可达性分析前不能直接删除 GT 或声称 GuC/HuC 必需/可省略。只允许提出待证伪的切片问题。

## 许可证台账的含义

156 条逐文件记录中，144 条观察到 SPDX 或真实许可头部，**12 条未取得本文件内许可证明**，见 [license-manifest.csv](license-manifest.csv)。其中包括 10 条说明/构建元数据、无许可头的 `intel_freebsd.c`，以及 base 的空 dummy `uapi/linux/sched/types.h`。缺头不等于证明无许可；不得猜一个 SPDX 填入。下一步需回溯完整树、作者声明及文件历史，空 dummy 也不能作为类型实现证据。

审查文件含 MIT、BSD、GPL/双许可声明、GPLv2 dma-buf 头，Apple IOFramebuffer.h 明示 APSL 1.1。台账只描述所见文本，未作组合二进制分发结论。**组合许可与 firmware 许可仍 BLOCKED**。本仓库只提交索引、hash、接口分析和本项目校验代码；第三方源码仅缓存，不打包分发。
