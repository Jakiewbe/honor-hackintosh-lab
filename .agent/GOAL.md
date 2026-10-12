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
