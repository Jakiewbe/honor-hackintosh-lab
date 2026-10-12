# upstream/｜只读上游源码（不入库）

`upstream/1401/` 与 `upstream/nvidia-macos-driver/` 是独立 Git 克隆，已被 `.gitignore` 排除。
本仓库只记录固定 SHA；上游代码为 PolyForm Noncommercial 许可，**不复制、不修改、不重新分发**。

| 目录 | 来源 | 固定点 | Commit |
|---|---|---|---|
| `1401/` | https://github.com/nullmoth/1401 | tag `v1.14.2`（detached） | `46d9fee308bbb8e373807d59773823e6a93c1f63` |
| `nvidia-macos-driver/` | https://github.com/nullmoth/nvidia-macos-driver | tag `v1.14.2` = `main` | `1083a98db33a0bb824290556de255f9a95ca5403` |

重建（只读，部分克隆）：

```powershell
git clone --filter=blob:none https://github.com/nullmoth/1401 upstream/1401
git -C upstream/1401 checkout --detach 46d9fee308bbb8e373807d59773823e6a93c1f63
git clone --filter=blob:none https://github.com/nullmoth/nvidia-macos-driver upstream/nvidia-macos-driver
git -C upstream/nvidia-macos-driver checkout --detach 1083a98db33a0bb824290556de255f9a95ca5403
```

规则：不在这里运行上游程序、安装脚本或测试；需要运行时复制到 `%TEMP%` 下的隔离沙箱（做法见 `logs/RESEARCH_LOG.md`）。
`tests/test_1401_static_audit.py` 会检查 `upstream/1401` 是否仍在审计过的 SHA。
