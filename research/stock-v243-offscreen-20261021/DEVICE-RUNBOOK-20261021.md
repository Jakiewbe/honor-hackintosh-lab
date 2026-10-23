# 旧设备执行手册已撤回

旧稿把 kextutil -n、局部 vtable 和构建通过扩大为“只剩加载”，并提供了未经验证的 KC 回退和 GPU 命令。
这些设备步骤不具备准入条件，已撤回；历史原文保留在 Git 历史，不作为当前执行指令。

唯一当前入口：[设备前检查与后续准入](DEVICE-CHECKLIST-20261021.md)。
A 为只读脚本设计，尚未在设备执行；B/C 均 NO-GO。

原始编译/链接结果仍有效，20项local-only导出、完整ABI、恢复能力、生命周期/PM和真实GPU执行仍未验收。

## 2026-10-23 修复脚本 v3.1：旧版本为什么必失败

设备实测（esults/fix-20261023-031910/S4-install.log）证明第三方 kext 装不上辅助集合的**不是**权限问题，
而是 v2 修复脚本走了 `kmutil install --update-all`：它会重建 Boot/System/development/debug/kasan/research
全部集合，System 卷是封存的只读卷，于是卡在

```
failed to build release collection:
    Error Domain=NSPOSIXErrorDomain Code=30 "Read-only file system"
```

上游 nullmoth 的 `package/install.sh` 从不这么做：它只建辅助集合

```
kmutil create -n aux --volume-root / --allow-missing-kdk \
  -B <BootKernelExtensions.kc> -S <SystemKernelExtensions.kc> \
  --repository <目录> -A <输出> -z
```

先在 /tmp 建测试集合并用 `kmutil inspect -a x86_64 -A` 确认含 `com.nullmoth.NVRM`，再建正式集合并原子替换。

### v3.1 与上游的逐项对齐

| 上游做法 | v3.1 |
| --- | --- |
| 只用 `kmutil create -n aux` | 同 |
| `KARG=(--allow-missing-kdk); [ -f /System/Library/Kernels/kernel ] && KARG+=(--kernel ...)` | 同 |
| 仓库副本 `chown -R root:wheel` + `chmod -R go-w` | 同 |
| `kmutil inspect` 验证 bundle 在集合里 | 同（测试+正式两次） |
| 备份旧 AuxKC | 同（`AuxiliaryKernelExtensions.kc.before`） |
| `-z`（不做授权检查） | 同 |

### 为什么先修权限

设备诊断显示 `Contents/MacOS/NVRM` 是 `-rw-r--r--`（0644）——从 exFAT U 盘拷进 /Library/Extensions
会丢可执行位。上游用 `chmod -R 755 "/.kext"`；v3.1 用 0755（MacOS/）+0644（plist）等价形态，
并先 `chown -R root:wheel`。

### 版本可辨识

v3.1 第一行打印 `==== G1 修复加载 v3.1 ====`，产物目录前缀 `results/fix3-`（v2 是 `results/fix-`），
并额外写一份 `/tmp/g1-fix3-<stamp>.log`，U 盘写失败也不会丢日志。

### 首次加载的额外一步

辅助集合重建后首次重启，macOS 可能弹出「系统扩展已被阻止」，需要到
**系统设置 > 隐私与安全性** 点「允许」，再重启一次。上游 install.sh 末尾也是这么提示的。
