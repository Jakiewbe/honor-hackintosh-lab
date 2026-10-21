# 两个候选对象的符号闭包（链接前的最小验证）

本轮完成了原生门禁（run 39470420908，提交 `378b508`，结论 **success**，
artifact `12286607574` / SHA256 `b6209029a94a43a76a86289a67c75976d2cb986e5e50bb8b4d572c58eb0d70b2`），
随后用该次运行产出的对象符号做了链接前的闭包核对。

**这仍不是链接**：下面是"每个未定义符号能否指出提供者"的静态核对，不是 `ld` 的结果。

## 1. 输入

| 输入 | 来源 | 绑定 |
|---|---|---|
| 两个候选对象的 `nm -u` | 本次 artifact 的 `candidate-NVRM-undefined.txt` / `candidate-NVRMFB-undefined.txt` | 提交 `378b508`（与本轮 HEAD 的代码文件逐字节相同，差异只有 README/knowledge） |
| 内核导出符号 | `runner-kernel-nm-raw.txt`（23,426 行）与 `kernel-symbolsets-decoded.txt` | 同一次真机 runner 抓取 |
| NVRM 自有对象定义 | `full-nvrm-defined.txt`（17,703 行） | **旧提交的完整 NVRM 链接**，只用于"驱动自己有没有这个定义"，不作为本次构建的证明 |
| IOPCIFamily / IOACPIFamily 允许表 | `IOPCIFamily-kext-allowlist.json`、`IOACPIFamily-kext-allowlist.json` | 来自 runner 的 kext exports |
| 驱动源码定义 | `kexts/NVRM/{os-xnu.cpp:278, nv_xnu_power.cpp:40, os-nvkms-xnu.cpp:195}` | 固定 pin `272ccd9` |

## 2. 结果

| TU | 未定义符号总数 | 内核 | IOFamily 允许表 | NVRM 自有对象 | 驱动源码 | IOGraphics | 无法归属 |
|---|---|---|---|---|---|---|---|
| `NVRM.cpp` | 468 | 412 | 7 | 46 | 3 | 0 | **0** |
| `nvm-fb.cpp`（NVRMFB） | 478 | 363 | 0 | 0 | 0 | 115 | **0** |

三点说明：

1. **本轮新增/变化的三个符号都能落到提供者**：
   `_thread_call_allocate_with_options`（内核，`runner-kernel-nm-raw.txt:20704`）、
   `__ZNK9IOService10isInactiveEv`（内核，`:6584`）、`_rm_disable_adapter`（NVRM 自有对象，
   `full-nvrm-defined.txt:15838`）。消失的 `_thread_call_allocate` 已在 lock 里登记为"已批准的移除"。
2. `NVRMFB` 的 115 个 IOGraphics 符号（`IOFramebuffer::*`、`IODisplay::*`、
   `IODisplayParameterHandler::*`、`gIODisplay*`）**目前没有导出清单证据**：仓库里有
   IOPCIFamily/IOACPIFamily 的 allowlist，没有 IOGraphics 的。
3. `nv_xnu_maps_init`、`nv_xnu_power_refresh`、`nvkms_xnu_suspend` 不在旧完整链接的定义表里，
   但在固定 pin 的驱动源码中有定义（行号见上），属于同一 kext 的其它 TU，不是外部依赖。

## 3. 真正的链接还缺什么（精确到输入）

| 缺口 | 需要的东西 | 可执行获取方式 |
|---|---|---|
| IOGraphics 导出证据 | `/System/Library/Extensions/IOGraphics.kext/Contents/Resources/config/IOGraphics.exports` 的条目清单 | 在 macOS runner 上读该文件（与现有 IOPCIFamily allowlist 同一采集方式），一次即可 |
| 链接对象集 | NVRM 其余 TU 的 `.o`（或整包 link-only 运行） | 复用仓库既有的完整构建配方；只有闭包证明必要时才扩大（本闭包尚未证明必须全量重编） |
| RM 对象提供者 | OGKM `e4a5faa` 构建出的 RM 对象 | 同一 link-only 运行内的 OGKM 构建步骤 |

## 4. 这层证据能说明什么、不能说明什么

- 能说明：两个候选对象**没有"指不出提供者"的外部依赖**，三个新符号都有提供侧证据，
  且没有重复定义冲突的迹象（定义集与原件相比只有 15 个新增 NVRM 方法，无删除）。
