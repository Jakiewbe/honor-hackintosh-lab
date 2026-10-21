# 设备前独立审计整改（2026-10-21）

基线：用户审计固定2b02575，后续修订至35143d5；本轮保留这些改动，继续修真实门禁。
当前里程碑为 **PRE-DEVICE STATIC INTEGRATION — CONDITIONAL PASS**，设备仍NO-GO。
本轮没有安装、签名、加载、访问GPU、修改KC或安全策略。

## 本轮原生验收完成：run39609383942

固定执行提交`da20a569b622a71b26ae91675c70e3899bbf0b3a`，实际事件为`workflow_dispatch`，
[运行39609383942](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39609383942)全部步骤success。
三个文本附件均已按API大小/SHA256核验；PM包23个成员全部是文本，没有程序或dSYM。
原始成员哈希见`evidence/39609383942/{package,pm,abi}/archive-binding.json`；
`verify_native_evidence.py`可在普通Python下复算已归档成员身份、诊断绑定、声明依赖、提供者分类及槽位算术。
它验证的是文本证据的内部一致性，没有重新读取未下载的驱动或KC二进制。

| 组件 | 原生链接大小 | 导入数 | 仅局部定义、导出未证 |
|---|---:|---:|---:|
| NVRM | 17528944 B | 478 | 0 |
| NVRMFB | 320840 B | 478 | 0 |
| NVAccel | 244664 B | 884 | 27 |

三个`kextutil`诊断均exit0，路径、可执行SHA、plist SHA及bundle ID与同run编译记录一致。
真实变异bundle的缺executable及不存在依赖，被本项目生产检查器拒收；`kextutil`本身仍接受这两个坏bundle，
故始终是INFORMATIONAL_ONLY。非零/未解析/身份变化等生产路径负控随原生步骤运行成功。
IOGraphicsFamily仅有KC身份、无可用版本元数据，两处声明仍为`IDENTITY_OBSERVED_VERSION_UNVERIFIED`。

**更正20→27的分类口径**：旧run的20项之外，另7项曾被`VTABLE_SLOT_OBSERVED_LOCAL_NAME_STRIPPED`
排除在local-only之外。严格检查撤销该替代关系后，这7项归回局部定义、导出未知。
新旧NVAccel SHA均为`04b13d7f38710bd61a189b3c2ca1c417bfb081c86cf16f95856f976cdb959884`，
导入均884，因而这不是新增二进制缺口。当前27个名称绑定**78条**原始nlist记录；
完整差分、多个地址、节范围及KC身份见`evidence/39609383942/local-only-binding.json`。
历史`local-only-binding.json`保留为run39585922948的20项快照，不能当最新全量清单。

新逐类观察的KC SHA仍为`12913116a90b3875e42f17ab42261875205e3cd5463fb7744b1a488b24df67c2`，
IOAcceleratorFamily2成员UUID为`65ceb805d3263f159595f6ec0a6d78da`。

| 类 | 自身vtable起点 | 到下个具名定义前的原始字数 | 本类相对候选槽位 |
|---|---|---:|---|
| IOAccelSurface | `0x148bcab0` | 328 | set_shape 322、backing_length 323、lock 324、unlock 325 |
| IOAccelGLContext2 | `0x148b64e0` | 374 | processSwap 366 |
| IOAccelLegacyDisplayPipe | `0x148bbd38` | 319 | setStereo 308 |
| IOAccelLegacyDisplayMachine | `0x148ad3f0` | 299 | setStereo 286 |

七个方法均与真实NVAccel导入精确名称配对，见`evidence/39609383942/enum-slot-binding.json`。
原始字、偏移、目标候选、全部命中nlist在`abi/per-class-vtable.json`；这些字数是保守上界范围内观察量，
不是完整槽位数量证明。低30位匹配仍只是候选指针解释；未证明完整chained walk、完整ABI或外部导出。

PM候选同run合同8/8、原基线2/8；非法编译负控exit1、无产物、未执行。
只替换NVRM对象的重链成功，17528944 B，SHA`50692a79ed46483a606501ab1084c45c31932705de2645cab00fb711cc2e688f`，
478导入不变。它与上表未合并PM的NVRM是不同产物，不混用身份；仍不证明睡眠否决、回滚或安全关闭。

**本轮裁定**：审计要求的诊断拒收、候选身份、完整声明依赖检查、原始符号归档、四类有界取证及文档修订
已经取得原生证据。27项外部导出、完整ABI、用户设备只读A、恢复能力、stop/PM和用户态组件配对仍未关闭。
下一步针对27项的加载器导出元数据做定向只读取证，必须先找到可验证输入；找不到则保留未知，
不重复整包编译，也不升级到设备加载。A需要用户macOS上的真实环境和合法候选实物，本机没有执行通路。
本轮复盘：按证据能力分类，不能用vtable命中代替外部导出；工具接受坏输入时应降低其结论等级。

## 已独立复算的既有证据

从GitHub API取回原始文本，核验artifact大小和SHA256后归档：

- run39585922948 / a25d2f5，artifact12339424975，962358 B，
  SHA256 `4cb3297a0bde218e9506cabe3bdc79a4d52948046ced9fe291dc154bd9cf26bd`，完整成员清单见 archive-binding.json。
  实际event为push，不能描述成手动运行。
