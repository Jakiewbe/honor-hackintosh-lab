# 装完固件、重启之后做什么（GLO-FX6P / RTX 2050）

状态基线：`results/diag-20261024-065702.txt`（macOS 15.8.1 24H32）
- NVRM 已加载（kextstat 163，0xe47ff8），设备节点在，IOProbeScore 1000
- RM 到 `PASS 1 REACHED`，BAR 映射成功，bus master + memory 使能，MSI armed
- 唯一失败点：`nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin` → `vnode_open failed 2`（ENOENT）→ `RmFetchGspRmImages: No firmware image found` → `RmInitAdapter failed! (0x61:0x56:2025)` → `auto-go: go(2) -> 0xe00002bc`
- head 0 / head 1 都是 `STOPPED`（vline raw 0xbadf1301）
- `/Library/Extensions` 里只有 HighPointIOP、HighPointRR、NVRM —— **NVRMFB / NVAccel 没装**
- 无 panic 文件

---

## 第 0 步：装完固件后的动作只有「重启」

固件是运行时可读文件，不在内核集合里，所以**不需要重建 KC**，重启即可让 `nv_get_firmware` 重新走一遍。

验证点（重启前就能查，可选）：

```bash
ls -l /Library/NullMoth/nvfw/nvidia/610.57.04/
# 期望 gsp_ga10x.bin 84310168 B，ucodes_ga10x.bin 31744 B，root:wheel 0644
```

## 第 1 步：重启后第一件事 —— 跑诊断，别看 ioreg 猜

```bash
bash ~/Desktop/honor-g1/G1-一键诊断.command     # v4
```

只读这 5 行（v4 结论区新增）：

| 行 | 通过值 | 含义 |
| --- | --- | --- |
| `GSP 固件已装载` | yes | `firmware loaded:` 出现，vnode 打开成功 |
| `RmInitAdapter 失败` | NO | 适配器初始化过，GSP 引导没有再退 |
| `head 没停(STOPPED)` | yes | `headwatch: head 0` 且没有 `STOPPED` |
| `panic 文件` | none | 本轮没有 panic |
| `NVRMFB/NVAccel 已安装` | 目前都是 NO | 这是下一关，不是本轮失败 |

返回码：`0` 全通（固件+适配器+head）、`9` 固件装上了但适配器还失败、`11` 适配器过了但 head 还停、`10` 出现 panic、`8` 还是缺固件。

把 `results/diag-<stamp>.txt` 发回。**不要**先跑 Metal 或 ioreg 看属性。

## 第 2 步：按返回码分支

### rc=0 固件 + 适配器 + head 都过
这一关过。接着是**装 NVRMFB / NVAccel**（现在缺），顺序不能反：

1. 用已构建的三件套（NVRM / NVRMFB / NVAccel，`kextutil -n` 各 0 unresolved）走加载实验脚本的 install 阶段；
2. 重建 AuxKC（`G1-修复加载.command` 同一路径）；
3. 重启；
4. 诊断确认 `NVRMFB 已安装 yes` / `NVAccel 已安装 yes`，且 kextstat 里三个都在；
5. 之后才轮到 Metal offscreen 验证器（`metal-offscreen.m`，需 `--execute-authorized --registry-id`，且 WindowServer 无头时会被 `nvmtl_process_is_allowed()` 拒）。

### rc=9 固件装上了，`rm_init_adapter` 仍 FAILED
固件缺失不再是原因。看诊断里「GSP / FSP / head 关键行」的**末尾错误码**，`0x61:0x56:2025` 会换一个值。
常见方向（未验证，按日志决定）：WPR/安全启动路径、固件版本与驱动不匹配（610.57.04 vs 615.78.08 陷阱）、GSP 引导超时。

### rc=11 适配器过了，head 仍 STOPPED
这是显示侧，不是 RM 侧。此时 GPU 已经在跑（`rm_init_adapter` 成功 = 有实算能力），head 停不影响 offscreen compute 的可行性 —— 但显示所有权仍归 Intel `8086:46A6`。

### rc=10 出现 panic
已知风险点，来自上游 `kexts/NVRM/patches/README.md:21`：

> 当 FSP 引导命令失败时，`kfspCleanupBootState` 从失败路径和 `kfspStateDestroy` 各跑一次，第二次 `tmrEventDestroy` 在已释放的 OS timer 上 fault（page fault at `0x1010` in `nv_destroy_nano_timer`）。补丁 `610-fsp-timer-double-destroy.patch` 改为只销毁一次、取消后清句柄。

**未验证**：我们这次装的 NVRM 是否含这个补丁。RM 源码树不在仓库里（是构建输入），`grep kfspCleanupBootState` 在本地候选源里无命中。若 panic 栈里出现 `nv_destroy_nano_timer` / `0x1010`，就是这个 bug，需要在 open-gpu-kernel-modules 610.57.04 树上打补丁后重编 RM 对象。

恢复（不重装系统）：
```bash
# 最快：boot-args 关掉自动 go，让 RM 停在 PASS 1，系统照常开机
sudo nvram boot-args="$(nvram boot-args | sed 's/boot-args\t//') -nvrmnogo"
# 或走加载实验的 rollback，把 NVRM 从扩展目录移走并重建 AuxKC
bash ~/Desktop/honor-g1/G1-加载实验.command
```

## 第 3 步：这一关过后剩下的门（按序，不跳）

| # | 门 | 判据 | 现状 |
| --- | --- | --- | --- |
| 1 | GSP 固件装载 | `firmware loaded:` | 待本轮 |
| 2 | RmInitAdapter | 无 `rm_init_adapter -> FAILED` | 待本轮 |
| 3 | head / display pipe | `headwatch: head 0` 非 STOPPED | 当前 STOPPED |
| 4 | NVRMFB + NVAccel 入 KC | kextstat 三个都在 | 未安装 |
| 5 | Metal 设备可见 | `MTLCopyAllDevices` 非空 | Metal 未跑 |
| 6 | offscreen 计算 | `program_executed=YES` / `gpu_executed=YES`，结果回读正确 | 未跑 |
| 7 | 错误传播 / 安全关机 | 注入错误有返回码；sleep/wake 不 panic | 未验证 |

## 边界

- 第 0–2 步都在已授权的设备实验范围内；`kextutil -n` 是非加载 dry run，安全。
- 装 NVRMFB/NVAccel、重建 KC、跑 Metal 各自独立授权，不要一次全做 —— 每一步失败原因要能定位到单一变量。
- 不碰 Windows/ESP/BCD/EFI/OpenCore/BIOS/SIP/NVRAM（`-nvrmnogo` 除外，那是文档化的回退开关）。
