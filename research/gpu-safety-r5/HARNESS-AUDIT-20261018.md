# DeepSeek Harness 增量独立审计与主线推进

固定审计基线：`64f8d57779c77d8a5f75f2b0976e7a989a5860e4` → `2f7b2b880d2ce6568caf8b77f3a35827c5fe0cf5`，28提交/14文件。主要是诊断工具和文档，没有驱动实现增量。原固定OGKM/NullMoth/Mesa不变，不改.agent、不操作旧检出或设备。

## 已确认缺陷

1. **P1：编译失败仍绿色，结论又退回“源码到顶”。** `g1_full_rm_probe.py`扫描两个子目录988个C文件，未用官方srcs.mk清单/逐TU参数，使用PORT空宏、强制include、600个头目录和-w。最新[run39138580661](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39138580661)实际编过135、失败853，失败样本仅留40项，随后将135成功对象和生成对象做部分链接并恒定return0；其成功状态不是完整构建成功。runner日志实际为macos-15-arm64（目标参数为x86_64），Xcode未固定，与已有Intel/Xcode16.4基线不同。产物ZIP SHA256 `9904f3a47b23408cd0964acfe37322313de175a982f174a19b675b241a6b0b00` 已下载校验，仅3文本。脚本blob在该run和审计head均为`6ba70256fd65e926b203ca5d24fd0647645274d6`。**整改：旧探针退休，真实子进程exit2，既不编译也不部分链接；原始错误证据保留。**
2. **P1：PM合同把已知危险行为固定成PASS。** Harness新增检查要求RM busy时不得中止挂起，IOPM ack正确与RM已静止是不同合同。用与run39127772586全部九个NVRM源码哈希一致的命名副本独立检查：`nv_xnu_pm_close(10000)`后忙分支只LOG，然后继续stop channels/STANDBY。**整改：该要求改为FAIL，真实exit1、31/32；显式--source/--out消除写死工作目录。** 仅修验收工具，没有修驱动PM；不能把return false一个字符串当完整PM方案。未运行带checkout -f/clean的旧verify-all总脚本，只更新其参数对接。
3. **P2：Mach-O头字段解析错误。** `filetype`被当ncmds，LC_SYMTAB若在后面就漏读；无符号表/字符串范围校验，混入本地/common也有风险。**整改：32/64位有界解析、严格字符串/表边界、仅真实外部未定义项；12项测试（含LC_SYMTAB第13条、截断、重表、名称越界/common/local）。** 对原发布物重算仍472项，与冻结候选交集471，Harness数字本身没有因此撤销。发行版IOUserClient::free的精确来源未证，不能仅按类名归因为“完整IOAccel客户端”。
4. **P2：grep推断调用来源失效。** 历史`uni-NVRM_cpp.ll`中已存在read8/read16/write16直接调用；源码grep无命中不排除SDK inline展开。新增调用侧诊断基于真实TU，拒绝只声明、对象无导入、调用参数扩展/声明不匹配。
5. **P2：词法索引/名称分档越过语义证据。** DECL不能当提供者定义；lstrip('_')不能保留Mach-O身份；引用87原语覆盖90%不等于实际启用路径或适配工作量。“IOMalloc可能分页需连续分配”“空宏无语义风险”“必须新写端口层”等工程结论撤回，未据此改驱动。索引目前只作历史词法资料，不能进入验收门禁。

## 保留的真实进展

- [run39127772586](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39127772586)：1280官方C TU、5shader、完整RM/modeset归档及独立NVLink后端、完整NVRM重建候选链接；候选SHA256`bbde79f1601ee7bc89bcef04f48dc45276d39f9dec9e3f8bbed456f157c1e1d3`。不因新探针配置错误撤销，也不重复构建。
- 464精确KPI/实际全局+8个runner KC外部节定义，以及六profile136布局/20接口形状：按原层级保留。名称存在与完整ABI、loader导出/版本、用户系统仍分别待验收。
- 发布物472/交集471已独立复算；文本证据见[harness-audit-evidence](harness-audit-evidence/)。生成文件编译在新探针日志为true，因此不把“生成文件必失败”的静态猜测写为发现。

## 本轮继续做什么

新增`g1-kc8-callers.yml`：Intel/Xcode16.4/SDK15.5，复用当前native_compile同一个完整补丁序列和统一编译参数。九个实际NVRM TU逐项与历史真实链接TU的**有序参数和源码哈希**核对，重定位根目录以外不放宽；每个对象有真实-MD依赖前后快照，IR直接编译原TU，依赖集合必须相同。要求六个PCI方法同时具有真实对象导入、函数内直接call、声明及SDK ABI形状一致，任一缺失即非零，不合成调用者。只构建这9对象和诊断IR，不编RM、不链接/运行驱动，严格仅发布文本。

本地新增解析器12/12、调用侧/负控11/11、旧manifest5/5、文本发布3/3通过；依赖绑定10项中8通过、2项Windows符号链接权限受限跳过，CI会执行。三组历史回归10/10、5/5、7/7通过。原生诊断尚未执行，不能先宣称write8补齐。PM审计的FAIL是正确暴露已有缺陷，不是“全部通过”。

## GO / NO-GO 与断点

允许相关源码/CPU/原生对象及只读文本诊断，受控main快进与授权Actions。设备加载/签名/安装/GPU运行继续NO-GO。当前仍没有RTX2050初始化、真实GPU渲染、正确像素读回或安全结束证据。

等新caller-only run，按真实日志处理：六方法全部对象+call一致才关闭选定调用形状缺口；失败只修本诊断，不写fake provider。下一实质驱动工作是RM关闭/IOPM恢复的集成方案与真实失败合同，以及family loader版本边界。NVLink锁测试不能替代freeDevice问题。当前不碰Intel显示与G2/G3。

## 本轮复盘

失败探针必须非零且不得部分链接冒充完整构建；新结论先与已验收固定输入/参数比较；源码grep和名称覆盖率不能替代对象/IR调用链。下轮沿真实断点推进，不再重复“公开源码是否存在”的历史循环。
