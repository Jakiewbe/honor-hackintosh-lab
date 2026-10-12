# 项目教训

仅记录验证过的失败模式、根因、解决办法、适用条件、证据及局限；猜测明确标为未验证。

## 2026-10-12 宿主兼容层的成功返回不能跨系统继承
FreeBSD14.3.0 pm_runtime.h的pm_runtime_get_sync仅return0，而i915通过它取wakeref；不能据此声明XNU设备已供电。验证：固定blob/函数体检查和25项负向测试中拒绝将其标为XNU implemented。限制：不证明BSD驱动有错误，必须研究host实际PM策略。见research/independent-i915/compat-notes.md与verification.json。

## 2026-10-12 PM返回类型名不等于故障传播
IOServicePM.cpp notifyControllingDriverDone将result<0作为已完成确认。Linux errno不能直接代表XNU拒绝上电；必须分离PM协议与驱动故障状态。固定raw源/body和21负向检查有据，API独立树仍未闭合。

## 2026-10-12 Git树查询范围要写入证据
GitHub JSON的url不保留recursive查询串；用响应url推导缓存名会错读非递归树。新增门禁实际失败后定位并保存request_url和完整未截断树snapshot，21检查最终通过。只修证据索引，没有重写旧实验。
