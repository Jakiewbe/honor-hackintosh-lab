# NVKMS 与 NVLink 内部链接集成

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

- 72/72 离线检查通过（既有 56 项 + 新增 16 项）。新检查覆盖缺定义、未消除导入、
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
