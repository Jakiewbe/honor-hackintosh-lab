; ModuleID = '/Users/runner/work/_temp/nullmoth-v2.3.3-gpu-safety-r5-candidate/kexts/NVRM/os-xnu.cpp'
source_filename = "/Users/runner/work/_temp/nullmoth-v2.3.3-gpu-safety-r5-candidate/kexts/NVRM/os-xnu.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.5.0"

%struct.anon = type { i32, [256 x i8] }
%struct.nv_xnu_pci_slot = type { ptr, i32, i8, i8, i8 }
%struct.nv_xnu_map = type { ptr, ptr, ptr, i64, i64, ptr }
%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@os_page_size = local_unnamed_addr global i64 4096, align 8
@os_page_mask = local_unnamed_addr global i64 -4096, align 8
@os_page_shift = local_unnamed_addr global i8 12, align 1
@os_max_page_size = local_unnamed_addr global i64 4096, align 8
@_ZZ12os_alloc_memE2_t = internal unnamed_addr global i1 false, align 1
@.str = private unnamed_addr constant [15 x i8] c"NVRM-xnu: >%s\0A\00", align 1
@__func__.os_alloc_mem = private unnamed_addr constant [13 x i8] c"os_alloc_mem\00", align 1
@_ZZ11os_free_memE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_free_mem = private unnamed_addr constant [12 x i8] c"os_free_mem\00", align 1
@_ZZ11os_mem_copyE1n = internal unnamed_addr global i64 0, align 8
@.str.1 = private unnamed_addr constant [36 x i8] c"NVRM-xnu: >os_mem_copy #%lu len=%u\0A\00", align 1
@_ZZ19os_memcpy_from_userE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_memcpy_from_user = private unnamed_addr constant [20 x i8] c"os_memcpy_from_user\00", align 1
@_ZZ17os_memcpy_to_userE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_memcpy_to_user = private unnamed_addr constant [18 x i8] c"os_memcpy_to_user\00", align 1
@_ZZ10os_mem_setE1n = internal unnamed_addr global i64 0, align 8
@.str.2 = private unnamed_addr constant [35 x i8] c"NVRM-xnu: >os_mem_set #%lu len=%u\0A\00", align 1
@_ZZ10os_mem_cmpE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_mem_cmp = private unnamed_addr constant [11 x i8] c"os_mem_cmp\00", align 1
@_ZZ16os_string_lengthE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_string_length = private unnamed_addr constant [17 x i8] c"os_string_length\00", align 1
@_ZZ14os_string_copyE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_string_copy = private unnamed_addr constant [15 x i8] c"os_string_copy\00", align 1
@_ZZ17os_string_compareE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_string_compare = private unnamed_addr constant [18 x i8] c"os_string_compare\00", align 1
@_ZZ11os_snprintfE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_snprintf = private unnamed_addr constant [12 x i8] c"os_snprintf\00", align 1
@_ZZ16os_get_cpu_countE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_cpu_count = private unnamed_addr constant [17 x i8] c"os_get_cpu_count\00", align 1
@_ZZ17os_get_cpu_numberE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_cpu_number = private unnamed_addr constant [18 x i8] c"os_get_cpu_number\00", align 1
@_ZZ9nv_printfE2_t = internal unnamed_addr global i1 false, align 1
@__func__.nv_printf = private unnamed_addr constant [10 x i8] c"nv_printf\00", align 1
@.str.3 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@_ZZ12nv_log_errorE2_t = internal unnamed_addr global i1 false, align 1
@__func__.nv_log_error = private unnamed_addr constant [13 x i8] c"nv_log_error\00", align 1
@.str.4 = private unnamed_addr constant [18 x i8] c"NVRM: Xid %u: %s\0A\00", align 1
@_ZL15nv_xnu_log_call = internal unnamed_addr global ptr null, align 8
@_ZL15nv_xnu_log_head = internal global i32 0, align 4
@_ZL15nv_xnu_log_ring = internal global [256 x %struct.anon] zeroinitializer, align 16
@_ZL18nv_xnu_log_dropped = internal global i32 0, align 4
@_ZZ11os_dbg_initE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_dbg_init = private unnamed_addr constant [12 x i8] c"os_dbg_init\00", align 1
@_ZZ16os_dbg_set_levelE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_dbg_set_level = private unnamed_addr constant [17 x i8] c"os_dbg_set_level\00", align 1
@_ZZ17os_dbg_breakpointE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_dbg_breakpoint = private unnamed_addr constant [18 x i8] c"os_dbg_breakpoint\00", align 1
@.str.5 = private unnamed_addr constant [29 x i8] c"NVRM-xnu: os_dbg_breakpoint\0A\00", align 1
@_ZZ14os_alloc_mutexE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_alloc_mutex = private unnamed_addr constant [15 x i8] c"os_alloc_mutex\00", align 1
@_ZZ13os_free_mutexE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_free_mutex = private unnamed_addr constant [14 x i8] c"os_free_mutex\00", align 1
@_ZZ16os_acquire_mutexE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_acquire_mutex = private unnamed_addr constant [17 x i8] c"os_acquire_mutex\00", align 1
@_ZZ21os_cond_acquire_mutexE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_cond_acquire_mutex = private unnamed_addr constant [22 x i8] c"os_cond_acquire_mutex\00", align 1
@_ZZ16os_release_mutexE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_release_mutex = private unnamed_addr constant [17 x i8] c"os_release_mutex\00", align 1
@_ZZ17os_alloc_spinlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_alloc_spinlock = private unnamed_addr constant [18 x i8] c"os_alloc_spinlock\00", align 1
@_ZZ16os_free_spinlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_free_spinlock = private unnamed_addr constant [17 x i8] c"os_free_spinlock\00", align 1
@_ZZ19os_acquire_spinlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_acquire_spinlock = private unnamed_addr constant [20 x i8] c"os_acquire_spinlock\00", align 1
@_ZZ19os_release_spinlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_release_spinlock = private unnamed_addr constant [20 x i8] c"os_release_spinlock\00", align 1
@_ZZ15os_alloc_rwlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_alloc_rwlock = private unnamed_addr constant [16 x i8] c"os_alloc_rwlock\00", align 1
@_ZZ14os_free_rwlockE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_free_rwlock = private unnamed_addr constant [15 x i8] c"os_free_rwlock\00", align 1
@_ZZ22os_acquire_rwlock_readE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_acquire_rwlock_read = private unnamed_addr constant [23 x i8] c"os_acquire_rwlock_read\00", align 1
@_ZZ23os_acquire_rwlock_writeE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_acquire_rwlock_write = private unnamed_addr constant [24 x i8] c"os_acquire_rwlock_write\00", align 1
@_ZZ27os_cond_acquire_rwlock_readE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_cond_acquire_rwlock_read = private unnamed_addr constant [28 x i8] c"os_cond_acquire_rwlock_read\00", align 1
@_ZZ28os_cond_acquire_rwlock_writeE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_cond_acquire_rwlock_write = private unnamed_addr constant [29 x i8] c"os_cond_acquire_rwlock_write\00", align 1
@_ZZ22os_release_rwlock_readE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_release_rwlock_read = private unnamed_addr constant [23 x i8] c"os_release_rwlock_read\00", align 1
@_ZZ23os_release_rwlock_writeE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_release_rwlock_write = private unnamed_addr constant [24 x i8] c"os_release_rwlock_write\00", align 1
@_ZZ18os_alloc_semaphoreE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_alloc_semaphore = private unnamed_addr constant [19 x i8] c"os_alloc_semaphore\00", align 1
@kernel_task = external local_unnamed_addr global ptr, align 8
@_ZZ17os_free_semaphoreE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_free_semaphore = private unnamed_addr constant [18 x i8] c"os_free_semaphore\00", align 1
@_ZZ20os_acquire_semaphoreE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_acquire_semaphore = private unnamed_addr constant [21 x i8] c"os_acquire_semaphore\00", align 1
@_ZZ25os_cond_acquire_semaphoreE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_cond_acquire_semaphore = private unnamed_addr constant [26 x i8] c"os_cond_acquire_semaphore\00", align 1
@_ZZ20os_release_semaphoreE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_release_semaphore = private unnamed_addr constant [21 x i8] c"os_release_semaphore\00", align 1
@_ZZ22os_semaphore_may_sleepE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_semaphore_may_sleep = private unnamed_addr constant [23 x i8] c"os_semaphore_may_sleep\00", align 1
@nv_xnu_isr_thread = global ptr null, align 8
@nv_xnu_in_isr = local_unnamed_addr global i32 0, align 4
@_ZZ19os_is_administratorE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_is_administrator = private unnamed_addr constant [20 x i8] c"os_is_administrator\00", align 1
@_ZZ11os_get_euidE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_euid = private unnamed_addr constant [12 x i8] c"os_get_euid\00", align 1
@_ZZ24os_get_monotonic_time_nsE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_monotonic_time_ns = private unnamed_addr constant [25 x i8] c"os_get_monotonic_time_ns\00", align 1
@_ZZ27os_get_monotonic_time_ns_hrE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_monotonic_time_ns_hr = private unnamed_addr constant [28 x i8] c"os_get_monotonic_time_ns_hr\00", align 1
@_ZZ18os_get_system_timeE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_system_time = private unnamed_addr constant [19 x i8] c"os_get_system_time\00", align 1
@_ZZ22nv_is_chassis_notebookE2_t = internal unnamed_addr global i1 false, align 1
@__func__.nv_is_chassis_notebook = private unnamed_addr constant [23 x i8] c"nv_is_chassis_notebook\00", align 1
@_ZZ26nv_acpi_is_battery_presentE2_t = internal unnamed_addr global i1 false, align 1
@__func__.nv_acpi_is_battery_present = private unnamed_addr constant [27 x i8] c"nv_acpi_is_battery_present\00", align 1
@_ZZ25nv_platform_supports_s0ixE2_t = internal unnamed_addr global i1 false, align 1
@__func__.nv_platform_supports_s0ix = private unnamed_addr constant [26 x i8] c"nv_platform_supports_s0ix\00", align 1
@_ZZ22os_is_nvswitch_presentE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_is_nvswitch_present = private unnamed_addr constant [23 x i8] c"os_is_nvswitch_present\00", align 1
@_ZZ8os_delayE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_delay = private unnamed_addr constant [9 x i8] c"os_delay\00", align 1
@_ZZ11os_delay_usE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_delay_us = private unnamed_addr constant [12 x i8] c"os_delay_us\00", align 1
@_ZZ20os_get_cpu_frequencyE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_cpu_frequency = private unnamed_addr constant [21 x i8] c"os_get_cpu_frequency\00", align 1
@_ZZ22os_get_current_processE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_current_process = private unnamed_addr constant [23 x i8] c"os_get_current_process\00", align 1
@_ZZ27os_get_current_process_nameE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_current_process_name = private unnamed_addr constant [28 x i8] c"os_get_current_process_name\00", align 1
@_ZZ21os_get_current_threadE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_current_thread = private unnamed_addr constant [22 x i8] c"os_get_current_thread\00", align 1
@_ZZ15os_get_pid_infoE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_pid_info = private unnamed_addr constant [16 x i8] c"os_get_pid_info\00", align 1
@_ZZ15os_put_pid_infoE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_put_pid_info = private unnamed_addr constant [16 x i8] c"os_put_pid_info\00", align 1
@_ZZ14os_find_ns_pidE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_find_ns_pid = private unnamed_addr constant [15 x i8] c"os_find_ns_pid\00", align 1
@_ZZ19os_get_random_bytesE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_random_bytes = private unnamed_addr constant [20 x i8] c"os_get_random_bytes\00", align 1
@_ZL13nv_xnu_nslots = internal unnamed_addr global i32 0, align 4
@_ZL12nv_xnu_slots = internal global [256 x %struct.nv_xnu_pci_slot] zeroinitializer, align 16
@.str.6 = private unnamed_addr constant [12 x i8] c"IOPCIDevice\00", align 1
@_ZN11IOPCIDevice9metaClassE = external local_unnamed_addr constant ptr, align 8
@_ZZ18os_pci_init_handleE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_init_handle = private unnamed_addr constant [19 x i8] c"os_pci_init_handle\00", align 1
@_ZZ16os_pci_read_byteE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_read_byte = private unnamed_addr constant [17 x i8] c"os_pci_read_byte\00", align 1
@_ZZ16os_pci_read_byteE2_w = internal unnamed_addr global i1 false, align 1
@.str.7 = private unnamed_addr constant [31 x i8] c"NVRM-xnu: %s: NULL pci handle\0A\00", align 1
@_ZZ16os_pci_read_wordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_read_word = private unnamed_addr constant [17 x i8] c"os_pci_read_word\00", align 1
@_ZZ16os_pci_read_wordE2_w = internal unnamed_addr global i1 false, align 1
@_ZZ17os_pci_read_dwordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_read_dword = private unnamed_addr constant [18 x i8] c"os_pci_read_dword\00", align 1
@_ZZ17os_pci_read_dwordE2_w = internal unnamed_addr global i1 false, align 1
@_ZZ17os_pci_write_byteE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_write_byte = private unnamed_addr constant [18 x i8] c"os_pci_write_byte\00", align 1
@_ZZ17os_pci_write_byteE2_w = internal unnamed_addr global i1 false, align 1
@_ZZ17os_pci_write_wordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_write_word = private unnamed_addr constant [18 x i8] c"os_pci_write_word\00", align 1
@_ZZ17os_pci_write_wordE2_w = internal unnamed_addr global i1 false, align 1
@_ZZ18os_pci_write_dwordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_pci_write_dword = private unnamed_addr constant [19 x i8] c"os_pci_write_dword\00", align 1
@_ZZ18os_pci_write_dwordE2_w = internal unnamed_addr global i1 false, align 1
@.str.8 = private unnamed_addr constant [65 x i8] c"NVRM-xnu: >os_map_kernel_space start=0x%llx size=0x%llx mode=%u\0A\00", align 1
@_ZL11nv_xnu_maps = internal unnamed_addr global [8192 x %struct.nv_xnu_map] zeroinitializer, align 16
@_ZL16nv_xnu_maps_high = internal unnamed_addr global i32 0, align 4
@.str.9 = private unnamed_addr constant [40 x i8] c"NVRM-xnu:   withPhysicalAddress FAILED\0A\00", align 1
@.str.10 = private unnamed_addr constant [40 x i8] c"NVRM-xnu:   md->map(cache=0x%x) FAILED\0A\00", align 1
@.str.11 = private unnamed_addr constant [58 x i8] c"NVRM-xnu:   mapped -> 0x%llx (slot %d, high water %u/%u)\0A\00", align 1
@_ZZ19os_map_kernel_spaceE6warned = internal unnamed_addr global i1 false, align 1
@.str.12 = private unnamed_addr constant [159 x i8] c"NVRM-xnu: *** nv_xnu_maps FULL at %u entries -- leaking bookkeeping for 0x%llx (+0x%llx). The mapping is still VALID and returned; raise NV_XNU_MAX_MAPS. ***\0A\00", align 1
@_ZZ21os_unmap_kernel_spaceE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_unmap_kernel_space = private unnamed_addr constant [22 x i8] c"os_unmap_kernel_space\00", align 1
@_ZZ16os_io_write_byteE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_write_byte = private unnamed_addr constant [17 x i8] c"os_io_write_byte\00", align 1
@_ZZ16os_io_write_wordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_write_word = private unnamed_addr constant [17 x i8] c"os_io_write_word\00", align 1
@_ZZ17os_io_write_dwordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_write_dword = private unnamed_addr constant [18 x i8] c"os_io_write_dword\00", align 1
@_ZZ15os_io_read_byteE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_read_byte = private unnamed_addr constant [16 x i8] c"os_io_read_byte\00", align 1
@_ZZ15os_io_read_wordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_read_word = private unnamed_addr constant [16 x i8] c"os_io_read_word\00", align 1
@_ZZ16os_io_read_dwordE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_io_read_dword = private unnamed_addr constant [17 x i8] c"os_io_read_dword\00", align 1
@_ZZ16os_registry_initE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_registry_init = private unnamed_addr constant [17 x i8] c"os_registry_init\00", align 1
@_ZZ15os_is_vgx_hyperE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_is_vgx_hyper = private unnamed_addr constant [16 x i8] c"os_is_vgx_hyper\00", align 1
@_ZZ20os_is_grid_supportedE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_is_grid_supported = private unnamed_addr constant [21 x i8] c"os_is_grid_supported\00", align 1
@_ZZ17os_is_efi_enabledE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_is_efi_enabled = private unnamed_addr constant [18 x i8] c"os_is_efi_enabled\00", align 1
@_ZZ16os_get_is_openrmE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_get_is_openrm = private unnamed_addr constant [17 x i8] c"os_get_is_openrm\00", align 1
@_ZZ25os_disable_console_accessE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_disable_console_access = private unnamed_addr constant [26 x i8] c"os_disable_console_access\00", align 1
@_ZZ24os_enable_console_accessE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_enable_console_access = private unnamed_addr constant [25 x i8] c"os_enable_console_access\00", align 1
@_ZZ22os_flush_cpu_cache_allE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_flush_cpu_cache_all = private unnamed_addr constant [23 x i8] c"os_flush_cpu_cache_all\00", align 1
@_ZZ19os_flush_user_cacheE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_flush_user_cache = private unnamed_addr constant [20 x i8] c"os_flush_user_cache\00", align 1
@_ZZ33os_flush_cpu_write_combine_bufferE2_t = internal unnamed_addr global i1 false, align 1
@__func__.os_flush_cpu_write_combine_buffer = private unnamed_addr constant [34 x i8] c"os_flush_cpu_write_combine_buffer\00", align 1
@_ZL19nv_xnu_log_draining = internal global i32 0, align 4
@_ZL15nv_xnu_log_tail = internal global i32 0, align 4
@.str.15 = private unnamed_addr constant [81 x i8] c"NVRM-xnu: out_string ring full -- %u RM line(s) dropped (serial still has them)\0A\00", align 1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 82) i32 @os_alloc_mem(ptr nocapture noundef writeonly %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ12os_alloc_memE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ12os_alloc_memE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_alloc_mem) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = tail call ptr @kern_os_malloc(i64 noundef %1) #10
  store ptr %6, ptr %0, align 8, !tbaa !4
  %7 = icmp eq ptr %6, null
  br i1 %7, label %10, label %8

