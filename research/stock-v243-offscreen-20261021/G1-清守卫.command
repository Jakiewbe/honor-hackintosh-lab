#!/bin/bash
# G1-清守卫.command — 清掉 NVRM 的开机守卫，以及上一轮实验留下的残留。不重启、不动 kext。
#
# 为什么需要它：
#   kexts/NVRM/nvrm_off.h 里，NVRM::probe() 第一行就是
#       if (nvrm_driver_off()) return NULL;
#   nvrm_driver_off() = boot-args 里有 -nvoff、或 NVRAM 有 nullmoth-remove、
#                       或 nullmoth-nv-starts >= 2（NVRM_GUARD_LIMIT）
#   计数只在 NVRM::start 里 +1，只有 NVRMFB 点亮 head 时才清。
#   本机没装 NVRMFB → 计数只涨不落 → 两次开机后驱动彻底不 probe，日志一行都没有。
#
# 用法：
#   bash ./G1-清守卫.command            显示 + 清守卫，写报告（默认，最常用）
#   bash ./G1-清守卫.command show        只看，不改
#   bash ./G1-清守卫.command all         守卫 + 残留 daemon + /var/tmp/g1-auto + 半成品集合
#   bash ./G1-清守卫.command bootargs    把 -nvoff 从 boot-args 里摘掉（先备份原文）
#   bash ./G1-清守卫.command verify      只做校验：守卫是不是真的清了
#
# 完全不重启。报告写到 results/guard-<时间>.txt（U 盘只读时退到 /var/tmp）。

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
LABEL_BASE=com.g1.auto
GUARD=nullmoth-nv-starts
REMOVE=nullmoth-remove
OKVAR=nullmoth-nv-ok
LIMIT=2

STAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HERE/results" 2>/dev/null
REPORT="$HERE/results/guard-$STAMP.txt"
if ! : >"$REPORT" 2>/dev/null; then
  REPORT="/var/tmp/g1-guard-$STAMP.txt"
  : >"$REPORT" 2>/dev/null
fi

say() { printf '\n== %s\n' "$*"; }
out() { printf '%s\n' "$*"; }
tee_in() { # 一边显示一边进报告
  tee -a "$REPORT"
}

need_sudo() {
  if sudo -n true 2>/dev/null; then return 0; fi
  echo "需要 sudo 权限（改 NVRAM），先输密码："
  sudo -v || { echo "拿不到 sudo，退出"; exit 2; }
}

# nvram -p 把二进制变量打印成 %XX 序列。驱动只读第一个字节
#   (nvrm_off.h: unsigned n = *(const unsigned char *)d->getBytesNoCopy())
# 所以这里吐第一个字节的十进制；非 %XX 形式就原样返回。
decode_hexnum() {
  local v="$1" first
  first=$(printf '%s' "$v" | sed -n 's/^%\([0-9A-Fa-f]\{2\}\).*/\1/p')
  if [ -n "$first" ]; then
    printf '%d\n' "0x$first"
  else
    printf '%s\n' "$v"
  fi
}

nvram_dump() { # 优先无 sudo 读；读不到再试 sudo -n（读不需要密码的场景）
  local d
  d=$(nvram -p 2>/dev/null)
  if [ -z "$d" ] && sudo -n true 2>/dev/null; then d=$(sudo -n nvram -p 2>/dev/null); fi
  printf '%s\n' "$d"
}

get_var() { # $1 = 变量名，输出原值（没有则空）
  nvram_dump | awk -v k="$1" '$1==k { $1=""; sub(/^[ \t]+/,""); print; exit }'
}

show_state() { # 打印当前状态（不改）
  say "NVRAM 里的 nullmoth-* 变量"
  local all
  all=$(nvram_dump | grep -i nullmoth || true)
  if [ -z "$all" ]; then
    out "  (没有 nullmoth-* 变量)"
  else
    printf '%s\n' "$all" | sed 's/^/  /'
  fi

  local g r o gd
  g=$(get_var "$GUARD"); r=$(get_var "$REMOVE"); o=$(get_var "$OKVAR")
  say "判读"
  if [ -z "$g" ]; then
    out "  $GUARD : 不存在 → 守卫计数 0（这一项不会挡驱动）"
  else
    gd=$(decode_hexnum "$g")
    out "  $GUARD : $g （十进制 $gd）"
    if [ "$gd" != "$g" ] && [ "$gd" -ge "$LIMIT" ] 2>/dev/null; then
      out "  → 已达到/超过上限 $LIMIT，NVRM::probe() 现在会直接 return NULL（这就是"装了不 attach、零日志"的原因）"
    else
      out "  → 还没到上限 $LIMIT"
    fi
  fi
  if [ -n "$r" ]; then
    out "  $REMOVE : 存在 → 等同于 -nvoff，驱动会整个闭嘴（要清）"
  else
    out "  $REMOVE : 不存在（正常）"
  fi
  [ -n "$o" ] && out "  $OKVAR : 存在（安装程序留下的"曾经成功"标记，不是开关，不用管）"

  say "boot-args"
  local ba
  ba=$(nvram boot-args 2>/dev/null || true)
  if printf '%s' "$ba" | grep -q -- '-nvoff'; then
    out "  $ba"
    out "  → 里面有 -nvoff，驱动一定不启动（要清）"
  else
    out "  ${ba:-(空)}"
    out "  → 没有 -nvoff（正常）"
  fi

  say "NVRMFB（清守卫的人）"
  if [ -d /Library/Extensions/NVRMFB.kext ]; then
    out "  已安装 /Library/Extensions/NVRMFB.kext"
    out "  → 显示路径起来时会自动清守卫；但显示路径没起来时，计数照样每开机 +1"
  else
    out "  未安装"
    out "  → 没人清计数：每两次开机要再清一次，否则驱动又会闭嘴"
  fi

  say "上一轮实验的残留"
  local f n=0
  for f in /Library/LaunchDaemons/$LABEL_BASE.plist /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    out "  daemon: $(basename "$f")"; n=$((n+1))
  done
  [ "$n" = 0 ] && out "  daemon: 没有"
  if [ -f "/Library/KernelCollections/AuxiliaryKernelExtensions.kc.g1-new" ]; then
    out "  半成品集合: /Library/KernelCollections/AuxiliaryKernelExtensions.kc.g1-new"
  else
    out "  半成品集合: 没有"
  fi
  n=$(ls -1 /var/tmp/g1-auto 2>/dev/null | wc -l | tr -d ' ')
  out "  /var/tmp/g1-auto: ${n} 个 run 目录"
}

