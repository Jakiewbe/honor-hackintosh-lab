# 当前断点

## 当前阶段
H1 外接SSD引导与安装：方案编写（文档），尚未执行任何写盘/BIOS/引导；RUNTIME_NO_GO直到用户逐条批准。

## 当前任务
H1 doing：写H1方案（前置检查、U盘与外接SSD准备、BIOS、引导、日志采集、回滚），交用户审阅。
R14C0 blocked（L1源码闭包，现归入H3）；R14C0PRE、A1401 done。

## 已完成工作
D-17：用户批准GOAL扩展为整机分阶段适配H1-H4；外接SSD实机，内置NVMe/Windows永不改。
候选EFI：D:\Hactk\efi-candidates\GLO-FX6P-1401-20261013（A-main首选、B-fexitbs对照），ocvalidate通过、未引导。
1401支线结论：RTX2050无输出、无MUX；内屏只能靠Iris Xe固件帧缓冲；触控板需改VoodooI2C匹配。
用户器材：U盘、外接SSD、USB鼠标；无外接显示器。

## 当前阻塞
H1每一步（关Secure Boot、写U盘、格式化外接SSD、引导）都需要用户单独批准。
同平台1401 Issue 26卡EXITBS:START，原因未定（Q-18）。

## 下一步动作
提交H1方案；用户批准后按步骤执行并记录OpenCore日志。

## 状态修订
以state.json/tasks.json为准，写入前status；1401支线日志见logs/RESEARCH_LOG.md。

## Git 检查
origin/main在985c28d；本地c5d5f69及之后提交未推送，推送需用户批准。不建分支/工作树。
