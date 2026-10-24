# 怎么把 GSP 固件弄到机器上（2026-10-24）

> **状态：已取到并放上 U 盘。** 详见下面「已完成的准备」一节。
> Mac 上只剩两步：`bash G1-装固件.command`、`sudo reboot`。

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

## 已完成的准备（2026-10-24，在 Windows 这一侧做完）

从上游发行包 `nullmoth-nvidia-2.4.2.tar.gz`（Release v2.4.2，269,134,785 B）取出固件，
**全部四个文件与驱动内建表逐字节相符**，已拷到 U 盘：

```
F:\HONOR-G1-FIRST-TOUCH\固件\gsp_ga10x.bin      84,310,168 B  f11971026ccd86a7ea09ba525548c2e0615565ce  OK
F:\HONOR-G1-FIRST-TOUCH\固件\ucodes_ga10x.bin       31,744 B  1daf70f4f9a256212dead6f1ba88c694c5ae3af9  OK
```

（`gsp_tu10x.bin` 29,381,504 B / `f20b8dc5…` 与 `ucodes_tu10x.bin` 12,032 B / `fe009104…`
也都核对通过，只是 RTX 2050 用不到，没往 U 盘放。）

取包过程本身也校验过：`nullmoth-nvidia-2.4.2.tar.gz` 大小 269,134,785 B 与 GitHub API
报告的 asset 大小一致；v2.5.3 的包另校验过 SHA-256
`6ec9d23f8d7e0ab340b9e0a9753f7c48722b9930118fff648d545e0b95016884`（与 `SHA256SUMS.txt` 一致）。

### 一个必须记住的坑：固件版本跟发行版本绑定

| 发行包 | 包里的固件目录 | 说明 |
|---|---|---|
| `nullmoth-nvidia-2.4.2` | `nvfw/nvidia/**610.57.04**/` | 我们这套 kext 要的就是这个 |
| `nullmoth-nvidia-2.5.3` | `nvfw/nvidia/**615.78.08**/` | 换这套就得整套换，不能只换固件 |

我们的 kext 是从 pin `272ccd9`（v2.4.2）+ 我们的补丁编出来的，
`os-xnu2.cpp:29` 写死 `610.57.04`，所以**必须用 2.4.x 的固件**。
拿 2.5.3 的 blob 会同时踩两个坑：目录名不对（直接 ENOENT）、哈希也不对（`os-xnu2.cpp:1248` 拒绝）。

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

U 盘里那两个脚本已经更新（`c350ac5` 之后），固件也已经放在 `固件/` 里了：

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
