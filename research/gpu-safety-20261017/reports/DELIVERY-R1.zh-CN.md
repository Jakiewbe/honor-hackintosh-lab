# GPU 源码安全候选 R1：第一批工程交付

日期：2026-10-17。状态：源码候选可审阅；运行 NO-GO。没有提交、推送、创建分支/worktree、触发 Actions 或设备操作。

## 输入与有效补丁序列

实验仓库只读快照：bb523a58757c9a4d1721f8f1f1cc98b89dc9bdbc。
候选完整源码：NullMoth v2.3.3，ac55984c473e746c2a8ebea7ba0913461aa7c393；OGKM e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb。
三版输入的完整 commit、源码归档哈希和文件数见 ../evidence/source-lock.json。

有效序列只有 ../patches/gpu-safety-r1.patch（SHA256 ad176fb5ced857718fdb7a3fd99f4e5db4cc67b0c58ca82929a2a013158dcf0b）。它基于 v2.3.3 tag 公开源码，属于本项目研发候选，不是稳定发行驱动的复现。不要叠加缺失的 BRIDGE-01～06 或旧 0002。

BRIDGE-06 和旧 0002 实体在此前记录的有限范围搜索中未找到，不能声称恢复了原补丁或修复了其实现。本轮没有继承租约式停止方案。独立候选目录为 candidate/nullmoth-v2.3.3-gpu-safety-r1。

## 实际修改及边界

| 文件 | 修改 | 限制 |
|---|---|---|
| kexts/NVRM/accel/nvrm-accel.cpp | framebuffer 发布要求正确 dependent ID/index；count、pipe、framebuffer 身份全部验证后提交注册位；检查新映射实际长度/地址；复制路径传播 GPU 等待及 CPU 可读性失败；超时不清 pending、表满不驱逐旧项；移除连续四次未就绪即放行 | 没有证明真实 GPU fence；其他 pageoff/flip 调用仍忽略等待结果；pending 丢失后拒绝继续存在活性风险 |
| kexts/NVRM/accel/frame_copy_checked.h | 新增实际 CPU 像素复制函数，完整预检尺寸、pitch、映射长度、对齐、地址溢出与虚拟区间重叠，只复制有效像素 | 调用者仍须保证映射生命周期、实际 GPU 完成与物理别名不重叠；该函数不实现 GPU 渲染 |
| kexts/NMIntelFB/intelfb.cpp | 停止开始后拒绝新 scanout 查询；返回映射实际长度 | fStopping 仍不是同步协议；已经外借的裸指针与 stop 竞争未修复 |

原文件许可声明保留，新 helper 使用 MIT SPDX。source → object → symbol 与许可限制见 ../evidence/verification.json。

## 实际执行与证据等级

| 验证 | 实际结果 | 证据 |
|---|---|---|
| SOURCE-REVIEW | 完整调用链、无头 owner、回调关闭及补丁 diff 已审；残余阻塞保留 | headless-device-owner.md |
| PATCH-APPLIED | v2.3.3 原始完整 611 文件树 git apply --check 退出 0；实际应用后 612 文件哈希全部等于候选；反向应用退出 0 且全部恢复 | ../evidence/patch-application.json |
| 版本适用性 | v2.3.1/v2.3.2 apply --check 均退出 1，不直接套用 | 同上 |
| HOST-TEST | 真实 helper 编译与运行退出 0；2160×1440、257×131 精确像素、padding/canary/源数据保持；9 类非法请求无写入，末行精确边界接受 | ../evidence/host-copy/results.txt、toolchain.txt、compile.txt |
| 手动门禁脚本检查 | 4 段 shell 语法、Python 语法通过；宏提取对既有真实 Make 日志通过 | ../evidence/native-export-check.json、native-probe-local-check.json |
| DARWIN-COMPILE | **BLOCKED：本机无 macOS/Xcode，新门禁未运行** | ../ci-export/ |
| KEXT-LINK | **BLOCKED：未实施；目标系统 Build/KDK、私有 IOFamily ABI/导出未闭合** | ../evidence/verification.json |
| KEXT-LOAD / GPU-RUNTIME / DISPLAY-RUNTIME / ACCELERATED-DESKTOP | 本候选均未执行或验收；运行 NO-GO | 不借用旧版本 PASS |