- 不能说明：kext 真的能链接、ABI 真的成立、能加载、GPU 能执行。`ld` 未运行，
  `kext_link` 仍未验收；设备继续 NO-GO。

## 5. 一个必须先回答的链接问题：`_kmod_info` 等三个符号在两个 TU 里都定义了

本轮把两个候选对象的 `nm -gU` 逐符号对比后发现：

| 符号 | NVRM 候选 | NVRMFB 候选 | 原始对象 |
|---|---|---|---|
| `__start` | `T 0x0` | `T 0x0` | 同样存在 |
| `__stop` | `T 0x10` | `T 0x10` | 同样存在 |
| `_kmod_info` | `D 0xcfe0` | `D 0x18f10` | 同样存在 |

也就是说，**两个 TU 各自都有强定义**。我一度给门禁加了 `ld -r` 合并两个对象这一步，
随后撤回了：在这组对象上它必然因这三个符号报重复定义，而这不是本次 ONCE 改动造成的
（原始对象同样如此），会让门禁产生与被测改动无关的失败。

这条不是坏消息，而是把"最小链接还缺什么"钉得更准：

- 真实 kext 链接必须由构建配方保证 `_kmod_info` / `__start` / `__stop` 只定义一次
  （或者用工程自己的规则处理），而我们目前的"单 TU 编译"配方会在每个 TU 里生成它们；
- 因此链接验证不能简单地把两个 `.o` 用 `ld -r` 拼起来，必须复用工程的真实链接规则。
  这条规则是当前缺失的输入之一（见 §3 的"链接对象集"行）。

## 6. 重复定义与新增定义的核对（本轮）

- 候选 NVRM 新增的 15 个定义，在旧完整链接的定义表里**一个都不存在**（0 冲突）。
- NVRMFB 的定义集与原件完全一致（177 → 177），无新增。
- 两个候选对象之间的共享定义只有 `__start` / `__stop` / `_kmod_info`（见 §5），
  与本次 ONCE 改动无关。

## 7. 本轮补完：IOGraphics 提供者与两个 kext 的真实链接探测

### 7.1 IOGraphics：115 个符号全部在内核集合里找到

macOS 15 的 runner 上没有 `/System/Library/Extensions/IOGraphics.kext`（该 kext 在
`SystemKernelExtensions.kc` 里），因此第一次采集失败。改为对集合本身取符号后
（run [39483921334](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39483921334)，
artifact `12292916197`）：

| 项 | 结果 |
|---|---|
| `nm -gU SystemKernelExtensions.kc` 行数 | 79,841 |
| 过滤出的 `IOFramebuffer`/`IODisplay` 符号 | 450 |
| NVRMFB 的 115 个 IOGraphics 未定义符号 | **115/115 找到** |

最初用前缀过滤时漏了 3 个，回到完整 `kc-nm.txt` 后都找到：
`__ZNK13IOFramebuffer11getWorkLoopEv`（`T 0x149f8130`）、
`__ZTV13IOFramebuffer`（`S 0x14a10248`）、`__ZTV25IODisplayParameterHandler`（`S 0x14a0da38`）。

因此 NVRMFB 的 478 个未定义符号：363 内核 + 115 IOGraphics，**0 无法归属**；
NVRM 的 468 个：412 内核 + 7 IOFamily + 46 自有对象 + 3 驱动源码，**0 无法归属**。

### 7.2 真实链接探测：每个 kext 单独链接，四次全部 exit 0

第一次探测把两个对象放在一起，`ld` 报 3 个重复定义（`__start`、`__stop`、`_kmod_info`）。
原因是 **NVRM.cpp 与 nvrm-fb.cpp 属于两个不同的 kext**，各自带
`KMOD_EXPLICIT_DECL`（`NVRM.cpp:45`、`nvrm-fb.cpp:107`）——重复是应有行为，不是缺陷。

改为按 kext 分别用工程真实模式链接（`-fapple-kext -nostdlib -Xlinker -kext -lkmodc++ -lkmod -lcc_kext`），
run [39485250953](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39485250953)：

| 链接 | 退出码 | 二进制大小 | SHA256 前缀 | 未定义导入 |
|---|---|---|---|---|
| original NVRM | 0 | 129,008 | `94ffda99` | 466 |
| candidate NVRM | 0 | 134,600 | `276ad641` | 468 |
| original NVRMFB | 0 | 320,768 | `1e50d04c` | 478 |
| candidate NVRMFB | 0 | 320,840 | `25f3fae3` | 478 |

