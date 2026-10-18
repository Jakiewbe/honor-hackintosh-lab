# 更正（R36）：`candidate-NVRM-undefined.txt` 不是"缺口清单"

## 上一份文档（R35）的框架错误

R35 把 `candidate-NVRM-undefined.txt` 里的 **470 个符号**当成"NVRM 单元集的缺口"。这是错的。

那个文件是 `nm -u candidate-NVRM.o`——**单个目标文件**的未定义符号表。单个 TU 引用其他 TU 定义的函数，
本来就会出现在这张表里。证据：

```
os-xnu2.cpp L1565: extern "C" IOMemoryDescriptor *nv_xnu_alloc_md(...)   ← 定义
NVRM.cpp  L363:    extern "C" IOMemoryDescriptor *nv_xnu_alloc_md(...);  ← 声明
NVRM.cpp  L1824:   nv_xnu_alloc_md(c->alloc, &bytes, &cache);            ← 引用
```

而 `os-xnu2.cpp` **就在** `nvrm_units` 列表里（第 9 个单元之一）。所以 `_nv_xnu_alloc_md` 出现在那张表里
完全正常，不是缺口。

## 因此撤回的结论

- ❌ "470 个未定义符号 = NVRM 缺 470 个实现"
- ❌ "一部分缺口只是单元集没选全"——`os-xnu2.cpp` 已经在单元集里
- ❌ 43 / 33 / 394 这个三桶分类的问题设定本身不成立（它分的是单对象的引用，不是链接缺口）

## 正确的问题该怎么问

真正有意义的量是**链接后 kext 的未定义/导入符号**，或链接是否报错。门禁已经产出后者：
`kext_link_nvrm` 的状态（当前是 `KEXT-LINK_INCOMPLETE_UNIT_SET`）。

下一步要查的是：
1. 门禁对 `kext_link_nvrm` 记录的**具体失败符号**（若有）；
2. 链接成功的四个目标（NVAccel、NVRMFB、NMIntelFB×2）里，各自 `nm -u` 的真实导入集合；
3. 把"未定义"换成"链接失败的符号 + 其提供者是否存在"，才谈得上缺口。

## 教训

上一轮我拿到一个文件就下了结构性结论，没有先确认**这个文件是什么命令的产物**。这与之前几次
"旧产物/旧源码"的误判是同一类错误：**先确认证据的来源与口径，再解释数字**。
