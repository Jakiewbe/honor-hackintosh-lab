接续HONOR RTX2050适配，当前内部链接任务已完成，不要重做。先读README顶部、
INTERNAL-LINK-20261021.md最终验收节、internal-link-lock.json和
internal-link-evidence/39531652222/independent-text-acceptance.json。
run39531652222 / 3e383c5原生成功：1055 RM、12 NVRM、225 modeset对象，
同run导入493→481→478，12 NVKMS与4 NVLink接口均有最终定义，仅新增_panic。
478项为470历史KPI+定义/8家族名单，尚非loader/完整ABI验收。

下一目标：冻结这份候选，列出进入设备阶段还缺的最小、可验证清单，并完成无需设备的核对。
先按最终478项、现有Info.plist/OSBundleLibraries/部署目标15.5核对依赖和版本；
将既有KC8实际定义/调用侧证据逐项绑定本候选，差异或未知必须保留，不能重复盲编1280 TU。
同时把当前stop/生命周期、callback参数寿命、使用者排空和PM阻塞定位到真实候选路径；
只为具体可证伪问题做最小定向修复，不再为了补丁数量无限扩展。
区分NVRM链接、整包依赖/格式、加载、RTX2050初始化、Metal执行、正确像素与安全结束。
每一步更新证据和断点；有实际阻塞就明确说，禁止用绿色CI冒充GPU功能。

允许相关已验证文本代码/报告的受控main快进提交及compile/link-only手动Actions；
不加push/schedule触发器、不建分支或worktree、不强推、不上传驱动/固件二进制。
不改.agent、旧检出、取证缓存、Windows/磁盘/EFI/BIOS/SIP/NVRAM；不安装软件，
不签名/安装/加载/运行驱动，不访问设备，不发上游消息。设备仍NO-GO，设备动作另行授权。
