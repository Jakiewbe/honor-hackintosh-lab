#!/bin/bash
# G1-试跑一次.command — 让 NVRM 带 GSP 固件跑【恰好一次】，然后把那一次的日志完整取回来。
#
# v3：不再安装任何 LaunchDaemon。
#     理由：写 /Library/LaunchDaemons 是这条链上最脆的一环（SIP/权限/中途掉线都会失败），
#     而它本来只为一件事存在——"开机时把日志抓下来"。但 macOS 的统一日志本身是落盘的，
#     重启之后依然可以按时间窗查询。于是整个 daemon 可以删掉：
#         go     → 只写两个 NVRAM 变量（守卫预置 1、解除闭嘴）
#         重启   → 驱动只启动这一次，之后自锁
#         report → 直接查日志 + 翻 panic 文件，什么都不用装
#
# 用法：
#   bash ./G1-试跑一次.command            # = go，写开关；然后你手动重启
#   bash ./G1-试跑一次.command report     # 重启后跑，取回那一次的完整记录
#   bash ./G1-试跑一次.command status     # 当前开关 / 开机时长 / 上次试跑时间
#   bash ./G1-试跑一次.command cancel     # 反悔：把驱动关回去、清计数
#
# 安全边界（写死，不接受参数改变）：
#   * 绝不调用 shutdown / reboot / launchctl bootstrap；
#   * 只写 nullmoth-nv-starts 与 nullmoth-remove 两个 NVRAM 变量；
#   * 不碰 /Library/Extensions、不碰 aux KC、不改 boot-args；
#   * 守卫预置 1 → 驱动这次开机启动一次后计数=2 → 永久自锁。即使 panic 也不会反复。
#
# 自锁原理（源码依据 kexts/NVRM/nvrm_off.h + NVRM.cpp）：
#   nvrm_driver_off() = (-nvoff) || (/options 里 nullmoth-remove) || (nvrm_guard_starts() >= 2)
#   NVRM::start() 先查 nvrm_driver_off()，放行后立刻 nvrm_guard_count_start()（+1）。
#   所以预置 1 → 本次放行、计数变 2 → 下次开机被挡。

set -u
set -o pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
LABEL=com.g1.trial
STATE=${G1_STATE_DIR:-/var/tmp/g1-trial}
PANIC_DIR=${G1_PANIC_DIR:-/Library/Logs/DiagnosticReports}
GUARD=nullmoth-nv-starts
REMOVE=nullmoth-remove
WINDOW=${G1_WINDOW:-2h}
STAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$STATE" 2>/dev/null
REPORT="$STATE/report-$STAMP.txt"
: >"$REPORT" 2>/dev/null || { echo "无法写 $STATE"; exit 1; }
# 先落一行头：这样即使后面 sudo 卡住/失败/被 Ctrl-C，报告也不会是 0 字节。
printf '# G1 试跑报告 %s  动作=%s  主机=%s\n' \
  "$STAMP" "${*:-go}" "$(hostname 2>/dev/null)" >>"$REPORT" 2>/dev/null
STICK_RESULTS="$HERE/results"
mkdir -p "$STICK_RESULTS" 2>/dev/null
STICK_REPORT="$STICK_RESULTS/$(basename "$REPORT")"

say() { printf '\n== %s\n' "$*"; printf '\n== %s\n' "$*" >>"$REPORT" 2>/dev/null; }
out() { printf '%s\n' "$*";    printf '%s\n' "$*"    >>"$REPORT" 2>/dev/null; }
sync_report() {
  [ -d "$STICK_RESULTS" ] || return 0
  cp "$REPORT" "$STICK_REPORT" 2>/dev/null
}

die() { out "!! $*"; sync_report; exit "${2:-1}"; }

