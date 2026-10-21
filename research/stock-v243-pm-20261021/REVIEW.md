# RM 忙时禁止继续 STANDBY：单点保护候选

## Darwin 结果更新

run [39535081198](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39535081198) / a8d6348：
PM步骤通过（整个run因独立整包检查器失败而红）。真实函数ASan/UBSan合同候选8/8、
原候选2/8，非法源码编译失败且无二进制、未运行；Darwin对象139840 B，
SHA256 `13f0048cd2b1ddde2c08e4057b0a5a9351b99661c8ec0883b6e75da2965e85a3`。
同run核验1069个显式对象/归档输入，只替换一个NVRM.o，重链17528944 B，
SHA256 `08aa02899933553f9c39312f1d7b837e90dedc69fc3cb10e59d99c51c8daef26`，478项导入不变。
没有加载、设备运行、睡眠否决或恢复证明。

证据见 native-evidence/39535081198/。误包附件包含2个CPU夹具和6个dSYM成员，
非驱动；文本及全部成员哈希保留，未提取/执行这些产物。
用户明确授权后已删除该唯一远端附件，HTTP204回执见artifact-correction.json。
修正把CPU编译产物移到日志目录之外，上传增加明确文本白名单；待新run验证实际附件。

输入是已验收 ONCE/任务生命周期候选 NVRM.cpp ac0c7518…，固定 NullMoth 272ccd9，
不修改已有 lock；只在命名副本上叠加 rm-busy-guard.patch，候选 7ce28054…。
变更只有 busy 分支：记录违规并返回，不执行 rm_stop_user_channels、pciSaveForSleep、
rm_power_management(STANDBY) 或关中断。无 busy 时保持旧顺序和错误处理。

两侧 fGpuPm/NVKMS 保持 Suspended，RM 门保持关闭，不错误地通知 framebuffer 恢复运行。
这是已进入 NVKMS suspend 后的保护，不是 suspend 回滚或请求取消，也没有重新打开准入。
XNU IOServicePM.cpp 的 notifyControllingDriverDone 对 result==IOPMAckImplied 或 result<0
都清 fDriverTimer；因此不能靠返回 kIOReturnBusy 否决系统断电。
已重新取得固定 XNU 43a9088 的完整 IOServicePM.cpp（284767 B），摘要及 L4525 起原文见
xnu-pm-binding.json。这是源码语义证据，不是用户设备内核绑定。

## 实际验证

本地生产补丁函数完成正向/反向/重放，只改一个源。
完整 gpuSuspend 函数提取到 CPU 调用边界夹具，WSL 现有 g++ + ASan/UBSan：
候选 8/8（busy=0/1/2/17）；原候选 2/8，六项真实反例；非法源码编译非零、无产物、未运行。
这些测试只证明被测路径的调用顺序，不证明并发排空或 GPU 行为。
首次本地验收时 Darwin 未执行；后续原生结果见本文顶部。入口复用同 run 的受控对象，
只替换唯一 NVRM.o，核验全部1069个显式对象/归档输入及最终导入不变；不使用跨 run 旧对象。

## 仍未关闭

系统依然可能断电；超时后的 RM 状态、未做 STANDBY 时的唤醒恢复、
NVKMS KAPI suspend 与 device free 的互斥、stop 全部使用者与 callback 排空均未验收。
没有把这一条保护作为安全睡眠、可恢复、可加载或设备 GO 的证据。
设备保持 NO-GO，不签名/安装/加载/运行驱动，无 GPU、像素或睡眠测试。

回退：不选择这份单独候选即可；ac0c7518… 基线和历史原生证据不被覆盖。