8:                                                ; preds = %5
  %9 = tail call { ptr, i64 } asm sideeffect "rep stosb", "={di},={cx},{ax},0,1,~{memory},~{dirflag},~{fpsr},~{flags}"(i32 0, ptr nonnull %6, i64 %1) #11, !srcloc !8
  br label %10

10:                                               ; preds = %5, %8
  %11 = phi i32 [ 0, %8 ], [ 81, %5 ]
  ret i32 %11
}

; Function Attrs: noimplicitfloat noredzone
declare void @kprintf(ptr noundef, ...) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare ptr @kern_os_malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_free_mem(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ11os_free_memE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ11os_free_memE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_free_mem) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %7, label %6

6:                                                ; preds = %4
  tail call void @kern_os_free(ptr noundef nonnull %0) #10
  br label %7

7:                                                ; preds = %6, %4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @kern_os_free(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @os_mem_copy(ptr noundef returned %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i64, ptr @_ZZ11os_mem_copyE1n, align 8, !tbaa !9
  %5 = add i64 %4, 1
  store i64 %5, ptr @_ZZ11os_mem_copyE1n, align 8, !tbaa !9
  %6 = icmp ult i64 %5, 5
  %7 = urem i64 %5, 1000000
  %8 = icmp eq i64 %7, 0
  %9 = or i1 %6, %8
  br i1 %9, label %10, label %11

10:                                               ; preds = %3
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.1, i64 noundef %5, i32 noundef %2) #10
  br label %11

11:                                               ; preds = %3, %10
  %12 = zext i32 %2 to i64
  %13 = tail call { ptr, ptr, i64 } asm sideeffect "rep movsb", "={di},={si},={cx},0,1,2,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr %0, ptr %1, i64 %12) #11, !srcloc !11
  ret ptr %0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 31) i32 @os_memcpy_from_user(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ19os_memcpy_from_userE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ19os_memcpy_from_userE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_memcpy_from_user) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = zext i32 %2 to i64
  %8 = ptrtoint ptr %1 to i64
  %9 = tail call i32 @copyin(i64 noundef %8, ptr noundef %0, i64 noundef %7) #10
  %10 = icmp eq i32 %9, 0
  %11 = select i1 %10, i32 0, i32 30
  ret i32 %11
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 31) i32 @os_memcpy_to_user(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ17os_memcpy_to_userE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ17os_memcpy_to_userE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_memcpy_to_user) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = zext i32 %2 to i64
  %8 = ptrtoint ptr %0 to i64
  %9 = tail call i32 @copyout(ptr noundef %1, i64 noundef %8, i64 noundef %7) #10
  %10 = icmp eq i32 %9, 0
  %11 = select i1 %10, i32 0, i32 30
  ret i32 %11
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @os_mem_set(ptr noundef returned %0, i8 noundef zeroext %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i64, ptr @_ZZ10os_mem_setE1n, align 8, !tbaa !9
  %5 = add i64 %4, 1
  store i64 %5, ptr @_ZZ10os_mem_setE1n, align 8, !tbaa !9
  %6 = icmp ult i64 %5, 5
  %7 = urem i64 %5, 1000000
  %8 = icmp eq i64 %7, 0
  %9 = or i1 %6, %8
  br i1 %9, label %10, label %11

10:                                               ; preds = %3
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.2, i64 noundef %5, i32 noundef %2) #10
  br label %11

11:                                               ; preds = %3, %10
  %12 = zext i8 %1 to i32
  %13 = zext i32 %2 to i64
  %14 = tail call { ptr, i64 } asm sideeffect "rep stosb", "={di},={cx},{ax},0,1,~{memory},~{dirflag},~{fpsr},~{flags}"(i32 %12, ptr %0, i64 %13) #11, !srcloc !8
  ret ptr %0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_mem_cmp(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ10os_mem_cmpE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ10os_mem_cmpE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_mem_cmp) #10
  br label %6

6:                                                ; preds = %3, %5
  %7 = zext i32 %2 to i64
  %8 = tail call i32 @memcmp(ptr noundef %0, ptr noundef %1, i64 noundef %7) #10
  ret i32 %8
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_string_length(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_string_lengthE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_string_lengthE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_string_length) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call i64 @strlen(ptr noundef %0) #10
  %6 = trunc i64 %5 to i32
  ret i32 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef ptr @os_string_copy(ptr noundef returned writeonly %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ14os_string_copyE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ14os_string_copyE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_string_copy) #10
  br label %5

5:                                                ; preds = %2, %4
  br label %6

6:                                                ; preds = %5, %6
  %7 = phi ptr [ %9, %6 ], [ %1, %5 ]
  %8 = phi ptr [ %11, %6 ], [ %0, %5 ]
  %9 = getelementptr inbounds i8, ptr %7, i64 1
  %10 = load i8, ptr %7, align 1, !tbaa !12
  %11 = getelementptr inbounds i8, ptr %8, i64 1
  store i8 %10, ptr %8, align 1, !tbaa !12
  %12 = icmp eq i8 %10, 0
  br i1 %12, label %13, label %6, !llvm.loop !13

