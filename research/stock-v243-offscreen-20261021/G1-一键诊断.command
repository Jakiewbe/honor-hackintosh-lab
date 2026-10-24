#!/bin/bash
# ============================================================================
#  G1 一键诊断 v5（只读）
#
#  双击运行，或：bash G1-一键诊断.command
#
#  它把判断"驱动到底走到哪一步"需要的全部信息写成一个文件，放在
#  本脚本旁边的 results/ 里，同时复制一份到桌面。
#  不需要 sudo，不改任何东西，不联网。
#
#  v3: 修标题格式；结论细化到 RM 的每一步（PASS 1 / 固件 / RmInitAdapter / headwatch）。
#  v4: 加 NVRMFB/NVAccel 安装状态、GSP/FSP 定向日志、head 与 panic 结论行。
#  v5: 加开机时刻与运行时长（判断"到底重启了没有"）、
#      不带 process 过滤的 nvrm 日志（kext 没 attach 时唯一线索）、
#      kextutil -n 诊断（不加载，只报 KMOD/依赖问题）、
#      kmutil showloaded 明细；节点缺失单独给 rc=12 分支。
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

printf 'G1 诊断 v5 %s\n' "$(date)"
printf '输出: %s\n' "$OUT"

# ---- 1. 环境 ---------------------------------------------------------------
sec collected;  date >> "$OUT"
sec host;       uname -srm >> "$OUT"
sec sw_vers;    sw_vers >> "$OUT" 2>&1; printf 'build: %s\n' "$(sw_vers -buildVersion 2>&1)" >> "$OUT"
sec '开机时刻 / 运行时长（判断有没有真的重启）'
sysctl -n kern.boottime >> "$OUT" 2>&1
uptime >> "$OUT" 2>&1
sec KDK;        ls -1 /Library/Developer/KDKs >> "$OUT" 2>&1 || echo '(none)' >> "$OUT"
sec 'kmutil kdk help'; kmutil install --help 2>&1 | grep -i -A2 'kdk' >> "$OUT" || echo '(no kdk option)' >> "$OUT"

# ---- 2. 加载状态 -----------------------------------------------------------
sec kextstat;   kextstat 2>/dev/null | grep -Ei 'NVRM|NVAccel|NVRMFB' >> "$OUT" || echo '(no NV kext loaded)' >> "$OUT"
sec showloaded; kmutil showloaded 2>&1 | grep -Ei 'NVRM|NVAccel|NVRMFB' >> "$OUT" || echo '(not in kernel collection)' >> "$OUT"
sec 'ioreg NVRM 关键属性'
ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation|boot-raster|bars)' >> "$OUT" \
  || echo '(no NVRM node)' >> "$OUT"
sec boot-args;  nvram boot-args >> "$OUT" 2>&1
sec '在用辅助集合里能不能看到 NVRM（区分「已加载」和「已登记」）'
sudo -n kmutil inspect -a x86_64 -A /Library/KernelCollections/AuxiliaryKernelExtensions.kc 2>&1 \
  | grep -i -m 5 'nullmoth\|NVRM' >> "$OUT" \
  || echo '(读不到：无 sudo 免密；请用 bash ./G1-修复加载.command 看 0.5 节)' >> "$OUT"

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
sec 'NVRMFB / NVAccel 安装状态'
for k in NVRMFB NVAccel NVRMAGDC; do
  if [ -d "/Library/Extensions/$k.kext" ]; then
    printf '%-10s installed  %s\n' "$k" "$(shasum -a 256 "/Library/Extensions/$k.kext/Contents/MacOS/$k" 2>/dev/null | cut -d' ' -f1)" >> "$OUT"
  else
    printf '%-10s (not installed)\n' "$k" >> "$OUT"
  fi
done
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
sec 'nvrm 日志（30m，不带 process 过滤；kext 没 attach 时只有这里有线索）'
log show --last 30m --predicate 'eventMessage CONTAINS[c] "nvrm" OR eventMessage CONTAINS[c] "nullmoth"' 2>&1 \
  | grep -viE 'Boot args:' | tail -60 >> "$OUT" || echo '(none)' >> "$OUT"
sec 'kernelmanagerd / syspolicyd 关于 NVRM 的行（30m）'
log show --last 30m --predicate 'process == "kernelmanagerd" OR process == "syspolicyd"' 2>&1 \
  | grep -i 'nvrm' | tail -30 >> "$OUT" || echo '(none)' >> "$OUT"
