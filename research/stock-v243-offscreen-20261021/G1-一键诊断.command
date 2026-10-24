#!/bin/bash
# ============================================================================
#  G1 一键诊断 v3（只读）
#
#  双击运行，或：bash G1-一键诊断.command
#
#  它把判断"驱动到底走到哪一步"需要的全部信息写成一个文件，放在
#  本脚本旁边的 results/ 里，同时复制一份到桌面。
#  不需要 sudo，不改任何东西，不联网。
#
#  v3 相对 v2 的改动：
#    - 修了标题格式：v2 里 `echo "== x"; cmd` 会把命令输出接到标题同一行，
#      所以 "== sw_vers" 后面直接跟着 "ProductName:"。
#    - 结论从"加载了没有"细化到"RM 走到哪一步"：
#      PASS 1（RM 初始化）/ 固件装载 / RmInitAdapter / headwatch。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# results/ 可能在只读 U 盘上：能写就写旁边，不能写就退到桌面
RESULTS="$HERE/results"
if ! mkdir -p "$RESULTS" 2>/dev/null; then
  RESULTS="$HOME/Desktop/g1-results"
  mkdir -p "$RESULTS" 2>/dev/null || true
fi
OUT="$RESULTS/diag-$STAMP.txt"
: > "$OUT"

sec() { printf '\n== %s\n' "$*" >> "$OUT"; }

printf 'G1 诊断 v3 %s\n' "$(date)"
printf '输出: %s\n' "$OUT"

# ---- 1. 环境 ---------------------------------------------------------------
sec collected;  date >> "$OUT"
sec host;       uname -srm >> "$OUT"
sec sw_vers;    sw_vers >> "$OUT" 2>&1; printf 'build: %s\n' "$(sw_vers -buildVersion 2>&1)" >> "$OUT"
sec KDK;        ls -1 /Library/Developer/KDKs >> "$OUT" 2>&1 || echo '(none)' >> "$OUT"
sec 'kmutil kdk help'; kmutil install --help 2>&1 | grep -i -A2 'kdk' >> "$OUT" || echo '(no kdk option)' >> "$OUT"

# ---- 2. 加载状态 -----------------------------------------------------------
sec kextstat;   kextstat 2>/dev/null | grep -Ei 'NVRM|NVAccel|NVRMFB' >> "$OUT" || echo '(no NV kext loaded)' >> "$OUT"
sec showloaded; kmutil showloaded 2>&1 | grep -Ei 'NVRM|NVAccel|NVRMFB' >> "$OUT" || echo '(not in kernel collection)' >> "$OUT"
sec 'ioreg NVRM 关键属性'
ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation|boot-raster|bars)' >> "$OUT" \
  || echo '(no NVRM node)' >> "$OUT"
sec boot-args;  nvram boot-args >> "$OUT" 2>&1

# ---- 3. 装了什么 -----------------------------------------------------------
sec '/Library/Extensions'; ls -1 /Library/Extensions >> "$OUT" 2>&1
sec 'installed NVRM bundle'
if [ -d /Library/Extensions/NVRM.kext ]; then
  ls -l /Library/Extensions/NVRM.kext/Contents/MacOS >> "$OUT" 2>&1
  shasum -a 256 /Library/Extensions/NVRM.kext/Contents/MacOS/NVRM >> "$OUT" 2>&1
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Library/Extensions/NVRM.kext/Contents/Info.plist >> "$OUT" 2>&1
  /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' /Library/Extensions/NVRM.kext/Contents/Info.plist >> "$OUT" 2>&1
else
  echo '(NVRM.kext is not installed)' >> "$OUT"
fi
sec 'kernel collections'
shasum -a 256 /System/Library/KernelCollections/*.kc* >> "$OUT" 2>&1
[ -d /Library/KernelCollections ] && shasum -a 256 /Library/KernelCollections/*.kc* >> "$OUT" 2>&1

# ---- 4. 设备节点与固件 -----------------------------------------------------
sec 'ioreg NVRM node (full)'
ioreg -l -w 0 -rc NVRM 2>/dev/null | head -80 >> "$OUT" || echo '(no NVRM node)' >> "$OUT"
sec 'ioreg NVRM instance count'
ioreg -c NVRM 2>/dev/null | grep -c '<class NVRM' >> "$OUT" || echo 0 >> "$OUT"
sec 'NullMoth tree'
ls -lR /Library/NullMoth 2>/dev/null | head -60 >> "$OUT" || echo '(absent)' >> "$OUT"
sec 'nvfw firmware'
ls -l /Library/NullMoth/nvfw/nvidia/*/ 2>/dev/null | head -30 >> "$OUT" || echo '(absent)' >> "$OUT"
sec 'nvfw 校验（驱动要求的字节数/SHA-1）'
for n in gsp_ga10x.bin ucodes_ga10x.bin; do
  f="/Library/NullMoth/nvfw/nvidia/610.57.04/$n"
  if [ -f "$f" ]; then
    printf '%-18s %12s B  %s\n' "$n" "$(stat -f %z "$f")" "$(shasum -a 1 "$f" | cut -d' ' -f1)" >> "$OUT"
  else
    printf '%-18s (absent)\n' "$n" >> "$OUT"
  fi
done