13:                                               ; preds = %6
  ret ptr %0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_string_compare(ptr noundef %0, ptr noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ17os_string_compareE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ17os_string_compareE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_string_compare) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = tail call i32 @strcmp(ptr noundef %0, ptr noundef %1) #10
  ret i32 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_snprintf(ptr noundef %0, i32 noundef %1, ptr noundef %2, ...) local_unnamed_addr #0 {
  %4 = alloca [1 x %struct.__va_list_tag], align 16
  %5 = load i1, ptr @_ZZ11os_snprintfE2_t, align 1
  br i1 %5, label %7, label %6

6:                                                ; preds = %3
  store i1 true, ptr @_ZZ11os_snprintfE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_snprintf) #10
  br label %7

7:                                                ; preds = %3, %6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #11
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %4, i8 0, i64 24, i1 false), !annotation !15
  call void @llvm.va_start.p0(ptr nonnull %4)
  %8 = zext i32 %1 to i64
  %9 = call i32 @vsnprintf(ptr noundef %0, i64 noundef %8, ptr noundef %2, ptr noundef nonnull %4) #10
  call void @llvm.va_end.p0(ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #11
  ret i32 %9
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #4

; Function Attrs: noimplicitfloat noredzone
declare i32 @vsnprintf(ptr noundef, i64 noundef, ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #4

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_cpu_count() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ16os_get_cpu_countE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ16os_get_cpu_countE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_cpu_count) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i32 4
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_cpu_number() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ17os_get_cpu_numberE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ17os_get_cpu_numberE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_cpu_number) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @nv_printf(i32 noundef %0, ptr noundef %1, ...) local_unnamed_addr #0 {
  %3 = alloca [512 x i8], align 16
  %4 = alloca [1 x %struct.__va_list_tag], align 16
  %5 = load i1, ptr @_ZZ9nv_printfE2_t, align 1
  br i1 %5, label %7, label %6

6:                                                ; preds = %2
  store i1 true, ptr @_ZZ9nv_printfE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.nv_printf) #10
  br label %7

7:                                                ; preds = %2, %6
  call void @llvm.lifetime.start.p0(i64 512, ptr nonnull %3) #11
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(512) %3, i8 0, i64 512, i1 false), !annotation !15
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #11
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %4, i8 0, i64 24, i1 false), !annotation !15
  call void @llvm.va_start.p0(ptr nonnull %4)
  %8 = call i32 @vsnprintf(ptr noundef nonnull %3, i64 noundef 512, ptr noundef %1, ptr noundef nonnull %4) #10
  call void @llvm.va_end.p0(ptr nonnull %4)
  %9 = getelementptr inbounds i8, ptr %3, i64 511
  store i8 0, ptr %9, align 1, !tbaa !12
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.3, ptr noundef nonnull %3) #10
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.3, ptr noundef nonnull %3) #10
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #11
  call void @llvm.lifetime.end.p0(i64 512, ptr nonnull %3) #11
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLog(ptr noundef, ...) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @nv_log_error(ptr nocapture noundef readnone %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) local_unnamed_addr #0 {
  %5 = alloca [512 x i8], align 16
  %6 = load i1, ptr @_ZZ12nv_log_errorE2_t, align 1
  br i1 %6, label %8, label %7

7:                                                ; preds = %4
  store i1 true, ptr @_ZZ12nv_log_errorE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.nv_log_error) #10
  br label %8

8:                                                ; preds = %4, %7
  call void @llvm.lifetime.start.p0(i64 512, ptr nonnull %5) #11
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(512) %5, i8 0, i64 512, i1 false), !annotation !15
  %9 = call i32 @vsnprintf(ptr noundef nonnull %5, i64 noundef 512, ptr noundef %2, ptr noundef %3) #10
  %10 = getelementptr inbounds i8, ptr %5, i64 511
  store i8 0, ptr %10, align 1, !tbaa !12
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.4, i32 noundef %1, ptr noundef nonnull %5) #10
  call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.4, i32 noundef %1, ptr noundef nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 512, ptr nonnull %5) #11
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @nv_xnu_log_init() local_unnamed_addr #0 {
  %1 = load ptr, ptr @_ZL15nv_xnu_log_call, align 8, !tbaa !4
  %2 = icmp eq ptr %1, null
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call ptr @thread_call_allocate(ptr noundef nonnull @_ZL16nv_xnu_log_drainPvS_, ptr noundef null) #10
  store ptr %4, ptr @_ZL15nv_xnu_log_call, align 8, !tbaa !4
  br label %5

5:                                                ; preds = %3, %0
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @thread_call_allocate(ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define internal void @_ZL16nv_xnu_log_drainPvS_(ptr nocapture readnone %0, ptr nocapture readnone %1) #0 {
  %3 = atomicrmw volatile xchg ptr @_ZL19nv_xnu_log_draining, i32 1 acquire, align 4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %28

5:                                                ; preds = %2
  %6 = load volatile i32, ptr @_ZL15nv_xnu_log_tail, align 4, !tbaa !16
  %7 = and i32 %6, 255
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [256 x %struct.anon], ptr @_ZL15nv_xnu_log_ring, i64 0, i64 %8
  %10 = load atomic volatile i32, ptr %9 acquire, align 4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %23, label %12

12:                                               ; preds = %5, %12
  %13 = phi ptr [ %20, %12 ], [ %9, %5 ]
  %14 = phi i32 [ %17, %12 ], [ %6, %5 ]
  %15 = getelementptr inbounds i8, ptr %13, i64 4
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.3, ptr noundef nonnull %15) #10
  store atomic volatile i32 0, ptr %13 release, align 4
  %16 = add i32 %14, 1
  store volatile i32 %16, ptr @_ZL15nv_xnu_log_tail, align 4, !tbaa !16
  %17 = load volatile i32, ptr @_ZL15nv_xnu_log_tail, align 4, !tbaa !16
  %18 = and i32 %17, 255
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [256 x %struct.anon], ptr @_ZL15nv_xnu_log_ring, i64 0, i64 %19
  %21 = load atomic volatile i32, ptr %20 acquire, align 4
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %12

23:                                               ; preds = %12, %5
  %24 = atomicrmw volatile xchg ptr @_ZL18nv_xnu_log_dropped, i32 0 monotonic, align 4
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %27, label %26

26:                                               ; preds = %23
  tail call void (ptr, ...) @IOLog(ptr noundef nonnull @.str.15, i32 noundef %24) #10
  br label %27

27:                                               ; preds = %26, %23
  store atomic volatile i32 0, ptr @_ZL19nv_xnu_log_draining release, align 4
  br label %28

28:                                               ; preds = %2, %27
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @out_string(ptr noundef %0) local_unnamed_addr #0 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %52, label %3

3:                                                ; preds = %1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.3, ptr noundef nonnull %0) #10
  %4 = load ptr, ptr @_ZL15nv_xnu_log_call, align 8, !tbaa !4
  %5 = icmp eq ptr %4, null
  br i1 %5, label %52, label %6

6:                                                ; preds = %3
  %7 = load atomic volatile i32, ptr @_ZL15nv_xnu_log_head monotonic, align 4
  br label %8

8:                                                ; preds = %17, %6
  %9 = phi i32 [ %7, %6 ], [ %21, %17 ]
  %10 = and i32 %9, 255
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [256 x %struct.anon], ptr @_ZL15nv_xnu_log_ring, i64 0, i64 %11
  %13 = load atomic volatile i32, ptr %12 acquire, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %8
  %16 = atomicrmw volatile add ptr @_ZL18nv_xnu_log_dropped, i32 1 monotonic, align 4
  br label %49

17:                                               ; preds = %8
  %18 = add i32 %9, 1
  %19 = cmpxchg volatile ptr @_ZL15nv_xnu_log_head, i32 %9, i32 %18 acq_rel monotonic, align 4
  %20 = extractvalue { i32, i1 } %19, 1
  %21 = extractvalue { i32, i1 } %19, 0
  br i1 %20, label %22, label %8, !llvm.loop !18

22:                                               ; preds = %17
  %23 = getelementptr inbounds i8, ptr %12, i64 4
  br label %24

24:                                               ; preds = %41, %22
  %25 = phi i64 [ 0, %22 ], [ %43, %41 ]
  %26 = getelementptr inbounds i8, ptr %0, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !12
  %28 = icmp eq i8 %27, 0
  br i1 %28, label %45, label %29

29:                                               ; preds = %24
  %30 = getelementptr inbounds [256 x i8], ptr %23, i64 0, i64 %25
  store i8 %27, ptr %30, align 1, !tbaa !12
  %31 = add nuw nsw i64 %25, 1
  %32 = getelementptr inbounds i8, ptr %0, i64 %31
  %33 = load i8, ptr %32, align 1, !tbaa !12
  %34 = icmp eq i8 %33, 0
  br i1 %34, label %45, label %35

35:                                               ; preds = %29
  %36 = getelementptr inbounds [256 x i8], ptr %23, i64 0, i64 %31
  store i8 %33, ptr %36, align 1, !tbaa !12
  %37 = add nuw nsw i64 %25, 2
  %38 = getelementptr inbounds i8, ptr %0, i64 %37
  %39 = load i8, ptr %38, align 1, !tbaa !12
  %40 = icmp eq i8 %39, 0
  br i1 %40, label %45, label %41

41:                                               ; preds = %35
  %42 = getelementptr inbounds [256 x i8], ptr %23, i64 0, i64 %37
  store i8 %39, ptr %42, align 1, !tbaa !12
  %43 = add nuw nsw i64 %25, 3
  %44 = icmp eq i64 %43, 255
  br i1 %44, label %45, label %24, !llvm.loop !19

45:                                               ; preds = %41, %35, %29, %24
  %46 = phi i64 [ %25, %24 ], [ %31, %29 ], [ %37, %35 ], [ 255, %41 ]
  %47 = and i64 %46, 4294967295
  %48 = getelementptr inbounds [256 x i8], ptr %23, i64 0, i64 %47
  store i8 0, ptr %48, align 1, !tbaa !12
  store atomic volatile i32 1, ptr %12 release, align 4
  br label %49

49:                                               ; preds = %45, %15
  %50 = load ptr, ptr @_ZL15nv_xnu_log_call, align 8, !tbaa !4
  %51 = tail call i32 @thread_call_enter(ptr noundef %50) #10
  br label %52

52:                                               ; preds = %49, %3, %1
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @thread_call_enter(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_dbg_init() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ11os_dbg_initE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ11os_dbg_initE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_dbg_init) #10
  br label %3

3:                                                ; preds = %0, %2
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_dbg_set_level(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_dbg_set_levelE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_dbg_set_levelE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_dbg_set_level) #10
  br label %4

4:                                                ; preds = %1, %3
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_dbg_breakpoint() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ17os_dbg_breakpointE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ17os_dbg_breakpointE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_dbg_breakpoint) #10
  br label %3

3:                                                ; preds = %0, %2
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.5) #10
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 82) i32 @os_alloc_mutex(ptr nocapture noundef writeonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ14os_alloc_mutexE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ14os_alloc_mutexE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_alloc_mutex) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @IOLockAlloc() #10
  store ptr %5, ptr %0, align 8, !tbaa !4
  %6 = icmp eq ptr %5, null
  %7 = select i1 %6, i32 81, i32 0
  ret i32 %7
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @IOLockAlloc() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_free_mutex(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ13os_free_mutexE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ13os_free_mutexE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_free_mutex) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %7, label %6

6:                                                ; preds = %4
  tail call void @IOLockFree(ptr noundef nonnull %0) #10
  br label %7

