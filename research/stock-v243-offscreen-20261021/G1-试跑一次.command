#!/bin/bash
# G1-试跑一次.command — 受控地让 NVRM 带着 GSP 固件跑【恰好一次】，并自动把证据留下来。
#
# 为什么需要它：
#   固件 2026-10-24 07:47 就装好了，之后两次开机驱动确实启动过（守卫计数 0→2），
#   但当时自动实验 daemon 在乱重启，日志没采到。现在要从"再跑一次"里拿到那一次完整日志。
#
# 三层自我限制（重要）：
#   1. 守 卫 = 计数器。安装时把 nullmoth-nv-starts 预置成 1，
#      驱动 start() 里先判断 <2 → 放行，再 +1 变 2；于是它只能启动这一回。
#      即使这次开机就 panic，下次开机计数已是 2，驱动自锁，不会反复重启。
#   2. 采集 daemon 只读日志，**没有任何 shutdown/reboot 代码**。
#   3. 采集完成后立刻写 nullmoth-remove=1 把驱动关回去，并 bootout + 删除自己。
#
# 用法：
#   bash ./G1-试跑一次.command            # 安装 + 清开关（然后你重启）
#   bash ./G1-试跑一次.command report     # 重启后看结果（几十秒内自动采好）
#   bash ./G1-试跑一次.command status     # 看现在的开关/任务状态
#   bash ./G1-试跑一次.command cancel     # 反悔：拆任务、把驱动关回去
#
# 不删 kext、不动 /Library/Extensions、不动 aux KC、不重启、不改 boot-args。

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LABEL=com.g1.once
PLIST=/Library/LaunchDaemons/$LABEL.plist
STATE=/var/tmp/g1-once
SELF_STABLE=$STATE/self.sh
GUARD=nullmoth-nv-starts
REMOVE=nullmoth-remove
STAMP=$(date +%Y%m%d-%H%M%S)
SUDO_ARGS="${*:-install}"

mkdir -p "$STATE" 2>/dev/null
mkdir -p "$HERE/results" 2>/dev/null
REPORT="$HERE/results/trial-$STAMP.txt"
: >"$REPORT" 2>/dev/null || REPORT="$STATE/trial-$STAMP.txt"

say() { printf '\n== %s\n' "$*"; printf '\n== %s\n' "$*" >>"$REPORT" 2>/dev/null; }
out() { printf '%s\n' "$*";    printf '%s\n' "$*"    >>"$REPORT" 2>/dev/null; }

need_sudo() {
  [ "$(id -u)" = 0 ] && return 0
  sudo -n true 2>/dev/null && return 0
  echo
  echo "这一步要管理员权限。请在下面输入开机密码（输入时屏幕不显示，是正常的）："
  sudo -v && return 0
  echo
  echo "没拿到权限。用这条重跑："
  echo "  sudo bash \"$0\" ${SUDO_ARGS:-install}"
  exit 2
}

nv() { sudo nvram "$@" 2>/dev/null; }
nv_get() { nvram -p 2>/dev/null | awk -v k="$1" '$1==k { $1=""; sub(/^[ \t]+/,""); print; exit }'; }

