> **后续结果：** NVLink四个内部导入已由真实Darwin信号量候选消除，见[run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329)与[NVLink报告](NVLINK-DARWIN-LOCKS-20261018.md)。剩余472个目标导出/ABI未知，设备NO-GO。下文475/四缺口是前次run的历史实测。

# 完整 NVIDIA 核心源码构建（2026-10-18）

实际状态：完整官方输入已经在 Darwin 编译并链接出 NVRM 重建候选；还剩四个已知内部导入，闭包和完整 ABI 未验收。RTX 2050 驱动适配尚未完成，没有设备初始化、GPU 渲染或像素读回证据。

## 本次真实原生结果

源码提交 `30485ae65d580eb63b4b60a78c50390fad50c757`；[run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) / job `117642983660` 实际结论 success。macos-15-intel、Xcode_16.4；artifact `12131884817` 为纯文本，下载 ZIP SHA256 `34f58929daf9bedb854a021dd10fb60e474af729f42f4e19e76f238de3673f4e` 已本地核验。

| 层级 | 实际结果 | 限制 |
|---|---|---|
| 官方源码与生成 ID | RM 1055/1055、modeset 225/225 编译成功，失败0 | 固定公开源码和已标注的重建参数，不是上游发布物复现 |
| shader 对象 | 5/5 成功；最终 nm 可见全部15个 start/end/size 名称 | 原始载荷身份按固定输入记录，不宣称由本工程编译生成GPU指令 |
| 完整归档 | RM 1055、modeset 230 个本轮输入对象 | 二进制仅在 runner，不上传 |
| NVRM 候选链接格式 | exit0，x86_64 MH_KEXT_BUNDLE；SHA256 `f2ae48aed1ad2690bf6c97ff23054e48de3cdf7e3bb721059248d8f83c813dde` | Darwin kext 链接允许保留导入，不能用exit0验收闭包 |
| 先前九项 UNKNOWN | 最终 nm 均观察到定义，包括 pNV_KMS_ID 与 NVOC 数据/函数 | 导出存在不等于函数行为或调用ABI正确 |
| 选定布局 | 六个旧probe/unified profile为 SELECTED_LAYOUT_MATCH，未观察到 altstack/NULL 冲突 | 尚未用完整官方逐TU参数重复观测，不是完整ABI验收 |
| 依赖闭包 | **未通过**：475个剩余导入，其中4个已知内部缺口 | 其余471个目标内核/家族导出与ABI仍未知，不能全叫KPI |
| 初始化/渲染/读回/安全结束 | **未执行** | 设备加载与运行仍 NO-GO |

实际 why_load 观察到 RM 954、modeset 188 个不同归档成员。此为当前 ac55984 根集合与本轮参数的事实，不要求与旧 v1.15.0 的 954/189 相等，也不以计数相近推断复现成功。

本地复核了1,278个固定源文件、两个生成ID源和五个固定shader源的哈希，1,285条对象记录均成功、具有哈希且路径唯一；复核九个导出和15个shader精确名称。结构化摘要及原始导入见 [native-result.json](full-source-evidence/native-result.json)、[full-nvrm-undefined.txt](full-source-evidence/full-nvrm-undefined.txt)。完整逐TU命令/源对象哈希/日志保存在该run的文本artifact及本地 `evidence/ci-full-39116405484/`；GitHub artifact保留14天，摘要和关键文本永久随仓库保存。

完整归档使用固定 OGKM 原始源码；原生门禁其他步骤的局部 KAPI 探针修复不自动代表已集成进该完整归档。上游已有弱桩和关闭安全问题仍需单独验收。

## 下一项已定位的真实缺口

`_nvlink_allocLock`、`_nvlink_freeLock`、`_nvlink_acquireLock`、`_nvlink_releaseLock` 仍在最终导入表。why_load 确认 `_nvlink_lib_link_locks_acquire` 拉入了 `nvlink_lock.c` 对象；其第41–44行在 NV_LINUX 下启用 top-level locking。四函数在固定 Linux OS 层 `kernel-open/nvidia/nvlink_linux.c:564–598` 有基于计数1 semaphore的实现，当前固定 NullMoth 无四个提供者。

下一工作必须设计真实 Darwin 锁后端，并核对阻塞/唤醒、失败、跨线程signal和释放生命周期语义；不能加空桩、删 nvlink_lock.c、随意取消 NV_LINUX 或把非递归 owner mutex 当作 semaphore 直接替换。并行的验收缺口是用本轮完整官方逐TU参数采集ABI，以及逐项绑定其余471个目标系统导出。未解决前闭包不放行。