7:                                                ; preds = %6, %4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockFree(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_acquire_mutex(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_acquire_mutexE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_acquire_mutexE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_acquire_mutex) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IOLockLock(ptr noundef %0) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockLock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 103) i32 @os_cond_acquire_mutex(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ21os_cond_acquire_mutexE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ21os_cond_acquire_mutexE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_cond_acquire_mutex) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call i32 @IOLockTryLock(ptr noundef %0) #10
  %6 = icmp eq i32 %5, 0
  %7 = select i1 %6, i32 102, i32 0
  ret i32 %7
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @IOLockTryLock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_release_mutex(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_release_mutexE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_release_mutexE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_release_mutex) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IOLockUnlock(ptr noundef %0) #10
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOLockUnlock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 82) i32 @os_alloc_spinlock(ptr nocapture noundef writeonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ17os_alloc_spinlockE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ17os_alloc_spinlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_alloc_spinlock) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @kern_os_malloc(i64 noundef 16) #10
  %6 = icmp eq ptr %5, null
  br i1 %6, label %13, label %7

7:                                                ; preds = %4
  %8 = tail call ptr @IOSimpleLockAlloc() #10
  store ptr %8, ptr %5, align 8, !tbaa !20
  %9 = getelementptr inbounds i8, ptr %5, i64 8
  store i32 0, ptr %9, align 8, !tbaa !22
  %10 = icmp eq ptr %8, null
  br i1 %10, label %11, label %12

11:                                               ; preds = %7
  tail call void @kern_os_free(ptr noundef nonnull %5) #10
  br label %13

12:                                               ; preds = %7
  store ptr %5, ptr %0, align 8, !tbaa !4
  br label %13

13:                                               ; preds = %4, %12, %11
  %14 = phi i32 [ 0, %12 ], [ 81, %11 ], [ 81, %4 ]
  ret i32 %14
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @IOSimpleLockAlloc() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_free_spinlock(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_free_spinlockE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_free_spinlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_free_spinlock) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %8, label %6

6:                                                ; preds = %4
  %7 = load ptr, ptr %0, align 8, !tbaa !20
  tail call void @IOSimpleLockFree(ptr noundef %7) #10
  tail call void @kern_os_free(ptr noundef nonnull %0) #10
  br label %8

8:                                                ; preds = %6, %4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOSimpleLockFree(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i64 @os_acquire_spinlock(ptr nocapture noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ19os_acquire_spinlockE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ19os_acquire_spinlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_acquire_spinlock) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = load ptr, ptr %0, align 8, !tbaa !20
  %6 = tail call i32 @ml_set_interrupts_enabled(i32 noundef 0) #10
  tail call void @IOSimpleLockLock(ptr noundef %5) #10
  %7 = getelementptr inbounds i8, ptr %0, i64 8
  store i32 %6, ptr %7, align 8, !tbaa !22
  ret i64 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_release_spinlock(ptr nocapture noundef readonly %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ19os_release_spinlockE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ19os_release_spinlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_release_spinlock) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = load ptr, ptr %0, align 8, !tbaa !20
  %7 = getelementptr inbounds i8, ptr %0, i64 8
  %8 = load i32, ptr %7, align 8, !tbaa !22
  tail call void @IOSimpleLockUnlock(ptr noundef %6) #10
  %9 = tail call i32 @ml_set_interrupts_enabled(i32 noundef %8) #10
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @os_alloc_rwlock() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ15os_alloc_rwlockE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ15os_alloc_rwlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_alloc_rwlock) #10
  br label %3

3:                                                ; preds = %0, %2
  %4 = tail call ptr @IORWLockAlloc() #10
  ret ptr %4
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @IORWLockAlloc() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_free_rwlock(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ14os_free_rwlockE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ14os_free_rwlockE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_free_rwlock) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %7, label %6

6:                                                ; preds = %4
  tail call void @IORWLockFree(ptr noundef nonnull %0) #10
  br label %7

7:                                                ; preds = %6, %4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IORWLockFree(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_acquire_rwlock_read(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ22os_acquire_rwlock_readE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ22os_acquire_rwlock_readE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_acquire_rwlock_read) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IORWLockRead(ptr noundef %0) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IORWLockRead(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_acquire_rwlock_write(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ23os_acquire_rwlock_writeE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ23os_acquire_rwlock_writeE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_acquire_rwlock_write) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IORWLockWrite(ptr noundef %0) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IORWLockWrite(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 103) i32 @os_cond_acquire_rwlock_read(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ27os_cond_acquire_rwlock_readE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ27os_cond_acquire_rwlock_readE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_cond_acquire_rwlock_read) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @IORWLockGetMachLock(ptr noundef %0) #10
  %6 = tail call i32 @lck_rw_try_lock(ptr noundef %5, i32 noundef 1) #10
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, i32 102, i32 0
  ret i32 %8
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @lck_rw_try_lock(ptr noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare ptr @IORWLockGetMachLock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 103) i32 @os_cond_acquire_rwlock_write(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ28os_cond_acquire_rwlock_writeE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ28os_cond_acquire_rwlock_writeE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_cond_acquire_rwlock_write) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @IORWLockGetMachLock(ptr noundef %0) #10
  %6 = tail call i32 @lck_rw_try_lock(ptr noundef %5, i32 noundef 2) #10
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, i32 102, i32 0
  ret i32 %8
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_release_rwlock_read(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ22os_release_rwlock_readE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ22os_release_rwlock_readE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_release_rwlock_read) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IORWLockUnlock(ptr noundef %0) #10
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @IORWLockUnlock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_release_rwlock_write(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ23os_release_rwlock_writeE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ23os_release_rwlock_writeE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_release_rwlock_write) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IORWLockUnlock(ptr noundef %0) #10
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @os_alloc_semaphore(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ18os_alloc_semaphoreE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ18os_alloc_semaphoreE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_alloc_semaphore) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @kern_os_malloc(i64 noundef 8) #10
  %6 = icmp eq ptr %5, null
  br i1 %6, label %12, label %7

7:                                                ; preds = %4
  %8 = load ptr, ptr @kernel_task, align 8, !tbaa !4
  %9 = tail call i32 @semaphore_create(ptr noundef %8, ptr noundef nonnull %5, i32 noundef 0, i32 noundef %0) #10
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  tail call void @kern_os_free(ptr noundef nonnull %5) #10
  br label %12

12:                                               ; preds = %7, %4, %11
  %13 = phi ptr [ null, %11 ], [ null, %4 ], [ %5, %7 ]
  ret ptr %13
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @semaphore_create(ptr noundef, ptr noundef, i32 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_free_semaphore(ptr noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ17os_free_semaphoreE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ17os_free_semaphoreE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_free_semaphore) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %10, label %6

6:                                                ; preds = %4
  %7 = load ptr, ptr @kernel_task, align 8, !tbaa !4
  %8 = load ptr, ptr %0, align 8, !tbaa !4
  %9 = tail call i32 @semaphore_destroy(ptr noundef %7, ptr noundef %8) #10
  tail call void @kern_os_free(ptr noundef nonnull %0) #10
  br label %10

10:                                               ; preds = %6, %4
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @semaphore_destroy(ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 65536) i32 @os_acquire_semaphore(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ20os_acquire_semaphoreE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ20os_acquire_semaphoreE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_acquire_semaphore) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = load ptr, ptr %0, align 8, !tbaa !4
  %6 = tail call i32 @semaphore_wait(ptr noundef %5) #10
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, i32 0, i32 65535
  ret i32 %8
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @semaphore_wait(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 103) i32 @os_cond_acquire_semaphore(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ25os_cond_acquire_semaphoreE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ25os_cond_acquire_semaphoreE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_cond_acquire_semaphore) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = load ptr, ptr %0, align 8, !tbaa !4
  %6 = tail call i32 @semaphore_wait_noblock(ptr noundef %5) #10
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, i32 0, i32 102
  ret i32 %8
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @semaphore_wait_noblock(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_release_semaphore(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ20os_release_semaphoreE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ20os_release_semaphoreE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_release_semaphore) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = load ptr, ptr %0, align 8, !tbaa !4
  %6 = tail call i32 @semaphore_signal(ptr noundef %5) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @semaphore_signal(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @os_semaphore_may_sleep() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ22os_semaphore_may_sleepE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ22os_semaphore_may_sleepE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_semaphore_may_sleep) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 1
}

; Function Attrs: mustprogress nofree noimplicitfloat noredzone nounwind ssp willreturn memory(readwrite, argmem: none)
define zeroext range(i8 0, 2) i8 @os_is_isr() local_unnamed_addr #5 {
  %1 = load volatile ptr, ptr @nv_xnu_isr_thread, align 8, !tbaa !4
  %2 = icmp eq ptr %1, null
  br i1 %2, label %8, label %3

3:                                                ; preds = %0
  %4 = load volatile ptr, ptr @nv_xnu_isr_thread, align 8, !tbaa !4
  %5 = tail call ptr @current_thread() #12
  %6 = icmp eq ptr %4, %5
  %7 = zext i1 %6 to i8
  br label %8

8:                                                ; preds = %3, %0
  %9 = phi i8 [ 0, %0 ], [ %7, %3 ]
  ret i8 %9
}

; Function Attrs: mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none)
declare ptr @current_thread() local_unnamed_addr #6

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext range(i8 0, 2) i8 @os_is_administrator() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ19os_is_administratorE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ19os_is_administratorE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_is_administrator) #10
  br label %3

3:                                                ; preds = %0, %2
  %4 = tail call i32 @kauth_getuid() #10
  %5 = icmp eq i32 %4, 0
  %6 = zext i1 %5 to i8
  ret i8 %6
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @kauth_getuid() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_get_euid(ptr noundef writeonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ11os_get_euidE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ11os_get_euidE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_euid) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = icmp eq ptr %0, null
  br i1 %5, label %8, label %6

6:                                                ; preds = %4
  %7 = tail call i32 @kauth_getuid() #10
  store i32 %7, ptr %0, align 4, !tbaa !16
  br label %8

8:                                                ; preds = %4, %6
  %9 = phi i32 [ 0, %6 ], [ 31, %4 ]
  ret i32 %9
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i64 @os_get_monotonic_time_ns() local_unnamed_addr #0 {
  %1 = alloca i64, align 8
  %2 = load i1, ptr @_ZZ24os_get_monotonic_time_nsE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %0
  store i1 true, ptr @_ZZ24os_get_monotonic_time_nsE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_monotonic_time_ns) #10
  br label %4

4:                                                ; preds = %0, %3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #11
  store i64 0, ptr %1, align 8, !annotation !15
  %5 = tail call i64 @mach_absolute_time() #10
  call void @absolutetime_to_nanoseconds(i64 noundef %5, ptr noundef nonnull %1) #10
  %6 = load i64, ptr %1, align 8, !tbaa !23
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #11
  ret i64 %6
}

; Function Attrs: noimplicitfloat noredzone
declare void @absolutetime_to_nanoseconds(i64 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare i64 @mach_absolute_time() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i64 @os_get_monotonic_time_ns_hr() local_unnamed_addr #0 {
  %1 = alloca i64, align 8
  %2 = load i1, ptr @_ZZ27os_get_monotonic_time_ns_hrE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %0
  store i1 true, ptr @_ZZ27os_get_monotonic_time_ns_hrE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_monotonic_time_ns_hr) #10
  br label %4

4:                                                ; preds = %0, %3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #11
  store i64 0, ptr %1, align 8, !annotation !15
  %5 = tail call i64 @mach_absolute_time() #10
  call void @absolutetime_to_nanoseconds(i64 noundef %5, ptr noundef nonnull %1) #10
  %6 = load i64, ptr %1, align 8, !tbaa !23
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #11
  ret i64 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_system_time(ptr nocapture noundef writeonly %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = alloca i64, align 8
  %4 = alloca i32, align 4
  %5 = load i1, ptr @_ZZ18os_get_system_timeE2_t, align 1
  br i1 %5, label %7, label %6

6:                                                ; preds = %2
  store i1 true, ptr @_ZZ18os_get_system_timeE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_system_time) #10
  br label %7

