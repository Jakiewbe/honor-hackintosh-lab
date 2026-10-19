# 证据索引（2026-10-20）

> 每个主张对应一条可复现命令或一次 CI 运行；第四列写明它**不能**证明什么。
> 文内引用的 4 个工具与 1 份计划文档已逐一确认存在（`Test-Path` 全为 True）。

| 主张 | 证据（命令 / 文件） | 运行或结果 | 边界 |
|---|---|---|---|
| 官方完整构建 1280 TU + 5 shader + 归档 + 链接 | `tools/g1_full_build.py`（CI 内执行） | run 39189188122 / 39294220812 | 文本日志，不含二进制；非发行版等价 |
| 36 项 NullMoth 序列可逐项应用 | `python3 tools/apply_series.py --candidate <nm> --repo .` | 本地 PASS（补丁 LF 归一化） | 只证明补丁可应用，不证明编译 |
| OGKM 候选 = r3 + niso + r36 + r38 + r42 | `tools/g1_ogkm_candidate.make_candidate` | 最终 sha `0305f74a…`→`dc4397d8…` | 只证明来源映射 |
| 关闭顺序 quiesce → FREE_DEVICE → NISO | `python3 tools/check-kapi-free-order.py <kapi>` | 自检 7/7；候选 PASS | 源码顺序；含 F1 失败分支规则 |
| backend 拒绝时 NISO 不解映射 | `tools/g1_r36_try_free_contract.py`（ASan） | run 39311033396 | CPU 运行；注入拒绝，非真实 RM |
| 成功关闭恰好解映射两次 / 重试先 0 后 2 | 同上 | run 39311033396 | 同上 |
| legacy 关闭有界等待两条分支 | `tools/g1_kms_close_retry_contract.py` | run 39319576695 | 桩在等待点清标志，非真实线程 |
| 延迟关闭表满时不丢 wrapper | `tools/g1_kms_close_retry_contract.py`（`overflow-reclaim`） | run 39339549232 | CPU 运行；真实并发未测 |
| legacy 关闭在等待期间完成 | 同上（`join-completes`） | run 39319576695 | 桩在等待点清标志 |
| 分配失败 owner：隔离表 + resume 回收 | `python3 tools/check-kapi-alloc-owner.py` | 自检 4/4；候选 4/4 | 静态；回收未运行验证 |
| PM 状态机 9+2 条规则 | `python3 tools/check-pm-state-machine.py` | 11/11 | 静态 |
| RM 门忙不进 STANDBY | `python3 tools/check-pm-exclusion.py` | 32/32 | 静态；代价未实测 |
| 安全合同独立门禁 | `.github/workflows/g1-safety-contract.yml` | run 39322771498 | 仅手动触发 |
| Intel kext 未进发行包 | `research/gpu-safety-r5/INTEL-TRACK-20261018.md` | tarball 清单 | 仅文件清单 |
| NMIntelFB 厂商级匹配 + 60000 分 | `kexts/NMIntelFB/Info.plist:17-20`、`intelfb.cpp:272-300` | 静态 | 未上机 |
| 内屏当前提供者 / 残留 kext / SIP | `DEVICE-PLAN-20261020.md` D0 命令 | **未执行** | 需授权 |

## 未执行项（必须显式保留）

| 项 | 原因 |
|---|---|
| KEXT 安装 / 加载 / 卸载 | 需逐项授权 |
| GPU 初始化 / 离屏渲染 / 像素读回 / 安全结束 | 同上，且当前 NO-GO |
| 真实回调并发、真实 RM 拒绝 | 只有建模夹具 |
| 完整 ABI / loader 导出 / 目标系统 | 未取得 |
