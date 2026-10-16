# 当前断点（2026-10-17：H1–H4 主线复位）

> **优先级与准入以 [主线复位门禁](../knowledge/12_MAINLINE_ALIGNMENT.md) 为准。** 此文件与任务账本同步更新，旧 EXITBS 失败不再是当前阶段。

## 最近已确认的实机情况

2026-10-17 之前最后一次有据可查的实测发生于 2026-10-15：通过 H1-COUNT 越过 EXITBS，在外接 SSD 完成 macOS 安装、首次设置并进入内屏 2160×1440 正式桌面。键盘可用，Wi-Fi、触控板不可用；蓝牙、音频、亮度、电池、USB、睡眠尚无完整验收。系统报告 Intel/NVIDIA 均 No Kext Loaded，桌面卡顿；显示画面不等于实际 GPU 加速。

## 现行 H1–H4 任务

- H1：外接 SSD 安装与首次桌面成功。独立复启、Windows 完好与恢复演练没有足够证据，故任务账本仍标为 blocked（剩余验收），**不再使用 10-14 EXITBS 死点作为当前 blocker**。
- H2：当前主线，仅做离线外设基线/诊断矩阵；优先 Wi-Fi AX201、I2C 触控板，记录其他外设已测/未测及风险/回滚。硬件动作待单独批准。
- H3：Intel 46A6 内屏已看到桌面，真实 IOFramebuffer/WindowServer 驱动提供者、持续刷新、亮度和停止恢复未核验；目前保持 blocked，准备将来只读诊断。
- H4：Intel Metal 与 RTX 2050 GSP/NVRM/DMA/混合显示冻结为技术研究档案。旧 B3–B10 静态链接、40/40 DMA、Darwin SDK API 编译 PASS 均非 GPU 运行证据；新增 17 项 C++/Segment64 探针 CI 尚未运行。

## 本阶段唯一允许的新增研究

离线整理 H1 不足证据、H2 每项外设现状和候选方案、H3 显示来源的无破坏性诊断清单；每一项必须指向 H1/H2/H3 的真实验收问题。停止新增 NVIDIA DMA Mock、驱动补丁和重复 CI，除非出现直接解决 H2/H3 的新证据或用户明确重启 H4。

## 绝对安全约束

主力 Windows / 内置 NVMe / 内置 ESP / BCD / BitLocker / TPM 不修改。每次重新开机、操作外接 SSD、EFI/BIOS/SIP/Secure Boot 变更及 kext 安装/加载都需用户针对该项单独授权。当前没有新授权，不得自行触发 Actions 或 GPU 实机试验。

## 来源与修订

最新现场：research/gpu-feasibility-20261015/README.md；正式门禁：knowledge/12_MAINLINE_ALIGNMENT.md；研发决策：knowledge/07_DECISIONS.md D-17/D-18。2026-10-14 EXITBS 五轮失败仍保存在历史材料中，不应被新代理误当作现状。
