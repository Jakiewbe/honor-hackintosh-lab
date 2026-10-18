# 门禁缺少的 OGKM 构建定义：初步结论（R42）

## 先纠正一个可能的误解

我上一轮说"门禁没有携带 OGKM 的构建宏"。查过之后需要修正：

`scripts/gpu-safety-r5/native_compile.py` 里已经有

```python
definitions = macros_from_make(dryrun.read_text(...))
```

也就是说它**确实**从 OGKM 的 make 干跑输出里提取 `-D` 宏，并传给每个单元。所以问题不是"完全没有宏"。

## 真正的问题

干跑是针对**门禁自己那 9 个单元**的配方做的。`kexts/NVRM/nvrm_pageoff.c` 是另一条编译配方（C 单元、不同头集合），
它的 `-D` 集合与那 9 个 `.cpp` 不同。于是出现：

```
error: unknown type name 'nv_dynamic_power_mode_t'
error: anonymous bit-field cannot have qualifiers
error: must use 'struct' tag to refer to type 'nv_state_t'
```

即：**头文件按"另一套宏"被解析**，类型别名没生效。

## 因此要做的事（尚未做）

1. 对 `nvrm_pageoff.c` **单独**跑一次 OGKM 的 make 干跑，取出它那条配方的完整 `-D` 列表；
2. 与门禁现有 `definitions` 做差集；
3. 把差集作为**该单元专用**的 flags 传入（不要污染其它单元）；
4. 重跑门禁，看 `nvrm_pageoff.c` 是否通过、514 个导入是否降到 507。

## 边界

- 本轮**只做到定位**，没有改门禁；42 个无提供者符号的数量**未变**。
- 上一轮的三次失败尝试（C、C++、回滚）过程已在提交历史里，未删除。

## 证据

- OGKM 本地树：`D:\Hactk\g1-dev-20261015\upstream\open-gpu-kernel-modules`
- 提取到的 `-D` 条目：91 个（含噪声，如 `-debug`、`-declaration`），需要按配方过滤
- 失败日志：`evidence/ci-r5/run-r41*.log` 与对应 artifact 的 `candidate-NVRM_nvrm_pageoff_c-compile.txt`
