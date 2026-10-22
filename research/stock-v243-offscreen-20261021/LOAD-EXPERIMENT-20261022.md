# 加载实验（一键，可回退）

这是目前唯一会写系统文件的脚本：`G1-加载实验.command`。

## 它做什么

| 阶段 | 动作 | 需要 sudo |
|---|---|---|
| `plan` | 只打印将要执行什么 | 否 |
| `backup` | 备份 `/Library/Extensions`、记录所有内核集合 SHA、kextstat、boot-args、csrutil | 是（读） |
| `install` | 只替换 NVRM、追加 `-nvrmnogo`、`kmutil install --update-all` | 是 |
| `verify` | 重启后检查加载、NVRM 属性、日志、panic | 否 |
| `rollback` | 还原 NVRM（或删除）、还原 boot-args 原文、重建内核集合 | 是 |
| `status` | 显示当前进度与已加载的 NV kext | 否 |

用法：

```bash
cd /Volumes/UNPLUGGED/HONOR-G1-FIRST-TOUCH
bash G1-加载实验.command plan
bash G1-加载实验.command backup
bash G1-加载实验.command install     # 需要输入 INSTALL
# 重启
bash G1-加载实验.command verify
bash G1-加载实验.command rollback    # 需要输入 ROLLBACK
```

## 它不做

- 不跑 `nvrmctl go`、不跑 Metal、不做 GPU 计算；
- 不做睡眠/唤醒测试；
- 不改显示所有权、不动 Windows/EFI/BIOS/SIP 其他项。

## 必须理解的三个限制

1. **`-nvrmnogo` 不是只读保证。** 它只关闭 auto-go；`start()` 仍会 `placeLargeBar1()`、`readBARs()`，
   会移动 BAR1 并映射寄存器。所以这仍然是**写硬件**。
2. **回退不等于恢复。** 脚本能把扩展与 boot-args 还原、重建内核集合，但
   "重启后系统状态与实验前完全一致"没有实测过；`clear-staging` 和复制 KC 都不是完整恢复证明。
3. **加载成功不等于能用。** 即使 NVRM 出现在 `kextstat`、`nvrm-autogo = off`，也只说明
   kext 驻留成功；GPU 通道、固件、Metal 全部未验证。

## 在跑 install 之前必须先做的一件事

**用安装盘实测一次恢复**：从 E: 启动进 Recovery 终端，删除 `/Volumes/<系统卷>/Library/Extensions/NVRM.kext`，
执行 `kmutil install --volume /Volumes/<系统卷> --update-all`，重启确认能回到系统。
没做这一步就装，等于把"panic 后只能重装"当成已知风险。

## 判据与停止条件

`verify` 通过需要同时满足：

- `kextstat` 里有 `NVRM`；
- `ioreg -rn NVRM` 出现 `nvrm-autogo`（值为 off）；
- 5 分钟内内核日志无 `panic` / `Kernel trap` / `can't load`。

任一不满足：**立即 rollback，不要继续任何操作**。

## 结果文件

每次运行写到 `results/load-<时间>/`：`kextstat-before/after.txt`、`nvrm-was-installed.txt`、
`boot-args-before.txt`、`kc-before.txt`、`kmutil-install.txt`、`nvrm-log.txt`、`panic-reports.txt`，
以及 `results/load-state.env`（当前阶段）。回传整个目录即可。

## 当前定位

- 构建层：目标机离线构建已通过（`PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU`）；
- 加载层：**NO-GO**，本脚本只是把这一步做成可审查、可回退的一键；
- GPU：**NOT RUN**。