7:                                                ; preds = %2, %6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #11
  store i64 0, ptr %3, align 8, !annotation !15
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #11
  store i32 0, ptr %4, align 4, !annotation !15
  call void @clock_get_calendar_microtime(ptr noundef nonnull %3, ptr noundef nonnull %4) #10
  %8 = load i64, ptr %3, align 8, !tbaa !9
  %9 = trunc i64 %8 to i32
  store i32 %9, ptr %0, align 4, !tbaa !16
  %10 = load i32, ptr %4, align 4, !tbaa !16
  store i32 %10, ptr %1, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #11
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #11
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @clock_get_calendar_microtime(ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @nv_is_chassis_notebook() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ22nv_is_chassis_notebookE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ22nv_is_chassis_notebookE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.nv_is_chassis_notebook) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @nv_acpi_is_battery_present() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ26nv_acpi_is_battery_presentE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ26nv_acpi_is_battery_presentE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.nv_acpi_is_battery_present) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @nv_platform_supports_s0ix() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ25nv_platform_supports_s0ixE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ25nv_platform_supports_s0ixE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.nv_platform_supports_s0ix) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @os_is_nvswitch_present() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ22os_is_nvswitch_presentE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ22os_is_nvswitch_presentE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_is_nvswitch_present) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_delay(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ8os_delayE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ8os_delayE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_delay) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IOSleep(i32 noundef %0) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IOSleep(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_delay_us(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ11os_delay_usE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ11os_delay_usE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_delay_us) #10
  br label %4

4:                                                ; preds = %1, %3
  tail call void @IODelay(i32 noundef %0) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @IODelay(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i64 @os_get_cpu_frequency() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ20os_get_cpu_frequencyE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ20os_get_cpu_frequencyE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_cpu_frequency) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i64 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_get_current_process() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ22os_get_current_processE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ22os_get_current_processE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_current_process) #10
  br label %3

3:                                                ; preds = %0, %2
  %4 = tail call i32 @proc_selfpid() #10
  ret i32 %4
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @proc_selfpid() local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_get_current_process_name(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ27os_get_current_process_nameE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ27os_get_current_process_nameE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_current_process_name) #10
  br label %5

5:                                                ; preds = %2, %4
  tail call void @proc_selfname(ptr noundef %0, i32 noundef %1) #10
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @proc_selfname(ptr noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_current_thread(ptr nocapture noundef writeonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ21os_get_current_threadE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ21os_get_current_threadE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_current_thread) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = tail call ptr @current_thread() #12
  %6 = ptrtoint ptr %5 to i64
  store i64 %6, ptr %0, align 8, !tbaa !23
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noalias noundef ptr @os_get_pid_info() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ15os_get_pid_infoE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ15os_get_pid_infoE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_pid_info) #10
  br label %3

3:                                                ; preds = %0, %2
  ret ptr null
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_put_pid_info(ptr nocapture noundef readnone %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ15os_put_pid_infoE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ15os_put_pid_infoE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_put_pid_info) #10
  br label %4

4:                                                ; preds = %1, %3
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_find_ns_pid(ptr nocapture noundef readnone %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ14os_find_ns_pidE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ14os_find_ns_pidE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_find_ns_pid) #10
  br label %5

5:                                                ; preds = %2, %4
  ret i32 86
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_random_bytes(ptr noundef %0, i16 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ19os_get_random_bytesE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ19os_get_random_bytesE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_random_bytes) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = zext i16 %1 to i32
  tail call void @read_random(ptr noundef %0, i32 noundef %6) #10
  ret i32 0
}

; Function Attrs: noimplicitfloat noredzone
declare void @read_random(ptr noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @nv_xnu_register_pci(ptr noundef %0, i32 noundef %1, i8 noundef zeroext %2, i8 noundef zeroext %3, i8 noundef zeroext %4) local_unnamed_addr #0 {
  %6 = icmp eq ptr %0, null
  br i1 %6, label %50, label %7

7:                                                ; preds = %5
  %8 = load i32, ptr @_ZL13nv_xnu_nslots, align 4
  %9 = icmp sgt i32 %8, 0
  br i1 %9, label %10, label %38

10:                                               ; preds = %7
  %11 = zext nneg i32 %8 to i64
  br label %12

12:                                               ; preds = %10, %33
  %13 = phi i64 [ 0, %10 ], [ %34, %33 ]
  %14 = getelementptr inbounds [256 x %struct.nv_xnu_pci_slot], ptr @_ZL12nv_xnu_slots, i64 0, i64 %13
  %15 = load ptr, ptr %14, align 16, !tbaa !25
  %16 = icmp eq ptr %15, %0
  br i1 %16, label %50, label %17

17:                                               ; preds = %12
  %18 = getelementptr inbounds i8, ptr %14, i64 8
  %19 = load i32, ptr %18, align 8, !tbaa !27
  %20 = icmp eq i32 %19, %1
  br i1 %20, label %21, label %33

21:                                               ; preds = %17
  %22 = getelementptr inbounds i8, ptr %14, i64 12
  %23 = load i8, ptr %22, align 4, !tbaa !28
  %24 = icmp eq i8 %23, %2
  br i1 %24, label %25, label %33

25:                                               ; preds = %21
  %26 = getelementptr inbounds i8, ptr %14, i64 13
  %27 = load i8, ptr %26, align 1, !tbaa !29
  %28 = icmp eq i8 %27, %3
  br i1 %28, label %29, label %33

29:                                               ; preds = %25
  %30 = getelementptr inbounds i8, ptr %14, i64 14
  %31 = load i8, ptr %30, align 2, !tbaa !30
  %32 = icmp eq i8 %31, %4
  br i1 %32, label %50, label %33

33:                                               ; preds = %29, %25, %21, %17
  %34 = add nuw nsw i64 %13, 1
  %35 = icmp eq i64 %34, %11
  br i1 %35, label %36, label %12, !llvm.loop !31

36:                                               ; preds = %33
  %37 = icmp slt i32 %8, 256
  br i1 %37, label %38, label %50

38:                                               ; preds = %7, %36
  %39 = load ptr, ptr %0, align 8, !tbaa !32
  %40 = getelementptr inbounds i8, ptr %39, i64 32
  %41 = load ptr, ptr %40, align 8
  tail call void %41(ptr noundef nonnull %0) #10
  %42 = load i32, ptr @_ZL13nv_xnu_nslots, align 4, !tbaa !16
  %43 = add nsw i32 %42, 1
  store i32 %43, ptr @_ZL13nv_xnu_nslots, align 4, !tbaa !16
  %44 = sext i32 %42 to i64
  %45 = getelementptr inbounds [256 x %struct.nv_xnu_pci_slot], ptr @_ZL12nv_xnu_slots, i64 0, i64 %44
  store ptr %0, ptr %45, align 16, !tbaa !4
  %46 = getelementptr inbounds i8, ptr %45, i64 8
  store i32 %1, ptr %46, align 8, !tbaa !16
  %47 = getelementptr inbounds i8, ptr %45, i64 12
  store i8 %2, ptr %47, align 4, !tbaa !12
  %48 = getelementptr inbounds i8, ptr %45, i64 13
  store i8 %3, ptr %48, align 1, !tbaa !12
  %49 = getelementptr inbounds i8, ptr %45, i64 14
  store i8 %4, ptr %49, align 2, !tbaa !12
  br label %50

50:                                               ; preds = %29, %12, %36, %5, %38
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @nv_xnu_register_all_pci() local_unnamed_addr #0 {
  %1 = tail call ptr @_ZN9IOService15serviceMatchingEPKcP12OSDictionary(ptr noundef nonnull @.str.6, ptr noundef null) #10
  %2 = icmp eq ptr %1, null
  br i1 %2, label %87, label %3

3:                                                ; preds = %0
  %4 = tail call ptr @_ZN9IOService19getMatchingServicesEP12OSDictionary(ptr noundef nonnull %1) #10
  %5 = icmp eq ptr %4, null
  br i1 %5, label %83, label %6

6:                                                ; preds = %3
  %7 = load ptr, ptr %4, align 8, !tbaa !32
  %8 = getelementptr inbounds i8, ptr %7, i64 296
  %9 = load ptr, ptr %8, align 8
  %10 = tail call ptr %9(ptr noundef nonnull %4) #10
  %11 = icmp eq ptr %10, null
  br i1 %11, label %79, label %12

12:                                               ; preds = %6
  %13 = load ptr, ptr @_ZN11IOPCIDevice9metaClassE, align 8, !tbaa !4
  br label %14

14:                                               ; preds = %12, %73
  %15 = phi ptr [ %10, %12 ], [ %77, %73 ]
  %16 = tail call ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef nonnull %15, ptr noundef %13) #10
  %17 = icmp eq ptr %16, null
  br i1 %17, label %73, label %18

18:                                               ; preds = %14
  %19 = load ptr, ptr %16, align 8, !tbaa !32
  %20 = getelementptr inbounds i8, ptr %19, i64 2280
  %21 = load ptr, ptr %20, align 8
  %22 = tail call zeroext i8 %21(ptr noundef nonnull %16) #10
  %23 = load ptr, ptr %16, align 8, !tbaa !32
  %24 = getelementptr inbounds i8, ptr %23, i64 2288
  %25 = load ptr, ptr %24, align 8
  %26 = tail call zeroext i8 %25(ptr noundef nonnull %16) #10
  %27 = load ptr, ptr %16, align 8, !tbaa !32
  %28 = getelementptr inbounds i8, ptr %27, i64 2296
  %29 = load ptr, ptr %28, align 8
  %30 = tail call zeroext i8 %29(ptr noundef nonnull %16) #10
  %31 = load i32, ptr @_ZL13nv_xnu_nslots, align 4
  %32 = icmp sgt i32 %31, 0
  br i1 %32, label %33, label %61

33:                                               ; preds = %18
  %34 = zext nneg i32 %31 to i64
  br label %35

35:                                               ; preds = %56, %33
  %36 = phi i64 [ 0, %33 ], [ %57, %56 ]
  %37 = getelementptr inbounds [256 x %struct.nv_xnu_pci_slot], ptr @_ZL12nv_xnu_slots, i64 0, i64 %36
  %38 = load ptr, ptr %37, align 16, !tbaa !25
  %39 = icmp eq ptr %38, %16
  br i1 %39, label %73, label %40

40:                                               ; preds = %35
  %41 = getelementptr inbounds i8, ptr %37, i64 8
  %42 = load i32, ptr %41, align 8, !tbaa !27
  %43 = icmp eq i32 %42, 0
  br i1 %43, label %44, label %56

44:                                               ; preds = %40
  %45 = getelementptr inbounds i8, ptr %37, i64 12
  %46 = load i8, ptr %45, align 4, !tbaa !28
  %47 = icmp eq i8 %46, %22
  br i1 %47, label %48, label %56

48:                                               ; preds = %44
  %49 = getelementptr inbounds i8, ptr %37, i64 13
  %50 = load i8, ptr %49, align 1, !tbaa !29
  %51 = icmp eq i8 %50, %26
  br i1 %51, label %52, label %56

52:                                               ; preds = %48
  %53 = getelementptr inbounds i8, ptr %37, i64 14
  %54 = load i8, ptr %53, align 2, !tbaa !30
  %55 = icmp eq i8 %54, %30
  br i1 %55, label %73, label %56

56:                                               ; preds = %52, %48, %44, %40
  %57 = add nuw nsw i64 %36, 1
  %58 = icmp eq i64 %57, %34
  br i1 %58, label %59, label %35, !llvm.loop !31

59:                                               ; preds = %56
  %60 = icmp slt i32 %31, 256
  br i1 %60, label %61, label %73

