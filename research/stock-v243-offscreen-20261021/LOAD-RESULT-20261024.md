# 加载后实测结果 — 2026-10-24（设备 diag-20261024-065702）

设备：HONOR GLO-FX6P，macOS 15.8.1 (24H32)，Darwin 24.6.0 x86_64。
来源：`/Volumes/UNPLUGGED/HONOR-G1-FIRST-TOUCH/results/diag-20261024-065702.txt`（28,130 B）。
本文件只记录这份诊断里**能直接读到**的东西，不掺推断；推断另起一节并标注。

---

## 1. 事实：驱动已经进了内核，而且匹配上了 GPU

```
kextstat:
  163  0 0xffffff7f97174000 0xe47ff8  0xe47ff8  com.nullmoth.NVRM (0.1) 628F533F-...
ioreg:
  +-o NVRM  <class NVRM, id 0x1000005f2, registered, matched, active, busy 0 (510 ms), retain 6>
      "nvrm-bars" = "bar0@0x10:0x51000000+0x1000000  bar1@0x14:0x7e00000000+0x100000000  bar2@0x1c:0x7f00000000+0x2000000"
      "IOProbeScore" = 1000
      "IOPCIPrimaryMatch" = "0x000010de&0x0000ffff"
  ioreg NVRM instance count: 1
```

`registered, matched, active` 三个状态都在，instance count = 1。
aux KC 重建成效：`/Library/KernelCollections/AuxiliaryKernelExtensions.kc`
SHA256 `5f558fcd42af83141254ff8644b7b8025b7b462eea7c1d2b3600065b29964d44`。

## 2. 事实：RM 起来了，私有状态建好了，寄存器/显存都映射成功

```
rm_is_supported_device OK - this chip has a HAL and a GSP
rm_init_private_state OK
PASS 1 REACHED: RM initialised, private state built, GSP firmware requested
bus master + memory enabled (command 0x0006)
  interrupt source 0 type 0x1
  interrupt source 1 type 0x10000 (MSI)
MSI 1 armed; calling rm_init_adapter() — GSP boot from inside macOS
RmSetupRegisters for 0x10de:0x25a9
  registers look  like: 0x51000000 0x1000000
  fb        looks like: 0x7e00000000 0x100000000
Successfully mapped framebuffer and registers
  regs: 0x51000000 0x1000000 0x0xffffffd147aec000
  dma address size 47 bits
```

`nv_get_screen_info -> base 0x4000000000 2160x1440 depth 32 pitch 8640 size 12441600`
—— 这是从固件帧缓冲读到的当前面板模式（2160x1440 → 2160*1440*4 = 12,441,600，对得上）。

## 3. 事实：唯一挡路的是 GSP 固件文件不存在

```
nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin
  vnode_open failed 2                         <- 2 = ENOENT
NVRM: RmFetchGspRmImages: No firmware image found
NVRM: GPU 0000:01:00.0: RmInitAdapter failed! (0x61:0x56:2025)
rm_init_adapter -> FAILED
DMA buffers alive: 0
auto-go: go(2) -> 0xe00002bc (fPassDone 1)    <- 0xe00002bc = kIOReturnError
boot hold RELEASED (go(2) failed)
```

诊断里 `/Library/NullMoth` 状态：`(absent)` —— 整个目录都不存在，不只是缺一个文件。

固件路径是写死的，见 `kexts/NVRM/os-xnu2.cpp:29`：

```c
#define NV_XNU_FW_DIR "/Library/NullMoth/nvfw/nvidia/610.57.04/"
```

文件名由芯片族决定，`os-xnu2.cpp:42`：family=4（Ampere/GA10x）→ `gsp_ga10x.bin`；
`type=0` 就是 `NV_FIRMWARE_TYPE_GSP`。RTX 2050 是 GA107，所以选 ga10x 是对的。

## 4. 事实：驱动会按字节数 + SHA-1 校验固件（不是随便丢个文件就行）

`os-xnu2.cpp:1199` 的 `nv_xnu_fw_set[]`：

| 文件 | 字节数 | SHA-1 |
|---|---|---|
| `gsp_ga10x.bin` | 84,310,168 | `f11971026ccd86a7ea09ba525548c2e0615565ce` |
| `gsp_tu10x.bin` | 29,381,504 | `f20b8dc50f3576ec18c395c1b3b1cccc36bac194` |
| `ucodes_ga10x.bin` | 31,744 | `1daf70f4f9a256212dead6f1ba88c694c5ae3af9` |
| `ucodes_tu10x.bin` | 12,032 | `fe009104df714ad3d4233566aa0abb664614f8e9` |

不符时 `os-xnu2.cpp:1248-1253` 会打印
`firmware %s is not the image this driver shipped (... bytes on disk, ... expected) - refusing it`
然后返回 NULL，结果是和"文件不存在"一样的失败，但日志能区分。
另外 `os-xnu2.cpp:1234` 还会拒绝 0 字节和超过 `NV_XNU_FW_MAX_BYTES` 的文件。

## 5. 事实：显示头没有跑起来

```
headwatch: head 0 STOPPED at 27086 ms since boot (vline raw 0xbadf1301)
headwatch: head 1 STOPPED at 27086 ms since boot (vline raw 0xbadf1301)
headwatch: done
```

`IOPowerManagement` = `{"CurrentPowerState"=1,"CapabilityFlags"=32770,"MaxPowerState"=1}`，
`nvrm-pm = running`，`nvrm-boot-raster = unknown`。
没有 panic 文件。`kmutil-install.txt` 里失败的那几条是
`kernel.development / kernel.debug / kernel.kasan / kernel.research` 和 release collection
`Read-only file system` —— 那是重建系统 KC 时的正常后果，不是这次加载的失败原因；
真正生效的是 aux KC 重建那一段（见 `LOAD-EXPERIMENT-20261022.md` 与本轮 fix3 日志）。

## 6. 判断（与事实分开）

- **加载链已经通了**：kext → 匹配 → RM init → 寄存器/显存映射 → 申请固件。这条链在本项目里第一次全绿。
- **GPU 没跑起来的原因只有一个**：缺 GSP 固件。不是 vtable 问题、不是 aux KC 问题、不是符号问题。
- 补齐 `gsp_ga10x.bin`（并建议同时放 `ucodes_ga10x.bin`）后，`rm_init_adapter` 才可能过；
  过了才轮到 head/RM 后续、`NVAccel`、Metal。
- 这一轮**仍未**发生任何 GPU 计算，`program_executed=NO`、`gpu_executed=NO` 不变。

## 7. 下一步（用户执行）

1. 拿到 NVIDIA 610.57.04 驱动包里的 `firmware/gsp_ga10x.bin`（82 MB 级），
   连同 `ucodes_ga10x.bin`（31 KB）。
2. `bash G1-装固件.command /path/to/pkg` —— 脚本会找、按上表核对、装到
   `/Library/NullMoth/nvfw/nvidia/610.57.04/`（root:wheel 0644，目录 0755）。
3. `sudo reboot`，再跑 `G1-一键诊断.command`，看是否出现
   `nv_get_firmware ... firmware loaded: 84310168 bytes`。
