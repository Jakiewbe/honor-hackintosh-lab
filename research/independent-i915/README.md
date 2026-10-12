# R1.4-C0｜Intel 46A6 独立源码与接口依赖工程

**首轮状态：SOURCE-STATIC / DEPENDENCY_CLOSURE_BLOCKED / RUNTIME_NO_GO。** 完整报告见 [R1.4-C0](../../docs/R1.4-C0_独立i915源码与接口依赖基线.md)。

|交付|内容|
|---|---|
|[source-lock.json](source-lock.json)、[upstream-provenance.json](upstream-provenance.json)|精确 commit/tree/blob 和 156 条公开文本源记录|
|[license-manifest.csv](license-manifest.csv)、[compat-notes.md](compat-notes.md)|逐文件许可证据、FreeBSD 14.3.0 候选依据与接口缺口|
|[callgraph.md](callgraph.md)、[symbol-inventory.csv](symbol-inventory.csv)|92 定义、79 源码关系；全部对象未编译|
|[required-apis.md](required-apis.md)、[api-contracts.json](api-contracts.json)|14 类必需 XNU 接口，全部 BLOCKED|
|[include-inventory.csv](include-inventory.csv)、[source-delta.json](source-delta.json)|字面 include 候选与 Linux/FreeBSD 差异；不是完整闭包|
|[verification.json](verification.json)|实际离线输出、25 通过/0 失败、闭包退出 2|

## 复核入口

在仓库根目录，Python 3.11 可执行以下本项目脚本。第一次 fetch 需要网络，只取得固定版本公开文本，**不执行第三方代码**；已有缓存不匹配时立即停止、不覆盖。`.cache/` 不提交，不含 firmware/发布二进制。离线检查本身不联网。

```text
python scripts/r14c0_fetch_locked_sources.py
python scripts/r14c0_validate_dependency_baseline.py --mode structure
python scripts/r14c0_validate_dependency_baseline.py --mode closure
python -m unittest discover -s tests -p test_r14c0_dependency_gate.py
```

`structure` 的 0 仅说明记录一致；`closure` **预期退出 2**，因为当前依赖/许可/配置/接口仍阻塞。测试必须具备真实缓存，缺源直接失败，不跳过、不造假的源文件。本轮实际使用已安装的 Python 3.11 解释器，详情见 verification。

## 执行前方案（2026-10-12）

目标：在 `6105f08842de41732a61036507d725fa1a5a9941` 的研究基础上，固定可审查的 FreeBSD base 候选，建立公开源码级版本、许可证、调用关系和未实现接口台账。仅 L1；不是驱动原型。

假设：drm-kmod 的 6.1-lts 候选可与某个明确的 FreeBSD base 构成进一步审查输入。精确 base commit、真实接口、构建配置或许可无法闭合即可否证，不以同系列名称推定兼容。

输入：Linux `830b3c68c1fb1e9176028d02ef86f3cf76aa2476`；drm-kmod `dba60e1e9465d4d6b2d4e7916174f7b915c35fb4`；XNU `a1e26a70f38d1d7daa7b49b258e2f8538ad81650`；IOGraphics `4d3fd008c80d1414c9da8f02ea67d534b47158c2`。Apple 已核验版本结论继承 R1.2-F，不重跑旧哈希/锁序门禁。

范围：本目录、专用离线校验及负向测试、最新知识库状态和研究账本索引；历史报告、补丁、旧测试及 Actions 保留。

验收：每个新观察到的源文件对应精确 commit/tree/blob；每个重点函数有定义位置与调用证据；接口和对象编译缺口明确 `BLOCKED`；缺文件、缺许可、版本错误和假成功声明退出非零。仅 `SOURCE-STATIC`，不声称全量依赖闭包、对象编译、kext 链接或硬件成功。

风险：文本调用关系不能证明预处理后的可达性、函数指针调度或 ABI。BSD 构建配置不能直接作为 XNU 配置。许可证台账仅记录公开头部，不代表混合二进制分发许可已解决。

回退：新增文件和新状态由独立本地提交记录；原始报告不回写。未授权远程推送、工作流运行、内核部署及主力机操作。
