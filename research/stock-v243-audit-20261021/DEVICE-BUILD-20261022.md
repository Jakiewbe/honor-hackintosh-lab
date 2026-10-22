# 目标机首次完整离线构建（2026-10-22）

**这是本项目第一次在 GLO-FX6P 真机上完成从源码到三个 kext 的离线编译与链接。**
它仍然只到 `KEXT-LINK` 层：没有加载、没有 GPU、没有 Metal。

## 1. 环境（全部来自设备自报的 preflight）

| 项 | 值 |
|---|---|
| 主机 | GLO-FX6P，macOS 15.8.1 / 24H32 / x86_64 |
| 工具链 | `/Library/Developer/CommandLineTools`（无完整 Xcode） |
| SDK | **15.5** |
| clang | Apple clang **17.0.0**（clang-1700.0.13.5），Target x86_64-apple-darwin24.6.0 |
| python3 | **3.9.6**（CLT 自带） |
| 网络 | 全程离线 |
| 磁盘 | 445 GB 可用（本次 run 目录 `/Users/chs/Desktop/g1-runs/20261022-155257`） |

## 2. preflight：14/14 PASS

`preflight-20261022-155257.json`，逐项：

host-os、host-arch、python、developer-tools、sdk、clang、repository、nullmoth、ogkm、
shell-lf、assets、gnu-make、workspace、disk-space 全部 `PASS`。

关键绑定：

- `repository` = `1cf61667b1046831033a77f4d64df045f1796f63`（与 U 盘 `expected-commit.txt` 一致）
- `nullmoth` = `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`
- `ogkm` = `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`
- `gnu-make` = 归档 `dd16fb1d…`（现场 bootstrap，不是系统 make 冒充）
- `assets` = 候选补丁与 lock 一致

## 3. build：`PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU`

三个产物（来自 build-report）：

| 组件 | 二进制 SHA256 | Info.plist SHA256 |
|---|---|---|
| NVRM | `4a38ea572e3b66e39e6a2ce62e7e74701c4a092a6a83b9e7f5a862dcd4711eba` | `934914c0…` |
| NVRMFB | `93617dc41855ba4a6f828b0567c83ab9a0b45cb20f0c14a3bedd789ee242e70d` | `151db446…` |
| NVAccel | `04b13d7f38710bd61a189b3c2ca1c417bfb081c86cf16f95856f976cdb959884` | `bc0a5ab6…` |

`package_report_sha256 = 4687028099326e534a2f58d72a2ad5a83f478bd945b820c11ab84157fc85fe8b`，
build 阶段会逐个校验 bundle 里的可执行与 plist 与打包报告一致，不一致即失败。

## 4. 必须记录的差异：NVRM 不是字节可复现

| 构建 | NVRM SHA256 |
|---|---|
| 早期 CI | `7d109e41…` |
| 较新 CI（run 39609383942） | `b0e20deb…` |
| **本次设备** | **`4a38ea57…`** |

而 NVRMFB（`93617dc4…`）与 NVAccel（`04b13d7f…`）在 CI 与设备上**完全一致**。

判断：NVRM 里含与构建环境相关的非确定性内容（RM/modeset 对象的构建路径或元数据），
所以 **NVRM 的哈希只能绑定"某一次构建"，不能当作"源码状态"的指纹**。验收应以打包报告的
内部一致性（三产物 + plist + 报告 SHA）为准，而不是拿 NVRM 哈希跨机比对。

这条差异是**观测事实**，不是失败，也没有被忽略。

## 5. 这个结果证明了什么

- 目标机具备完整离线链路：CLT + SDK 15.5 + 本地源码 + 现场 bootstrap 的 GNU make 4.4.1；
- 14 项前置条件在真机上全部成立；
- 三个 kext 能从固定源码编译、链接、打包通过，且产物自洽；
- 之前反复卡住的构建环境问题（无网、无 Xcode、CRLF、.DS_Store、gmake、bash 3.2）已全部消除。

## 6. 这个结果没有证明什么

- **没有加载**：`kext_load = NO_GO`；
- **没有 GPU 执行**：`gpu = NOT_RUN`，离屏计算与像素读回仍是 0 次；
- **没有验收 stop/PM/在途工作**；
- **没有验收恢复能力**：Recovery 独立入口仍未实测；
- 27 项外部导出仍是"所查形式不可观测"，不是"运行时一定不可用"；
- 设备上的 NVRM 与 CI 的 NVRM 不同字节，不能拿旧 CI 的 ABI/符号结论直接套到这份二进制上。

## 7. 下一断点

按合同，安装/回退入口仍是禁用状态。要把这一层推进到 `KEXT-LOAD`，需要**单独设计并授权**
一个加载实验，至少包含：

1. 恢复路径实测（安装盘 Recovery 删除 + 重建）；
2. 加载前备份扩展集合与所有内核集合；
3. 最小暴露：只装 NVRM，`-nvrmnogo`（注意它不是只读保证）；
4. 明确的停止判据与回退命令。

在那之前：**BUILD 通过 ≠ 可以加载**，仍是 `LOAD NO-GO / GPU NOT RUN`。
