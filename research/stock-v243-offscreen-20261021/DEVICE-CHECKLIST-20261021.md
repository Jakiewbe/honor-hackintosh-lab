# 实机执行清单（A → B → C）

逐段做，上一段不通过就停，不要跳步。所有命令都在 macOS 侧（外接 SSD 上的系统）执行。
不涉及 Windows、内置盘、ESP、OpenCore、BIOS；不做睡眠测试；不改显示所有权。

---

## 0. 前置检查（只读，5 分钟）

```bash
mkdir -p ~/Desktop/g1-run
sw_vers | tee ~/Desktop/g1-run/sw_vers.txt
csrutil status | tee -a ~/Desktop/g1-run/sw_vers.txt
kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB|NVMTL' | tee ~/Desktop/g1-run/kextstat.txt
ls -l /Library/Extensions | grep -Ei 'NVRM|NVAccel|NVRMFB' | tee -a ~/Desktop/g1-run/kextstat.txt
system_profiler SPDisplaysDataType | tee ~/Desktop/g1-run/displays.txt
```

判据：`displays.txt` 里能看到 `10de:25a9` 对应的设备（哪怕没有加速）。
如果已安装的 kext 版本不是 v2.4.x，先记录版本，不要覆盖。

---

## 1. 构建候选（约 20–40 分钟，不加载）

```bash
cd ~/honor-hackintosh-lab
git fetch origin && git checkout 2b02575
bash research/stock-v243-offscreen-20261021/device-kextutil.sh
```

产物在 `~/Desktop/g1-kextutil/`：

- `internal-products/package-products/NVRM.kext`、`NVRMFB.kext`、`NVAccel.kext`
- `package-text/package-report.json`（应含 `"unresolved": {}`、`loader_dry_run` 三项 `exit: 0`）
- `kextutil-NVRM.txt` / `kextutil-NVRMFB.txt` / `kextutil-NVAccel.txt`

**先把 `package-report.json` 与三个 `kextutil-*.txt` 发回来**，确认后再做 A。

---

## A. 加载前解析（只读，不改系统状态）

A1 基线（已安装的发行版）：

```bash
for k in NVRM NVRMFB NVAccel; do
  sudo xcrun kextutil -n "/Library/Extensions/$k.kext" 2>&1 | tee ~/Desktop/g1-run/base-$k.txt
  echo "exit=${PIPESTATUS[0]}" | tee -a ~/Desktop/g1-run/base-$k.txt
done
```

A2 候选（刚构建的）：

```bash
for k in NVRM NVRMFB NVAccel; do
  bundle=~/Desktop/g1-kextutil/internal-products/package-products/$k.kext
  sudo xcrun kextutil -n "$bundle" 2>&1 | tee ~/Desktop/g1-run/cand-$k.txt
  echo "exit=${PIPESTATUS[0]}" | tee -a ~/Desktop/g1-run/cand-$k.txt
done
```

判据：六个文件全部 `exit=0`，且没有 `can't resolve symbol` / `unresolved`。
出现未解析就停，把文件发回来——不要加参数绕过。

---

## B. 装入（会改启动内核集合，先备份）

前置：外接 SSD 可回退、有快照或 Time Machine；内置盘与 ESP 不参与。

1. 备份当前 KC 并记录哈希：

```bash
sudo cp -a /System/Library/KernelCollections ~/Desktop/g1-run/KernelCollections.bak
shasum -a 256 /System/Library/KernelCollections/*.kc | tee ~/Desktop/g1-run/kc-before.txt
```

2. 用候选替换（沿用你此前安装该驱动的方式；若是 `/Library/Extensions`）：

```bash
for k in NVRM NVRMFB NVAccel; do
  sudo rm -rf "/Library/Extensions/$k.kext"
  sudo cp -R ~/Desktop/g1-kextutil/internal-products/package-products/$k.kext "/Library/Extensions/$k.kext"
  sudo chown -R root:wheel "/Library/Extensions/$k.kext"
done
sudo kmutil install --update-all 2>&1 | tee ~/Desktop/g1-run/kmutil-install.txt
```

3. 重启，然后：

```bash
kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' | tee ~/Desktop/g1-run/kextstat-after.txt
log show --last 5m --predicate 'eventMessage CONTAINS "NVRM" OR eventMessage CONTAINS "NVAccel"' \
  | tee ~/Desktop/g1-run/log-after.txt
```

判据：三个 kext 都出现在 `kextstat`；5 分钟内无 panic、无 `Kernel trap`、无 `can't load`。
**失败即回退**：把 `KernelCollections.bak` 放回、`sudo kmutil clear-staging`、重启。

---

## C. 离屏 Metal 验收（GPU 第一次真实执行）

前置：驱动与 Metal 插件已装好；插件只放行 `mtlprobe`/`nvmtltest`/`nvmtlrender`、
设了 `NVMTL_ENABLE` 的进程，或 allow-list 文件里的进程。

1. 构建验收程序（与 CI 同参数）：

```bash
cd ~/honor-hackintosh-lab
xcrun clang -arch x86_64 -mmacosx-version-min=15.5 -fobjc-arc -fblocks -O1 \
  -Wall -Wextra -Werror -Werror=unguarded-availability-new \
  research/stock-v243-offscreen-20261021/metal-offscreen.m \
  -framework Foundation -framework Metal -framework IOKit -framework CoreFoundation \
  -o ~/Desktop/g1-run/nvmtltest
shasum -a 256 ~/Desktop/g1-run/nvmtltest | tee ~/Desktop/g1-run/validator-sha.txt
```

2. 取 RTX 2050 的 registryID（两种方式，任选）：

```bash
swift -e 'import Metal; for d in MTLCopyAllDevices() { print(d.name, String(d.registryID, radix: 16)) }'
# 或
ioreg -rn IOPCIDevice -d 1 -l | grep -E 'IORegistryEntryID|"device-id"' | head -40
```

3. 运行（把 `<HEX>` 换成上一步 NVIDIA 设备的 ID）：

```bash
cd ~/Desktop/g1-run
sudo NVMTL_ENABLE=1 ./nvmtltest --execute-authorized --registry-id <HEX> 2>&1 | tee run.txt
echo "exit=${PIPESTATUS[0]}" | tee -a run.txt
log show --last 2m --predicate 'process == "kernel"' | tee kernel-during-run.txt
```

判据（程序内已实现，全部满足才打印 `APP_TEST_PASS`）：
registryID 唯一匹配且向上找到 `10DE:25A9`；64 个 uint32 与 CPU 预期逐项相等；
RGBA8 三角形绘制后像素逐项正确；无效着色器必须编译失败并带 NSError；
每条命令 10 s 超时、任何状态错误立即非零退出。

回退：删掉 `/Library/GPUBundles` 里的插件或 allow-list 行，重启。

---

## 回传清单

`~/Desktop/g1-run/` 下：`sw_vers.txt`、`kextstat*.txt`、`base-*.txt`、`cand-*.txt`、
`kernutil-install.txt`、`log-after.txt`、`run.txt`、`kernel-during-run.txt`、`validator-sha.txt`。

## 停止条件（任一出现就停，不要继续下一步）

- `kextutil -n` 出现未解析符号；
- 装入后 5 分钟内 panic 或 kext 未出现在 `kextstat`；
- 验收程序报 `RTX2050-registry-and-PCI-binding`（说明设备没被 Metal 暴露）；
- 内核日志出现 GPU 固件/MMU/超时错误。