## 已确认的原生失败

基线 main `b070bdef7cd7bcb5ba708d3630aff1996530e2f6` 已实际触发 [run 39115546785](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39115546785)，job `117640493628` 失败在工具测试，驱动编译及之后的步骤全部跳过。测试预期 `/var/folders/.../source.cpp`，正确生成的 wrapper 使用规范化后的 `/private/var/folders/.../source.cpp`。只把测试断言改为 `source.resolve().as_posix()`，保留生产代码路径规范化与测试本身。

## 本轮实质改动

- `tools/g1_full_build.py` 按固定 OGKM `srcs.mk` 纳入 RM 1,054 个、modeset 224 个源文件及两个生成 ID：共 1,280 个 C 编译单元。五个着色器载荷另生成对象。不存在目录抽样、100项上限或失败项裁剪。
- 通过原版 `gmake -n -B` 展开每 TU 专有 flags/include/条件。关闭依赖文件生成以便命令直接按 argv 执行，不运行 dryrun 中的链接器、objcopy 或安装配方。官方编译器能力探测仍会在 make 展开时执行；仅作编译探测，不接触设备。
- 保留 `NV_UNIX/NV_LINUX` 重建候选配置，追加现有 Darwin kernel SDK 参数；不宣称此组合已通过完整 ABI 核验，不宣称复现 NullMoth 发布物。
- 只执行已审阅的公开 `GENERATE_NVIDSTRING` 片段，固定候选身份 `HONOR-G1-REBUILD-CANDIDATE`、g1@ci 和日期。五个固定原始 shader 按 XZ check-none/preset6 extreme 压缩，解压字节必须与原始输入一致，Mach-O 只读段导出真正 start/end/size 符号。
- 每项记录源哈希、官方命令、候选命令、退出码和有效 x86_64 MH_OBJECT 哈希。任何 TU 失败时，不生成归档、不进入链接。全部成功才生成两个完整归档，使用本轮显式 NVRM 对象尝试链接并保存 why_load 和全部导入/导出。
- 明确替换 `nvkms_shaders.cpp` 对象：该 TU 已嵌入相同五组 start/end 标签，新链接以五个固定 OGKM payload 对象替代，不能同时放入两套定义。其余八个 NVRM C++ 和两个本地 C 对象保留且逐项校验本轮源/对象哈希；替换原因写进链接报告。
- 旧 every-fifth-source `rm_sample` 由完整官方源码构建替代，不把未运行的旧统计填为 0。其余原生回归和现有闭包诊断保留。
- 现有 workflow 增加完整构建步骤，45分钟上限、2线程；即使前面的选定 ABI 诊断失败，只要原生前置步骤完成，仍尝试完整构建。完整输出只有文本白名单能上传，shader/对象/归档/kext 留在 runner。

## 本地验证与证据边界

Windows 本地：56项工具合同通过，历史 WP1 10/10、FBClaim 5/5、B2 7/7。校验17个工作流仍仅 `workflow_dispatch`。清单严格核验固定 clean OGKM；历史原生 RM 日志的 1,055 条编译命令全部对应官方源集合（仅历史解析 fixture 去掉旧 AUTO_DEPEND shell 尾巴，本次真实 make 显式 `NV_AUTO_DEPEND=0`）。证据见 [local-validation.json](full-source-evidence/local-validation.json)。

新增合同覆盖：缺漏/重复/未知 make 清单、不同目录同名文件、逐 TU flags 保留、缺漏/多余/重复命令、壳操作符、失败或缺哈希禁止归档、对象/源哈希及路径绑定、shader 精确符号/字节保存、错误 Mach-O 类型。合成对象头只用于失败反例，不是原生驱动证据。

以上为提交前的本地验证。提交后已按开头的新run取得完整对象/归档/候选链接证据；内核导出、完整跨平台ABI和运行证据仍未验收，依赖闭包为 NOT_ACCEPTED，KEXT-LOAD / GPU-RUNTIME 均 NO-GO。

## 下一断点与回退

本轮完整源码编译和候选链接已经执行，下一断点是上述四个NVLink锁导入、完整参数下的ABI和目标导出核验，不重复相同抽样统计。新候选若失败则保留失败输入，不去掉必要功能或错误检查，不用空实现/旧对象/伪造导出来变绿。

本轮仅修改构建工具、合同、工作流和文档，不改固定上游源码、不动 .agent、无分支/worktree、无签名/安装/加载或设备操作。回退使用后续受控提交撤销本轮相关改动，不改写公共历史。