61:                                               ; preds = %59, %18
  %62 = load ptr, ptr %16, align 8, !tbaa !32
  %63 = getelementptr inbounds i8, ptr %62, i64 32
  %64 = load ptr, ptr %63, align 8
  tail call void %64(ptr noundef nonnull %16) #10
  %65 = load i32, ptr @_ZL13nv_xnu_nslots, align 4, !tbaa !16
  %66 = add nsw i32 %65, 1
  store i32 %66, ptr @_ZL13nv_xnu_nslots, align 4, !tbaa !16
  %67 = sext i32 %65 to i64
  %68 = getelementptr inbounds [256 x %struct.nv_xnu_pci_slot], ptr @_ZL12nv_xnu_slots, i64 0, i64 %67
  store ptr %16, ptr %68, align 16, !tbaa !4
  %69 = getelementptr inbounds i8, ptr %68, i64 8
  store i32 0, ptr %69, align 8, !tbaa !16
  %70 = getelementptr inbounds i8, ptr %68, i64 12
  store i8 %22, ptr %70, align 4, !tbaa !12
  %71 = getelementptr inbounds i8, ptr %68, i64 13
  store i8 %26, ptr %71, align 1, !tbaa !12
  %72 = getelementptr inbounds i8, ptr %68, i64 14
  store i8 %30, ptr %72, align 2, !tbaa !12
  br label %73

73:                                               ; preds = %52, %35, %61, %59, %14
  %74 = load ptr, ptr %4, align 8, !tbaa !32
  %75 = getelementptr inbounds i8, ptr %74, i64 296
  %76 = load ptr, ptr %75, align 8
  %77 = tail call ptr %76(ptr noundef nonnull %4) #10
  %78 = icmp eq ptr %77, null
  br i1 %78, label %79, label %14, !llvm.loop !34

79:                                               ; preds = %73, %6
  %80 = load ptr, ptr %4, align 8, !tbaa !32
  %81 = getelementptr inbounds i8, ptr %80, i64 40
  %82 = load ptr, ptr %81, align 8
  tail call void %82(ptr noundef nonnull %4) #10
  br label %83

83:                                               ; preds = %79, %3
  %84 = load ptr, ptr %1, align 8, !tbaa !32
  %85 = getelementptr inbounds i8, ptr %84, i64 40
  %86 = load ptr, ptr %85, align 8
  tail call void %86(ptr noundef nonnull %1) #10
  br label %87

87:                                               ; preds = %0, %83
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService15serviceMatchingEPKcP12OSDictionary(ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN9IOService19getMatchingServicesEP12OSDictionary(ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN15OSMetaClassBase12safeMetaCastEPKS_PK11OSMetaClass(ptr noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @os_pci_init_handle(i32 noundef %0, i8 noundef zeroext %1, i8 noundef zeroext %2, i8 noundef zeroext %3, ptr noundef writeonly %4, ptr noundef writeonly %5) local_unnamed_addr #0 {
  %7 = load i1, ptr @_ZZ18os_pci_init_handleE2_t, align 1
  br i1 %7, label %9, label %8

8:                                                ; preds = %6
  store i1 true, ptr @_ZZ18os_pci_init_handleE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_init_handle) #10
  br label %9

9:                                                ; preds = %6, %8
  %10 = load i32, ptr @_ZL13nv_xnu_nslots, align 4, !tbaa !16
  %11 = icmp sgt i32 %10, 0
  br i1 %11, label %12, label %45

12:                                               ; preds = %9
  %13 = zext nneg i32 %10 to i64
  br label %14

14:                                               ; preds = %12, %42
  %15 = phi i64 [ 0, %12 ], [ %43, %42 ]
  %16 = getelementptr inbounds [256 x %struct.nv_xnu_pci_slot], ptr @_ZL12nv_xnu_slots, i64 0, i64 %15
  %17 = getelementptr inbounds i8, ptr %16, i64 8
  %18 = load i32, ptr %17, align 8, !tbaa !27
  %19 = icmp eq i32 %18, %0
  br i1 %19, label %20, label %42

20:                                               ; preds = %14
  %21 = getelementptr inbounds i8, ptr %16, i64 12
  %22 = load i8, ptr %21, align 4, !tbaa !28
  %23 = icmp eq i8 %22, %1
  br i1 %23, label %24, label %42

24:                                               ; preds = %20
  %25 = getelementptr inbounds i8, ptr %16, i64 13
  %26 = load i8, ptr %25, align 1, !tbaa !29
  %27 = icmp eq i8 %26, %2
  br i1 %27, label %28, label %42

28:                                               ; preds = %24
  %29 = getelementptr inbounds i8, ptr %16, i64 14
  %30 = load i8, ptr %29, align 2, !tbaa !30
  %31 = icmp eq i8 %30, %3
  br i1 %31, label %32, label %42

32:                                               ; preds = %28
  %33 = icmp eq ptr %4, null
  br i1 %33, label %37, label %34

34:                                               ; preds = %32
  %35 = load ptr, ptr %16, align 8, !tbaa !25
  %36 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %35, i64 noundef 0) #10
  store i16 %36, ptr %4, align 2, !tbaa !35
  br label %37

37:                                               ; preds = %34, %32
  %38 = icmp eq ptr %5, null
  br i1 %38, label %45, label %39

39:                                               ; preds = %37
  %40 = load ptr, ptr %16, align 8, !tbaa !25
  %41 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %40, i64 noundef 2) #10
  store i16 %41, ptr %5, align 2, !tbaa !35
  br label %45

42:                                               ; preds = %28, %24, %20, %14
  %43 = add nuw nsw i64 %15, 1
  %44 = icmp eq i64 %43, %13
  br i1 %44, label %45, label %14, !llvm.loop !37

45:                                               ; preds = %42, %9, %39, %37
  %46 = phi ptr [ %16, %37 ], [ %16, %39 ], [ null, %9 ], [ null, %42 ]
  ret ptr %46
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_read_byte(ptr noundef readonly %0, i32 noundef %1, ptr nocapture noundef writeonly %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ16os_pci_read_byteE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ16os_pci_read_byteE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_read_byte) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ16os_pci_read_byteE2_w, align 1
  br i1 %9, label %15, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ16os_pci_read_byteE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_read_byte) #10
  br label %15

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  %14 = tail call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef %12, i64 noundef %13) #10
  store i8 %14, ptr %2, align 1, !tbaa !12
  br label %15

15:                                               ; preds = %8, %10, %11
  %16 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %16
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_read_word(ptr noundef readonly %0, i32 noundef %1, ptr nocapture noundef writeonly %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ16os_pci_read_wordE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ16os_pci_read_wordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_read_word) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ16os_pci_read_wordE2_w, align 1
  br i1 %9, label %15, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ16os_pci_read_wordE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_read_word) #10
  br label %15

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  %14 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %12, i64 noundef %13) #10
  store i16 %14, ptr %2, align 2, !tbaa !35
  br label %15

15:                                               ; preds = %8, %10, %11
  %16 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %16
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_read_dword(ptr noundef readonly %0, i32 noundef %1, ptr nocapture noundef writeonly %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ17os_pci_read_dwordE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ17os_pci_read_dwordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_read_dword) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ17os_pci_read_dwordE2_w, align 1
  br i1 %9, label %15, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ17os_pci_read_dwordE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_read_dword) #10
  br label %15

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  %14 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %12, i64 noundef %13) #10
  store i32 %14, ptr %2, align 4, !tbaa !16
  br label %15

15:                                               ; preds = %8, %10, %11
  %16 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %16
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_write_byte(ptr noundef readonly %0, i32 noundef %1, i8 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ17os_pci_write_byteE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ17os_pci_write_byteE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_write_byte) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ17os_pci_write_byteE2_w, align 1
  br i1 %9, label %14, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ17os_pci_write_byteE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_write_byte) #10
  br label %14

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  tail call void @_ZN11IOPCIDevice20extendedConfigWrite8Eyh(ptr noundef %12, i64 noundef %13, i8 noundef zeroext %2) #10
  br label %14

14:                                               ; preds = %8, %10, %11
  %15 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %15
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_write_word(ptr noundef readonly %0, i32 noundef %1, i16 noundef zeroext %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ17os_pci_write_wordE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ17os_pci_write_wordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_write_word) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ17os_pci_write_wordE2_w, align 1
  br i1 %9, label %14, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ17os_pci_write_wordE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_write_word) #10
  br label %14

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %12, i64 noundef %13, i16 noundef zeroext %2) #10
  br label %14

14:                                               ; preds = %8, %10, %11
  %15 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %15
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define range(i32 0, 32) i32 @os_pci_write_dword(ptr noundef readonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = load i1, ptr @_ZZ18os_pci_write_dwordE2_t, align 1
  br i1 %4, label %6, label %5

5:                                                ; preds = %3
  store i1 true, ptr @_ZZ18os_pci_write_dwordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_pci_write_dword) #10
  br label %6

6:                                                ; preds = %5, %3
  %7 = icmp eq ptr %0, null
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = load i1, ptr @_ZZ18os_pci_write_dwordE2_w, align 1
  br i1 %9, label %14, label %10

10:                                               ; preds = %8
  store i1 true, ptr @_ZZ18os_pci_write_dwordE2_w, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.7, ptr noundef nonnull @__func__.os_pci_write_dword) #10
  br label %14

11:                                               ; preds = %6
  %12 = load ptr, ptr %0, align 8, !tbaa !25
  %13 = zext i32 %1 to i64
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %12, i64 noundef %13, i32 noundef %2) #10
  br label %14

14:                                               ; preds = %8, %10, %11
  %15 = phi i32 [ 0, %11 ], [ 31, %10 ], [ 31, %8 ]
  ret i32 %15
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define ptr @os_map_kernel_space(i64 noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca ptr, align 8
  %5 = icmp eq i32 %2, 0
  %6 = icmp eq i32 %2, 2
  %7 = select i1 %6, i32 1024, i32 256
  %8 = select i1 %5, i32 0, i32 %7
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.8, i64 noundef %0, i64 noundef %1, i32 noundef %2) #10
  %9 = tail call zeroext i1 @nv_pm_is_gpu(i64 noundef %0, i64 noundef %1) #10
  br i1 %9, label %65, label %10

10:                                               ; preds = %3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #11
  store ptr null, ptr %4, align 8, !tbaa !4
  %11 = call ptr @nv_pm_alias(i64 noundef %0, i64 noundef %1, ptr noundef nonnull %4) #10
  %12 = icmp eq ptr %11, null
  br i1 %12, label %62, label %13

13:                                               ; preds = %10, %59
  %14 = phi i64 [ %60, %59 ], [ 0, %10 ]
  %15 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %14
  %16 = getelementptr inbounds i8, ptr %15, i64 16
  %17 = load ptr, ptr %16, align 16, !tbaa !38
  %18 = icmp eq ptr %17, null
  br i1 %18, label %25, label %41

19:                                               ; preds = %53
  %20 = getelementptr inbounds i8, ptr %55, i64 16
  br label %27

21:                                               ; preds = %47
  %22 = getelementptr inbounds i8, ptr %49, i64 16
  br label %27

23:                                               ; preds = %41
  %24 = getelementptr inbounds i8, ptr %43, i64 16
  br label %27

25:                                               ; preds = %13
  %26 = getelementptr inbounds i8, ptr %15, i64 16
  br label %27

