# 完整 NVIDIA 核心源码构建（2026-10-18）

实际状态：RTX 2050 驱动适配尚未完成。当前目标是获得完整官方输入的 Darwin 编译和链接结果；没有设备初始化、GPU 渲染或像素读回证据。

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

**新完整构建未执行；新对象和完整归档/链接均未验收。** 工作流运行后按本提交的实际日志更新本段，不继承旧 run 的成功。即使链接成功，内核导出、完整跨平台 ABI 和运行证据未验收前，依赖闭包仍为 NOT_ACCEPTED，KEXT-LOAD / GPU-RUNTIME 均 NO-GO。

## 下一断点与回退

推送后执行已授权的 compile-only Actions，按 `full-source/report.json` 和逐 TU first_errors 调整首个真实构建阻塞。失败时保留失败输入，不去掉必要功能或错误检查，不用空实现/旧对象/伪造导出来变绿。全部源码能编译后才研究完整归档链接缺口和 ABI。

本轮仅修改构建工具、合同、工作流和文档，不改固定上游源码、不动 .agent、无分支/worktree、无签名/安装/加载或设备操作。回退使用后续受控提交撤销本轮相关改动，不改写公共历史。
