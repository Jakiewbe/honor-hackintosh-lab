# 当前断点

## 当前阶段
H1 外接SSD引导与安装：U盘实机引导已做5轮，全部卡在 EXITBS:START；用户 10-14 18:2x 决定先停，记录结论。

## 当前任务
H1 blocked：i5-12500H 在 OpenCore 下过不了 boot.efi→内核交接（零内核输出、Caps Lock 无反应）。
R14C0 blocked（L1源码闭包，现归入H3）；R14C0PRE、A1401 done。

## 已完成工作
D-17：用户批准GOAL扩展为整机分阶段适配H1-H4；外接SSD实机，内置NVMe/Windows永不改。
U盘（KIOXIA，磁盘1）：原数据已备份校验；GPT+FAT32 OCINSTALL；macOS 15 恢复镜像（内核24.4.0）。
Secure Boot 已由用户关闭。OpenCore 阶段全部成功：恢复项加载、29个kext注入、CPU补丁、内置NVMe隐藏属性。
已排除（逐项日志确认生效仍卡死）：ForceExitBootServices、删DMAR、SetupVirtualMap=false、cpus=8；HideAuxiliary 已撤销、Timeout 改 0。
MADT 只读核对：性能核在前（APIC 0/1/8/9/16/17/24/25），能效核 32–46 偶数；“能效核被当主核”假设不成立。
候选EFI：D:\Hactk\efi-candidates\GLO-FX6P-1401-20261013（H1-A…H1-E）；U盘当前 config.plist=H1-E，备份 config-A/B/C/D。

## 当前阻塞
Dortania bugtracker 336：12500H 需 BIOS 关超线程或关能效核才能过 EXITBS；本机BIOS无此选项，无已知Sequoia纯软件解法（Q-18）。

## 下一步动作（均需用户重新决定，未批准）
1. 关掉1401额外的3条“force HT enabled”内核补丁（_cpu_thread_alloc），U盘单变量试验。
2. 核心数/包 128→16 的用户内核补丁（需先能读取内核验证落点；本机无DMG工具）。
3. 只读研究 Insyde 隐藏“超线程”设置（改BIOS变量风险高，须单独批准）。
用户返回时先确认是否继续 H1；Windows 正常，引导文件只在U盘。

## 状态修订
以state.json/tasks.json为准，写入前status；H1细节见docs/H1_外接SSD引导安装方案.md附录与logs/RESEARCH_LOG.md。

## Git 检查
origin/main在985c28d；本地c5d5f69及之后提交未推送，推送需用户批准。不建分支/工作树。
