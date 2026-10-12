# HONOR Hackintosh Lab 项目复盘（待人工补全、审核）

## 原始目标
# 项目目标

## 核心目标
让 Intel 8086:46A6 内屏在 macOS 中稳定持续刷新基础桌面，允许无 Metal 加速。

## 项目背景
HONOR GLO-FX6P/i5-12500H，RTX2050 10DE:25A9；内屏连接 Intel 已确认。用户于 2026-10-12 授权正式接管。

## 关键约束
根目录 AGENTS.md；仅公开源码、文本与离线 Python。禁止宿主硬件变更、kext 部署、自行触发 Actions、上游 Issue/PR、二进制发布、强推、私建分支/工作树。

## 非目标
L2 Metal、L3 NVIDIA 混合显示；当前不写完整 AlderFB.kext。

## 验收标准
最终 L1 必须隔离实机持续画面、输入、停止与恢复证据；本轮仅 R1.4-C0 的版本、许可、真实调用图和失败即停止检查，维持 RUNTIME_NO_GO。

## 目标版本
以 state.json 为准；依据用户本轮明确目标。


## 最终交付
L1 与完整 R14C0 任务未完成，任务 blocked；已交付首轮 SOURCE-STATIC 基线、正式报告和 verification：156 条源锁，92 定义/79 关系，25 通过0失败，闭包门禁退出2。

## 重要决策
# 重要决策

仅记录已经确认的决策。每条包含时间、背景、备选方案、选择、原因、适用范围及变更情况。

## 2026-10-12 接管与源码阶段边界
用户明确授权L1及R1.4-C0；采用四个旧固定commit和测试矩阵支持的FreeBSD14.3.0精确候选。拒绝以版本名、上游PM空成功或source slice冒充XNU实现。首轮证据见正式报告和verification；完整B0/B1未验收，任务blocked，不进入B2/B3。其他候选base与裁剪路线未采用；改变需新的真实源码/接口证据。


## 成功经验
通过固定测试矩阵取得可审查base候选，按实际函数体和callback追踪依赖；不重复旧构建/模型。

## 失败及根因
# 项目教训

仅记录验证过的失败模式、根因、解决办法、适用条件、证据及局限；猜测明确标为未验证。

## 2026-10-12 宿主兼容层的成功返回不能跨系统继承
FreeBSD14.3.0 pm_runtime.h的pm_runtime_get_sync仅return0，而i915通过它取wakeref；不能据此声明XNU设备已供电。验证：固定blob/函数体检查和25项负向测试中拒绝将其标为XNU implemented。限制：不证明BSD驱动有错误，必须研究host实际PM策略。见research/independent-i915/compat-notes.md与verification.json。


## 不值得重复的尝试
旧R1.2-C/F/G和R1.3-D，内屏归属调查以及上游重复Issue。

## 后续建议
C0.1已交付；下一项C0.2固定IOPCIFamily与PCI/MMIO/PM生命周期；不得进入kext实现。

## 可复用知识候选
待审核；包含适用条件、证据、局限和来源项目。未经确认禁止入库。

## 2026-10-12 C0.1收尾
复用C0，补真实BSD生成规则/提供者与power失败传播。21通过0失败；新增查询scope错误被门禁发现后修正。必要XNU故障退出/配置/许可仍BLOCKED；不把静态绿色当作驱动成功。
