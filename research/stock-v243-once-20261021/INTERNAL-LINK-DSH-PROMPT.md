你接续 HONOR RTX2050 主线，先读 README 顶部、INTERNAL-LINK-20261021.md、
internal-link-lock.json 和对应最新实际 Actions 产物。保持固定 NullMoth272ccd9、
OGKMe4a5faa 与两 TU 候选身份。目标是验收同一 run 的 RM-only → 配对 NVKMS →
真实 NVLink 后端三个阶段：225 modeset C/C++ 对象、两个 RM 清理替换对象、
原 shader TU 五份真实数据、12+4 接口的最终定义和导入差分。
不要用旧 run 或绿色 job 代替实际 report/对象/ARGV/nm/哈希核对。
如失败，只按真实失败阶段修复；如通过，基于最终导入安排最小 loader/版本/ABI 检查，
不重复盲目全构建、不夹带历史 R43 补丁链。更新真实结果和下一断点。
仅允许相关文本代码/文档的受控 main 快进提交及 compile/link-only 手动 Actions。
不得改 .agent、旧检出、取证缓存、Windows/磁盘/EFI/BIOS/SIP/NVRAM；
不得安装/签名/加载/运行驱动、访问设备、发上游消息、上传驱动或固件二进制。
不添加 push/schedule 触发器。设备 NO-GO；完整 ABI/关闭安全与 GPU 功能分别验收。