sec 'panic files'
ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 >> "$OUT" || echo '(none)' >> "$OUT"
sec 'GSP / FSP / head 关键行（只看这几类）'
log show --last 30m --predicate 'process == "kernel"' 2>/dev/null \
  | grep -iE 'firmware loaded|RmFetchGspRmImages|RmInitAdapter|fsp|gsp boot|WPR|headwatch|NVRM-xnu: .*-> ' \
  | tail -60 >> "$OUT" || echo '(none)' >> "$OUT"
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
headgo=0;  grep -q 'headwatch: head 0' "$OUT" && ! grep -q 'headwatch: head 0 STOPPED' "$OUT" && headgo=1
panic=0;   ls /Library/Logs/DiagnosticReports/*.panic >/dev/null 2>&1 && panic=1
fbk=0;     [ -d /Library/Extensions/NVRMFB.kext ] && fbk=1
acck=0;    [ -d /Library/Extensions/NVAccel.kext ] && acck=1

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
printf 'head 没停(STOPPED):%s\n' "$([ "$headgo" = 1 ] && echo ' yes' || echo NO)"
printf 'NVRMFB 已安装:     %s\n' "$([ "$fbk" = 1 ] && echo yes || echo NO)"
printf 'NVAccel 已安装:    %s\n' "$([ "$acck" = 1 ] && echo yes || echo NO)"
printf 'panic 文件:        %s\n' "$([ "$panic" = 1 ] && echo '有（看 panic files）' || echo none)"

if [ "$panic" = 1 ]; then
  printf '\n判定: 本轮重启后出现了 panic —— 先把 /Library/Logs/DiagnosticReports/*.panic 发回。\n'
  printf '      已知风险点：GSP/FSP 启动失败清理路径的 tmrEventDestroy 二次销毁\n'
  printf '      （nv_destroy_nano_timer 里 page fault 0x1010），上游补丁\n'
  printf '      kexts/NVRM/patches/610-fsp-timer-double-destroy.patch。\n'
  printf '      恢复：G1-加载实验.command 的 rollback，或 boot-args 加 -nvrmnogo。\n'
  rc=10
elif [ "$node" = 1 ] && [ "$pass1" = 1 ] && [ "$adapter" = 1 ] && [ "$fwnone" = 1 ]; then
  printf '\n判定: 驱动与 RM 都通了，卡在 GSP 固件不在盘上。\n'
  printf '      期望路径: /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin\n'
  printf '      用 G1-装固件.command 安装后重启。\n'
  rc=8
elif [ "$node" = 1 ] && [ "$fwload" = 1 ] && [ "$adapter" = 0 ] && [ "$headgo" = 1 ]; then
  printf '\n判定: 固件装载 + RmInitAdapter 通过 + head 在跑 —— 这一关过了。\n'
  printf '      下一步: 装 NVRMFB / NVAccel（现在缺），重建 KC，再看显示与 Metal。\n'
  rc=0
elif [ "$node" = 1 ] && [ "$fwload" = 1 ] && [ "$adapter" = 0 ]; then
  printf '\n判定: 固件装载 + RmInitAdapter 通过，但 head 仍 STOPPED。\n'
  printf '      下一步: 看「GSP / FSP / head 关键行」，再决定是 display pipe 还是 head 配置问题。\n'
  rc=11
elif [ "$node" = 1 ] && [ "$fwload" = 1 ] && [ "$adapter" = 1 ]; then
  printf '\n判定: 固件装上了但 RmInitAdapter 仍然失败 —— 原因已不是固件缺失，看日志末尾的错误码。\n'
  rc=9
elif [ "$loaded" = 1 ] && [ "$node" = 1 ]; then
  printf '\n判定: 已加载、设备节点在，但 RM 没到 PASS 1 —— 看「内核 NV log」最早那几行。\n'
  rc=4
elif [ "$loaded" = 1 ] && [ "$node" = 0 ]; then
  printf '\n判定: 扩展进内核了，但这次开机 NVRM 没有 attach 到 GPU（没有设备节点、没有 RM 日志）。\n'
  printf '      这不是固件问题 —— 固件连读都没读到。先看三处：\n'
  printf '        1) 「开机时刻」对得上你装固件之后吗？装完固件没重启，就是上一次开机留下的旧状态。\n'
  printf '        2) 「在用辅助集合里能不能看到 NVRM」——看不到就说明「加载了但没登记」，\n'
  printf '           IOKit 不会去匹配 personality，于是 probe/start 根本不被调用。\n'
  printf '        3) 「kernelmanagerd / syspolicyd 关于 NVRM 的行」里有没有\n'
  printf '           restricted lookup table 报错。\n'
  printf '      处理: bash ./G1-修复加载.command --force，再 sudo reboot，然后重跑本脚本。\n'
  rc=12
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