# --------------------------------------------------------------------------
# 开机自动执行的采集器（由 launchd 以 root 调用，参数 --collect-once）
collect_once() {
  local d="$STATE"
  local stamp dump log k c lb
  stamp=$(date +%Y%m%d-%H%M%S)
  log="$d/boot-$stamp.log"
  dump="$d/nvrm-$stamp.txt"
  lb=$(command -v log 2>/dev/null || echo /usr/bin/log)
  mkdir -p "$d" 2>/dev/null
  sleep 10                       # 给 NVRM/RM 一点时间跑到失败点

  "$lb" show --last 5m --style compact \
    --predicate 'eventMessage CONTAINS[c] "NVRM" OR eventMessage CONTAINS[c] "NullMoth" OR eventMessage CONTAINS[c] "RmInit" OR eventMessage CONTAINS[c] "nvaccel" OR eventMessage CONTAINS[c] "boot guard"' \
    >"$dump" 2>/dev/null

  {
    echo "== 一次性试跑采集"
    echo "   采集时间: $(date)"
    echo "   开机时间: $(sysctl -n kern.boottime 2>/dev/null)"
    echo "   当前开关:"; nvram -p 2>/dev/null | grep -i nullmoth | sed 's/^/     /'
    echo
    echo "== 关键标记"
    for k in "probe 10de" "boot guard" "PASS 1 REACHED" "nv_get_firmware" \
             "vnode_open failed" "firmware loaded" "RmFetchGspRmImages" \
             "RmInitAdapter" "rm_init_adapter ->" "bus master" "headwatch" \
             "nvaccel" "FSP" "WPR" "panic("; do
      c=$(grep -c -F "$k" "$dump" 2>/dev/null)
      [ "${c:-0}" -gt 0 ] 2>/dev/null && echo "   [$c] $k"
    done
    echo
    echo "== 结论草稿"
    if grep -q "firmware loaded" "$dump" 2>/dev/null; then
      echo "   固件读到了 —— 新边界，往下看 RmInitAdapter / FSP"
    else
      echo "   没看到 'firmware loaded'"
    fi
    if grep -q "PASS 1 REACHED" "$dump" 2>/dev/null; then
      echo "   RM 初始化到了 PASS 1"
    else
      echo "   没到 PASS 1"
    fi
    if grep -q "RmInitAdapter failed\|rm_init_adapter -> FAILED" "$dump" 2>/dev/null; then
      echo "   adapter 初始化失败（固件之后的那一关）"
    fi
    echo
    echo "== NVRM / RM / GSP 日志原文（最近 5 分钟，$(wc -l <"$dump" 2>/dev/null | tr -d ' ') 行）"
    cat "$dump" 2>/dev/null
    echo
    echo "== kextstat（nullmoth 相关）"
    kextstat 2>/dev/null | grep -i nullmoth
    echo
    echo "== ioreg 设备节点"
    ioreg -w0 -l -r -n "pci10de,25a9" -d 3 2>/dev/null | head -40
    echo
    echo "== panic 文件（最近 5 个）"
    ls -lt /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | head -5
  } >"$log" 2>&1

  # 拷一份到 U 盘（若能写）
  if [ -d "$HERE/results" ] && [ -w "$HERE/results" ]; then
    cp "$log" "$HERE/results/" 2>/dev/null
  fi

  # 立刻把驱动关回去 + 清计数（只此一次，之后彻底静默）
  /usr/sbin/nvram "$REMOVE=1" 2>/dev/null
  /usr/sbin/nvram -d "$GUARD" 2>/dev/null

  # 自删，绝不留第二次
  /bin/launchctl bootout "system/$LABEL" 2>/dev/null
  /bin/rm -f "$PLIST" 2>/dev/null
  echo "DONE $(date)" >>"$log"
  exit 0
}

# --------------------------------------------------------------------------
do_install() {
  need_sudo
  if [ -f "$PLIST" ]; then
    echo "已经有一个一次性任务在等待开机：$PLIST"
    echo "先 bash \"$0\" cancel 再装，或直接 bash \"$0\" report 看结果。"
    exit 3
  fi

  say "将要做的三件事"
  out "  1) 守卫计数置 1 → 下次开机驱动只能启动【一次】，之后自锁"
  out "  2) 清掉 $REMOVE（解除闭嘴）"
  out "  3) 装一次性采集 daemon（只读日志，绝不重启），采完自动关驱动并自删"
  out ""
  out "  最坏情况：这次开机驱动 panic → 机器自动重启 → 计数已是 2 → 驱动永久自锁，不会反复重启。"
  out "  想彻底反悔：bash \"$0\" cancel"

  printf '\n确认执行？[y/N] '
  read -r ans
  case "$ans" in y|Y|yes|YES) ;; *) echo "已取消，什么都没改。"; exit 1 ;; esac

  say "安装"
  cp "$0" "$SELF_STABLE" 2>/dev/null
  chmod +x "$SELF_STABLE" 2>/dev/null
  [ -f "$SELF_STABLE" ] || { out "  !! 复制自身失败，中止"; exit 4; }
  out "  采集器: $SELF_STABLE"

  cat >/tmp/g1-once.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SELF_STABLE</string>
    <string>--collect-once</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>$STATE/daemon.out</string>
  <key>StandardErrorPath</key><string>$STATE/daemon.err</string>
