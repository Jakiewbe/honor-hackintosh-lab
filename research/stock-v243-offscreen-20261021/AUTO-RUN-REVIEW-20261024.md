# 自动实验报告复盘 + 真正的拦路虎（2026-10-24）

对象：`results/auto-20261024-082410`、`results/auto-20261024-082714` 两份自动实验输出，
以及 06:57 / 07:33 / 07:49 / 08:06 四份 `G1-一键诊断` 报告。

结论先行：**"kext 装上了、ioreg 里没有节点、日志一行不报"的真正原因是驱动自己的开机守卫
`nullmoth-nv-starts >= 2`，`NVRM::probe()` 第一行就返回 NULL。** 和签名、和集合内容、
和 vtable 都没有关系。脚本 v2 另有 4 个缺陷，导致这一轮实验白跑。

---

## 1. 报告里的事实（可复核）

### 1.1 时间线

| 采集 | 本次开机时刻 | aux KC sha256（前 8） | ioreg NVRM 实例 | 驱动是否跑到 PASS 1 |
|---|---|---|---|---|
| `diag-…065702` | ~06:56:0x | `5f558fcd` | **1** | **是**（06:56:09 起整串日志） |
| `diag-…073331` | ~07:30:05 | `5f558fcd` | 0 | 否（一行都没有） |
| `diag-…074934` | 07:48:14 | `5f558fcd` | 0 | 否 |
| `diag-…080624` | 08:05:08 | `507ed452` | 0 | 否 |
| `auto-…082410/cyc1` | 08:22:53 | `507ed452` | 0 | 否 |

同一份 KC（`5f558fcd`，06:57 与 07:33 逐字节相同）、同一份 bundle
（`NVRM` = `4a38ea572e3b66e39e6a2ce62e7e74701c4a092a6a83b9e7f5a862dcd4711eba`，17528944 B）、
同一份 boot-args、同一份 `/Library/Extensions` 列表，却在 06:56 能 attach、07:30 起不能。
→ 磁盘状态被排除，剩下的只能是 **NVRAM / 运行时状态**。

### 1.2 06:56 那次开机到底做到了哪一步

`diag-…065702.txt` L90-171（`kernel NV log`）里，06:56:09 连续输出：

```
rm_is_supported_device OK - this chip has a HAL and a GSP
rm_init_private_state OK
PASS 1 REACHED: RM initialised, private state built, GSP firmware requested
bus master + memory enabled (command 0x0006)
interrupt source 0 type 0x1 / interrupt source 1 type 0x10000 (MSI)
MSI 1 armed; calling rm_init_adapter() — GSP boot from inside macOS
nv_get_screen_info -> base 0x4000000000 2160x1440 depth 32 pitch 8640 size 12441600
RMRmSetupRegisters for 0x10de:0x25a9
registers look  like: 0x51000000 0x1000000
fb        looks like: 0x7e00000000 0x100000000
Successfully mapped framebuffer and registers
nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin
  vnode_open failed 2
Tearing down registers
```

即：**那次 attach 成功、RM 起来了、只差固件**。固件是 07:47 才装上的
（`results/fw-20261024-074709`），所以 **固件到现在一次都没被真正读过**。

### 1.3 07:30 起"什么都没发生"的现场

`diag-…073331.txt` L124-137：

```
07:30:09.308 syspolicyd  canLoadKernelExtension - direct, evaluate, Kext ((null), com.nullmoth.NVRM)
07:30:09.328 syspolicyd  Kernel Extension ALLOWED: ... NVRM
07:30:09.335 kernelmanagerd  Validate approval for /Library/Extensions/NVRM.kext in auxKC: approved
07:30:09.503 kernelmanagerd  error: tried to insert an invalid codeful kernel extension in the
                             restricted lookup table: Kext com.nullmoth.NVRM v0.1 ...
07:30:10.565 kernelmanagerd  Received kext load notification: com.nullmoth.NVRM
```

