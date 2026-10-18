# NVRM 单元集的未定义符号归类（R35）

来源：最近一次原生门禁的 `candidate-NVRM-undefined.txt`（`39084082896`，27 补丁）。

## 总数

**470** 个未定义符号（文件里另有一行 `ARGV=[...]`，不是符号）。

| 桶 | 数量 | 判定方式 | 含义 |
|---|---|---|---|
| 内核 KPI | **33** | 以 `_IO*`、`_OS*`、`_kern_*`、`_mach_*`、`_thread_*`、`_clock_*`、`_absolutetime*`、`_bzero/_memcpy/_strlcpy/_kprintf` 等开头 | 链接 kext 时由 kernel 提供，**不是缺口** |
| NullMoth/OGKM 风格 | **43** | `_nv_*`、`_nvkms*`、`_Rm*`、`_rm_*`、`_gpu*` | 见下，性质不同 |
| 其他 | **394** | 其余（C++ 运行时、IOService/IOKit 方法、RM 内部符号） | 未归类，需逐个核对 |

## 一个关键发现

43 个"OGKM 风格"符号里，**大部分是 `_nv_xnu_*`**，也就是 **NullMoth 自己这套代码里的函数**，例如：

```
_nv_xnu_alloc_md          _nv_xnu_isr_thread        _nv_xnu_phys_for_kernel_va
_nv_xnu_chat              _nv_xnu_log_init          _nv_xnu_dump_live_allocs
_nv_pm_is_gpu             _nv_pm_ram_submd          _nv_get_ctl_state
```

这些不是"取自 OGKM 的私有实现"，而是**同一棵仓库里、我们门禁没有编译的那些 TU**。也就是说：

> 470 个未定义里有一部分**只是单元集没选全**，不是结构性缺口。

这与"发行版 7.93 MB 不透明载荷"是两回事，不能混为一谈。

## 下一步（不需要实机）

1. 对 `_nv_xnu_*` / `_nv_pm_*` / `_nv_get_ctl_state` 逐个定位定义文件（`grep -rn 'nv_xnu_alloc_md' kexts/`），判断该文件是否可加入门禁编译；
2. 可加入的，加入 `native_compile.py` 的单元列表，重跑门禁，看未定义数量是否下降；
3. 不能加入的（依赖 OGKM 私有头/符号），单独登记原因；
4. 394 个"其他"按同样方式分批归类，不一次性扩大改动面。

## 边界

本文件只是**归类结果**，不是"缺口已缩小"的结论。未定义符号数下降才算进展，且需要门禁复跑证明。
