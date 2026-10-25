# 外部审查请求（给 Codex）

> 用法：把下面 `====` 之间的整段原样贴给 Codex。仓库是公开的，让它直接 `git clone` 后 checkout `b05550d` 再审（本文件所在提交；被审代码在 `d149e0d`）。

====

# 审查任务：HONOR GLO-FX6P 上 RTX 2050（10DE:25A9）在 macOS 15 的 NVIDIA 驱动移植

你是独立审查者。我在一台真机上做一个高风险的内核驱动移植，已经连续多轮出现"脚本交给用户才第一次运行、然后失败"的问题。
我要你**只做审查，不要重写目标、不要给替代方案**，按证据判我对错。

## 你的输出必须满足

1. 开头一句总判断：当前这套东西**可以继续往下走 / 需要先修再走**。
2. 按 `P0`（会把机器搞坏或结论错误）/ `P1`（会浪费一轮实验）/ `P2`（可读性、卫生）分级。
3. 每条给出 `文件:行号`，指到具体代码或文档；不能只给"建议加强测试"这种空话。
4. 每条给**可证伪的验证方法**（一条命令、一个断言、或一段日志该长什么样）。
5. 明确列出你认为我**过度声称**的结论（我说了"已证明"但证据只到"没报错"的那种）。
6. 用中文回答。不要复述我的目标，直接进入发现。

## 1. 环境事实（已实测，不要再质疑）

- 机器：HONOR GLO-FX6P 笔记本。
- 独显：NVIDIA RTX 2050，PCI `10DE:25A9`（GA107 系），BAR0 = `0x51000000+0x1000000`，BAR1 = `0x7e00000000+0x100000000`。
- 集显：Intel `8086:46A6`，**负责一切显示输出**，这也是这台机器还能用的原因。
- 系统：macOS 15.8.1 24H32，Darwin 24.6.0，x86_64，SIP 开启（`csrutil` 默认状态）。
- boot-args（实测）：
  `-v debug=0x100 keepsyms=1 -vi2c-force-polling ctrsmt=full nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 cpus=8`
- 内核集合（实测 sha256 前缀）：`SystemKernelExtensions.kc 2296155f…`、`BootKernelExtensions.kc cd013c14…`、`AuxiliaryKernelExtensions.kc 5f558fcd…`
- 这台机器**没有网络、没有 Xcode**，只有 CommandLineTools + SDK 15.5，所以一切构建都得离线、在 Windows 侧准备好再拿过去。

## 2. 目标（不要改）

最终目标：macOS 15 上这块 RTX 2050 **能初始化、能跑真实离屏 GPU 计算、读回正确结果、错误能传播、能安全关机**；Intel 集显保持显示。
当前阶段目标只有两步：(a) 让驱动带着 GSP 固件跑起来；(b) 取回那一次开机的完整日志。

## 3. 硬约束（这些是已授权边界，你的建议不能越界）

- 不装/不签/不加载任何新 kext 到我未授权的路径；不动 OpenCore / EFI / BCD / BIOS / SIP / NVRAM 之外的任何系统文件。
- 引擎不允许调用 `shutdown`/`reboot`；跨开机的动作一律交给用户按一次回车。
- 不许联网下载驱动包或固件（固件已按上游发布包核对过）。
- 不许 force push、不许改旧 checkout `D:\Hactk\honor-hackintosh-lab`。

## 4. 代码与证据在哪

- 仓库：`https://github.com/Jakiewbe/honor-hackintosh-lab`，`main` HEAD = `b05550d`（远端已确认一致，工作树干净）；**被审代码的基线是 `d149e0d`**（脚本 v3 + 43 条断言 + 恢复检测修复）。
- 运行脚本（10 个，全部在 `research/stock-v243-offscreen-20261021/`）：
  `G1-试跑一次.command`、`G1-一键诊断.command`、`G1-急救.command`、`G1-清守卫.command`、`G1-修复加载.command`、`G1-装固件.command`、`G1-加载实验.command`、`G1-一键运行.command`、`G1-自动实验.command`（**已废弃，会重启机器**）、`g1-first-touch.command`。
