# 更正：`_rm_*` 在固定 OGKM 源码中有定义（R49）

## 上一份结论错在哪

R48 写"23 个 `_rm_*` 全树未定位，来源未知"。这是错的。真实原因是**两次检索方法错误**叠加：

1. 第一次用 `src\nvidia\**\*.c` 作路径——**PowerShell 不支持 `**` 递归**，实际只扫了下一层目录，
   `arch/nvalloc/unix/src/` 从未被扫描；
2. 第二次改成 `Get-ChildItem -Recurse`，却又用 `Select-Object -First 1` 取首个命中——
   `nv.h` 里的**声明**字母序在前，真正的**定义**被丢弃。

## 更正后的定义位置（固定提交 `e4a5faa`，1300 个 .c 文件，全递归）

| 符号 | 定义位置 |
|---|---|
| `rm_init_rm` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2754` |
| `rm_ioctl` | `osapi.c:2950` |
| `rm_stop_user_channels` | `osapi.c:2815` |
| `rm_restart_user_channels` | `osapi.c:2845` |
| `rm_power_management` | `src/nvidia/arch/nvalloc/unix/src/dynamic-power.c:2538` |
| `rm_isr` | `unix_intr.c:780` |
| `rm_isr_bh` | `unix_intr.c:830` |
| `rm_shutdown_adapter` | `osapi.c:1876` |
| `rm_init_adapter` | `osapi.c:1773` |
| `rm_is_supported_device` | `osapi.c:3693` |
| `rm_is_supported_pci_device` | `osapi.c:3840` |
| `rm_get_device_name` | `osapi.c:3567` |
| `rm_kernel_rmapi_op` | `osapi.c:5143` |
| `rm_execute_work_item` | `osapi.c:3550` |
| `rm_set_rm_firmware_requested` | `osapi.c:5106` |
| `rm_write_registry_dword` | `osapi.c:3206` |
| `rm_write_registry_string` | `osapi.c:3283` |
| `rm_perform_version_check` | `osapi.c:4498` |
| `rm_cleanup_file_private` | `osapi.c:3047` |
| `rm_free_private_state` | `osapi.c:1759` |
| `rm_init_private_state` | `osapi.c:1742` |
| `rm_init_event_locks` | `osapi.c:2783` |
| `rm_run_nano_timer_callback` | **仍未找到定义**（只有声明/引用） |

**22 / 23 有定义。** 它们位于 `arch/nvalloc/unix/src/`——正是 RM 的 Unix 适配层。

## 仍未找到的

| 符号 | 状态 |
|---|---|
| `rm_run_nano_timer_callback` | OGKM `src` 下未找到定义（可能是注册用名字或宏生成） |
| `nvKmsKapiProbe` | 未找到 |
| `nvKmsKapiSuspendResume` | 未找到 |
| `nvKmsKapiGetFunctionsTableInternal` | 未找到 |
| `nvKmsKapiHandleEventQueueChange` | 未找到 |

这次是用同样的全递归方法（1300 个 .c 文件）确认的，方法学错误已排除。

## 结论修正

- **`_rm_*` 不是结构性缺口**，是**构建闭包缺口**：源码在公开树里，能否在 macOS 内核编译是另一个问题。
- `_nvKmsKapi*`（4 个）仍是"公开树无定义"，但**证据强度提升了**（同一次严谨检索）。
- 因此 R48 那句"静态研发已经穷尽"**不成立**——至少还有 22 个函数可以逐个评估依赖与可移植性。

## 下一步（按验收单元，不再扩大）

1. 对 22 个函数逐个列出：定义位置、所在编译单元、依赖的 Linux/Unix 设施、是否已有 macOS 等价物；
2. 判断 `arch/nvalloc/unix/src/` 这一层能否整体纳入构建，还是必须逐个替换；
3. 只有在第 1–2 步有结论后，才谈"是否缩小 42 这个数字"。
