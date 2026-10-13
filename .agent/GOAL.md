# 项目目标

## 核心目标
在 HONOR GLO-FX6P 上分阶段适配 macOS 整机：H1 外接 SSD 引导与安装 → H2 外设逐项（Wi-Fi/蓝牙/键盘/触控板/音频/电池/USB/睡眠）→ H3 Intel 46A6 内屏基础显示（先固件帧缓冲，再自研最小驱动，即原 L1）→ H4 加速可行性（后置）。

## 项目背景
HONOR GLO-FX6P/i5-12500H，Iris Xe 8086:46A6 接内屏，RTX2050 10DE:25A9 为 0302 无显示输出、无 MUX；BitLocker 未加密、Secure Boot 开启。用户 2026-10-12 授权接管 L1，2026-10-13 批准扩展为整机分阶段适配。

## 关键约束
根目录 AGENTS.md。内置 NVMe、Windows、其 ESP/BCD/启动项始终不动；macOS 只装在外接 SSD。改 BIOS/Secure Boot、写 U 盘或外接 SSD、引导、kext 加载等每个有副作用的动作需用户逐条批准。禁止自行触发 Actions、上游 Issue/PR、二进制发布、强推、私建分支/工作树。

## 非目标
不在内置硬盘安装或双系统分区；不承诺 Intel Metal 加速；不改 Windows 引导。

## 验收标准
每阶段以实机证据验收（OpenCore 日志、macOS 日志/ioreg、可复现步骤与回滚记录）；ocvalidate、编译通过、模型不能冒充实机结果。H3 沿用 L1 标准：持续画面、输入、停止与恢复证据。

## 目标版本
以 state.json 为准；依据用户本轮明确目标。