- 测试：`tests/command_scripts/test_trial.sh` + `tests/command_scripts/stubs/{nvram,sysctl,log,kextstat,ioreg}`（用假命令在 Linux/Windows 上模拟 macOS，**不需要真 Mac**）。
- 关键文档：`STATE-20261024.md`（现状一页纸）、`TRIAL-REVIEW-20261024.md`（本轮审查与交付）、`AUTO-RUN-REVIEW-20261024.md`（自动实验脚本事故复盘）、`LOAD-RESULT-20261024.md`（真机加载结果）。
- 驱动源码：上游 `nullmoth/nvidia-macos-driver`，我锁的 pin 是 `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`；线上装的是该 pin 构建出的 **2.4.2 二进制**（`NVRM.kext` 二进制 sha256 `4a38ea572e3b66e39e6a2ce62e7e74701c4a092a6a83b9e7f5a862dcd4711eba`，17,528,944 B）。
- 真机证据在 U 盘 `results/` 下，文件名与结论我在第 6 节点名引用；贴给你的时候我会把原文附上。

## 5. 现在的证据等级（我按这个分级说话，请检查我有没有越级）

| 等级 | 内容 | 证据 |
|---|---|---|
| SOURCE-REVIEW | 守卫机制、固件表、日志字符串 | 源码 + 二进制里的格式串 |
| HOST-TEST | 脚本逻辑 | `test_trial.sh` 43 条断言 `PASS=43 FAIL=0`；Python 290 条里 286 通过（4 条因缺 `.cache/freebsd-src` 失败，见 Q5） |
| DARWIN-COMPILE | 离线构建链 | 真机 14/14 preflight 通过、构建成功 |
| KEXT-LINK | kextutil 试装 | `kextutil -n` 全绿 |
| KEXT-LOAD | 驱动进了内核 | `kextstat`：`163 0 0xffffff7f97174000 0xe47ff8 com.nullmoth.NVRM (0.1) 628F533F-…` |
| GPU 部分 | RM 初始化到 PASS 1 | 日志 `PASS 1 REACHED: RM initialised, private state built, GSP firmware requested`，`bus master + memory enabled (command 0x0006)`，`nv_get_screen_info -> base 0x4000000000 2160x1440 depth 32 pitch 8640 size 12441600` |
| **未达成** | **固件被读进驱动** | `nv_get_firmware … -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin` 之后 `vnode_open failed 2`（ENOENT，当时目录不存在） |

## 6. 关键事实链（请重点检查这条链是否闭合）

**为什么后来驱动再也不启动**：源码里有一个自带"关机守卫"。

- `kexts/NVRM/nvrm_off.h:20-46`：`#define NVRM_GUARD_VAR "nullmoth-nv-starts"`、`#define NVRM_GUARD_LIMIT 2`；
  `nvrm_driver_off()` 在三种情况下返回 true：boot-arg `-nvoff`、`/options` 里有 `nullmoth-remove`、`nvrm_guard_starts() >= 2`。
- `kexts/NVRM/NVRM.cpp:372-374`：`IOService *NVRM::probe(...) { { if (nvrm_driver_off()) return NULL; } …`——**在第一条 LOG 之前就返回**，所以被挡住时日志里一个字都没有。
- `kexts/NVRM/NVRM.cpp:395-396`：`start()` 里同样先查守卫，放行后 `nvrm_guard_count_start()` 让计数 +1。
- 计数**只有** `nvrm_guard_display_up()`（`nvrm_off.h:114-127`）会清零，而它唯一的调用点是 `kexts/NVRMFB/fb/nvrm-fb.cpp:2995`；这台机器上 **NVRMFB 没装**（`/Library/Extensions` 里只有 HighPoint 两个 kext + NVRM）。

由此推出：**固件装好（真机 07:47）之后，每一次开机都被守卫挡在 probe 之外，固件从未被真正读过。**
真机时间线（同名 `diag-*.txt`，文件名是设备时区，比 Windows 慢约 7 小时）：

