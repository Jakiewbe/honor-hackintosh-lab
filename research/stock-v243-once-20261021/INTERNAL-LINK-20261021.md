# NVKMS 与 NVLink 内部链接集成

**当前结论：run39531652222 / 3e383c5 已原生通过，16个内部接口名称闭合；478个系统导入及设备安全仍未验收，GPU未执行，NO-GO。下文保留初稿与失败纠错过程，以末节实际验收为准。**

本轮目标：在同一次 Darwin 运行中，从已经验收的 RM-only 探测出发，
用固定源码配对归档补齐 12 个 NVKMS 接口，再由真实 Darwin semaphore 后端
补齐 4 个 NVLink 锁接口。验收限于源码身份、对象与符号链接；设备继续 NO-GO。

固定 NullMoth `272ccd9da04ff5de95c2791b902fe17a3fa77ce7`，
OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`，SDK/部署目标 15.5。
ONCE 的两个源码候选和原有补丁字节保持不变。

## 配对方式与可证伪条件

- 新入口 `stock_v243_internal_link.py` 先调用原有 fail-closed 探测。
  原有入口及其成功证据不修改。基线成功后集成状态立即改为 FAILED，
  任一后续异常都须返回 2，保留阶段、错误及文本报告。
- 只在明确命名的 OGKM 候选副本应用固定 NullMoth 自带的三份 modeset 补丁：
  `610-display-completion.patch`、`610-setmode-reason.patch`、
  `610-backlight-register-log.patch`。依其 README 再应用
  `610-fsp-timer-double-destroy.patch`，重编两个受影响的 RM 对象。
  不导入旧 R43 补丁链。四份补丁共改四个源文件。
- `internal-link-lock.json` 记录每步补丁身份、逐文件前后 SHA256、配方身份与
  NVLink 后端身份。要求正向、反向、重放逐阶段匹配，原始输入不变。
- 官方 Makefile `ALL_SRCS/BUILD_OBJECT_LIST` 提供 modeset 的 224 个源和版本 TU，
  精确 225 个 C/C++ 对象。只请求对象目标，make 必须 exit0，不能吞末端 ELF 错误。
  用真实对象生成配对归档，校验其完整成员顺序。
- 五个 shader 已从固定 NullMoth TU 解压，与固定 OGKM 数据逐字节相等。
  保留并链接该真实 TU；`SHADER_OBJS=` 仅跳过重复的 GNU/ELF 数据包装，
  不删除任何 C/C++ TU，不省略 shader 功能。CI 还须核对真实 Mach-O 对象的
  十个 start/end 标签、只读节、边界和嵌入字节，不使用新生成的五个重复数据对象。
- 链接顺序：同 run RM-only 基线 → 替换两个 RM 清理对象并加入配对 NVKMS 归档 →
  增加已审阅真实 NVLink semaphore 后端。每一阶段保存实际链接参数、对象哈希和 nm。
- NVKMS 必须消除全部 12 项且在最终产物观察到定义，禁止新增未审阅导入；
  可同时消除 modeset 自带实现的 SHA1Init/Update/Final，但必须观察到最终定义。
  NVLink 阶段须恰好消除四项并观察到定义，新增导入只允许已登记的 `_panic`。
  不以导入数接近发布版作为验收。

## 已完成的本地检查

- 74/74 离线检查通过（既有 56 项 + 新增 18 项）。新检查覆盖缺定义、未消除导入、
  未批准依赖、意外丢失导入、shader 内容/标签/对象边界、归档缺项及基线成功后的失败传播。
- 从固定 Git blob 核对配方/补丁 SHA；四份补丁在命名临时副本正向、反向、重放通过。
- 五份实际 shader 解压内容与固定 OGKM 一致，数据大小 244224–253184 B。
- 现有 WSL make 只展开模式集清单，225 项通过新解析器；没有编译驱动。
- 新工作流 YAML 可解析，只有 workflow_dispatch，只上传独立文本目录。

本条记录写入时 Darwin 新集成尚未执行。历史 run39526958107 只验收 RM-only 探测，
不能替代本轮配对归档与内部接口差分。新工作流为
`g1-stock-v243-internal-link.yml`，不能以工作流存在声明原生通过。

## 剩余边界与回退

即使集成通过，也仅说明内部名称由真实对象提供；系统 KPI/IOFamily 的 loader、版本、
完整 ABI、用户 macOS、驱动格式/签名与设备初始化仍未验收。
stop 入口/参数寿命/使用者排空与 PM 风险没有随链接闭合而修复。
不运行驱动，不安装、签名、加载，不访问 GPU、不测试睡眠唤醒。

回退可撤销本轮新增入口、lock、工作流和测试，保留原有已验收探测与候选。
本轮复盘：现成 TU 已有完整 shader 数据时，应先验证实际字节并复用；
不要为套用历史全量脚本而重复包装载荷或夹带旧补丁。

下一断点：验收本轮原生产物及同 run 差分；失败只按实际日志修正。
若成功，再以最终真实导入清单安排 loader/ABI 与设备阻塞验收，不重复盲建 1280 TU。

## 本地补丁验收纠错

初次 lock 构造时，命名临时目录处于父级 Git 仓库内，带 diff --git 头的 FSP 补丁被 Git 静默跳过，导致其 before/after 被误记成相同值。首次“四份补丁往返通过”的说法撤回。现以 core.autocrlf=false、--no-index 及 GIT_CEILING_DIRECTORIES 隔绝父仓库和 CRLF 策略，并逐文件拒绝空改动。重新从固定 Git blob 构造、实际正向/反向/重放，四个源文件哈希均改变且可恢复。新增真实父仓库夹具与空改动负控，74项通过。首次run39530341498绑定b4fee62，不能使用修正后的本地结果替它验收；修正提交须另验原生。

## 第一次完整原生结果：集成尚未通过

run [39530710502](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39530710502)，86969fa，failure。固定四补丁正反向/重放通过；1055 RM、12 NVRM、225 modeset 对象编译通过，基线493导入；在归档成员校验处 exit2，尚未执行配对链接和NVLink差分。文本产物12314998853，993775 B，SHA256 `8711294156a4cf2a352c3b5c29f808daa5422f68849ede4a0e140c3dc3e9f789`。原失败检查未保存ar列表，不能从错误字符串断言具体成员。下一修正保存列表，只把Darwin ar已知的至多一个符号索引成员识别为元数据，全部225对象仍须逐项、按序相等；其他多项、缺项、重复均拒绝。新本地检查76项通过；新链接未运行。b4fee62的过时run39530341498已主动取消，不作为通过/失败验收。

## 最终原生验收与冻结断点

运行 [39531652222](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39531652222)，
`workflow_dispatch`，源码 `3e383c5cad2f9efbce58701f2c064a4de662b841`，success。
文本产物 `12315372808`，1432915 B，ZIP SHA256
`e4a67ec2fd242a74f4517c4e3c7ecbfca3a59354fbe99c05647c90403b6dcffe`，已下载核验。

| 检查 | 实际结果 |
|---|---|
| CI 离线检查 | 76/76 |
| 真实非法源/非法 ld 选项/必要对象缺失 | 均被拒绝；旧对象和旧产物清除 |
| RM / NVRM / modeset | 1055 / 12 / 225 对象，make/compile exit0 |
| 配对候选 | 四份上游固定补丁，四个源文件；正向、反向、重放12步通过 |
| shader | 保留原TU；五份实际源数据、对象标签/边界/只读字节一致 |
| 归档 | 225个源对象，外加一个 `__.SYMDEF` 索引；并非缺失或额外源码对象 |
| 同 run RM-only 基线 | 链接exit0，493导入 |
| 配对 NVKMS 阶段 | 链接exit0，消除12项，新增0，剩481 |
| NVLink 后端阶段 | 编译/链接exit0，恰好消除4项，仅新增 `_panic`，剩478 |
| 最终对象/格式探测 | x86_64 MH_KEXT_BUNDLE，17528944 B |
| 最终二进制SHA256 | `b873afbe94d19fae77397a1763c9ac1217d2b9ee86dcf0ee333bdd6e51cd73b1` |
| 配对归档SHA256 | `059e9d20f3eddf182ca62e34555ec7af7774a55517f5696524398f6ad4c4f453` |
| 原始输入/候选/对象复核 | 固定原树不变；候选符合lock；消费的对象及归档哈希前后相同 |

已从原始nm文本独立重算，16个内部接口均有最终全局定义且不再作为导入。
实际链接ARGV相对同run基线，精确对应两个RM清理对象替换、配对归档和真实锁后端。
没有消除SHA1导入（可选规则未被使用），不得把旧R43的472项套到本候选。
最终478项名称归属为470项历史runner KPI及实际定义、8项IOPCI/IOACPI历史名单；
分类不是loader/版本/完整ABI或用户设备验收。

证据在 `internal-link-evidence/39531652222/`：review绑定run/提交/ZIP和每个原始文本成员SHA，
保留实际ARGV、模式集对象清单、最终定义/导入、补丁证明、归档成员、shader证明和负控。
文本一致性复核工具 `verify-text-consistency.py` 可对原ZIP重放；提供者取证按固定Git blob校验，
避免Windows CRLF改变散列。该复核不是对未下载二进制的独立格式/加载验证。
原始 `negative-link.txt` 的ld诊断含末尾空格，为保留原文与SHA不修剪；代码文档diff检查通过。

本次已结束的任务：补齐12+4项内部链接缺口。无需再为这些接口盲目重编。
下一步冻结本候选与清单，只核对最终系统依赖/OSBundleLibraries/版本/ABI的具体缺口，
并把已有stop/生命周期/排空/PM阻塞与当前实际候选对应；只对可证实且影响准入的问题定向处理。
优先复用既有KC8等真实证据并核对绑定，不重复采集已有的同等证据。
NVRMFB整包、NVAccel/Metal、GSP资源与设备初始化均未随本轮链接验收。
无完整kext格式/签名/安装/加载验收；无GPU执行、像素读回或睡眠唤醒。
设备继续NO-GO，设备操作仍需独立授权。

复盘：补丁必须验证实际内容改变，Git返回0不够；归档须区分索引元数据与源对象；
内部链接缺口关闭后就切换到下一层，不用导入数量猜测发布版等价性。