clear_guard() {
  need_sudo
  local before after rc=0
  before=$(get_var "$GUARD")
  say "清守卫"
  out "  清理前: $GUARD = ${before:-（不存在）}"
  sudo nvram -d "$GUARD" 2>/dev/null
  sudo nvram -d "$REMOVE" 2>/dev/null
  after=$(get_var "$GUARD")
  out "  清理后: $GUARD = ${after:-（不存在）}"
  if [ -n "$after" ]; then
    out "  !! 没清掉（NVRAM 不可写？），手动试: sudo nvram -d $GUARD"
    rc=1
  else
    out "  已清掉"
  fi
  if [ -n "$(get_var "$REMOVE")" ]; then
    out "  !! $REMOVE 还在，手动试: sudo nvram -d $REMOVE"; rc=1
  fi
  return $rc
}

clear_daemons() {
  need_sudo
  say "移除自动实验 daemon"
  local f b found=0
  for f in /Library/LaunchDaemons/$LABEL_BASE.plist /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    b=$(basename "$f" .plist)
    sudo launchctl bootout "system/$b" 2>/dev/null
    sudo rm -f "$f"
    out "  已移除 $b"
    found=1
  done
  [ "$found" = 0 ] && out "  没有 daemon 需要移除"
}

clear_tmp() {
  say "清临时状态 / 半成品集合"
  if [ -d /var/tmp/g1-auto ]; then
    sudo rm -rf /var/tmp/g1-auto 2>/dev/null
    out "  已删 /var/tmp/g1-auto（各 run 的 state）"
  else
    out "  /var/tmp/g1-auto 不存在"
  fi
  if [ -f "/Library/KernelCollections/AuxiliaryKernelExtensions.kc.g1-new" ]; then
    sudo rm -f "/Library/KernelCollections/AuxiliaryKernelExtensions.kc.g1-new" 2>/dev/null
    out "  已删半成品集合 .../AuxiliaryKernelExtensions.kc.g1-new"
  else
    out "  没有半成品集合"
  fi
}

fix_bootargs() {
  need_sudo
  local ba new
  ba=$(nvram boot-args 2>/dev/null || true)
  say "去掉 boot-args 里的 -nvoff"
  if ! printf '%s' "$ba" | grep -q -- '-nvoff'; then
    out "  boot-args 里没有 -nvoff，什么都不做"
    return 0
  fi
  out "  原文（已记进报告，要还原就用这一段）:"
  out "    $ba"
  new=$(printf '%s' "$ba" | tr ' ' '\n' | grep -v '^-nvoff$' | paste -sd' ' -)
  sudo nvram boot-args="$new" 2>/dev/null
  out "  新值: $new"
  if nvram boot-args 2>/dev/null | grep -q -- '-nvoff'; then
    out "  !! 没改掉，手动试: sudo nvram boot-args=\"$new\""; return 1
  fi
  out "  已去掉"
}

main_default() {
  show_state
  clear_guard || true
  say "结论"
  if [ -z "$(get_var "$GUARD")" ] && [ -z "$(get_var "$REMOVE")" ] \
     && ! nvram boot-args 2>/dev/null | grep -q -- '-nvoff'; then
    out "  守卫已清空：下次开机 NVRM::probe() 会正常执行，日志里应出现"
    out "    NVRM-xnu: probe 10de:25a9 class 03.02 subsystem ..."
    out "  以及随后的 nv_get_firmware（固件到 2026-10-24 07:47 才装上，还没被读过一次）。"
    out "  现在可以重启，或跑 bash ./G1-自动实验.command collect 留一份基线。"
  else
    out "  还有东西挡着驱动，见上面带 !! 的项。"
  fi
  out "  报告: $REPORT"
}

case "${1:-clear}" in
  show)     show_state; out "  报告: $REPORT" ;;
  clear|"") main_default ;;
  all)
    show_state
    clear_guard || true
    clear_daemons
    clear_tmp
    out "  报告: $REPORT" ;;
  bootargs) fix_bootargs; out "  报告: $REPORT" ;;
  verify)
    show_state
    if [ -z "$(get_var "$GUARD")" ]; then out "  VERDICT: GUARD_CLEAR"; exit 0; fi
    out "  VERDICT: GUARD_STILL_SET"; exit 1 ;;
  *) echo "用法: bash $0 [clear|show|all|bootargs|verify]"; exit 2 ;;
esac
