# -e 全部外部表逐表复核

输入仍为不可变 registry DSDT + 15 SSDT；iasl 20250404、Debian 20250404-1，包和可执行文件 SHA256 与 toolchain.txt 一致。在无网络、无宿主挂载、非 root 容器执行，没有执行 AML 方法。本次不重跑 -da。

每个目标执行 `iasl -e <其余全部15张原表> -d <目标原表>`。16 条完整参数、退出码、输出及摘要见 [external-runs.json](external-runs.json)。**0 通过、16 失败，均退出 255。** 多数在加载外部 SaSsdt 时因对象重复终止；SaSsdt/SSDT9 作为目标时也有 namespace 加载错误。没有成功的新 DSL；现有 DSL 保留上轮单表结果，只规范化路径，不改变行号。

`-e` 本轮实测也要加载外部表中的命名对象，不能避开重复声明。未加 `-fe`：本轮失败是对象创建冲突，不能靠补方法参数声明宣称完成所有原表的解析。没有删表、改 AML、忽略错误或填入猜测声明。

## 重复 _S0W 的精确位置与影响

| 原表 | DSL 位置 | 相同作用域中的声明 |
|---|---|---|
| reg_SSD3 / SaSsdt | reg_SSD3_HONOR_SaSsdt__00003000.dsl:2105–2112 | `If(PBR1)` 内，`Scope(\_SB.PC00.PEG1.PEGP)`，`Method(_S0W,0,NotSerialized)`，返回 4 |
| reg_SSD9 / ADL-P-M | reg_SSD9_HONOR_ADL-P-M_00000002.dsl:2554–2567 | 同一 Scope，零参数 _S0W；RD3C 存在且等于 2 时返回 4，否则返回 3 |

重复完整路径为 `\_SB.PC00.PEG1.PEGP._S0W`，不是本轮 NvdTable 的 PEG0 或 Intel GFX0。**对已引用的 PEG0/GFX0 方法体、_DSM 位图、PEGP._DOD 常量与 IGDM 字段声明，未发现语义改变；对全表 External 闭包验收有影响，仍失败。** PBR1 实际值和操作系统运行时装载结果 UNKNOWN，不能从静态装载错误推断 Windows 固件运行故障，也不能写成“完全没有影响”。

## 跨表条目复核

findings.csv 的 `external_review` 列记录所有旧条目复核边界；[findings-changes.json](findings-changes.json) 列出 12 个跨表条目。因为 -e 无成功输出，不能报告新的自动绑定。以下只对照既有真实方法定义与 External 文本，不等于完整命名空间验收。

| 调用/External | 原声明位置 | 定义与参数个数 | 本次结果 |
|---|---|---|---|
| P8XH | NvdTable:65，2 Arguments；调用1282–1305 | DSDT:31375，2；D8XH:31360，2 | 参数文本一致；-e 绑定未验收，MXMX 仍为调试路径 |
| GGIV | NvdTable:23，1 Arguments | DSDT:13695，1 | 参数文本一致，GC6 实际执行 UNKNOWN |
| SGOV | NvdTable:61 / IgfxSsdt:35，2 Arguments | DSDT:13726，2 | 参数文本一致，GPIO 含义和实际值 UNKNOWN |
| GGOV | IgfxSsdt:23，1 Arguments | DSDT:13711，1 | 参数文本一致，不证明 MUX |
| IMMC | IgfxSsdt:33，5 Arguments | TcssSsdt:296，5 | 参数文本一致，运行关联未验收 |
| GUAM / PBCL | IgfxSsdt:58 / 84，分别1 / 0 Arguments | DSDT:31859 / 31564，分别1 / 0 | 参数文本一致，背光运行结果 UNKNOWN |
| EDMX | IgfxSsdt:28 为 `_SB_.PC00.GFX0.EDMX` UnknownObj | DSDT:4867 为 GNVS 中同名字段 | 同名不证明同一对象；维持 UNKNOWN，不新增自动绑定结论 |
| ASLB / DME0 / DME1 | Igfx/Tcss 外部字段及方法体 | DSDT SANV 字段，ASLB:2771、DME0/1:2896–2897 | 字段/条件文本不变；内容与初始化者未取得 |

实质修改：联合命名空间验收改为明确记录 -e 的 16 次失败；MXMX 增加参数文本对照与绑定边界；MUX 明确 EDMX 路径差异；新增 `_S0W重复定义`。原位图、PEGP._DOD、DD 方法、OpRegion 布局和 TCSS 条件结论不变。

继续 R1.4-C0 T2 的真实平台合同研究；原表重复及运行条件单独保留证据，不要求用户重采内屏归属。OpRegion/VBT 未取得，保持 SOURCE-STATIC / RUNTIME_NO_GO。
