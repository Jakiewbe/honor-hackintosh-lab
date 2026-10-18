# 完整构建实际参数的 RM/NVRM ABI 核查（2026-10-18）

本轮目标：核查已链接 NVRM 重建候选的三个 RM TU 与三个 NVRM C++ TU 之间的选定结构布局、20个 runtime 边界函数的 LLVM ABI 形状及 altstack 条件。设备继续 NO-GO，不将选定合同扩展成完整驱动 ABI 验收。

## 小型方案

- 实验仓库输入 main `78a85f23aa6ba663bd491672940542afc5d39dbc`；固定 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`、NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393`。不修改上游取证树或.agent。
- 已有事实：[run 39118504329](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39118504329) 已完成1280 C TU、5 shader、真实NVLink信号量后端和完整候选链接；472个目标导出/ABI未验收。旧六profile布局MATCH只覆盖探针参数，不能代替完整官方逐TU参数。
- 真实路径：RM `unix_intr.c`、`osapi.c`、`dynamic-power.c`；调用侧 `NVRM.cpp`、`os-nvkms-xnu.cpp`、`os-xnu2.cpp`。头 `nv.h` 提供接口声明，`osapi.h` 的 `__use_altstack__` 分支会读sp->top并改rbp；31处NULL实参词法命中不自动等于运行可达。
- 读取同run `full-source/report.json` 的实际candidate_argv、源码/对象hash及明确compile_cwd；逐项核对官方argv经现有Darwin转换后的相等性、编译log成功和对象位置/格式/hash。C++参数来自本轮native manifest及对应真实编译log，且对象必须在最终链接输入中。拒绝旧probe回退、缺项、重复、失败、篡改对象或不明目录。
- 仅生成诊断wrapper：包含未修改完整TU，追加现有选定布局表与20个函数的真实typeof地址引用以保留LLVM声明；不把wrapper对象链接进驱动，不运行任何驱动。没有补函数或改生产宏。
- 比较选定字段的sizeof/align/offset，以及20个C符号的LLVM标量/指针ABI、扩展属性和调用约定。未知IR语法拒绝解析；忽略纯优化推导属性（如nocapture、noundef、range）。opaque ptr不证明指针所指类型/回调签名，未列结构/嵌套布局/所有权/原子语义仍开放。
- altstack同时记录实际macro与20个真实定义的LLVM内联asm，遇到启用altstack且存在NULL调用或直接切换栈寄存器不得放行。最终macro不等于header-time trace，IR观测仅针对本轮编译函数。
- 在现有手动触发workflow的完整构建后追加独立诊断步骤。只有真实编译、对象、调用侧与提供侧资料完整且选定比较一致才通过；失败按真实日志处理，不猜-D、不裁功能。
- 风险/回退：本轮改变工具、报告字段、工作流与文档，不改变驱动源码/编译flags/链接输入；可用后续普通快进提交撤销。只发布UTF-8文本，发布前逐文件验证Git blob hash，避免Windows输出编码再次损坏中文。

## 实际结果

源码提交 `0308ed4f93cba2bfa7ddccf6c1dc0bf08f3e63b2`；[run 39122635883](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39122635883) 真实 success，job `117661164012`；Xcode 16.4 / Apple clang 17 / SDK 15.5，实际工具链见证据。文本artifact `12135031774` 的ZIP SHA256 `7a54d6c84d929851423e056d6dd0751089b5dfbaa51e06833ab9e08fece94e6c` 已下载校验。ABI report SHA256 `5f703d8d6cca94feade502ada04bff8de960398fd8dfb4ba610a7de0d7315895`，完整构建report SHA256 `d7bb41dd1a1ab9a7240d14e3e0b1b58aded964a0f2f755c7c86ef67a793f2541`。

| 层级 | 实测 | 限定结论 |
|---|---|---|
| 本地工具 | 69项；WP1 10/10、FBClaim 5/5、B2 7/7 | 工具/旧回归，非驱动运行 |
| 完整原生构建 | 1280 C TU、5 shader、1个独立Darwin后端；归档1055/230；候选kext链接成功 | 重建候选 |
| 选定布局 | 六profile、136个sizeof/align/offset值一致 | 顶层选定字段 |
| 接口ABI形状 | 20个接口在六profile中相同；真实提供侧20个define | LLVM标量/opaque ptr及扩展/调用约定 |
| altstack | 六profile均未定义；20个真实定义未见直接栈寄存器内联asm；NULL词法命中31 | 本配置未观察到该组altstack/NULL冲突；非NULL有效性证明 |
| GPU初始化/渲染/像素读回 | 未执行 | 加载与设备运行NO-GO |

候选SHA256 `bbde79f1601ee7bc89bcef04f48dc45276d39f9dec9e3f8bbed456f157c1e1d3`；仍有472个目标导出/ABI未知导入，不是472个缺失实现。对象二进制不上传，本地复核的是文本ZIP摘要、固定源码hash、真实compile log、原始LLVM/macros及重算合同；对象/归档/kext字节hash由同run门禁检查并记录。新增诊断wrapper没有进入驱动链接，不改变生产源码、参数或链接输入。

## 证据与尚未验收事项

[结构化结果](full-abi-evidence/native-result.json)、[原始ABI报告](full-abi-evidence/full-flags-abi/full-abi-report.json)、[精确签名与宏行摘录](full-abi-evidence/exact-signature-macro-lines.json)。摘录标有原始IR/macros hash与行号；完整IR、宏和构建report在同run文本artifact中（14天），不能把摘录描述为完整IR。每个profile的真实编译log及诊断stderr已保存。

相等布局与LLVM签名不是完整ABI验收：opaque ptr所指类型、callback深层签名、嵌套/未列字段、C atomic与C++ volatile的内存序、对象生命周期、目标macOS内核/IO家族真实导出与私有C++ ABI仍开放。最终TU宏不是header-time trace；wrapper的include层级不同；未检测间接/外部函数中的栈操作。P0-1/P0-4、完整modeset归档与局部关闭候选的集成继续开放。

## 主线断点与复盘

已从“抽样源码能编译”推进到“完整RM/modeset重建候选可链接，真实参数下选定RM/NVRM数据接口一致”。尚无GPU正确初始化、提交执行、渲染或读回证据。下一最小动作是核对472个导入的目标提供者/ABI证据，明确可从SDK声明确认的部分与必须绑定目标内核/家族产物的部分；同时不能遗忘完整modeset关闭路径尚未集成局部保留修复。未具备目标导出证据时维持UNKNOWN，不用源码声明当运行导出。

本轮复盘：完整官方命令包含相对include，必须保留原编译cwd；需要真实typeof引用保留未调用声明，不能为取证添加猜测声明。旧probe/解析器烟测不能替代新原生结果。发布前逐项验证UTF-8 Git blob hash，.agent与无关文件保持不变。
