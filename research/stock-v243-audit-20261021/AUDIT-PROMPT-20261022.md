# 离线构建链固定审计任务书（不是审计结论）

原始审计基线：`7fa7fdc9b44f035329c4d36a17d3025f34f87e7c`。后续修订必须另填实际完整提交SHA，
不能把历史run39609383942/da20a56或39617435532/d37efcd当作新提交完整离线链的验证。

核心对象：

1. `research/stock-v243-offscreen-20261021/g1-first-touch.command`
2. `research/stock-v243-offscreen-20261021/device-kextutil.sh`
3. `scripts/g1/stock_v243_kext_link.py`及其直接Python调用链
4. `tools/g1_kc_vtable_bounded.py`与`tools/g1_kc_exports.py`
5. `research/stock-v243-audit-20261021/DEVICE-BASELINE-20261022.md`
6. `research/stock-v243-offscreen-20261021/RECOVERY-FROM-INSTALLER.md`

辅助审查新增共用入口、测试、工作流及历史first-touch.sh，防止其他入口继续绕过限制。

八项待审断言（保持原审计含义，不预填通过）：

- A1：四次历史崩溃均已修复并回归。区分对应代码存在与原设备日志复现。
- A2：CLT/Python3.9路径可用，xcodebuild非必要，失败报告也能保存。
- A3：14项preflight真实、有稳定ID、执行失败不能变成PASS，所有构建入口强制经过。
- A4：重复执行不误删数据；错误WORK、别名、源目标重合与非托管目录必须拒绝。
- B5：原始设备KC哈希、工具身份及七个方法观察可复算；有界槽位不是完整ABI。
- B6：27名称的局部定义和特定导出元数据观察不等于运行时可用/不可用。
- C7：-nvrmnogo只抑制autoGo，不能声称在BAR配置之前阻止所有硬件副作用。
- C8：安装事务及独立Recovery恢复必须有设备闭环，删除候选、复制KC或清staging不足。

构建修复最低验收：

- Python3.9真实执行，Bash3.2真实入口测试，不能用新版本语法检查代替。
- 错误/缺失SHA、Git非零且空stdout、tracked修改、坏补丁、无源码、无GNU Make4/坏归档、
  CRLF、缺SDK或Kernel头、空间不足、非托管/重合WORK均非零且编译入口未启动。
- 有真实GNU Make4时不强制tarball；没有时只用已固定哈希的本地GNU源码，绝不伪装旧make。
- 禁止自动联网、自动安装工具；输出明确绑定提交、解释器/编译器、输入与产物SHA。
- 新测试需直接调用生产函数或执行真实入口；任何夹具替代必须只限合同测试，并标注未编译驱动。

裁定始终分事实、判断、未验证。新合同通过不能替代目标机完整编译、加载或GPU执行。
本轮不安装/签名/加载/卸载、不写KC/NVRAM、不改EFI/BIOS/Windows/磁盘/E:，不测试Recovery引导。
不把本任务书当作设备授权。实际结果单独写在`AUDIT-RESULT-20261022.md`。