27:                                               ; preds = %25, %23, %21, %19
  %28 = phi i64 [ %54, %19 ], [ %48, %21 ], [ %42, %23 ], [ %14, %25 ]
  %29 = phi ptr [ %55, %19 ], [ %49, %21 ], [ %43, %23 ], [ %15, %25 ]
  %30 = phi ptr [ %20, %19 ], [ %22, %21 ], [ %24, %23 ], [ %26, %25 ]
  %31 = trunc nuw nsw i64 %28 to i32
  %32 = load ptr, ptr %4, align 8, !tbaa !4
  store ptr null, ptr %29, align 16, !tbaa !4
  %33 = getelementptr inbounds i8, ptr %29, i64 8
  store ptr null, ptr %33, align 8, !tbaa !4
  store ptr %11, ptr %30, align 16, !tbaa !4
  %34 = getelementptr inbounds i8, ptr %29, i64 24
  store i64 %0, ptr %34, align 8, !tbaa !23
  %35 = getelementptr inbounds i8, ptr %29, i64 32
  store i64 %1, ptr %35, align 16, !tbaa !23
  %36 = getelementptr inbounds i8, ptr %29, i64 40
  store ptr %32, ptr %36, align 8, !tbaa !4
  %37 = load i32, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  %38 = icmp ugt i32 %37, %31
  br i1 %38, label %64, label %39

39:                                               ; preds = %27
  %40 = add nuw nsw i32 %31, 1
  store i32 %40, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  br label %64

41:                                               ; preds = %13
  %42 = or disjoint i64 %14, 1
  %43 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %42
  %44 = getelementptr inbounds i8, ptr %43, i64 16
  %45 = load ptr, ptr %44, align 16, !tbaa !38
  %46 = icmp eq ptr %45, null
  br i1 %46, label %23, label %47

47:                                               ; preds = %41
  %48 = or disjoint i64 %14, 2
  %49 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %48
  %50 = getelementptr inbounds i8, ptr %49, i64 16
  %51 = load ptr, ptr %50, align 16, !tbaa !38
  %52 = icmp eq ptr %51, null
  br i1 %52, label %21, label %53

53:                                               ; preds = %47
  %54 = or disjoint i64 %14, 3
  %55 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %54
  %56 = getelementptr inbounds i8, ptr %55, i64 16
  %57 = load ptr, ptr %56, align 16, !tbaa !38
  %58 = icmp eq ptr %57, null
  br i1 %58, label %19, label %59

59:                                               ; preds = %53
  %60 = add nuw nsw i64 %14, 4
  %61 = icmp eq i64 %60, 8192
  br i1 %61, label %64, label %13, !llvm.loop !40

62:                                               ; preds = %10
  %63 = call ptr @llvm.returnaddress(i32 0)
  call void @nv_pm_foreign(i64 noundef %0, i64 noundef %1, i32 noundef %2, ptr noundef %63) #10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #11
  br label %65

64:                                               ; preds = %59, %39, %27
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #11
  br label %139

65:                                               ; preds = %62, %3
  %66 = call ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef %0, i64 noundef %1, i32 noundef 3) #10
  %67 = icmp eq ptr %66, null
  br i1 %67, label %68, label %69

68:                                               ; preds = %65
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.9) #10
  br label %139

69:                                               ; preds = %65
  %70 = load ptr, ptr %66, align 8, !tbaa !32
  %71 = getelementptr inbounds i8, ptr %70, i64 512
  %72 = load ptr, ptr %71, align 8
  %73 = call ptr %72(ptr noundef nonnull %66, i32 noundef %8) #10
  %74 = icmp eq ptr %73, null
  br i1 %74, label %75, label %79

75:                                               ; preds = %69
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.10, i32 noundef %8) #10
  %76 = load ptr, ptr %66, align 8, !tbaa !32
  %77 = getelementptr inbounds i8, ptr %76, i64 40
  %78 = load ptr, ptr %77, align 8
  call void %78(ptr noundef nonnull %66) #10
  br label %139

79:                                               ; preds = %69
  %80 = load ptr, ptr %73, align 8, !tbaa !32
  %81 = getelementptr inbounds i8, ptr %80, i64 280
  %82 = load ptr, ptr %81, align 8
  %83 = call i64 %82(ptr noundef nonnull %73) #10
  %84 = inttoptr i64 %83 to ptr
  %85 = icmp eq i64 %83, 0
  br i1 %85, label %139, label %86

86:                                               ; preds = %79, %131
  %87 = phi i64 [ %132, %131 ], [ 0, %79 ]
  %88 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %87
  %89 = getelementptr inbounds i8, ptr %88, i64 16
  %90 = load ptr, ptr %89, align 16, !tbaa !38
  %91 = icmp eq ptr %90, null
  br i1 %91, label %98, label %113

92:                                               ; preds = %125
  %93 = getelementptr inbounds i8, ptr %127, i64 16
  br label %100

94:                                               ; preds = %119
  %95 = getelementptr inbounds i8, ptr %121, i64 16
  br label %100

96:                                               ; preds = %113
  %97 = getelementptr inbounds i8, ptr %115, i64 16
  br label %100

98:                                               ; preds = %86
  %99 = getelementptr inbounds i8, ptr %88, i64 16
  br label %100

100:                                              ; preds = %98, %96, %94, %92
  %101 = phi i64 [ %126, %92 ], [ %120, %94 ], [ %114, %96 ], [ %87, %98 ]
  %102 = phi ptr [ %127, %92 ], [ %121, %94 ], [ %115, %96 ], [ %88, %98 ]
  %103 = phi ptr [ %93, %92 ], [ %95, %94 ], [ %97, %96 ], [ %99, %98 ]
  %104 = trunc nuw nsw i64 %101 to i32
  store ptr %66, ptr %102, align 16, !tbaa !4
  %105 = getelementptr inbounds i8, ptr %102, i64 8
  store ptr %73, ptr %105, align 8, !tbaa !4
  store ptr %84, ptr %103, align 16, !tbaa !4
  %106 = getelementptr inbounds i8, ptr %102, i64 24
  store i64 %0, ptr %106, align 8, !tbaa !23
  %107 = getelementptr inbounds i8, ptr %102, i64 32
  store i64 %1, ptr %107, align 16, !tbaa !23
  %108 = getelementptr inbounds i8, ptr %102, i64 40
  store ptr null, ptr %108, align 8, !tbaa !4
  %109 = load i32, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  %110 = icmp ugt i32 %109, %104
  br i1 %110, label %134, label %111

111:                                              ; preds = %100
  %112 = add nuw nsw i32 %104, 1
  store i32 %112, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  br label %134

113:                                              ; preds = %86
  %114 = or disjoint i64 %87, 1
  %115 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %114
  %116 = getelementptr inbounds i8, ptr %115, i64 16
  %117 = load ptr, ptr %116, align 16, !tbaa !38
  %118 = icmp eq ptr %117, null
  br i1 %118, label %96, label %119

119:                                              ; preds = %113
  %120 = or disjoint i64 %87, 2
  %121 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %120
  %122 = getelementptr inbounds i8, ptr %121, i64 16
  %123 = load ptr, ptr %122, align 16, !tbaa !38
  %124 = icmp eq ptr %123, null
  br i1 %124, label %94, label %125

125:                                              ; preds = %119
  %126 = or disjoint i64 %87, 3
  %127 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %126
  %128 = getelementptr inbounds i8, ptr %127, i64 16
  %129 = load ptr, ptr %128, align 16, !tbaa !38
  %130 = icmp eq ptr %129, null
  br i1 %130, label %92, label %131

131:                                              ; preds = %125
  %132 = add nuw nsw i64 %87, 4
  %133 = icmp eq i64 %132, 8192
  br i1 %133, label %136, label %86, !llvm.loop !41

134:                                              ; preds = %100, %111
  %135 = phi i32 [ %109, %100 ], [ %112, %111 ]
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.11, i64 noundef %83, i32 noundef %104, i32 noundef %135, i32 noundef 8192) #10
  br label %139

136:                                              ; preds = %131
  %137 = load i1, ptr @_ZZ19os_map_kernel_spaceE6warned, align 1
  br i1 %137, label %139, label %138

138:                                              ; preds = %136
  store i1 true, ptr @_ZZ19os_map_kernel_spaceE6warned, align 1
  call void (ptr, ...) @kprintf(ptr noundef nonnull @.str.12, i32 noundef 8192, i64 noundef %0, i64 noundef %1) #10
  br label %139

