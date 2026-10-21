# 首次接触实验（最小暴露，可回退）

你的判断成立：只有加载才会暴露加载期缺陷。静态证据再堆也不会冒出新 bug。
所以这份文档不是"再等等"，而是把"试"做成一次**变量最少、能回退、信息量最大**的实验。

## 前提（不可跳过，10 分钟）

- 有**可独立启动的第二个 macOS**（外接盘、另一个分区或安装盘），并确认能从它启动。
  理由：如果首次加载 panic，唯一能救的是另一条启动路径。
- 没有这个前提，就不要做；这不是保守，是"panic 之后你只能重装"。

## 实验设计：只换一个组件

| 变量 | 选择 | 原因 |
|---|---|---|
| 先换哪个 kext | **只换 NVRM**，NVRMFB/NVAccel 保持现状 | 一次只动一个；NVRM 是我们改动最大的组件 |
| GPU 初始化 | **`-nvrmnogo`** | auto-go 关闭，不载固件、不开通道；仍会移动 BAR1、映射寄存器 |
| 是否 `nvrmctl go` | **不执行** | 首次实验只回答"能不能加载"，不回答"能不能算" |
| 是否跑 Metal | **不执行** | 同上 |

## 步骤（脚本已入库：`first-touch.sh`）

```bash
cd ~/honor-hackintosh-lab
git fetch origin && git checkout 79c7fab
bash research/stock-v243-offscreen-20261021/first-touch.sh backup
```

备份后先把 `kextstat-before.txt`、`kc-before.txt`、`boot-args-before.txt` 发我，确认现状再说下一步。

```bash
bash research/stock-v243-offscreen-20261021/first-touch.sh install   # 换 NVRM + 加 -nvrmnogo + 重建 KC
# 重启
bash research/stock-v243-offscreen-20261021/first-touch.sh verify    # 记录到底加载了什么
```

判据：

- `kextstat` 里出现 NVRM；
- `ioreg -rn NVRM` 里 `nvrm-autogo` 为 `off (-nvrmnogo)`；
- 内核日志 5 分钟内无 `panic`、无 `Kernel trap`、无 `can't load`。

## 失败时

```bash
bash research/stock-v243-offscreen-20261021/first-touch.sh rollback
# 重启；对比 kextstat-before.txt
```

若已经 panic、无法进入系统：从**第二个 macOS** 启动，删掉 `/Library/Extensions/NVRM.kext`，
或用备份覆盖，再 `kmutil install --update-all`。

## 这个实验能证明什么、不能证明什么

能证明：候选 NVRM 能否被加载器接受并完成 `start()` 的前半段（PCI 注册、BAR 定位、claim 设备）；
能不能在 auto-go 关闭的状态下稳定驻留。

不能证明：GPU 初始化、固件、通道、Metal、像素读回；也不能证明 stop/PM 安全。

## 我会同时准备的

- 把实验的判据、日志字段和回退命令固定进文档，避免"试完说不清发生了什么"；
- 你贴回 `kextstat-after.txt` / `nvrm-properties.txt` / `nvrm-log.txt` 后，我按真实日志判断下一步
  （是加 `nvrmctl go`，还是先修某个 start 期错误）。