实际主机命令为 `wsl -d Ubuntu -- bash /mnt/d/Hactk/gpu-mainline-20261017/work/run-host-copy.sh`；脚本使用既有 g++ 13.3、C++17、-Wall -Wextra -Wconversion -Werror、AddressSanitizer/UndefinedBehaviorSanitizer。没有安装新软件。完整补丁应用使用逐命令 `git -c core.autocrlf=false apply`，没有改全局 Git 配置。初次 Windows autocrlf 的字节不一致已保留在证据说明中，后续全树字节核对通过。

## 三版本源码与发行物

三包均已取得并核对外层 SHA256。逐成员差异、真实 Mach-O minOS/SDK 与三份源码 diff 见 ../evidence/release-audit/release-source-identity-report.zh-CN.md。

2.3.3 的所检 NVRM/NVRMFB/NVRMAGDC、15/26 NVAccel 与 2.3.1 字节一致；NVK 三包一致。macOS15 NVAccel 三包均一致；2.3.2 的 macOS26 缓存 NVAccel 与 2.3.1 不同，2.3.3 恢复旧字节。Metal 并非三个包完全相同，不能把整个 2.3.3 包说成完整的 2.3.1 二进制副本。2.3.3 tag 源码继续包含 2.3.2 与新增修改，故发行回退不等于源码回退，也不能据 tag 推断发行驱动已经含有这些源码修改。

包间字节对照没有闭合源码 commit → 原始构建参数 → 每个发行对象的强绑定。发行包审计只做静态归档/头字段读取，没有执行安装器或包内程序，没有提取固件供运行。

## 无头服务与下一源码文件

公开 OGKM 有 displayless Device 分支；grabOwnership 的公开合同是 modeset 所需。目前 NVRMFB 创建共享 gDev，NVAccel 的 VRAM/handles 依赖已发布 fFB，全局 handles 缓存缺少代际；未见该 framebuffer 路径对 freeDevice/releaseOwnership 的完整对称调用。

最小设计是 NVRM 在 RM/GSP ready 后持有唯一内存 Device owner，显示客户端单独管理 modeset ownership，NVAccel 经 owner 访问 VRAM/GPUVA，不让 NMIntelFB 冒充 NVIDIA framebuffer。设计在 headless-device-owner.md，尚未实施。

下一源文件优先为 `kexts/NVRM/os-nvkms-xnu.cpp:kms_close_common`：先闭合回调取消、在途工作和可失败关闭协议，再改 NVRM.cpp/nvrm_gpuva.cpp。当前 eventBusy 无界等待、回调自等待及 PM 失败处理阻止安全直接补 freeDevice。不能用超时后释放制造退出成功。

更底层真实 IOMapper/IOVA、DMA 所有权和 GSP 静默仍为 P0。三个 DMA 回调函数体与旧基线逐字相同（../evidence/dma-source-continuity.json）；旧 40/40 不重跑，也不代表硬件 DMA 成功。Intel 裸 scanout 生命周期、其他 flip/pageoff 忽略等待、sleep/reset 代际和真实 fence 全部未闭合。Head 4 未开启。

## 原生交付及回退

ci-export 提供仅 workflow_dispatch 的 macos-15-intel/Xcode16.4 对象门禁。同 profile 编译原版/候选 NMIntelFB real、virtual 与 NVAccel，共六个完整翻译单元；固定真实输入，记录依赖、编译命令、对象 hash、Mach-O 格式及 nm 定义/未定义列表。重建宏配置明确标为候选，不冒充上游原始配置。只上传文本日志，不链接、不上传驱动对象、不加载。CI 上安装 GNU make 只发生在临时 runner，本机环境未改变。

工作流、脚本、research/gpu-safety-r1 资产尚未复制到实验仓库、未提交。导入和 Actions 手动运行需要用户后续操作；本轮没有触发。

lab-overlay 是五份 knowledge 文件的待审阅覆盖层，保留历史并在顶部记入用户 GPU 优先的新决定；project-status-r1.patch 仅导出文档差异，没有应用到旧检出或远端。research/gpu-safety-20261017 的引用对应本交付的文本研究包，正式导入时应将研究资料一起放置。

回退只需停止采用该候选补丁与覆盖层；完整反向应用已验证可恢复原始源码字节。所有修改都在独立研发目录，没有系统/驱动部署，无需变更 Windows、EFI 或外接 macOS。
