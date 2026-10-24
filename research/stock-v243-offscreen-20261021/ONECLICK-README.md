# 一键运行（目标机，离线）

## 脚本清单

| 脚本 | 干什么 | 风险 |
|---|---|---|
| `G1-一键运行.command` | preflight 14 项 + 编译（问 `BUILD` 才编） | 只读 + 写自己的输出目录 |
| `G1-一键诊断.command` | 只读诊断，v3 起结论细化到 RM 走到哪一步 | 只读，不需要 sudo |
| `G1-修复加载.command` | 重建 aux KC 让 NVRM 能加载 | 会改 `/Library/Extensions`、aux KC |
| `G1-加载实验.command` | 装/验/回滚 NVRM（加载实验） | 会改 KC，有回滚 |
| `G1-装固件.command` | 把 GSP 固件装到 `/Library/NullMoth/nvfw/…` | 只加文件，按字节数+SHA-1 校验 |

固件为什么需要：2026-10-24 实测驱动与 RM 全部走通，唯一失败点是
`/Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin` 不存在
（`vnode_open failed 2` → `RmFetchGspRmImages: No firmware image found`）。
详见 `LOAD-RESULT-20261024.md`。

双击 `G1-一键运行.command` 即可（或者终端里 `bash G1-一键运行.command`）。

它做三件事：

1. 清掉 Finder 往文件夹里写的 `.DS_Store` / `._*`；
2. 跑 14 项 preflight，结果写到 `results/preflight-<时间>.json`，同时复制一份到桌面；
3. preflight 全过后**问你要不要编译**（输入 `BUILD` 才开始，20–40 分钟）。

## 为什么还要一个 `expected-commit.txt`

审计合同要求期望提交必须由**外部**提供，不能自动取当前 HEAD。所以交付时把这个文件放在 U 盘里，
内容是一行 40 位提交号。缺少它，脚本会直接停，不会拿错版本去编译。

## 你只需要做

1. 把整个 `HONOR-G1-FIRST-TOUCH` 文件夹拷到 macOS（或直接从 U 盘运行）。
2. 双击 `G1-一键运行.command`。
3. 把 `results/` 里的 `preflight-<时间>.json` 发回（没过）或 `build-<时间>.txt` 发回（编译过/失败）。

## 它不会做

- 不安装、不加载、不写 KC / NVRAM、不需要 sudo；
- 不联网（不 clone、不 fetch、不 brew）；
- 不删除旧数据：每次编译新建 `$HOME/Desktop/g1-runs/<时间>/run-*`。

## 如果双击没反应

exFAT/FAT32 不保存可执行位，Finder 可能拒绝执行。改用终端：

```bash
cd /Volumes/UNPLUGGED/HONOR-G1-FIRST-TOUCH
bash G1-一键运行.command
```

## 常见 preflight 失败

| 失败项 | 含义 | 处理 |
|---|---|---|
| `sdk` | SDK 不是 15.5 | 换 Xcode 16.4 / 对应 CLT |
| `repository` | 仓库有未跟踪或被改文件 | 重新拷贝整个文件夹（脚本已清 `.DS_Store`） |
| `workspace` | 工作目录被占用 | 不要设 `WORK`，让脚本自己建新目录 |
| `disk-space` | 桌面剩余 < 8 GB | 清理空间 |
| `gnu-make` | 没有 GNU make 4 且找不到归档 | 确认 `g1-tools/make-4.4.1.tar.gz` 在 |