</dict>
</plist>
PLIST
  sudo cp /tmp/g1-once.plist "$PLIST" && sudo chown root:wheel "$PLIST" && sudo chmod 644 "$PLIST"
  rm -f /tmp/g1-once.plist
  if [ ! -f "$PLIST" ]; then out "  !! plist 没写进去，中止（什么都没改）"; exit 4; fi
  out "  已装: $PLIST"

  nv "$GUARD=%01"
  out "  守卫计数 = $(nv_get "$GUARD")  （期望 %01 = 只放行一次）"
  nv -d "$REMOVE"
  if [ -n "$(nv_get "$REMOVE")" ]; then
    out "  !! $REMOVE 没删掉 → 驱动仍是关的。手动: sudo nvram -d $REMOVE"; exit 5
  fi
  out "  已解除闭嘴"

  say "现在重启"
  out "  重启后等 1 分钟，然后运行："
  out "    bash \"$0\" report"
  out "  报告: $REPORT"
}

# --------------------------------------------------------------------------
do_report() {
  say "一次性试跑结果"
  if [ -f "$PLIST" ]; then
    out "  注意：采集任务还在（说明这次开机它没跑成功，或还没重启）"
  else
    out "  采集任务已自删（正常：说明它跑完了）"
  fi
  local f
  f=$(ls -t "$STATE"/boot-*.log 2>/dev/null | head -1)
  [ -n "$f" ] || f=$(ls -t "$HERE"/results/boot-*.log 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    out "  还没找到采集文件。先重启过吗？"
    out "  也可以直接手动采：sudo log show --last 10m --predicate 'eventMessage CONTAINS \"NVRM\"' | tail -60"
    exit 6
  fi
  out "  采集文件: $f"
  say "关键标记"
  local k c
  for k in "probe 10de" "boot guard" "PASS 1 REACHED" "nv_get_firmware" \
           "vnode_open failed" "firmware loaded" "RmFetchGspRmImages" \
           "RmInitAdapter" "rm_init_adapter ->" "bus master" "headwatch" \
           "nvaccel" "panic("; do
    c=$(grep -c -F "$k" "$f" 2>/dev/null)
    [ "${c:-0}" -gt 0 ] 2>/dev/null && out "  [$c] $k"
  done
  say "NVRM 全部日志行（尾部 80 行）"
  grep -i "NVRM\|NullMoth\|RmInit\|boot guard\|nvaccel" "$f" 2>/dev/null | tail -80 | cut -c1-220 | sed 's/^/  /'
  say "报告"
  out "  完整文件: $f  （发回这个文件即可）"
}

# --------------------------------------------------------------------------
do_status() {
  say "当前状态"
  out "  $GUARD : $(nv_get "$GUARD")   （%02 = 已自锁；%01 = 还允许启动一次）"
  out "  $REMOVE : $(nv_get "$REMOVE")   （有值 = 驱动关闭）"
  if [ -f "$PLIST" ]; then out "  一次性任务: 已安装（等下次开机）"; else out "  一次性任务: 无"; fi
  ls -t "$STATE"/boot-*.log 2>/dev/null | head -3 | sed 's/^/  采集: /'
  sy=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date '+%Y-%m-%d %H:%M:%S')" +%s 2>/dev/null)
  out "  本次开机: $(sysctl -n kern.boottime 2>/dev/null)"
  out "  报告: $REPORT"
}

do_cancel() {
  need_sudo
  say "反悔：拆掉一次性任务并关掉驱动"
  sudo launchctl bootout "system/$LABEL" 2>/dev/null
  sudo rm -f "$PLIST"
  out "  已移除 $LABEL"
  nv "$REMOVE=1"; nv -d "$GUARD"
  out "  驱动已关闭（$REMOVE=1），计数已清"
  out "  报告: $REPORT"
}

case "${1:-install}" in
  --collect-once) collect_once ;;
  install|"")     do_install ;;
  report)         do_report; out "  报告: $REPORT" ;;
  status)         do_status ;;
  cancel)         do_cancel ;;
  *) echo "用法: bash $0 [install|report|status|cancel]"; exit 2 ;;
esac