这说明：**两个候选对象各自作为 kext 二进制链接成功**，且链接后的导入表与对象阶段一致
（466→468 / 478→478）。仍不等于整包 kext 链接：NVRM 其余 TU 的链接配方与对象集仍缺（见 §3）。

## 8. 整包 NVRM kext 链接（本轮达成）

工作流 `.github/workflows/g1-stock-v243-kext-link.yml`，run
[39498653458](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39498653458) /
提交 `584abcf`：

| 项 | 值 |
|---|---|
| 补丁应用与身份校验 | 通过（SHA 来自 lock，不写死在 workflow 里） |
| OGKM RM 对象（`gmake TARGET_OS=Darwin`） | 1055 个实际链接 `.o`（3167 为目录条目数），`errors=0`（`make_rc=2`，末尾 ELF 链接步骤在 macOS 上不可用，属预期） |
| NullMoth NVRM TU 编译 | **12/12 OK**（含本轮修改的 `NVRM.cpp`） |
| 链接 | `-Xlinker -kext`，12 个 TU 对象 + 1055 个 RM 对象 |
| 链接结果 | **exit 0**，16,185,000 B，SHA256 `28e9386a4b72f15899b4d51fb49356de89eac7b9c48893cfa7cf5a983b382f5e` |
| 链接后未定义导入 | 493 |

这证明：**改过的 `NVRM.cpp` 能与该 kext 其余 11 个 TU 以及 RM 对象一起，在工程真实的链接模式下产出 kext 二进制**，
且没有重复定义冲突。此前一次只链进 10 个 TU（两个 `.c` 用 clang++ 编译失败）时也已经 exit 0，
12/12 之后仍然是 exit 0。

仍不是发布等价物，也不能加载：

- 只链接了 `nvidia` 的 RM 对象，**没有** `nvidia-modeset` 的对象；493 个未定义导入里包含
  NVKMS 侧的符号，提供对象尚未集成；不能假定系统会自动解析，见 §9；
- 二进制没有签名、没有做 kext 格式校验、没有加载、没有执行；
- NVRMFB 是另一个 kext，其整包链接未做（它的单 TU 链接已在门禁里 exit 0）。

## 9. 独立审计后的准确边界与门禁修复

run39498653458 的真实 link_exit=0、大小、SHA256 已独立核对；本轮不撤销这一成果。
但旧工作流的 make/TU 阶段容忍失败，ld 失败分支也可能返回 0，故 success 不能单独充当门禁验收。
新专用脚本直接请求固定 Makefile 的 1055 个对象目标，不执行末端 ELF 链接，不再容忍 make=2；
编译或链接失败、对象集合不一致、错误 Mach-O 类型或旧产物残留均拒绝。负控使用相同验收函数。

上文 468/478 是单 TU 的名称归属，不是整包 493 项导入的闭包。493 项逐项记录见
[FINAL-IMPORTS-BASELINE-20261021.json](FINAL-IMPORTS-BASELINE-20261021.json)，绑定原始文本产物哈希：

| 类别 | 数量 | 证据边界 |
|---|---|---|
| 历史 runner KPI 条目及目标定义 | 469 | 非用户设备、非完整 ABI；仍需绑定 OSBundleLibraries/版本 |
| IOFamily 导出名单 | 8 | 名称允许，不代表当前二进制定义/完整 ABI 已验收 |
| NVKMS 未集成入口 | 12 | 需要固定 modeset 对象集；不能假定系统提供 |
| NVLink OS 锁后端缺失 | 4 | nvlink_os.h 的真实实现合同，不可用空桩补齐 |

`SystemKernelExtensions.kc` 中找到同名定义，只说明 runner 上存在；不独立证明
目标 kext 的依赖声明、可绑定性、版本和 ABI。上述两类内部缺口应先做明确的同 run
链接增量，不能以导入数量接近发布版作为验收。

新构建配方固定 SDK15.5 / deployment target15.5，与旧链接的15.0目标不同；
新结果必须单独记录，也不覆盖 macOS15.0–15.4 的加载兼容性。
本轮恢复三个工作流为 workflow_dispatch，不再用文档 push 启动全量构建。
原始候选、补丁、上游 pin 均未改变。新 Darwin 结果与下一断点见
[GATE-REPAIR-20261021.md](GATE-REPAIR-20261021.md)。设备 NO-GO。
