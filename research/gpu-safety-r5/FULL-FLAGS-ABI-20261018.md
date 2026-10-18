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

## 当前结果

方案已建立。新增工具、原生诊断尚未执行；完整ABI、目标导出、初始化/渲染/像素读回和安全关闭运行均未验收。