- `diag-20261024-065702.txt`（06:56 开机）：NVRM 实例数 1，跑到 PASS 1，固件 ENOENT；
- `diag-…073331` / `…074934`（07:30 / 07:48）：实例数 0，NVRM 日志 0 行；
- `diag-…080624`（08:05，KC `507ed452`）：实例数 0，panic 段 = `(none)`。

**今天查清的第二件事**：用户抱怨"一直自动重启"。我查 `git show c31fb6e:research/stock-v243-offscreen-20261021/G1-自动实验.command`，
里面的 LaunchDaemon `com.g1.auto`（`RunAtLoad`）在 `daemon_step()` 末尾执行 `/sbin/shutdown -r now`，且队列没走完就每次开机都跑。
删掉 daemon 后重启停止。**驱动从未产生过 panic 文件**，所以重启不是驱动崩的。

## 7. 请逐条审的问题

**Q1（P0 级）试跑脚本的安全边界真的够吗。**
`G1-试跑一次.command`（13,242 B，随 `d149e0d` 交付）v3 的设计是：不装任何 LaunchDaemon，`go` 只写两个 NVRAM 变量
（`nullmoth-nv-starts=%01`、删掉 `nullmoth-remove`），然后让用户自己重启，`report` 用 `log show` 回捞。
请检查：(a) 是否存在任何路径会让机器进入"驱动永久静音且用户不知道怎么恢复"的状态；
(b) `set -u`、`sudo` 重入（`exec sudo … bash "$0" "$@"`）、`exec > >(tee …)` 在 macOS bash 3.2 上是否有未覆盖的坑；
(c) 我把守卫预置成 1 是否真的只放行一次（计数变成 2 后自锁），有没有可能变成 0 或不变。

**Q2（P0 级）守卫是不是还有第三条清零/绕过路径我没找到。**
我找到的是 `nvrm_off.h` 那三种 off 条件 + 唯一清零点 `nvrm-fb.cpp:2995`。
请在上游 pin `272ccd9` 里复核：除 `nvrm_guard_display_up()` 之外，还有没有任何地方写 `nullmoth-nv-starts`、`nullmoth-nv-ok`、`nullmoth-remove`
（包括 `nvram` 调用、`IODeviceMemory`/`/options` 属性读取、`sysctl`、用户态工具）。如果我的"唯一"是错的，整套实验设计要重排。

**Q3（P1 级）43 条断言的盲区。**
`tests/command_scripts/test_trial.sh` 用假 `nvram`/`sysctl`/`log` 跑。请指出：哪些"真机会失败但假环境永远成功"的地方没有被覆盖
（比如 macOS 上 `nvram -p` 输出格式与我的 `awk` 解析、`log show --start` 的时间格式、`sudo -p` 交互、U 盘只读挂载、`/var/tmp` 权限）。

**Q4（P1 级）"重启是 daemon 不是驱动"这个结论是否被证据唯一支持。**
我的推理是：守卫计数读到 `%02` ⇒ 那次开机 `probe` 直接返回 NULL ⇒ 驱动不可能重启机器；加上 `(none)` 的 panic 段。
请挑刺：有没有别的机器级机制能造成同样现象（`kmutil` 每次开机重建、OpenCore 改写 boot-args、`softwareupdated` 的 NVRAM 访问被沙盒拒绝等）。

**Q5（P2 级）Python 测试有 4 条失败是环境造成的，该不该改成 skip。**
`290 tests, failures=2, errors=2, skipped=21`，4 条全在 `test_r14c0_dependency_gate.py` / `test_r14c01_power_contract.py`，
报错都是 `[Errno 2] No such file or directory: …/.cache/freebsd-src/share/mk/bsd.sysdir.mk`（这个缓存不在本 checkout 里）。
请判断：把缺缓存当成 skip 会不会掩盖真实回归？还是应该保留 fail？

