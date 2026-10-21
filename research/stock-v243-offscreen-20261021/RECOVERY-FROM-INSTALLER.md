# 从安装盘救回（Recovery 步骤）

前提：如果首次加载后 panic / 卡在苹果 logo，用**已有的安装盘（E: OCINSTALL）**启动，不用第二套 macOS。
安装盘就是可启动的 Recovery：能开终端、能挂载外接 SSD、能删 kext 和重建内核集合。

## 1. 从 E: 启动

开机按住 Option（或 OpenCore 菜单）→ 选 E: 上的安装器/Recovery 入口 → 进入"macOS 实用工具"。

## 2. 打开终端，先认清盘

```bash
diskutil list
ls /Volumes
```

外接 SSD 的系统卷通常显示为 `Macintosh HD` 或你起的名字，下面记作 `<VOL>`。

## 3. 删掉候选（最快恢复）

```bash
sudo rm -rf "/Volumes/<VOL>/Library/Extensions/NVRM.kext"
```

如果 `/Volumes/<VOL>/Library/Extensions` 里还有 NVRMFB/NVAccel 且它们也是这次装的，一并删。

## 4. 重建该卷的内核集合

```bash
sudo kmutil install --volume "/Volumes/<VOL>" --update-all
```

如果这条不可用（老系统），退而用：

```bash
sudo kextcache -i "/Volumes/<VOL>"
```

## 5. 恢复 boot-args（去掉 -nvrmnogo）

```bash
nvram boot-args="-v debug=0x100 keepsyms=1 -vi2c-force-polling ctrsmt=full nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 cpus=8"
```

（这是 2026-10-22 备份里的原文，见 `boot-args-before.txt`。）

## 6. 重启回外接 SSD

```bash
reboot
```

## 7. 用完整备份还原（更彻底）

备份在 F: 的 `g1-first-touch`：

```bash
ls /Volumes               # 找到存备份的卷，记作 <USB>
cp -R "/Volumes/<USB>/g1-first-touch/Extensions/." "/Volumes/<VOL>/Library/Extensions/"
shasum -a 256 "/Volumes/<USB>/g1-first-touch/KernelCollections/"*.kc
sudo kmutil install --volume "/Volumes/<VOL>" --update-all
```

注意：备份里的 `.kc` 是**实验前**的版本；直接覆盖 KC 只适合应急，正常还是让 `kmutil` 重建。

## 8. 确认恢复成功

回到系统后：

```bash
kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB'      # 应该没有输出
shasum -a 256 /System/Library/KernelCollections/*.kc
```

与 `kc-before.txt` 对比，确认回到实验前状态。
