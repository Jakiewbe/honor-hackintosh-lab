# R28：真实事务的 owner-copy 错误传播

研发仓库输入：`80a5db6b8f2cc9d8928d7e0e09c1f0872dd54978`。仅修复实际调用点 `NVDisplayPipe::performTransaction()`；不改零调用的 `nvAccelCopyToScanout()`、Intel provider、显示所有权或 PM。

## 目标与实现

R22 接入的真实事务把所有 owner-copy 失败都当作“不支持”并使用旧 kva 路径，可能掩盖执行错误。R28 保留 `callPlatformFunction` 的返回值：成功直接返回；仅 `kIOReturnUnsupported` 允许原有回退；其余错误经原 `NVIOP_FAIL` 原样返回，不访问回退映射、不增加成功计数。symbol 分配失败返回 `kIOReturnNoMemory`。

依据是固定 XNU [`IOService.cpp:1493–1555`](https://github.com/apple-oss-distributions/xnu/blob/a1e26a70f38d1d7daa7b49b258e2f8538ad81650/iokit/Kernel/IOService.cpp#L1493)：symbol overload 默认 Unsupported 且只在此状态向 provider 转发；字符串 overload 分配 symbol 失败时返回 NoMemory。不能把任意失败等同于缺少接口。

补丁：`nullmoth-r28-owner-copy-errors.patch`；SHA256：
`ef21d54a3c9386628fc95d34aba083f5ae4bac98938c982b0d40966a1826a842`。

## 实际验证

`tools/test_r28_owner_copy.py` 提取输入源码中**完整真实函数和真实 NVIOP_FAIL 宏**，引用输入树的 ABI 头及 `frame_copy_checked.h`。IOKit/IOSurface、原子计数、日志、同步和 provider 响应均为 CPU 桩；状态值只用于分支与原样传播合同，不证明 Darwin ABI。所有场景用新进程，避免静态 symbol 缓存掩盖分配失败。

WSL Ubuntu / g++ 13.3.0，ASan + UBSan：候选 **15/15**；同套测试在重建 R27 基线上有 **6 个预期失败**（case 0、6–10）。覆盖：

| case | 合同 |
|---|---|
| 0 | symbol 分配失败，不调用 provider、不回退 |
| 1–2 | owner 成功，kva 为空或不可用仍成功 |
| 3 | Unsupported 合法回退，逐像素核验 |
| 4–5 | Unsupported 但缺映射/长度不足，拒绝且不写入 |
| 6–10 | NotReady、BadArgument、NoMemory、超时值、任意错误原样传播；有效 kva 也不得回退 |
| 11 | owner 错误并缺 kva，保持原错误 |
| 12–14 | 源完成未证、CPU 内容未就绪、格式不支持，均在 provider 前拒绝 |

每项同时检查返回值、provider/回退次数、错误/成功/源/每 head 计数及目的缓冲区。负向控制注入 `#error`：编译 exit 1，无二进制、未执行。输出目录必须不存在；编译失败直接退出，正常测试二进制在归档前删除。

证据：`r28-evidence/host/report.json`、完整编译/场景日志、生成的真实函数 fixture。它们是 CPU 合同证据，不是 GPU 或内核生命周期证据。

完整补丁往返由 `tools/check_g1_patch_series.py` 在临时目录执行；不 checkout/reset/clean 输入。原始快照全部 611 个文件逐 Git blob 对照固定 NullMoth tree `528e804da39cb6c358727455385563d414606a70`；前 26 个 NullMoth 补丁与当前远端 blob 一致，重建 R27 全树与既有 clean 候选逐文件一致；追加 R28 后 612 个文件，反向恢复全部原始字节。

本工具树哈希定义：按相对路径排序，对每项 `path + NUL + SHA256(file)` 以换行连接再求 SHA256；与旧脚本遍历顺序口径不同，不直接比较旧短哈希。

| 树 | SHA256 |
|---|---|
| 原始/反向恢复 | `97e76f376f620a7a0500c862a9cbd224c1680b8bfceed89f760642d7c38f2c2f` |
| R27 基线 | `bd1afdc0248f022d50b6c0e78198b3a8972ec569e6999ffc5588c4c28c1cc3e7` |
| R28 候选 | `5964c4ad02a39e1306978e7cb04c1d7fbaf98171df627faeab9663fa13fe24ac` |

往返证据：`r28-evidence/series.json`。R28 原生脚本序列为 **27 个 NullMoth 补丁 + 既有 1 个 OGKM 补丁**，总计 28；不要把轮次当成 NullMoth 补丁数量。

既有工具回归 9/9；历史 G1 三组回归 10/10、5/5、7/7。后者只证明历史合同未回归，不能验收 R28。

## 原生门禁与边界

`.github/workflows/gpu-safety-r5-native.yml` 新增完整序列往返及真实函数主机合同步骤；原生编译序列追加 R28，保留九单元配方、五个 OGKM 探针与精确宏/对象 inventory 入口，不增加试探性平台宏。

本轮 **Darwin 对象编译与 kext 链接未执行**。最新已核实 run 仍为 `39090712869`，其 head 是旧提交 `1db63e0`，不能验收本次改动。当前 GitHub 连接器没有 dispatch 接口；此前本机凭据与浏览器入口也不可用，未伪造触发或把 push 改为自动触发。用户的主动触发授权继续有效。

可在已有原生门禁以 `main`、`xcode=Xcode_16.4` 执行；需同时验收新 head、R28 host/series 报告、原生编译与链接结果，以及新的 `g1-probe-inventory.json`。Mac clang/ASan 的首次运行也在待验范围内。

R28 只关闭此处源码/CPU 合同的错误掩盖；kva fallback 自身的借用映射生命周期、symbol 缓存并发、provider 生命周期均未因此得到证明。完整 RM/modeset 构建闭包与 ABI、P0-1、R24 超时后行为、P0-4 继续 OPEN/BLOCKED；KEXT-LOAD、GPU-RUNTIME、PIXEL-READBACK、SAFE-SHUTDOWN 未验收，实机 NO-GO。

下一断点：取得新原生宏/依赖/对象报告后，先确定三个 RM TU 的 altstack 分支与 35 目标的真实对象定义，再扩展核心链接闭包和核对跨平台结构布局。没有新原生报告时可继续公开源码的签名/布局分析，不重复已有五 TU 的首次编译声明。

复盘：本轮通过完整真实函数与旧基线反例避免“只改死代码”；通过新输出目录、失败即退出及负向控制避免旧二进制假通过；这些合同仍不能替代系统 PM、映射生命周期或 GPU 运行验收。
