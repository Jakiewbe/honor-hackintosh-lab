# 提供者独立审计修复：必要证据门禁与外部运行身份

目标：落实已确认的P1/P2，不重新解释为驱动适配失败，也不把464/8名称证据扩大为ABI验收。固定审计基线main `f191682e8edbe49918622312a3d8f69769674652`；历史采集源码 `1a481ba2d5a57ada56648eb7a1ae25868fc90861`、run39130439405、artifact12138280225及其ZIP SHA256均保持原始身份。

## 实现与可证伪条件

P1：采集完成与必要证据成功分开。kernel nm必须PARSED且非空，kernel symbolsets必须PLIST_DECODED，两份指定family allowlist必须PARSED且非空；缺失、重复或失败均写入required_evidence_gate并退出2。保留部分report和原始观察；workflow的always()文本保存不变。独立family可执行文件缺失仍是未知，因为runner把它们放在KC中，不能把该缺失当必须失败。

原生负控在独立Python进程中运行真实collect()/run_collection()，只注入kernel nm返回失败，要求子进程exit2、report保留、kernel无匹配及门禁FAILED。负控外层通过只表示“真实拒绝符合预期”；不是一次成功的内核观察。没有改动或执行驱动。

P2：analyse()与CLI必需外部给定run ID、采集源码SHA、artifact ID、ZIP SHA256；不从待验目录生成预期值。核对下载器local-artifact-binding.json及其成员摘要，再核对report.source_commit；新报告另核对source_run_id。历史报告未携带run ID时明确依赖已校验下载绑定，不伪造原生字段。ZIP摘要在下载时验证；离线工具只核对下载见证，不声称从不存在的ZIP重新计算，也不能独立认证伪造的本地见证。

测试涵盖每类必要观察失败、缺失/重复/空表、报告保存、异常保留、单独family可执行文件缺失的允许情况，以及另一套内部一致但不同run/commit/artifact的拒绝。改动仅诊断工具、测试、工作流和文档；回退这些文本即可。

## 当前真实证据

- Windows：采集器13/13、复算器11/11；原三组回归10/10、5/5、7/7。
- 对固定历史原始文本使用外部身份重新复算：464项runner KPI精确条目及真实目标全局，8项仅family名单，14别名目标，23424全局。结果与独立审计一致。
- Darwin：本修复尚未执行；待此源码提交后运行只读provider workflow，包括真实失败注入。不以本地测试代替原生证据。

## 下一主线与限制

原生门禁通过后推进G1-KC-8：两家族KC真实成员/UUID/符号表，区分6函数与2数据；观察不到精确符号时记KC_BINARY_SYMBOL_NOT_OBSERVABLE；再做SDK15.5下6方法的返回宽度/参数/扩展属性/调用约定与真实候选调用侧比较。普通C++ mangled名称不携带返回类型，不能只看名字通过ABI。无需重跑1280TU。

本修复不改变驱动行为；完整ABI、版本兼容、用户最终系统、PM/关闭集成未验收。GPU初始化、真实渲染、像素读回与安全结束未执行，设备NO-GO。不写.agent、不改固定upstream、不操作设备。
