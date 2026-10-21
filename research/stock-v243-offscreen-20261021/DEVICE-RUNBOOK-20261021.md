# 设备阶段执行手册（需在 macOS 侧由你执行，本仓库不代跑）

本轮把能在这台 Windows 主机和 GitHub runner 上做的部分都做了：**三组件静态审计通过**，
并用 `kextutil -n`（只做解析、不加载）对三个 bundle 做了加载前检查。下面两步必须在
GLO-FX6P 的 macOS 侧执行；harness 没有到那台机器的通路，因此这里给的是可执行步骤、判据与回退。

## A. NVAccel / NVRMFB / NVRM 的加载前解析（已在 runner 验证，可在设备上复验）

runner 上 run 39550544476（`c60f6ff`）结果：

| bundle | `kextutil -n` 退出码 | 未解析符号 |
|---|---|---|
| NVRM | 0 | 0 |
| NVRMFB | 0 | 0 |
| NVAccel | 0 | 0 |

设备上复验命令（**不加载**，可安全执行）：

```bash
xcrun kextutil -n /path/to/NVAccel.kext 2>&1 | tee ~/Desktop/NVAccel-kextutil.txt
xcrun kextutil -n /path/to/NVRMFB.kext 2>&1 | tee ~/Desktop/NVRMFB-kextutil.txt
xcrun kextutil -n /path/to/NVRM.kext    2>&1 | tee ~/Desktop/NVRM-kextutil.txt
```

判据：三条命令都以 0 退出、输出中没有 `can't resolve` / `unresolved`。任何一条不满足就停，
把文本发回来。这一步不改变系统状态。

## B. 装入隔离 KC（需要你确认后执行）

> 这一阶段会改变系统启动内核集合，属于设备阶段。执行前请确认：外接 SSD 上的 macOS 可回退、
> 有 Time Machine 或快照、内置 Windows 与 ESP 不在操作范围内。

1. 备份当前启动 KC：
   `sudo cp -a /System/Library/KernelCollections/BootKernelExtensions.kc ~/Desktop/BootKernelExtensions.kc.bak`
   并记录 `shasum -a 256`。
2. 复制 bundle 到 `/Library/Extensions/`，权限 `root:wheel`，然后：
   `sudo kmutil install --update-all`（或按你现有流程重建 AuxKC）。
3. 重启，检查：
   `kextstat | grep -E 'NVRM|NVRMFB|NVAccel'`
   `log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"'`
4. 判据：三个 bundle 都出现在 `kextstat`，5 分钟内无 panic、无 `Kernel trap`。
   失败即回退：`sudo kmutil clear-staging`，把备份的 KC 放回并重启。

**不要**在这一步做 GPU 初始化、不要跑 Metal 验收程序；先把"能解析、能加载、能卸载"分开验证。

## C. 离屏 Metal 验收程序

编译产物已就绪（源码 `539e9ae6…`、二进制 `aa65a54f…`、run 39535625079）。

1. 进程准入：插件只放行名为 `mtlprobe`/`nvmtltest`/`nvmtlrender` 的进程、或设了 `NVMTL_ENABLE`
   的进程、或 `/Library/GPUBundles/nvmtl-allow.txt` 里的进程。把可执行文件命名为 `nvmtltest`
   或写入 allow-list，或用 `NVMTL_ENABLE=1` 启动。
2. 运行：
   ```bash
   sudo NVMTL_ENABLE=1 ./nvmtltest --execute-authorized --registry-id <RTX2050 的 registryID 十六进制>
   ```
3. 判据（程序自身已实现，全部满足才输出 `APP_TEST_PASS`）：
   - registryID 唯一匹配且向上找到 `10DE:25A9`；
   - 64 个 uint32 计算结果与 CPU 预期逐项相等；
   - RGBA8 纹理真实三角形绘制后像素逐项正确；
   - 无效着色器编译必须失败并带 NSError；
   - 每条命令 10 秒超时、任何状态错误立即非零退出。
4. 同时保存 `log show --last 2m --predicate 'process == "kernel"'`，用于确认是 GPU 固件/驱动错误
   而不是程序自身失败。
5. 回退：删除 `/Library/GPUBundles` 中的插件或 allow-list 行，重启。

## D. 类布局反解（第 3 项的现状）

- 目标：从 `SystemKernelExtensions.kc` 反解 `IOAccelSurface` 等类的真实 vtable 槽位，验证
  本轮"把 7 个虚函数裁掉"是否与 macOS 15.7.9 一致。
- 已试：直接按 raw QWORD 读 vtable → 全 `UNRESOLVED`，因为 KC 用 **chained fixups** 编码指针；
  `xcrun dyld_info -fixups` 在 365 MB 的 KC 上直接 **assertion failed**（工具限制）。
- 下一步（未做）：自己解析 `LC_DYLD_CHAINED_FIXUPS`，按 segment 起点表还原每个 vtable 槽的目标地址，
  再与 nlist 的 `N_EXT|N_SECT` 符号对齐；或者用 `kmutil` 导出的 per-member 信息交叉验证。
- 在拿到真实槽位之前，"裁掉 7 个虚函数"只有 `kextutil -n` 0 未解析这一层证据，**不等于** vtable
  ABI 正确。