# --------------------------------------------------------------------------
# 权限：整体提到最前面，一次拿够，避免"跑到一半才问密码"
elevate() {
  [ "${G1_NO_ELEVATE:-0}" = 1 ] && return 0
  [ "$(id -u)" = 0 ] && return 0
  echo "需要管理员权限，正在重新以 sudo 启动（会提示输入开机密码）..."
  exec sudo -p '开机密码: ' bash "$0" "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

LOG_BIN=$(command -v log 2>/dev/null || echo /usr/bin/log)

nvram_get() {
  local dump
  dump=$(nvram -p 2>/dev/null) || dump=""
  if [ -z "$dump" ]; then dump=$(/usr/sbin/nvram -p 2>/dev/null); fi
  printf '%s\n' "$dump" | awk -v k="$1" '$1==k { $1=""; sub(/^[ \t]+/,""); print; exit }'
}
nvram_set() { nvram "$1" 2>/dev/null || /usr/sbin/nvram "$1" 2>/dev/null; }
nvram_del() { nvram -d "$1" 2>/dev/null || /usr/sbin/nvram -d "$1" 2>/dev/null; }

boot_epoch() {
  # 注意：kern.boottime 是 "{ sec = 1792883385, usec = 0 } ..."，
  # 用 ".*sec = " 做贪婪匹配会先撞上 "usec = " 而抓到 0 —— 必须带前导空格。
  sysctl -n kern.boottime 2>/dev/null | sed -n 's/.* sec = \([0-9][0-9]*\).*/\1/p'
}
# macOS: date -r <epoch>；GNU（仅本地测试用）: date -d @<epoch>
epoch_to_str() {
  date -r "$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null ||
    date -d "@$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
}
boot_start_str() {
  local e
  e=$(boot_epoch)
  [ -n "$e" ] || return 1
  epoch_to_str "$e"
}
uptime_short() {
  local e now
  e=$(boot_epoch); now=$(date +%s)
  [ -n "$e" ] || { echo "?"; return; }
  echo "$(( (now - e) / 60 )) 分钟"
}

# --------------------------------------------------------------------------
do_go() {
  say "受控试跑：让驱动带固件跑恰好一次"
  local cur
  cur=$(nvram_get "$GUARD")
  out "  试跑前状态："
  out "    $GUARD = ${cur:-（未设置）}"
  out "    $REMOVE  = $(nvram_get "$REMOVE")"

  say "写入开关"
  nvram_set "$GUARD=%01"
  local after
  after=$(nvram_get "$GUARD")
  case "$after" in
    *%01*|*01*) out "  [1/2] 守卫已预置为 1（只放行一次）：$after" ;;
    *)          out "  !! [1/2] 守卫写入失败（读到：${after:-空}）。中止，未解除闭嘴。"; sync_report; exit 3 ;;
  esac

  nvram_del "$REMOVE"
  if [ -n "$(nvram_get "$REMOVE")" ]; then
    out "  !! [2/2] $REMOVE 删不掉，驱动仍是关闭状态。中止。"
    out "     手动：sudo nvram -d $REMOVE"
    sync_report; exit 4
  fi
  out "  [2/2] 已解除闭嘴（$REMOVE 已删除）"

  date +%s >"$STATE/go-at" 2>/dev/null
  date '+%Y-%m-%d %H:%M:%S' >"$STATE/go-at-readable" 2>/dev/null

  say "下一步：重启这台机器"
  out "  重启后等 90 秒，然后在同一目录跑："
  out "    bash \"$0\" report"
  out ""
  out "  说明：这次开机驱动会启动一次，然后计数变 2 自锁。"
  out "        就算它 panic，下次开机也被挡住，不会反复重启。"
  out "  反悔：bash \"$0\" cancel"
  sync_report
  echo
  echo "报告已存: $REPORT"
}

