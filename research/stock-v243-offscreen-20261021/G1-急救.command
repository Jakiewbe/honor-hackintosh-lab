#!/bin/bash
# G1-急救.command — 系统反复自动重启时先让它稳下来，并把"到底谁在重启"的证据留下来。
#
# 默认动作（不需要你判断，跑一次就行）：
#   1. 让 NVRM 永久闭嘴：NVRAM 写 nullmoth-remove
#      —— nvrm_off.h 里 nvrm_driver_off() 一看到这个属性就 return true，
#         probe() 直接 return NULL，驱动完全不碰 GPU。
#      —— 这个标志 OpenCore 启动时不会重写（boot-args 里的 -nvoff 会被重写，所以不用那个）。
#   2. 拆掉我们自己的自动实验 daemon（com.g1.auto*），否则它每次开机会再重启一次。
#   3. 清守卫计数（nullmoth-nv-starts）。
#   4. 收集证据：panic 文件、最近几次重启、内核日志里的 NVRM/GSP 行。
# 不重启、不删 kext、不改 /Library/Extensions、不动 aux KC。
#
# 用法：
#   bash ./G1-急救.command            # 一键止损 + 收集证据（最常用）
#   bash ./G1-急救.command fast       # 只拆 daemon + 让 NVRM 闭嘴，几秒完成（机器活不过 1 分钟时用）
#   bash ./G1-急救.command off        # 只让 NVRM 闭嘴
#   bash ./G1-急救.command on         # 解除闭嘴（要重新测驱动时）
#   bash ./G1-急救.command panics     # 只看 panic 记录
#   bash ./G1-急救.command status     # 只看当前开关 / daemon / 最近重启
#   bash ./G1-急救.command daemons    # 只拆我们的自动实验 daemon
#
# 报告写到 results/rescue-<时间>.txt（U 盘只读时退到 /var/tmp）。

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LABEL_BASE=com.g1.auto
GUARD=nullmoth-nv-starts
REMOVE=nullmoth-remove
PANIC_DIR=/Library/Logs/DiagnosticReports

STAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HERE/results" 2>/dev/null
REPORT="$HERE/results/rescue-$STAMP.txt"
if ! : >"$REPORT" 2>/dev/null; then
  REPORT="/var/tmp/g1-rescue-$STAMP.txt"
  : >"$REPORT" 2>/dev/null
fi

say() { printf '\n== %s\n' "$*"; printf '\n== %s\n' "$*" >>"$REPORT" 2>/dev/null; }
out() { printf '%s\n' "$*";    printf '%s\n' "$*"    >>"$REPORT" 2>/dev/null; }

need_sudo() {
  if sudo -n true 2>/dev/null; then return 0; fi
  echo "需要 sudo 权限，先输密码："
  sudo -v || { echo "拿不到 sudo，退出"; exit 2; }
}

nvram_dump() {
  local d
  d=$(nvram -p 2>/dev/null)
  if [ -z "$d" ] && sudo -n true 2>/dev/null; then d=$(sudo -n nvram -p 2>/dev/null); fi
  printf '%s\n' "$d"
}
get_var() { nvram_dump | awk -v k="$1" '$1==k { $1=""; sub(/^[ \t]+/,""); print; exit }'; }

# --------------------------------------------------------------------------
status() {
  say "当前状态"
  if [ -n "$(get_var "$REMOVE")" ]; then
    out "  $REMOVE : 存在 → NVRM 现在完全不启动（= 已闭嘴）"
  else
    out "  $REMOVE : 不存在 → NVRM 会去初始化 GPU"
  fi
  out "  $GUARD: $(get_var "$GUARD" | sed 's/^$/（不存在）/' )"
  local ba; ba=$(nvram boot-args 2>/dev/null || true)
  out "  boot-args: ${ba:-(空)}"

  say "我们的自动实验 daemon"
  local f found=0
  for f in /Library/LaunchDaemons/$LABEL_BASE.plist /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    out "  存在: $(basename "$f")"; found=1
  done
  [ "$found" = 0 ] && out "  没有（正常）"

  say "NVRM 安装情况"
  local k
  for k in NVRM NVRMFB NVAccel; do
    if [ -d "/Library/Extensions/$k.kext" ]; then
      out "  $k.kext: 已安装"
    else
      out "  $k.kext: 未安装"
    fi
  done

  say "最近的重启"
  last reboot 2>/dev/null | head -8 | sed 's/^/  /'
  out "  本次开机: $(sysctl -n kern.boottime 2>/dev/null)"
  out "  运行了: $(uptime 2>/dev/null)"
}

