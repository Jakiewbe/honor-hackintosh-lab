# 怎么把 GSP 固件弄到机器上（2026-10-24）

设备现状（已实测，见 `LOAD-RESULT-20261024.md`）：驱动进了内核、匹配了 GPU、RM 跑到
`PASS 1`，唯一失败是固件文件不在盘上：

```
nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin
  vnode_open failed 2                        <- ENOENT
RmFetchGspRmImages: No firmware image found
```

所以只需要一个文件：`gsp_ga10x.bin`（84,310,168 B，SHA-1
`f11971026ccd86a7ea09ba525548c2e0615565ce`），外加建议放的 `ucodes_ga10x.bin`
（31,744 B，`1daf70f4f9a256212dead6f1ba88c694c5ae3af9`）。

---

## 这个文件从哪来（两条路，都是 NVIDIA 原样未改）

### 路 A：NullMoth 发行包里自带（最稳，哈希必然对上）

上游 `package/install.sh:11` 定义：

```sh
EXT=/Library/Extensions; GB=/Library/GPUBundles; FW=/Library/NullMoth/nvfw; FWOLD=/Users/Shared/nvfw
```

`package/install.sh:302` 是这一行在装固件：

```sh
ditto "$HERE/Users/Shared/nvfw" "$FW" || die "copy firmware"
```

也就是**发行包根目录里的 `Users/Shared/nvfw/` 就是固件**，路径是：

```
<解开的发行包>/Users/Shared/nvfw/nvidia/610.57.04/gsp_ga10x.bin
<解开的发行包>/Users/Shared/nvfw/nvidia/610.57.04/ucodes_ga10x.bin
```

发行包形式任选其一：

- `nullmoth-nvidia-<version>.tar.gz`（README:57 的 Releases 下载）
- `1401-Mac-<version>.dmg`（README:72，DMG 里带同一份 driver package）

README:41 也写明这一项：`GPU firmware (GSP) | /Users/Shared/nvfw/nvidia/610.57.04 | NVIDIA, unmodified`。

### 路 B：NVIDIA r610 Linux 驱动包

驱动是 `open-gpu-kernel-modules` tag `610.57.04`（README:155），固件就来自同版本的
NVIDIA Linux 驱动包 `NVIDIA-Linux-x86_64-610.57.04.run` 里的：

```
NVIDIA-Linux-x86_64-610.57.04/firmware/gsp_ga10x.bin
NVIDIA-Linux-x86_64-610.57.04/firmware/ucodes_ga10x.bin
```

版本必须正好是 **610.57.04**：驱动按字节数 + SHA-1 校验（`os-xnu2.cpp:1199`），
换成别的版本的 blob 会被拒绝，日志会写
`is not the image this driver shipped (... bytes on disk, ... expected)`。

---

## Windows 这边怎么做（当前这台机器）

1. 用 7-Zip 打开 `nullmoth-nvidia-*.tar.gz`：**解两次**（`.tar.gz` → `.tar` → 目录）。
2. 进到 `Users\Shared\nvfw\nvidia\610.57.04\`，确认有 `gsp_ga10x.bin`。
3. 校验（PowerShell，注意 certutil 输出是带空格的大写）：

   ```powershell
   certutil -hashfile .\gsp_ga10x.bin SHA1
   (Get-Item .\gsp_ga10x.bin).Length
   ```

   期望：`f11971026ccd86a7ea09ba525548c2e0615565ce`，长度 `84310168`。
4. 建目录并拷进 U 盘：

   ```powershell
   New-Item -ItemType Directory -Force F:\HONOR-G1-FIRST-TOUCH\固件
   Copy-Item .\gsp_ga10x.bin,F:\...\ucodes_ga10x.bin F:\HONOR-G1-FIRST-TOUCH\固件\
   ```

## Mac 这边怎么做

U 盘里那两个脚本已经更新（`a9782fd` 之后）：

```bash
cd /Volumes/UNPLUGGED/HONOR-G1-FIRST-TOUCH
bash G1-装固件.command          # 不带参数：自动在 固件/ firmware/ nvfw/ ~/Downloads 里找
```

它会：找 → 按表核对字节数 + SHA-1 → 装到
`/Library/NullMoth/nvfw/nvidia/610.57.04/`（`root:wheel 0644`，目录 `0755`）→ 打印判决。
任何一个文件不符就一个都不装，直接退出 5。

然后：

```bash
sudo reboot
bash G1-一键诊断.command
```

成功的样子（内核日志）：

```
nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin
  firmware loaded: 84310168 bytes
```

诊断 v3 的结论区会出现 `GSP 固件已装载: yes`，判定从
“卡在 GSP 固件不在盘上”变成“这一关过了，看 head/RM 后续日志”。

---

## 两条硬提醒

1. **不要运行发行包里的 `install.sh`。** 它会覆盖 `/Library/Extensions`、
   `/Library/GPUBundles` 和 aux KC——把我们自己编译的 kext 换掉，等于把这几轮的工作
   全部作废。我们只需要固件那一个目录。
2. 固件的校验不是可选的：`os-xnu2.cpp:1234` 还会拒绝 0 字节和超限大小的文件，
   `os-xnu2.cpp:1248` 会拒绝哈希不符的文件，两者都表现为
   “RmAInitAdapter 失败”，日志里的措辞能区分开。装完先看 `verify.txt`。
