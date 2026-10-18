# G1 逐符号依赖表（机器生成）

仅为固定源码的词法审计；不是预处理、ABI 或运行验收。全部命中、参数、直接 include 和源哈希见 JSON。

| 符号 | OGKM 定义 | RM runtime 宏 | Darwin 同名依赖候选 |
|---|---|---|---|
| `nvKmsClose` | `src/nvidia-modeset/src/nvkms.c:5254` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsGetBacklight` | `src/nvidia-modeset/src/nvkms.c:7053` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsIoctl` | `src/nvidia-modeset/src/nvkms.c:5049` | 未直接调用 | nvkms_copyin, nvkms_copyout |
| `nvKmsKapiGetFunctionsTableInternal` | `src/nvidia-modeset/kapi/src/nvkms-kapi.c:4122` | 未直接调用 | nvkms_allow_write_combining, nvkms_strcmp |
| `nvKmsKapiHandleEventQueueChange` | `src/nvidia-modeset/kapi/src/nvkms-kapi.c:3827` | 未直接调用 | eventCallback, nvkms_ioctl_from_kapi |
| `nvKmsKapiProbe` | `src/nvidia-modeset/kapi/src/nvkms-kapi.c:3978` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsKapiSuspendResume` | `src/nvidia-modeset/kapi/src/nvkms-kapi.c:3946` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsModuleLoad` | `src/nvidia-modeset/src/nvkms.c:6366` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsOpen` | `src/nvidia-modeset/src/nvkms.c:5344` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsResume` | `src/nvidia-modeset/src/nvkms.c:6910` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsSetBacklight` | `src/nvidia-modeset/src/nvkms.c:7075` | 未直接调用 | 未命中（不等于实现不存在） |
| `nvKmsSuspend` | `src/nvidia-modeset/src/nvkms.c:6873` | 未直接调用 | 未命中（不等于实现不存在） |
| `rm_cleanup_file_private` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3047` | 是 | nv_put_file_private, os_free_mem |
| `rm_execute_work_item` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3550` | 是 | 未命中（不等于实现不存在） |
| `rm_free_private_state` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:1759` | 是 | 未命中（不等于实现不存在） |
| `rm_get_device_name` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3567` | 未直接调用 | 未命中（不等于实现不存在） |
| `rm_init_adapter` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:1773` | 是 | os_disable_console_access, os_enable_console_access |
| `rm_init_event_locks` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2783` | 是 | 未命中（不等于实现不存在） |
| `rm_init_private_state` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:1742` | 是 | 未命中（不等于实现不存在） |
| `rm_init_rm` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2754` | 是 | 未命中（不等于实现不存在） |
| `rm_ioctl` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2950` | 是 | 未命中（不等于实现不存在） |
| `rm_is_supported_device` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3693` | 是 | nv_printf |
| `rm_is_supported_pci_device` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3840` | 未直接调用 | 未命中（不等于实现不存在） |
| `rm_isr` | `src/nvidia/arch/nvalloc/unix/src/unix_intr.c:780` | 是 | 未命中（不等于实现不存在） |
| `rm_isr_bh` | `src/nvidia/arch/nvalloc/unix/src/unix_intr.c:830` | 是 | 未命中（不等于实现不存在） |
| `rm_kernel_rmapi_op` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:5143` | 是 | os_free_mem |
| `rm_perform_version_check` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:4498` | 是 | 未命中（不等于实现不存在） |
| `rm_power_management` | `src/nvidia/arch/nvalloc/unix/src/dynamic-power.c:2538` | 是 | os_disable_console_access, os_enable_console_access, os_flush_work_queue |
| `rm_restart_user_channels` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2845` | 是 | 未命中（不等于实现不存在） |
| `rm_run_nano_timer_callback` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3518` | 是 | 未命中（不等于实现不存在） |
| `rm_set_rm_firmware_requested` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:5106` | 未直接调用 | 未命中（不等于实现不存在） |
| `rm_shutdown_adapter` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:1876` | 是 | os_disable_console_access, os_enable_console_access |
| `rm_stop_user_channels` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:2815` | 是 | 未命中（不等于实现不存在） |
| `rm_write_registry_dword` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3206` | 是 | 未命中（不等于实现不存在） |
| `rm_write_registry_string` | `src/nvidia/arch/nvalloc/unix/src/osapi.c:3283` | 是 | 未命中（不等于实现不存在） |

所有调用形标识符均保留在 JSON；同名候选尚未核对 ABI。