kext 确实加载了（`kextstat` 里一直在），但 **内核日志里连一行 `NVRM` 都没有**。

---

## 2. 根因：开机守卫（`kexts/NVRM/nvrm_off.h`）

`D:\Hactk\g1-stock-work\nm-lf\kexts\NVRM\nvrm_off.h:20-46`：

```c
#define NVRM_GUARD_VAR "nullmoth-nv-starts"
#define NVRM_GUARD_OK_VAR "nullmoth-nv-ok"
#define NVRM_GUARD_LIMIT 2

static inline bool nvrm_driver_off(void) {
    char arg[8];
    if (PE_parse_boot_argn("-nvoff", arg, sizeof arg)) return true;
    IORegistryEntry *options = IORegistryEntry::fromPath("/options", gIODTPlane);
    if (!options) return false;
    OSObject *flag = options->copyProperty("nullmoth-remove");
    const bool guard = nvrm_guard_starts(options) >= NVRM_GUARD_LIMIT;
    options->release();
    if (flag) { flag->release(); return true; }
    return guard;
}
```

调用点 `kexts/NVRM/NVRM.cpp:372-397`：

```c
IOService *NVRM::probe(IOService *provider, SInt32 *score)
{
    { if (nvrm_driver_off()) return NULL; }          // ← 这里是静默返回，一句 LOG 都没有
    ...
    LOG("probe %04x:%04x class %02x.%02x ...", ...);
}

bool NVRM::start(IOService *provider)
{
    { if (nvrm_driver_off()) return false; }
    nvrm_guard_count_start();                         // ← 每启动一次 +1
    ...
}
```

计数**只加不清**：只有 `NVRMFB` 点亮第一个 head（或者本卡没有 head 可点）时才调用
`nvrm_guard_display_up()`（`kexts/NVRMFB/fb/nvrm-fb.cpp:2995`）把变量删掉。
我们设备上 `/Library/Extensions` 只有 `HighPointIOP.kext`、`HighPointRR.kext`、`NVRM.kext`
—— **NVRMFB 根本没装**，所以计数只涨不落，两次开机后驱动就永久闭嘴。

这条链和现场完全对得上：

- `kextstat` 有 NVRM（kext 加载成功）✔
- `ioreg` 没有节点（`probe` 返回 NULL → 没 attach）✔
- 内核日志零行（返回点在第一个 `LOG` 之前）✔
- 磁盘一模一样却是 06:56 能、07:30 不能（差别只在 NVRAM 计数）✔
- 旁证：`diag-…073331.txt:109` `Sandbox: softwareupdated(106) deny(1) nvram-get nullmoth-nv-starts`
  —— 说明这个 NVRAM 变量确实存在（softwareupdated 在枚举 NVRAM 键）✔

**判定级别**：机制 = 源码已证实（SOURCE-REVIEW）；本机计数当前值 = 强推断，
一条命令即可证实（见下）。若 `nvram -p` 里没有 `nullmoth-nv-starts`，那这条推断被推翻，
回到"probe 因别的原因返回 NULL"，但那时日志里应能看到 `probe 10de:25a9 ...`（现在看不到）。

### 会不会是 `nullmoth-remove`？

`nvrm_off.h:41` 的 `copyProperty("nullmoth-remove")` 也会让驱动闭嘴。装驱动的
`install.sh` 在"移除驱动"流程里会写它。同样一条 `nvram -p | grep nullmoth` 就能分辨。

---

## 3. 撤回上一轮的一个错误判断

上一轮我把 `kernelmanagerd: tried to insert an invalid codeful kernel extension in the
restricted lookup table` 当成"我们的 kext 没签名"的线索。**这条是错的**：同一份报告里，
同一条错误也命中

- `com.highpoint-tech.kext.HighPointRR v4.22.1`（Apple 公证过，team `DX6G69M9N2`）
- `com.highpoint-tech.kext.HighPointIOP v4.4.5`（同上）
- `com.apple.driver.AppleMobileDevice v4.0`（**Apple 自己的 codeless kext**，
  `/Library/Apple/System/Library/Extensions/AppleMobileDevice.kext`）

