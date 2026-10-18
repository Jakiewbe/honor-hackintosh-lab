# NVRM 链接产物的真实导入/导出（R37）

## 先确认口径

上一轮的错误是拿 `candidate-NVRM-undefined.txt`（**单个目标文件**的 `nm -u`）当缺口。这一轮用门禁产出的
**链接后 kext** 的两张表：

- `nvrm-kext-defined.txt` / `nvrm-kext-undefined.txt`（对 `NVRM.kext/Contents/MacOS/NVRM` 跑 `nm -gU`）

## 事实

| 项 | 值 |
|---|---|
| 链接结果 | **exit 0**（不是链接失败） |
| 产物 | `NVRM` **362,472 B** |
| 定义符号 | **655** |
| 导入（未定义）符号 | **514**（逐行统计；报告字段记 517，差 3 行为 `ARGV=` 之类的非符号行） |

也就是说：9 个单元**能够链接成一个完整 Mach-O kext**。门禁里的 `KEXT-LINK_INCOMPLETE_UNIT_SET`
是**策略标签**（我们只编了 9 个 TU，不等于发行版），**不是链接错误**。这一点此前被我误读。

## 514 个导入里有什么

| 类别 | 数量 | 说明 |
|---|---|---|
| 内核 KPI 风格（`_IO*`/`_OS*`/`_mach_*`/`_clock_*`…） | **66** | 加载时由 kernel 解析，正常 |
| 其余 | **448** | 大量 C++ 符号，如 `__ZN11IOPCIDevice20extendedConfigRead32Ey`、`__ZN10IOWorkLoop8workLoopEv`、`__ZN11OSMetaClass21_RESERVEDOSMetaClass0Ev` |

448 里的绝大多数是 **IOKit/C++ 运行时符号**（`IOPCIDevice`、`IOWorkLoop`、`OSMetaClass` 的成员与元类），
由 `com.apple.kpi.*` 提供——**不是缺失实现**。

真正的判据是"加载时能不能解析"，而这只能由 **KEXT-LOAD** 回答（NO-GO）。静态上可以继续做的，是把
448 再分成"由 com.apple.kpi.* 提供"与"无人提供"两类，后者才是会导致加载失败的符号。

## 因此当前准确的结论

- ✅ 我们的 9 单元集**能编译、能链接**成 362 KB 的 kext；
- ❓ 它能否**加载**（514 个导入是否全部可由 kernel/其他 kext 解析）——**未验证**；
- ❌ 它**不等于**发行版 NVRM（发行版 16.8 MB，含不透明载荷）——这条由 REA 证据支持。

## 下一步

把 448 个"非 KPI"导入按提供者归类（`com.apple.kpi.iokit` / `libkern` / `c++` / 无人提供），
产出"静态可判定的加载失败符号"清单——这是 KEXT-LOAD 之前唯一还能做的验证。