- run39582513978 / 605307a，artifact12337227005，32513 B；
  SHA256 `2ae9a1018eb8116366edd3fcdea15cdf006fe4f9ff0711860469d1a3d7251e3e`，实际event也是push。

三组件链接记录：NVRM 17528944 B / `7d109e417548c1237e696adc823f55f2afdd1a2e7aa83de625e976e65bcfc257`；
NVRMFB 320840 B / `93617dc41855ba4a6f828b0567c83ab9a0b45cb20f0c14a3bedd789ee242e70d`；
NVAccel 244664 B / `04b13d7f38710bd61a189b3c2ca1c417bfb081c86cf16f95856f976cdb959884`。
导入分别478、478、884；这些是既有run结果，不是新修正已原生通过。

## P1：生产诊断门禁及负向控制

最新基线已增加非零退出拒收，但旧测试重新实现一份相同逻辑并搜索源码字符串，无法证明生产路径拒收。
现把生产路径提取为loader_diagnostics/accept_loader_diagnostics；测试直接调用它们，真实启动Python子进程
注入exit7及exit0+未解析文本。三项清单必须精确，未知/布尔退出码、身份错配、运行中plist改变均拒绝。
每项记录确切bundle路径、可执行及plist SHA、标识符，前后检查；错误记录写回报告，日志始终保留。

kextutil曾接受两个坏bundle，不把这一工具升级为验证器，也不因某次拒绝一个反例就认为其已具备加载验证能力。
最终始终标注KEXTUTIL_INFORMATIONAL_ONLY；认证、排他候选依赖绑定、loader resolution均UNVERIFIED。
返回码不再用任意PASS前缀接受未知状态，只接受两个明确静态状态。

新增独立的完整声明依赖检查：OSBundleLibraries即使没有被当前导入使用，也必须找到提供者身份。
对实际变异副本中的com.example.g1-missing做生产检查负控；缺可执行副本也必须被本项目检查器拒绝。
这些拒收不依赖kextutil是否报错。家族有KC身份却无版本元数据时保留UNVERIFIED，不填0。

## P1：20个local-only与enum证据

local-only-binding.json完整绑定20个不同名称、40条原始nlist记录、节范围、地址、KC SHA及成员UUID；
部分名称有多个地址，逐项保留，没有发明唯一提供者。它们仍是设备阻塞，不作为外部可链接导出证明。
local证据只从已声明依赖中归因，删除“未声明依赖默认版本0”的退路。

enum-native-binding.json绑定真实NVAccel产物中的七个具名enum导入和相应提供者记录，
包括IOAccelSurface四项、GLContext2::processSwap、LegacyDisplayPipe::setStereo、
LegacyDisplayMachine::setStereo。认可类型修饰修复；不扩大为完整ABI正确。

## P1：vtable证据边界

历史120 hits来自IOAccelSurface地址后900个字的扫描；按符号声明类分类，不等于其他类真实vtable槽位。
真实KC SHA256为 `12913116a90b3875e42f17ab42261875205e3cd5463fb7744b1a488b24df67c2`，
大小365887488 B，macOS15.7.9/24G830；由已绑定原始文本交叉核对，不是对用户设备的绑定。
原始CHAIN_FAILED保留，不能只因掩码命中地址就宣称完整链解码通过。
生产导入检查现在不会拿历史vtable槽位替代外部符号提供者。

新取证器g1_kc_vtable_bounded.py分别从四个类自己的ZTV地址起步，最多到同节下一个具名定义，
输出各槽原始字、文件偏移、target30候选、所有匹配nlist记录、KC哈希和成员UUID。
它只给有界静态观察：下一个符号是上界；掩码是候选解释；成员偏移、调用约定、导出及完整布局仍未知。
相邻类越界、歧义起点、截断输入负控通过。新原生输出已按顶部run39609383942结果验收。

## P0/P2：设备流程

DEVICE-CHECKLIST为唯一当前入口；DEVICE-RUNBOOK撤回，旧R43计划顶部标记失效。
撤下KC安装、清staging/复制KC回退、热卸载及GPU执行命令，不把加载与初始化人为分离。
恢复设计明确要求独立入口、完整扩展/AuxKC状态、真实签名策略与恢复后启动一致性；目前没有恢复实测。
只读A脚本改用Python直接获取退出码，无Bash/zsh管道数组歧义；绑定三个候选和构建报告，
只保存目标PCI ID，不保存完整ioreg/序列号。脚本未在用户设备运行，不自动安装Python或Xcode。

两个重新出现的push触发器已移除；后续只用已授权workflow_dispatch。
本地109项检查通过；新Darwin整包及逐类取证现已按上节验收。旧失败run39536854715仍保留，不能用新报告改写。

## 剩余硬阻塞

27项导出（历史20项加7项原vtable替代分类）、IOGraphics版本及完整ABI、用户真实系统绑定、候选用户态Metal/NVK/GSP配对、
stop准入与全部使用者/回调排空、PM及在途工作清理、设备恢复能力均未关闭。
编译和链接已有实物，GPU一次未执行。“只剩真机加载”不成立。