**Q6（P1 级）顺序问题：要不要先装 NVRMFB 再试跑。**
NVRMFB 是唯一能清零守卫的组件（`nvrm-fb.cpp:2995`），但它也是显示路径上风险最大的组件。
我目前的顺序是：先只跑 NVRM（带固件）+ 回捞日志，确认固件能读、RM 能过 adapter，再考虑装 NVRMFB/NVAccel 并重建 aux KC。
请判断这个顺序在"减少不可逆操作"和"给守卫一个自动清零机制"之间的取舍是否合理。

**Q7（P1 级）`report` 的结论判定是否可靠。**
判定用 `grep -F "firmware loaded"`。我在真机二进制里确认过格式串是
`NVRM-xnu:   firmware loaded: %zu bytes`（同一批还有 `firmware %s is %llu bytes, refusing (limit %u)`、
`is not the image this driver shipped`、`instructions on installing the correct firmware.`）。
请检查这个 grep 会不会误命中的情况（例如失败路径也打印含 `firmware loaded` 的行），以及四个分支
（`firmware loaded` / `vnode_open failed` / 无 `probe 10de` / 其它）是否互斥且穷尽。

**Q8（P1 级）我是否在用"静态缺失"冒充 ABI 验证。**
另一条线上，我从 365 MB 的 `SystemKernelExtensions.kc` 解出了 `IOAccelSurface` 的 120 个真实 vtable 槽位（链式 fixup 解码），
并用它裁掉了头文件里 7 个虚函数（`set_shape`/`set_shape_backing_length_ext`/`surface_lock_options`/`surface_unlock_options`、
`IOAccelGLContext2::processSwap`、`IOAccelLegacyDisplayPipe::setStereo`、`IOAccelLegacyDisplayMachine::setStereo`）。
目前的凭据只是"KC 里静态不存在 + `kextutil -n` 能过"。请判断：这算不算把"静态缺失"当成了 ABI 证明；若裁错，后果是不是槽位整体错位。

## 8. 我自己已经知道的薄弱点（不用重复报，但可以否决我的判断）

1. 固件"能被读到"这件事**从未被观测**——装好固件后的两次开机都被守卫挡了，所以这一格仍是空的。
2. `kextutil -n` 只是不加载的装载检查，不等于 ABI 正确，更不等于能跑。
3. 34 个 NVAccel 导入符号只有本地定义、导出未验证。
4. 设备时区与主机差约 7 小时，文件名必须换算后再比对。

## 9. 一致性自查（可以拿来快速验我的数字）

- `git rev-parse HEAD` = `b05550d`，`git status --porcelain` 为空；被审代码基线 `d149e0d`。
- `bash tests/command_scripts/test_trial.sh` → `合计: PASS=43 FAIL=0`。
- `python -m unittest discover -s tests -p 'test_*.py'` → `Ran 290 tests ... failures=2, errors=2, skipped=21`。
- 固件：`/Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin`，84,310,168 B，SHA-1 `f11971026ccd86a7ea09ba525548c2e0615565ce`
  （与驱动 `os-xnu2.cpp` 里的表逐字节一致）；`ucodes_ga10x.bin` 31,744 B，SHA-1 `1daf70f4f9a256212dead6f1ba88c694c5ae3af9`。
- 上游 2.5.3 的固件目录是 `615.78.08`（**不能用**，版本和哈希都不对），所以固件取自 2.4.2 的发布包。

====

## 给 Codex 的补充材料（贴的时候一起给）

1. 仓库：`git clone https://github.com/Jakiewbe/honor-hackintosh-lab && cd honor-hackintosh-lab && git checkout b05550d`
2. 驱动源码（对照源码用）：`git clone https://github.com/nullmoth/nvidia-macos-driver && git checkout 272ccd9`
3. 本机不需要 macOS：`bash tests/command_scripts/test_trial.sh` 在 Linux 上就能跑（用 `tests/command_scripts/stubs/`）。
4. 真机日志原文在 U 盘，我会按文件名附上；没有原文时请只凭仓库内文档判断，并注明"未看到原始日志"。
