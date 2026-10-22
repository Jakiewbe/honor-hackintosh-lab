#!/bin/bash
# ============================================================================
#  G1 一键诊断（只读）
#
#  双击运行，或：bash G1-一键诊断.command
#
#  它把判断"驱动到底加载没有"需要的全部信息写成一个文件，放在
#  本脚本旁边的 results/ 里，同时复制一份到桌面。
#  不需要 sudo，不改任何东西，不联网。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
RESULTS="$HERE/results"
OUT="$RESULTS/diag-$STAMP.txt"

mkdir -p "$RESULTS" 2>/dev/null || true

printf 'G1 诊断 %s\n' "$(date)"
printf '输出: %s\n' "$OUT"

{
  echo "== collected";      date
  echo "== host";           uname -srm
  echo "== sw_vers";        sw_vers 2>&1; echo "build: $(sw_vers -buildVersion 2>&1)"
  echo "== KDK";            ls -1 /Library/Developer/KDKs 2>&1 || echo '(none)'
  echo "== kmutil kdk help"; kmutil install --help 2>&1 | grep -i -A2 'kdk' || echo '(no kdk option)'
  echo "== kextstat";       kextstat 2>/dev/null | grep -Ei 'NVRM|NVAccel|NVRMFB' || echo '(no NV kext loaded)'
  echo "== showloaded";     kmutil showloaded 2>&1 | grep -Ei 'NVRM|NVAccel|NVRMFB' || echo '(not in kernel collection)'
  echo "== ioreg NVRM";     ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation)' || echo '(no NVRM node)'
  echo "== boot-args";      nvram boot-args 2>&1
  echo "== /Library/Extensions"; ls -1 /Library/Extensions 2>&1
  echo "== installed NVRM bundle"
  if [ -d /Library/Extensions/NVRM.kext ]; then
    ls -l /Library/Extensions/NVRM.kext/Contents/MacOS 2>&1
    shasum -a 256 /Library/Extensions/NVRM.kext/Contents/MacOS/NVRM 2>&1
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Library/Extensions/NVRM.kext/Contents/Info.plist 2>&1
    /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' /Library/Extensions/NVRM.kext/Contents/Info.plist 2>&1
  else
    echo '(NVRM.kext is not installed)'
  fi
  echo "== kernel collections"
  shasum -a 256 /System/Library/KernelCollections/*.kc* 2>&1
  [ -d /Library/KernelCollections ] && shasum -a 256 /Library/KernelCollections/*.kc* 2>&1
  echo "== NVRM log (10m)"
  log show --last 10m --predicate 'eventMessage CONTAINS "NVRM"' 2>&1 | tail -60
  echo "== panic files"
  ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 || echo '(none)'
  echo "== recent kmutil logs"
  ls -1t "$RESULTS"/load-*/kmutil-*.txt 2>/dev/null | head -3
  for f in $(ls -1t "$RESULTS"/load-*/kmutil-*.txt 2>/dev/null | head -2); do
    echo "--- $f"; tail -20 "$f"
  done
} > "$OUT" 2>&1

cp "$OUT" "$HOME/Desktop/diag-$STAMP.txt" 2>/dev/null || true

# ---- 结论 ----------------------------------------------------------------
kdk=0;  ls /Library/Developer/KDKs >/dev/null 2>&1 && kdk=1
inst=0; [ -d /Library/Extensions/NVRM.kext ] && inst=1
loaded=0; kextstat 2>/dev/null | grep -q 'NVRM' && loaded=1
auto=0; ioreg -rn NVRM -l 2>/dev/null | grep -q 'nvrm-autogo' && auto=1

printf '\n== 结论\n'
printf 'KDK 已安装:        %s\n' "$([ "$kdk" = 1 ] && echo yes || echo NO)"
printf 'NVRM 在扩展目录:   %s\n' "$([ "$inst" = 1 ] && echo yes || echo NO)"
printf 'NVRM 已加载:       %s\n' "$([ "$loaded" = 1 ] && echo yes || echo NO)"
printf 'nvrm-autogo 属性:  %s\n' "$([ "$auto" = 1 ] && echo yes || echo NO)"

if [ "$loaded" = 1 ] && [ "$auto" = 1 ]; then
  printf '\n判定: 已加载且 auto-go 关闭（GPU 未初始化）。\n'
  rc=0
elif [ "$loaded" = 1 ]; then
  printf '\n判定: 已加载，但没有看到 nvrm-autogo（可能不是 -nvrmnogo 启动）。\n'
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