139:                                              ; preds = %64, %75, %68, %134, %79, %138, %136
  %140 = phi ptr [ %11, %64 ], [ %84, %134 ], [ null, %79 ], [ %84, %138 ], [ %84, %136 ], [ null, %68 ], [ null, %75 ]
  ret ptr %140
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i1 @nv_pm_is_gpu(i64 noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare ptr @nv_pm_alias(i64 noundef, i64 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @nv_pm_foreign(i64 noundef, i64 noundef, i32 noundef, ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.returnaddress(i32 immarg) #7

; Function Attrs: noimplicitfloat noredzone
declare ptr @_ZN18IOMemoryDescriptor19withPhysicalAddressEyyj(i64 noundef, i64 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none)
define i64 @nv_xnu_phys_for_kernel_va(ptr noundef %0) local_unnamed_addr #8 {
  %2 = load i32, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %29, label %4

4:                                                ; preds = %1
  %5 = zext i32 %2 to i64
  br label %6

6:                                                ; preds = %4, %26
  %7 = phi i64 [ 0, %4 ], [ %27, %26 ]
  %8 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %7
  %9 = getelementptr inbounds i8, ptr %8, i64 16
  %10 = load ptr, ptr %9, align 16, !tbaa !38
  %11 = icmp eq ptr %10, null
  %12 = icmp ugt ptr %10, %0
  %13 = or i1 %11, %12
  br i1 %13, label %26, label %14

14:                                               ; preds = %6
  %15 = getelementptr inbounds i8, ptr %8, i64 32
  %16 = load i64, ptr %15, align 16, !tbaa !42
  %17 = getelementptr inbounds i8, ptr %10, i64 %16
  %18 = icmp ugt ptr %17, %0
  br i1 %18, label %19, label %26

19:                                               ; preds = %14
  %20 = getelementptr inbounds i8, ptr %8, i64 24
  %21 = load i64, ptr %20, align 8, !tbaa !43
  %22 = ptrtoint ptr %0 to i64
  %23 = ptrtoint ptr %10 to i64
  %24 = sub i64 %22, %23
  %25 = add i64 %24, %21
  br label %29

26:                                               ; preds = %6, %14
  %27 = add nuw nsw i64 %7, 1
  %28 = icmp eq i64 %27, %5
  br i1 %28, label %29, label %6, !llvm.loop !44

29:                                               ; preds = %26, %1, %19
  %30 = phi i64 [ %25, %19 ], [ 0, %1 ], [ 0, %26 ]
  ret i64 %30
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_unmap_kernel_space(ptr noundef readnone %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ21os_unmap_kernel_spaceE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ21os_unmap_kernel_spaceE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_unmap_kernel_space) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = load i32, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %35, label %8

8:                                                ; preds = %5
  %9 = zext i32 %6 to i64
  br label %13

10:                                               ; preds = %13
  %11 = add nuw nsw i64 %14, 1
  %12 = icmp eq i64 %11, %9
  br i1 %12, label %35, label %13, !llvm.loop !45

13:                                               ; preds = %8, %10
  %14 = phi i64 [ 0, %8 ], [ %11, %10 ]
  %15 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %14
  %16 = getelementptr inbounds i8, ptr %15, i64 16
  %17 = load ptr, ptr %16, align 16, !tbaa !38
  %18 = icmp eq ptr %17, %0
  br i1 %18, label %19, label %10

19:                                               ; preds = %13
  %20 = getelementptr inbounds i8, ptr %15, i64 40
  %21 = load ptr, ptr %20, align 8, !tbaa !46
  %22 = icmp eq ptr %21, null
  br i1 %22, label %24, label %23

23:                                               ; preds = %19
  tail call void @nv_pm_alias_drop(ptr noundef nonnull %21) #10
  br label %34

24:                                               ; preds = %19
  %25 = getelementptr inbounds i8, ptr %15, i64 8
  %26 = load ptr, ptr %25, align 8, !tbaa !47
  %27 = load ptr, ptr %26, align 8, !tbaa !32
  %28 = getelementptr inbounds i8, ptr %27, i64 40
  %29 = load ptr, ptr %28, align 8
  tail call void %29(ptr noundef nonnull %26) #10
  %30 = load ptr, ptr %15, align 16, !tbaa !48
  %31 = load ptr, ptr %30, align 8, !tbaa !32
  %32 = getelementptr inbounds i8, ptr %31, i64 40
  %33 = load ptr, ptr %32, align 8
  tail call void %33(ptr noundef nonnull %30) #10
  br label %34

34:                                               ; preds = %24, %23
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(48) %15, i8 0, i64 48, i1 false)
  br label %35

35:                                               ; preds = %10, %5, %34
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @nv_pm_alias_drop(ptr noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none)
define range(i32 0, 2) i32 @nv_xnu_kmap_overlap(i64 noundef %0, i64 noundef %1) local_unnamed_addr #8 {
  %3 = load i32, ptr @_ZL16nv_xnu_maps_high, align 4, !tbaa !16
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %35, label %5

5:                                                ; preds = %2
  %6 = add i64 %1, %0
  %7 = zext i32 %3 to i64
  br label %8

8:                                                ; preds = %5, %28
  %9 = phi i64 [ 0, %5 ], [ %29, %28 ]
  %10 = phi i1 [ true, %5 ], [ %30, %28 ]
  %11 = getelementptr inbounds [8192 x %struct.nv_xnu_map], ptr @_ZL11nv_xnu_maps, i64 0, i64 %9
  %12 = getelementptr inbounds i8, ptr %11, i64 16
  %13 = load ptr, ptr %12, align 16, !tbaa !38
  %14 = icmp eq ptr %13, null
  br i1 %14, label %28, label %15

15:                                               ; preds = %8
  %16 = getelementptr inbounds i8, ptr %11, i64 40
  %17 = load ptr, ptr %16, align 8, !tbaa !46
  %18 = icmp eq ptr %17, null
  br i1 %18, label %19, label %28

19:                                               ; preds = %15
  %20 = getelementptr inbounds i8, ptr %11, i64 24
  %21 = load i64, ptr %20, align 8, !tbaa !43
  %22 = getelementptr inbounds i8, ptr %11, i64 32
  %23 = load i64, ptr %22, align 16, !tbaa !42
  %24 = add i64 %23, %21
  %25 = icmp ugt i64 %24, %0
  %26 = icmp ult i64 %21, %6
  %27 = and i1 %26, %25
  br i1 %27, label %32, label %28

28:                                               ; preds = %8, %15, %19
  %29 = add nuw nsw i64 %9, 1
  %30 = icmp ult i64 %29, %7
  %31 = icmp eq i64 %29, %7
  br i1 %31, label %32, label %8, !llvm.loop !49

32:                                               ; preds = %19, %28
  %33 = phi i1 [ %30, %28 ], [ %10, %19 ]
  %34 = zext i1 %33 to i32
  br label %35

35:                                               ; preds = %32, %2
  %36 = phi i32 [ 0, %2 ], [ %34, %32 ]
  ret i32 %36
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_io_write_byte(i32 noundef %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ16os_io_write_byteE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ16os_io_write_byteE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_write_byte) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = trunc i32 %0 to i16
  tail call void asm sideeffect "outb $0, $1", "{ax},{dx},~{dirflag},~{fpsr},~{flags}"(i8 %1, i16 %6) #11, !srcloc !50
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_io_write_word(i32 noundef %0, i16 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ16os_io_write_wordE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ16os_io_write_wordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_write_word) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = trunc i32 %0 to i16
  tail call void asm sideeffect "outw $0, $1", "{ax},{dx},~{dirflag},~{fpsr},~{flags}"(i16 %1, i16 %6) #11, !srcloc !51
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_io_write_dword(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = load i1, ptr @_ZZ17os_io_write_dwordE2_t, align 1
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  store i1 true, ptr @_ZZ17os_io_write_dwordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_write_dword) #10
  br label %5

5:                                                ; preds = %2, %4
  %6 = trunc i32 %0 to i16
  tail call void asm sideeffect "outl $0, $1", "{ax},{dx},~{dirflag},~{fpsr},~{flags}"(i32 %1, i16 %6) #11, !srcloc !52
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i8 @os_io_read_byte(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ15os_io_read_byteE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ15os_io_read_byteE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_read_byte) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = trunc i32 %0 to i16
  %6 = tail call i8 asm sideeffect "inb $1, $0", "={ax},{dx},~{dirflag},~{fpsr},~{flags}"(i16 %5) #11, !srcloc !53
  ret i8 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i16 @os_io_read_word(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ15os_io_read_wordE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ15os_io_read_wordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_read_word) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = trunc i32 %0 to i16
  %6 = tail call i16 asm sideeffect "inw $1, $0", "={ax},{dx},~{dirflag},~{fpsr},~{flags}"(i16 %5) #11, !srcloc !54
  ret i16 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @os_io_read_dword(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_io_read_dwordE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_io_read_dwordE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_io_read_dword) #10
  br label %4

4:                                                ; preds = %1, %3
  %5 = trunc i32 %0 to i16
  %6 = tail call i32 asm sideeffect "inl $1, $0", "={ax},{dx},~{dirflag},~{fpsr},~{flags}"(i16 %5) #11, !srcloc !55
  ret i32 %6
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_registry_init() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ16os_registry_initE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ16os_registry_initE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_registry_init) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @os_is_vgx_hyper() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ15os_is_vgx_hyperE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ15os_is_vgx_hyperE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_is_vgx_hyper) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @os_is_grid_supported() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ20os_is_grid_supportedE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ20os_is_grid_supportedE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_is_grid_supported) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef zeroext i8 @os_is_efi_enabled() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ17os_is_efi_enabledE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ17os_is_efi_enabledE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_is_efi_enabled) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i8 1
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_get_is_openrm(ptr nocapture noundef writeonly %0) local_unnamed_addr #0 {
  %2 = load i1, ptr @_ZZ16os_get_is_openrmE2_t, align 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %1
  store i1 true, ptr @_ZZ16os_get_is_openrmE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_get_is_openrm) #10
  br label %4

4:                                                ; preds = %1, %3
  store i8 1, ptr %0, align 1, !tbaa !12
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_disable_console_access() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ25os_disable_console_accessE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ25os_disable_console_accessE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_disable_console_access) #10
  br label %3

3:                                                ; preds = %0, %2
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_enable_console_access() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ24os_enable_console_accessE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ24os_enable_console_accessE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_enable_console_access) #10
  br label %3

3:                                                ; preds = %0, %2
  ret void
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_flush_cpu_cache_all() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ22os_flush_cpu_cache_allE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ22os_flush_cpu_cache_allE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_flush_cpu_cache_all) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define noundef i32 @os_flush_user_cache() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ19os_flush_user_cacheE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ19os_flush_user_cacheE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_flush_user_cache) #10
  br label %3

3:                                                ; preds = %0, %2
  ret i32 0
}

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @os_flush_cpu_write_combine_buffer() local_unnamed_addr #0 {
  %1 = load i1, ptr @_ZZ33os_flush_cpu_write_combine_bufferE2_t, align 1
  br i1 %1, label %3, label %2

2:                                                ; preds = %0
  store i1 true, ptr @_ZZ33os_flush_cpu_write_combine_bufferE2_t, align 1
  tail call void (ptr, ...) @kprintf(ptr noundef nonnull @.str, ptr noundef nonnull @__func__.os_flush_cpu_write_combine_buffer) #10
  br label %3

3:                                                ; preds = %0, %2
  tail call void asm sideeffect "sfence", "~{memory},~{dirflag},~{fpsr},~{flags}"() #11, !srcloc !56
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @copyin(i64 noundef, ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare i32 @copyout(ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone nounwind
declare i32 @memcmp(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #9

; Function Attrs: noimplicitfloat noredzone nounwind
declare i64 @strlen(ptr noundef) local_unnamed_addr #9

; Function Attrs: noimplicitfloat noredzone nounwind
declare i32 @strcmp(ptr noundef, ptr noundef) local_unnamed_addr #9

; Function Attrs: noimplicitfloat noredzone
declare i32 @ml_set_interrupts_enabled(i32 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @IOSimpleLockLock(ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @IOSimpleLockUnlock(ptr noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice20extendedConfigWrite8Eyh(ptr noundef, i64 noundef, i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef, i64 noundef, i16 noundef zeroext) local_unnamed_addr #1

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef, i64 noundef, i32 noundef) local_unnamed_addr #1

attributes #0 = { mustprogress noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noimplicitfloat noredzone "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #5 = { mustprogress nofree noimplicitfloat noredzone nounwind ssp willreturn memory(readwrite, argmem: none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree noimplicitfloat noredzone nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nocallback nofree nosync nounwind willreturn memory(none) }
attributes #8 = { mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(read, argmem: none, inaccessiblemem: none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { noimplicitfloat noredzone nounwind "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #10 = { nobuiltin noimplicitfloat noredzone nounwind "no-builtins" }
attributes #11 = { nounwind }
attributes #12 = { nobuiltin noimplicitfloat noredzone nounwind willreturn memory(none) "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"Apple clang version 17.0.0 (clang-1700.0.13.5)"}
!4 = !{!5, !5, i64 0}
!5 = !{!"any pointer", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C++ TBAA"}
!8 = !{i64 612}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !6, i64 0}
!11 = !{i64 754}
!12 = !{!6, !6, i64 0}
!13 = distinct !{!13, !14}
!14 = !{!"llvm.loop.mustprogress"}
!15 = !{!"auto-init"}
!16 = !{!17, !17, i64 0}
!17 = !{!"int", !6, i64 0}
!18 = distinct !{!18, !14}
!19 = distinct !{!19, !14}
!20 = !{!21, !5, i64 0}
!21 = !{!"_ZTS11nv_xnu_spin", !5, i64 0, !17, i64 8}
!22 = !{!21, !17, i64 8}
!23 = !{!24, !24, i64 0}
!24 = !{!"long long", !6, i64 0}
!25 = !{!26, !5, i64 0}
!26 = !{!"_ZTS15nv_xnu_pci_slot", !5, i64 0, !17, i64 8, !6, i64 12, !6, i64 13, !6, i64 14}
!27 = !{!26, !17, i64 8}
!28 = !{!26, !6, i64 12}
!29 = !{!26, !6, i64 13}
!30 = !{!26, !6, i64 14}
!31 = distinct !{!31, !14}
!32 = !{!33, !33, i64 0}
!33 = !{!"vtable pointer", !7, i64 0}
!34 = distinct !{!34, !14}
!35 = !{!36, !36, i64 0}
!36 = !{!"short", !6, i64 0}
!37 = distinct !{!37, !14}
!38 = !{!39, !5, i64 16}
!39 = !{!"_ZTS10nv_xnu_map", !5, i64 0, !5, i64 8, !5, i64 16, !24, i64 24, !24, i64 32, !5, i64 40}
!40 = distinct !{!40, !14}
!41 = distinct !{!41, !14}
!42 = !{!39, !24, i64 32}
!43 = !{!39, !24, i64 24}
!44 = distinct !{!44, !14}
!45 = distinct !{!45, !14}
!46 = !{!39, !5, i64 40}
!47 = !{!39, !5, i64 8}
!48 = !{!39, !5, i64 0}
!49 = distinct !{!49, !14}
!50 = !{i64 19195}
!51 = !{i64 19333}
!52 = !{i64 19471}
!53 = !{i64 19608}
!54 = !{i64 19755}
!55 = !{i64 19902}
!56 = !{i64 20740}