→ 这是本机 AMFI 配置（boot-args 里 `amfi=0x80` + `amfi_get_out_of_my_way=0x1`）
下的普遍现象，**不是** NVRM 不 attach 的原因。签名假设从"待验证"降级为"基本无关"，
`sign` 步骤在新脚本里排到 `none` 之后。

---

## 4. 脚本 v2 的缺陷（已在 v3 修掉）

| 级别 | 缺陷 | 现象 | v3 修法 |
|---|---|---|---|
| P0 | `apply_step` 里用了 `$CYCLE`，但 `cmd_run` 从没设过它 | `line 92: CYCLE: unbound variable` → **签名一步根本没执行**，却照样重启 | `CYCLE=0 apply_step`，步骤内用 `${CYCLE:-0}` |
| P0 | 步骤失败被忽略，无条件重启 | 两步都崩，仍然重启两轮 | 返回值 0/1/2（成功/失败/跳过）；失败 → `STEP_FAILED`，不重启、结束 |
| P0 | `RunAtLoad` 让 daemon 在**装它的那次开机**里立刻跑 | `auto-…082410` 的 cyc0（08:24:10）和 cyc1（08:24:46）是**同一次开机**，白等 36 s 又白重启 | `state` 里记 `INSTALL_BOOT`，同一次开机直接退出 |
| P0 | 固定 `STATE=/var/tmp/g1-auto` + 固定 label | 08:24 和 08:27 两次 run 共用状态，后一次把前一次清掉、覆盖同一个 daemon plist | 每次 run 独立 `RUN`，state / runner / label 全部带 run id；已有循环在跑时拒绝启动（`--force` 覆盖） |
| P1 | 队列里排了 `reinstall`，但 U 盘上根本没有 `NVRM.kext` | 必然失败 | 有备用 bundle 才排；没有就跳过（计 2），不算失败 |
| P1 | 采集不含 NVRAM 守卫变量、不含加载来源 | 这轮最关键的变量没被采到 | 采集加 `nullmoth-*` 全量、`kmutil inspect` 加载来源、设备节点父子链 |
| P1 | `ioreg ... grep -c 'class NVRM'` 会被 `NVRMUserClient` 干扰 | 节点数偏大 | 改成 `grep -c 'class NVRM,'` |
| P2 | v2 的旧 label `com.g1.auto`（无 run 后缀）不会被 `stop` 清掉 | 残留 daemon 继续重启机器 | `remove_daemon` 显式清 `com.g1.auto` 和 `com.g1.auto.*` |

另外 v3 新增 `guard` 子命令，并在**每次重启前**清一次守卫计数——否则任何实验都在
`probe` 第一步就死掉。

---

## 5. 下一步（一条命令，只重启一次）

```bash
bash ./G1-自动实验.command guard      # 只打印 + 清 nullmoth-nv-starts / nullmoth-remove，不重启
bash ./G1-自动实验.command collect    # 零改动零重启，把当前状态采一份（含 nvram -p）
```

先跑这两条、把 `results/collect-*.txt` 发回来，确认守卫变量确实存在且已被清掉。
确认后：

```bash
bash ./G1-自动实验.command            # 队列 none → sign → rebuild；第一次重启只是"清完守卫再看"
```

预期：`none` 这一轮开机就会出现 `NVRM-xnu: probe 10de:25a9 ...` 和
`boot guard: start N ...`，然后走 `nv_get_firmware` —— **这是固件第一次被真正读取**。
可能出现的结果分三支（见 `POST-FIRMWARE-STEP2-20261024.md` 的 B/C 分支）。

> 注意：只要 NVRMFB 没装，守卫计数就一直没人清。所以每两次开机就要再清一次；
> 或者装上 NVRMFB 让 `nvrm_guard_display_up()` 接管（那是显示路径，风险更高，另议）。