# ---- 5. GPU 与日志 ---------------------------------------------------------
sec 'GPU PCI'
ioreg -l -w 0 -rc IOPCIDevice 2>/dev/null | grep -iE '"IOName" = "10de|25a9|pcidebug' | head -10 >> "$OUT"
sec 'kernel NV log (20m)'
log show --last 20m --predicate 'process == "kernel"' 2>/dev/null \
  | grep -iE 'NVRM|NullMoth|GSP|nvaccel' | tail -120 >> "$OUT"
sec 'NVRM log (10m)'
log show --last 10m --predicate 'eventMessage CONTAINS "NVRM"' 2>&1 | tail -60 >> "$OUT"
sec 'panic files'
ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 >> "$OUT" || echo '(none)' >> "$OUT"
sec 'recent kmutil logs'
ls -1t "$RESULTS"/load-*/kmutil-*.txt 2>/dev/null | head -3 >> "$OUT"
for f in $(ls -1t "$RESULTS"/load-*/kmutil-*.txt 2>/dev/null | head -2); do
  printf -- '--- %s\n' "$f" >> "$OUT"; tail -20 "$f" >> "$OUT"
done

cp "$OUT" "$HOME/Desktop/diag-$STAMP.txt" 2>/dev/null || true

# ---- 6. 结论（看日志，不靠猜）---------------------------------------------
kdk=0;    ls /Library/Developer/KDKs >/dev/null 2>&1 && kdk=1
inst=0;   [ -d /Library/Extensions/NVRM.kext ] && inst=1
loaded=0; kextstat 2>/dev/null | grep -q 'NVRM' && loaded=1
node=0;   ioreg -c NVRM 2>/dev/null | grep -q '<class NVRM' && node=1
fwfile=0; [ -f /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin ] && fwfile=1
pass1=0;  grep -q 'PASS 1 REACHED' "$OUT" && pass1=1
fwload=0; grep -q 'firmware loaded:' "$OUT" && fwload=1
fwnone=0; grep -qE 'vnode_open failed|No firmware image' "$OUT" && fwnone=1
adapter=0; grep -q 'rm_init_adapter -> FAILED' "$OUT" && adapter=1
headrun=0; grep -q 'headwatch: done' "$OUT" && headrun=1

printf '\n== 结论\n'
printf 'KDK 已安装:        %s\n' "$([ "$kdk" = 1 ] && echo yes || echo NO)"
printf 'NVRM 在扩展目录:   %s\n' "$([ "$inst" = 1 ] && echo yes || echo NO)"
printf 'NVRM 已加载:       %s\n' "$([ "$loaded" = 1 ] && echo yes || echo NO)"
printf 'NVRM 设备节点:     %s\n' "$([ "$node" = 1 ] && echo yes || echo NO)"
printf 'RM 到 PASS 1:      %s\n' "$([ "$pass1" = 1 ] && echo yes || echo NO)"
printf 'GSP 固件在盘上:    %s\n' "$([ "$fwfile" = 1 ] && echo yes || echo NO)"
printf 'GSP 固件已装载:    %s\n' "$([ "$fwload" = 1 ] && echo yes || echo NO)"
printf 'RmInitAdapter 失败:%s\n' "$([ "$adapter" = 1 ] && echo ' yes（看日志里的原因）' || echo NO)"
printf 'headwatch 跑过:    %s\n' "$([ "$headrun" = 1 ] && echo yes || echo NO)"

if [ "$node" = 1 ] && [ "$pass1" = 1 ] && [ "$adapter" = 1 ] && [ "$fwnone" = 1 ]; then
  printf '\n判定: 驱动与 RM 都通了，卡在 GSP 固件不在盘上。\n'
  printf '      期望路径: /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin\n'
  printf '      用 G1-装固件.command 安装后重启。\n'
  rc=8
elif [ "$node" = 1 ] && [ "$fwload" = 1 ] && [ "$adapter" = 0 ]; then
  printf '\n判定: 固件装上了、RmAInitAdapter 没有报失败 —— 这一关过了，看 head/RM 后续日志。\n'
  rc=0
elif [ "$node" = 1 ] && [ "$fwload" = 1 ] && [ "$adapter" = 1 ]; then
  printf '\n判定: 固件装上了但 RmInitAdapter 仍然失败 —— 原因已不是固件缺失，看日志末尾。\n'
  rc=9
elif [ "$loaded" = 1 ] && [ "$node" = 1 ]; then
  printf '\n判定: 已加载、设备节点在，但 RM 没到 PASS 1 —— 看「内核 NV log」最早那几行。\n'
  rc=4
elif [ "$inst" = 1 ] && [ "$kdk" = 1 ]; then
  printf '\n判定: 扩展在、KDK 在，但没加载 —— 内核集合可能没重建成功，或需要重启。\n'
  rc=5
elif [ "$inst" = 1 ]; then
  printf '\n判定: 装进了扩展目录，但没有 KDK，集合无法重建，所以不会加载。\n'
  rc=6
else
  printf '\n判定: NVRM 根本没装。\n'
  rc=7
fi

printf '\n报告: %s\n' "$OUT"
printf '桌面副本: %s\n' "$HOME/Desktop/diag-$STAMP.txt"
exit "$rc"