# --------------------------------------------------------------------------
panics() {
  say "panic 记录（$PANIC_DIR）"
  local n=0 f
  # shellcheck disable=SC2044
  for f in $(ls -1t "$PANIC_DIR"/*.panic 2>/dev/null | head -5); do
    n=$((n+1))
    out "  $f"
    out "    大小 $(stat -f%z "$f" 2>/dev/null) 字节，时间 $(stat -f%Sm "$f" 2>/dev/null)"
  done
  [ "$n" = 0 ] && out "  没有 .panic 文件（说明不是内核 panic 重启）"

  if [ "$n" -gt 0 ]; then
    local newest
    newest=$(ls -1t "$PANIC_DIR"/*.panic 2>/dev/null | head -1)
    say "最新 panic 的开头（里面 panic(cpu… 和后面的调用栈就是原因）"
    sudo head -40 "$newest" 2>/dev/null | sed 's/^/  /' || head -40 "$newest" 2>/dev/null | sed 's/^/  /'
  fi

  say "NVRAM 里的 panic 线索"
  sudo nvram -p 2>/dev/null | grep -i panic | sed 's/^/  /' || true

  say "内核日志（NVRM / GSP / watchdog / panic，最近 2 小时）"
  out "  （这条可能要几十秒）"
  sudo log show --last 2h --style compact \
    --predicate 'eventMessage CONTAINS[c] "NVRM" OR eventMessage CONTAINS[c] "gsp" OR eventMessage CONTAINS[c] "panic" OR eventMessage CONTAINS[c] "watchdog"' \
    2>/dev/null | tail -60 | sed 's/^/  /'
}

# --------------------------------------------------------------------------
drv_off() {
  need_sudo
  say "让 NVRM 闭嘴"
  sudo nvram "$REMOVE=1" 2>/dev/null
  if [ -n "$(get_var "$REMOVE")" ]; then
    out "  已写 $REMOVE → 下次开机 NVRM::probe() 直接 return NULL，不碰 GPU"
  else
    out "  !! 写不进去。手动试: sudo nvram $REMOVE=1"
    return 1
  fi
  sudo nvram -d "$GUARD" 2>/dev/null
  out "  已清 $GUARD（值不重要，驱动反正不跑了）"
  out "  解除方法: bash ./G1-急救.command on"
}

drv_on() {
  need_sudo
  say "解除 NVRM 闭嘴"
  sudo nvram -d "$REMOVE" 2>/dev/null
  sudo nvram -d "$GUARD" 2>/dev/null
  if [ -z "$(get_var "$REMOVE")" ]; then
    out "  已清 $REMOVE 和 $GUARD → 下次开机 NVRM 会重新尝试初始化"
    out "  注意：装上 NVRMFB 之前，守卫每两次开机要再清一次"
  else
    out "  !! 没清掉，手动试: sudo nvram -d $REMOVE"
    return 1
  fi
}

kill_daemons() {
  need_sudo
  say "拆掉自动实验 daemon"
  local f b found=0
  for f in /Library/LaunchDaemons/$LABEL_BASE.plist /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    b=$(basename "$f" .plist)
    sudo launchctl bootout "system/$b" 2>/dev/null
    sudo rm -f "$f"
    out "  已移除 $b"
    found=1
  done
  [ "$found" = 0 ] && out "  没有需要移除的 daemon"
  if pgrep -fl "自动实验|G1-自动实验" >/dev/null 2>&1; then
    out "  还有进程在跑："
    pgrep -fl "自动实验|G1-自动实验" | sed 's/^/    /'
  fi
}

# --------------------------------------------------------------------------
# 从统一日志里把历史 NVRM 记录捞出来。只读，不改任何状态。
# 用途：那些没来得及采集的开机（尤其"固件装上之后驱动真的跑过的那两次"），
#       日志还留在盘上，可以倒推当时走到哪一步、有没有崩。
logs_dump() {
  local since="${1:-12h}" f n k c
  need_sudo
  say "取回 NVRM 历史日志（最近 $since，只读）"
  f="$HERE/results/nvrm-log-$STAMP.txt"
  : >"$f" 2>/dev/null || f="/var/tmp/nvrm-log-$STAMP.txt"
  out "  可能要几十秒到几分钟，取决于日志量"
  sudo log show --last "$since" --style compact \
    --predicate 'eventMessage CONTAINS[c] "NVRM" OR eventMessage CONTAINS[c] "NullMoth" OR eventMessage CONTAINS[c] "RmInit" OR eventMessage CONTAINS[c] "gsp" OR eventMessage CONTAINS[c] "nvaccel" OR eventMessage CONTAINS[c] "boot guard"' \
    >"$f" 2>/dev/null
  n=$(wc -l <"$f" 2>/dev/null | tr -d ' ')
  out "  抓到 ${n:-0} 行 → $f"

  say "关键标记"
  for k in "probe 10de" "boot guard" "PASS 1 REACHED" "nv_get_firmware" \
           "firmware loaded" "RmFetchGspRmImages" "RmInitAdapter" \
           "rm_init_adapter ->" "bus master" "headwatch" "nvaccel" "panic("; do
    c=$(grep -c -F "$k" "$f" 2>/dev/null)
    [ "${c:-0}" -gt 0 ] 2>/dev/null && out "  [$c] $k"
  done

  say "最后 40 行（看它停在哪）"
  tail -40 "$f" 2>/dev/null | cut -c1-200 | sed 's/^/  /'

  say "怎么读"
  out "  PASS 1 REACHED          → RM 起来了"
  out "  nv_get_firmware + vnode_open failed → 固件没读到"
  out "  firmware loaded         → 固件读到了（今天还没验证过这个边界）"
  out "  RmInitAdapter failed    → 卡在 adapter 初始化，固件已过"
  out "  panic(                  → 崩过，配合 panics 看调用栈"
}

# --------------------------------------------------------------------------
# fast：只做最要紧的两件事，几秒内完成。机器活不过一分钟时用这个。
fast() {
  kill_daemons || true     # 先拆会重启的 daemon，这一步最要紧
  drv_off || true          # 再让 NVRM 闭嘴
  status
}

rescue() {
  kill_daemons || true
  drv_off || true
  status
  panics
  say "下一步"
  if ls "$PANIC_DIR"/*.panic >/dev/null 2>&1; then
    out "  有 panic 文件 → 是内核/驱动把它弄崩的。把这份报告和 panic 文件发回，我按调用栈定位。"
    out "  现在可以正常重启：NVRM 已被挡住，重启后应该稳定。"
  else
    out "  没有 panic 文件 → 不是内核崩溃。最可能是残留的自动实验 daemon 在按周期重启，已一并拆掉。"
    out "  现在重启，如果还自动重启，说明是别的东西（电源/内存/Apple 自己的 kext），再采一次诊断。"
  fi
  out "  报告: $REPORT"
  out "  把这个文件发回即可（含 panic、日志、开关状态）。"
}

case "${1:-rescue}" in
  rescue|"") rescue ;;
  fast)    fast;    out "  报告: $REPORT" ;;
  off)     drv_off; out "  报告: $REPORT" ;;
  on)      drv_on;  out "  报告: $REPORT" ;;
  status)  status;  out "  报告: $REPORT" ;;
  panics)  panics;  out "  报告: $REPORT" ;;
  daemons) kill_daemons; out "  报告: $REPORT" ;;
  logs)    logs_dump "${2:-12h}"; out "  报告: $REPORT" ;;
  *) echo "用法: bash $0 [rescue|fast|off|on|status|panics|daemons|logs [时长]]"; exit 2 ;;
esac