# --------------------------------------------------------------------------
do_report() {
  say "取回试跑记录"
  local go_at="" cur_guard cur_remove bs
  [ -f "$STATE/go-at-readable" ] && go_at=$(cat "$STATE/go-at-readable" 2>/dev/null)
  cur_guard=$(nvram_get "$GUARD")
  cur_remove=$(nvram_get "$REMOVE")
  bs=$(boot_start_str)

  out "  上次执行 go : ${go_at:-（没跑过 go）}"
  out "  本次开机    : ${bs:-未知}（已运行 $(uptime_short)）"
  out "    $GUARD = ${cur_guard:-（未设置）}"
  out "    $REMOVE  = ${cur_remove:-（未设置）}"

  # 判定"这次到底跑没跑"
  local go_epoch="" be
  [ -f "$STATE/go-at" ] && go_epoch=$(tr -dc '0-9' <"$STATE/go-at" 2>/dev/null)
  be=$(boot_epoch)
  if [ -z "$go_at" ]; then
    out "  → 没跑过 go，下面看到的是历史日志，不代表本次实验。"
  elif [ -z "$go_epoch" ] || [ -z "$be" ]; then
    out "  → 时间戳对不上（取不到开机时间或标记损坏），按 A/B 两段的原始时间自行判断。"
  elif [ "$go_epoch" -lt "$be" ]; then
    out "  → 已重启过（开机时间晚于 go），下面的记录有效。"
  else
    out "  → 还没重启（开机时间早于 go），现在看到的仍是上一次的日志。"
  fi

  # A. 本次开机以来
  say "A. 本次开机以来的 NVRM 记录"
  if [ -n "$bs" ]; then
    "$LOG_BIN" show --start "$bs" --style compact 2>/dev/null \
      --predicate 'eventMessage CONTAINS[c] "NVRM" OR eventMessage CONTAINS[c] "NullMoth" OR eventMessage CONTAINS[c] "RmInit" OR eventMessage CONTAINS[c] "nvaccel" OR eventMessage CONTAINS[c] "boot guard"' \
      | tail -120 | cut -c1-240 | sed 's/^/  /'
  else
    out "  （取不到开机时间，跳过）"
  fi

  # B. 最近窗口（含上一次开机）
  say "B. 最近 $WINDOW 的全部 NVRM 记录（含上一次开机）"
  local wide
  wide="$STATE/nvrm-$STAMP.txt"
  "$LOG_BIN" show --last "$WINDOW" --style compact 2>/dev/null \
    --predicate 'eventMessage CONTAINS[c] "NVRM" OR eventMessage CONTAINS[c] "NullMoth" OR eventMessage CONTAINS[c] "RmInit" OR eventMessage CONTAINS[c] "nvaccel" OR eventMessage CONTAINS[c] "boot guard"' \
    >"$wide" 2>/dev/null
  local n
  n=$(wc -l <"$wide" 2>/dev/null | tr -d ' ')
  out "  共 ${n:-0} 行，完整内容：$wide"
  [ "${n:-0}" -gt 0 ] 2>/dev/null && tail -60 "$wide" | cut -c1-240 | sed 's/^/  /'
  [ -d "$STICK_RESULTS" ] && cp "$wide" "$STICK_RESULTS/" 2>/dev/null

  say "C. 关键标记"
  local k c
  for k in "probe 10de" "boot guard" "PASS 1 REACHED" "nv_get_firmware" \
           "vnode_open failed" "firmware loaded" "RmFetchGspRmImages" \
           "RmInitAdapter" "rm_init_adapter ->" "bus master" "headwatch" \
           "nvaccel" "FSP" "WPR" "panic("; do
    c=$(grep -c -F "$k" "$wide" 2>/dev/null)
    [ "${c:-0}" -gt 0 ] 2>/dev/null && out "  [$c] $k"
  done

  say "D. panic 记录"
  if ls "$PANIC_DIR"/*.panic >/dev/null 2>&1; then
    local p
    p=$(ls -t "$PANIC_DIR"/*.panic 2>/dev/null | head -1)
    out "  找到 panic 文件：$p"
    out "  前 40 行（调用栈在这里）："
    head -40 "$p" 2>/dev/null | cut -c1-240 | sed 's/^/  /'
    [ -d "$STICK_RESULTS" ] && cp "$p" "$STICK_RESULTS/" 2>/dev/null
  else
    out "  没有 panic 文件。"
  fi

  say "E. 驱动/设备现状"
  if kextstat 2>/dev/null | grep -qi nullmoth; then
    kextstat 2>/dev/null | grep -i nullmoth | sed 's/^/  /'
  else
    out "  kextstat 里没有 NullMoth 相关项。"
  fi
  ioreg -w0 -l -r -n "pci10de,25a9" -d 3 2>/dev/null | head -20 | cut -c1-200 | sed 's/^/  /'

  say "F. 结论"
  local verdict
  if grep -q "firmware loaded" "$wide" 2>/dev/null; then
    verdict=firmware
    out "  固件被读到了 —— 这是新边界。"
    if grep -q "RmInitAdapter failed\|rm_init_adapter -> FAILED" "$wide" 2>/dev/null; then
      out "  但 adapter 初始化失败 → 下一关是 GSP/FSP 启动序列。"
    else
      out "  且没看到 adapter 失败 → 可能比预期走得远，看 A 段最后几行。"
    fi
  elif grep -q "vnode_open failed" "$wide" 2>/dev/null; then
    verdict=no-fw
    out "  固件仍然没读到（vnode_open failed）→ 查 /Library/NullMoth 是否存在及权限。"
  elif [ "$(grep -c 'probe 10de' "$wide" 2>/dev/null)" = "0" ] 2>/dev/null; then
    verdict=no-probe
    out "  日志里没有 probe 行 → 驱动这次没启动（守卫挡着，或还没重启）。"
  else
    verdict=partial
    out "  有 probe 但没有固件相关行 → 看 B 段原文定位停在哪。"
  fi

  say "G. 下一步该做什么"
  case "$verdict" in
    firmware)
      out "  1) 再做一次同样的试跑，确认结果可重复：bash \"$0\"（然后重启、report）"
      out "  2) 重复稳定后，才轮到装 NVRMFB / NVAccel 并重建辅助集合（那是下一步，不是现在）"
      ;;
    no-probe)
      out "  驱动这次没起来，多半是守卫已经锁住。重新跑一次 go 再重启："
      out "    bash \"$0\""
      out "  每次开机守卫都会 +1，一次机会用完就自锁 —— 所以每一轮实验都要先 go。"
      ;;
    no-fw)
      out "  固件文件的问题。先确认文件在不在、对不对："
      out "    ls -l /Library/NullMoth/nvfw/nvidia/610.57.04/"
      out "    shasum -a 1 /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin"
      out "  正确值是 f11971026ccd86a7ea09ba525548c2e0615565ce（84,310,168 字节）。"
      ;;
    *)
      out "  把报告和 B 段原文发回来，按原文最后几行定位停在哪一步。"
      ;;
  esac
  out ""
  out "  反悔/收工：bash \"$0\" cancel   （驱动关回去，下次开机不启动）"

  out ""
  out "  报告: $REPORT"
  sync_report
  echo
  echo "把这两个文件发回："
  echo "  $REPORT"
  echo "  $wide"
}

# --------------------------------------------------------------------------
do_status() {
  say "当前状态"
  out "  $GUARD = $(nvram_get "$GUARD")   （%02=已自锁  %01=还允许一次  空=未设置）"
  out "  $REMOVE  = $(nvram_get "$REMOVE")   （有值=驱动关闭）"
  out "  本次开机: $(boot_start_str 2>/dev/null)（已运行 $(uptime_short)）"
  [ -f "$STATE/go-at-readable" ] \
    && out "  上次 go : $(cat "$STATE/go-at-readable" 2>/dev/null)" \
    || out "  上次 go : 没跑过"
  kextstat 2>/dev/null | grep -i nullmoth | sed 's/^/  驱动: /' || out "  驱动: 未加载"
  out "  报告: $REPORT"
  sync_report
  echo
  echo "报告已存: $REPORT"
}

do_cancel() {
  say "反悔：把驱动关回去"
  nvram_set "$REMOVE=1"
  out "  $REMOVE = $(nvram_get "$REMOVE")"
  nvram_del "$GUARD"
  out "  $GUARD 已清（=$(nvram_get "$GUARD")）"
  rm -f "$STATE/go-at" "$STATE/go-at-readable" 2>/dev/null
  out "  下次开机驱动不会启动。"
  sync_report
  echo
  echo "报告已存: $REPORT"
}

# --------------------------------------------------------------------------
main() {
  case "${1:-go}" in
    go|install|"") elevate "$@"; do_go ;;
    report)        elevate "$@"; do_report ;;
    status)        do_status ;;          # 只读，不需要 root
    cancel)        elevate "$@"; do_cancel ;;
    -h|--help|help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *) echo "用法: bash $0 [go|report|status|cancel]"; exit 2 ;;
  esac
}
main "$@"
