# 设备基线（GLO-FX6P，2026-10-22 备份）

来源：用户在真机执行 `first-touch.sh backup`，把 `~/Desktop/g1-first-touch` 拷到 `F:\g1-first-touch`。
全部只读采集，没有加载、没有改 KC。

## 1. 真实系统与 CI 不同（重要）

| 项 | 设备 | 之前所有静态证据用的 CI |
|---|---|---|
| SystemKernelExtensions.kc SHA256 | `2296155f1f12471e7b774020ba70d9fb487d02224c1f85d373130511969c2243` | `12913116a90b3875e42f17ab42261875205e3cd5463fb7744b1a488b24df67c2` |
| 字节数 | **373,112,832** | 365,887,488 |
| BootKernelExtensions.kc SHA256 | `cd013c14a7f21dbb8181fb06c44e079de8646b6a674abe21f6e47f42e8979af3` | — |
| IOAcceleratorFamily2 成员 fileoff | 350,302,208 | 344,207,360 |
| 成员 UUID | `97a7305cfb1439fcbc20ed834abceb2d` | `65ceb805d3263f159595f6ec0a6d78da` |

结论：**设备不是 CI 那台 macOS 的同一构建**。必须用设备自己的 KC 复核，不能把 CI 的结论直接搬过来。

## 2. 用设备 KC 复核 ABI 槽位：与 CI 完全一致

对设备 KC 跑 `tools/g1_kc_vtable_bounded.py`（有界观察，不宣称完整布局）：

| 类 | vtable | 原始字数 | 关键槽位 |
|---|---|---:|---|
| IOAccelSurface | `0x14e8cab0` | 328 | 322 `set_shape`、323 `set_shape_backing_length_ext`、324 `surface_lock_options`、325 `surface_unlock_options`、326 `surface_control_with_lock` |
| IOAccelGLContext2 | `0x14e864e0` | 374 | 366 `processSwap` |
| IOAccelLegacyDisplayPipe | `0x14e8bd38` | 319 | 308 `setStereo(IOAccelStereoMode)` |
| IOAccelLegacyDisplayMachine | `0x14e7d3f0` | 299 | 286 `setStereo(unsigned, IOAccelStereoMode)` |

四个类的字数（328/374/319/299）与 CI 完全相同，槽位也完全相同。
**这是设备绑定证据**：之前审计要求的"用户真实系统绑定"，在这一项上补齐了。

## 3. 27 个 local-only 名称在设备 KC 上

| 项 | 结果 |
|---|---|
| 27 个名称在设备 nlist 中 | **27 / 27 全部存在** |
| 带外部导出位（N_EXT） | **0** |
| 成员里的导出 trie | **不存在**（`LC_DYLD_EXPORTS_TRIE` / `LC_DYLD_INFO` 均无） |
| 27 项命中导出 | **0 / 27** |

与 CI 结论一致，而且现在是在设备自己的 KC 上得到的：这些函数存在、被 vtable 引用，但没有外部导出元数据。

## 4. 设备当前没有装 NullMoth 驱动

`kextstat-before.txt`（175 行）里没有任何 `NVRM` / `NVAccel` / `NVRMFB`。
`/Library/Extensions` 备份里只有 `HighPointIOP.kext` 与 `HighPointRR.kext`（第三方 RAID 驱动）。

**这意味着：**

- 首次接触实验没有"发行版 NVRM"可作回退；回退方式是**删除候选**，而不是恢复旧包。
  `first-touch.sh` 已按此修正（备份时记录 `nvrm-was-installed.txt`，回退时按情况处理）。
- 装上去的三个 kext 会是系统上第一次出现的 NullMoth 驱动。

## 5. 安全策略与 boot-args

```
System Integrity Protection status: unknown (Custom Configuration).
  Kext Signing: disabled
  Filesystem Protections: disabled
  NVRAM Protections: disabled
```

```
boot-args  -v debug=0x100 keepsyms=1 -vi2c-force-polling ctrsmt=full nvfb=1 nvaccel=1 \
           nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 \
           ipc_control_port_options=0 cpus=8
```

`nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth` 已经是为这套驱动准备的；首次接触只需在其后追加 `-nvrmnogo`，
回退时还原为上面这串原文。

## 6. 对首次接触实验的影响

| 项 | 状态 |
|---|---|
| 回退方式 | 改为"删除候选"，已修脚本 |
| ABI 槽位证据 | ✅ 设备绑定，与 CI 一致 |
| 27 项导出 | ⛔ 设备上同样不可观测（结构如此） |
| 设备 KC 哈希 | 已记录，可作为实验前后的对照 |
| 仍缺 | 可独立启动的第二条引导路径（脚本无法替你做） |

## 7. 复现命令

```bash
python tools/g1_kc_vtable_bounded.py /path/to/SystemKernelExtensions.kc --out device-vtable.json
python tools/g1_kc_exports.py /path/to/SystemKernelExtensions.kc com.apple.iokit.IOAcceleratorFamily2 \
  --names names.json
```
