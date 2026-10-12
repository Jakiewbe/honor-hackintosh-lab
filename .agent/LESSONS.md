# 项目教训

仅记录验证过的失败模式、根因、解决办法、适用条件、证据及局限；猜测明确标为未验证。

## 2026-10-12 宿主兼容层的成功返回不能跨系统继承
FreeBSD14.3.0 pm_runtime.h的pm_runtime_get_sync仅return0，而i915通过它取wakeref；不能据此声明XNU设备已供电。验证：固定blob/函数体检查和25项负向测试中拒绝将其标为XNU implemented。限制：不证明BSD驱动有错误，必须研究host实际PM策略。见research/independent-i915/compat-notes.md与verification.json。
