# G1 构建闭包与 RM 栈 ABI：逐符号审计

输入仓库基线 `60b752cfe1a8934af7442eaee26498a9cae89c46`。本轮落实用户修订后的构建闭包/跨平台 ABI 优先级，未改驱动补丁、原九单元编译配方或混合链接输入。

## 1. 本轮实际完成的证据

`tools/g1_dependency_audit.py` 在固定 OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb` 上扫描 3824 个受版本控制的 C/C++/头文件，另纳入 Makefile/.mk 共 3836 个文本输入。此前 3821 的口径不含本工具纳入的 .hpp；不是新增源码。扫描前核对 HEAD 与受控文件无修改；保留全部定义候选、调用形标识符、直接 include 和源文件 SHA256。

Darwin 对照为固定 NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393` 的 `kexts/` 下 71 个 C/C++/头文件；对应真实 tree SHA 为 `528e804da39cb6c358727455385563d414606a70`，逐文件 Git blob 与完整 GitHub tree 核对。工具区分 commit 与 tree SHA。对照基线未应用当前补丁，因此不得把旧行号直接套到候选树。

产物：
- `dependency-audit/dependencies.json`：35 个目标符号的全部定义、参数、函数体哈希、调用形标识符、Darwin 同名定义候选、TU 直接 include、完整扫描源哈希清单。
- `dependency-audit/dependencies.md`：逐符号表。
- `dependency-audit/ci-baseline-binding.json`：已执行编译的来源绑定。

**这是词法依赖审计，尚非完整的编译/链接依赖闭包。** 调用形标识符可能是宏、类型转换或函数指针；同名 Darwin 定义可能是成员方法或不兼容实现。全部候选保留，不能用首个命中认定提供者。未预处理的条件分支均保留；直接 include 的数量与路径名不能证明传递 Linux/Unix 依赖少或已解决。

## 2. 栈风险不是只落在 osapi.c

35 个符号中 **20 个函数**直接使用 `NV_ENTER_RM_RUNTIME`：

| TU | 目标函数数 |
|---|---:|
| `arch/nvalloc/unix/src/osapi.c` | 17 |
| `arch/nvalloc/unix/src/dynamic-power.c` | 1（`rm_power_management`） |
| `arch/nvalloc/unix/src/unix_intr.c` | 2（`rm_isr` / `rm_isr_bh`） |

上述路径均位于 `src/nvidia/` 下。NullMoth 固定基线记录到 **32 处**向审计目标函数首参传字面 NULL 的调用，其中 **31 处涉及这 20 个 runtime 宏使用者**，覆盖初始化、ioctl、ISR、PM、work item、nano timer 与 RM API。完整位置/实参见 JSON，未把声明计为这些 NULL 调用。

OGKM `arch/nvalloc/unix/include/osapi.h:34–104` 的契约：
- `__use_altstack__` 开启且为 x86_64 时，进入宏读取 `sp->top` 并写 `%rbp`；退出宏再次读取 `sp->top` 并恢复 `%rbp`。
- 同时开启 `QA_BUILD` 时，marker 检查还会访问 `sp->stack` / `sp->size`。
- `__use_altstack__` 未定义时，进入宏只丢弃参数，退出宏为空。

因此：**开启 altstack 的这些实现与 NULL 栈调用不兼容。** 这不是已观测的 Darwin 崩溃；现有探针 ARGV 没有显式定义该宏，也不能仅凭 ARGV 推断最终预处理状态。不得为消掉风险盲目加 `-U__use_altstack__`，或把“宏未启用”扩大为整个 RM ABI 安全。

旧 `OGKM-DEPENDENCY-AUDIT` 中“只有 osapi.c 提及宏，所以风险只在该文件”的推论撤回。宏由头文件展开，风险跨越三个 TU；完整源码/构建文本中该选择器的全部命中已保留。

## 3. 已有五单元编译不重复当作新突破

实际运行：[39090712869](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39090712869)，head `1db63e034517020d656e1954e6eae767aec2570d`，API 确认为 completed/success。

Artifact `12123001015` 的 API digest 与本地 ZIP 实算一致：
`a96edc0191dc68c1162d90c794e2e5b3a3366a66776bc635ab2c17dad8ea677a`。
直接从该 ZIP 读取 report/compile ARGV：五个 OGKM 探针均 exit 0；独立 14 对象混合链接 exit 0，591624 B，821 个未定义符号，原前缀分类剩 23 项。

这些数字不代表完整闭包。前缀分类不是全量提供者核验；混合配置的结构布局、ABI 与行为仍未证明。

## 4. 新增原生取证入口

`tools/g1_probe_inventory.py` 加在现有门禁的编译之后，对五个探针：
1. 验证原 compile log 为 exit 0、对象为 x86_64 `MH_OBJECT`，记录对象和源码哈希；
2. 沿用该单元的**原始 flags**，仅把编译动作换为 `-E -dM` 与 `-M`，保存完整宏表和传递 include 依赖；
3. 用实际对象的 `nm -gU` / `nm -u` 保留所有符号，逐项核对 35 个审计目标是否真的被编入；
4. 输出 `g1-probe-inventory.json`，记录 `__use_altstack__`、`QA_BUILD`、NVRM、OS/CPU 选择器等。

不修改任何平台宏、不重新链接或执行对象，不将二进制加入 artifact。预处理/符号采集失败会使新增步骤失败，避免生成无证据的 PASS。九单元配方及既有五探针编译/混合链接逻辑未变。

本地九项回归通过，覆盖声明/调用误判、跨行与长参数、注释/字符串/嵌套括号、条件定义全部保留、宏体排除、精确 flags 转换，以及真实 tree SHA/被修改 blob/截断清单检查。**新的 Darwin 预处理/对象取证尚待本次 Actions 执行**，不能继承旧 run 的结果。

## 5. 复现与下一断点

从固定 clean git 输入运行：
```
python tools/g1_dependency_audit.py --nv <OGKM> --nm <NullMoth> --definitions research/gpu-safety-r5/symbol-definitions.json --out <不存在的输出目录>
python tools/test_g1_dependency_audit.py
```
如果 NullMoth 是无 .git 的原始快照，额外传入 `--nm-tree <固定提交的完整 GitHub tree JSON>`，工具会逐 blob 核验。

接下来读取新 run 的对象/宏/依赖报告：先确定三个 RM TU 的实际 altstack 分支和 35 个提供者的对象定义，再从传递 include 及实际 undefined 清单扩展核心构建闭包。对 `nv_state_t` 等跨配置结构做独立布局/签名核对，不能只因新增对象链接成功就称 ABI 兼容。

P0-1（IOPM 负返回值不能否决睡眠）、P0-4（关闭失败不可传播）、R24 超时后行为与 owner-copy 执行失败回退继续开放。本轮不改这些驱动路径。KEXT-LOAD / GPU-RUNTIME / PIXEL-READBACK / SAFE-SHUTDOWN 均未验收，保持 NO-GO；无设备操作。

### 执行环境断点

取证入口已在 `1dc3567` 快进提交至 main。当前连接器提供提交/更新引用，但没有 Actions dispatch 工具；本机非交互凭据助手未返回凭据，浏览器自动化初始化失败。本轮触发未成功，API 核对最新 run 仍为 `39090712869`，不存在需要等待的新运行。不是授权不足，不要求重新授权。

可在 [原生门禁](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/workflows/gpu-safety-r5-native.yml) 选择 `main` / `Xcode_16.4` 运行；随后验收 `g1-probe-inventory.json`。在取得新报告前，只将新增脚本记为本地回归通过、Darwin 取证未执行。
