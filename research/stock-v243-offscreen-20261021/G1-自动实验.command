#!/bin/bash
# G1-自动实验.command — 一次启动，自动跑完「改一步 → 重启 → 采集 → 判定 → 下一步」的循环。
#
# 你只需要跑一次 `bash ./G1-自动实验.command`，然后走开。它会：
#   0) 先采集当前状态（签名 / personality / 集合内容 / kextstat / ioreg / 日志关键行）
#   1) 应用第 1 步改动（默认：ad-hoc 签名），装一个开机自启的 LaunchDaemon，重启
#   2) 重启后由 daemon 接管：等桌面起来 → 采集 → 判定有没有 attach
#        成功  → 写报告、删 daemon、桌面留一份，**不再重启**
#        失败  → 应用下一步改动 → 再重启
#   3) 步骤跑完或成功即停。最多 3 个改动周期，绝不会无限重启。
#
# 用法:
#   bash ./G1-自动实验.command            开始（会重启，最多 3 次）
#   bash ./G1-自动实验.command status     看进度/最新报告（不重启）
#   bash ./G1-自动实验.command stop       立刻停止自动循环（不重启）
#   bash ./G1-自动实验.command collect     只采集一次，什么都不改、不重启
#
# 每一步都写进 results/auto-<时间>/，另存 /var/tmp/g1-auto/（U 盘没挂上时用它兜底）。
# 回退: bash ./G1-自动实验.command stop; sudo rm -rf /var/tmp/g1-auto

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
EXT=/Library/Extensions
KC=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
LABEL=com.g1.auto
DAEMON=/Library/LaunchDaemons/$LABEL.plist
STATE=/var/tmp/g1-auto
RUNNER=$STATE/self.sh
STEPS=$STATE/steps
STATE_FILE=$STATE/state
MAXCYC=3

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }
have_sudo() { sudo -n true 2>/dev/null; }

# --------------------------------------------------------------------------
# 采集（root 或普通用户都能跑；root 能读集合）
# --------------------------------------------------------------------------
collect() { # $1 = 输出文件
  local out="$1"
  : >"$out"
  {
    echo "== collected"; date
    echo "== host"; uname -a 2>&1
    echo "== 开机时刻 / 运行时长"; sysctl -n kern.boottime 2>&1; uptime
    echo "== kextstat NVRM"; kextstat 2>/dev/null | grep -i nvrm
    echo "== ioreg NVRM 节点"; ioreg -l -w0 -p IOService 2>/dev/null | grep -c 'class NVRM'
    echo "== ioreg NVRM 关键属性"
    ioreg -r -c NVRM -l -w0 2>/dev/null | grep -E 'nvrm-bars|IOProbeScore|IOClass|name' | head -8
    echo "== GPU PCI 是否在"
    ioreg -l -w0 -p IOService 2>/dev/null | grep -o 'pci10de,[0-9a-f]*' | sort -u | head -3
    echo "== 安装的 bundle"
    if [ -d "$EXT/NVRM.kext" ]; then
      ls -l "$EXT/NVRM.kext/Contents/MacOS/NVRM" 2>&1
      shasum -a 256 "$EXT/NVRM.kext/Contents/MacOS/NVRM" 2>&1
    else
      echo '(NVRM.kext 不在)'
    fi
    echo "== 签名状态（signed @none = 未签名）"
    codesign -dv --verbose=4 "$EXT/NVRM.kext" 2>&1 | head -10 \
      || echo '(codesign 读不出：bundle 没有签名)'
    codesign --verify --deep --strict "$EXT/NVRM.kext" 2>&1 | head -3
    echo "== personality（IOKitPersonalities）"
    /usr/libexec/PlistBuddy -c 'Print :IOKitPersonalities' \
      "$EXT/NVRM.kext/Contents/Info.plist" 2>&1 | head -40
    echo "== 在用辅助集合里的 NVRM"
    kmutil inspect -a x86_64 -A "$KC" 2>&1 | grep -i -A2 nullmoth || echo '(读不到)'
    echo "== 集合 sha256"; shasum -a 256 "$KC" 2>&1
    echo "== boot-args"; nvram boot-args 2>&1
    echo "== 关键日志（本次开机以来）"
    log show --last 8m --style compact --predicate \
      'eventMessage CONTAINS "NVRM" OR eventMessage CONTAINS "NullMoth" OR eventMessage CONTAINS "restricted lookup table" OR eventMessage CONTAINS "canLoadKernelExtension"' \
      2>/dev/null | tail -60
  } >>"$out" 2>&1
}

verdict() { # $1 = 采集文件；0 = attach 成功
  local f="$1" n
  n=$(grep -A1 '== ioreg NVRM 节点' "$f" | tail -1)
  case "$n" in
    ''|0) return 1 ;;
    *)    return 0 ;;
  esac
}

# --------------------------------------------------------------------------
# 改动步骤
# --------------------------------------------------------------------------
step_sign() {
  say "步骤: ad-hoc 签名 NVRM.kext"
  local bk="$OUT/cyc$CYCLE/NVRM.kext.before-sign"
  mkdir -p "$bk" 2>/dev/null
  rm -rf "$bk" 2>/dev/null
  cp -R "$EXT/NVRM.kext" "$bk" 2>/dev/null && echo "  已备份原 bundle: $bk"
  codesign --force --deep --sign - "$EXT/NVRM.kext" || { bad "codesign 失败"; return 1; }
  codesign -dv --verbose=4 "$EXT/NVRM.kext" 2>&1 | sed 's/^/   /'
  codesign --verify --deep --strict "$EXT/NVRM.kext" 2>&1 | sed 's/^/   verify: /'
  chown -R root:wheel "$EXT/NVRM.kext"; chmod -R go-w "$EXT/NVRM.kext"
}

step_rebuild() {
  say "步骤: 重建辅助内核集合（kmutil create -n aux）"
  mkdir -p "$OUT/cyc$CYCLE" 2>/dev/null
  local K=/System/Library/Kernels/kernel
  local KB=/System/Library/KernelCollections/BootKernelExtensions.kc
  local KS=/System/Library/KernelCollections/SystemKernelExtensions.kc
  local NEW=$KC.g1-new rc
  local args=(--volume-root / --allow-missing-kdk -B "$KB" -S "$KS")
  [ -f "$K" ] && args+=(--kernel "$K")
  kmutil create -n aux "${args[@]}" --repository "$EXT" -A "$NEW" -z \
    --no-variant-extension >"$OUT/cyc$CYCLE/rebuild.log" 2>&1
  rc=$?
  cat "$OUT/cyc$CYCLE/rebuild.log" | sed 's/^/   /' | tail -6
  if [ "$rc" != 0 ] || [ ! -f "$NEW" ]; then
    bad "重建失败 rc=$rc"
    log show --last 3m --predicate 'process == "kmutil"' --style compact 2>/dev/null \
      | tail -20 | sed 's/^/   | /'
    return 1
  fi
  cp -p "$KC" "$OUT/cyc$CYCLE/AuxiliaryKernelExtensions.kc.before" 2>/dev/null
  chmod 0644 "$NEW"; chown root:wheel "$NEW"
  mv -f "$NEW" "$KC" || { bad "替换集合失败"; return 1; }
  chmod 0644 "$KC"; chown root:wheel "$KC"
  echo "  集合 sha256: $(shasum -a 256 "$KC" | cut -d' ' -f1)"
  kmutil inspect -a x86_64 -A "$KC" 2>&1 | grep -i nullmoth | sed 's/^/   集合里: /'
}

step_reinstall() {
  say "步骤: 从 U 盘重新安装 NVRM.kext 再重建集合"
  local src='' h
  h=$(get_state HERE); [ -z "$h" ] && h="$HERE"
  for d in "$h/NVRM.kext" "$h/候选/NVRM.kext" "$h/build/NVRM.kext" \
           "$h/../NVRM.kext"; do
    [ -d "$d" ] && { src="$d"; break; }
  done
  if [ -z "$src" ]; then
    bad "U 盘上找不到 NVRM.kext（放一份到脚本旁边再跑）"
    return 1
  fi
  rm -rf "$EXT/NVRM.kext" && cp -R "$src" "$EXT/NVRM.kext" \
    || { bad "复制失败"; return 1; }
  chown -R root:wheel "$EXT/NVRM.kext"; chmod -R 755 "$EXT/NVRM.kext"
  chmod 644 "$EXT/NVRM.kext/Contents/Info.plist"; chmod -R go-w "$EXT/NVRM.kext"
  echo "  已安装: $src"
  step_rebuild
}

apply_step() { # $1 = 步骤名
  case "$1" in
    sign)      step_sign ;;
    rebuild)   step_rebuild ;;
    reinstall) step_reinstall ;;
    "")        return 0 ;;
    *)         bad "未知步骤 $1"; return 1 ;;
  esac
}

# --------------------------------------------------------------------------
# 安装/卸载开机自启 daemon
# --------------------------------------------------------------------------
install_daemon() {
  mkdir -p "$STATE"
  cp -f "$0" "$RUNNER"
  chmod 0755 "$RUNNER"
  local tmp=$STATE/$LABEL.plist.tmp
  cat >"$tmp" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$RUNNER</string><string>--daemon-step</string></array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$STATE/daemon.out</string>
  <key>StandardErrorPath</key><string>$STATE/daemon.err</string>
</dict>
</plist>
PLIST
  sudo install -m 0644 -o root -g wheel "$tmp" "$DAEMON" \
    || { bad "写 $DAEMON 失败"; return 1; }
  echo "  已写 $DAEMON"
  sudo launchctl bootout system/$LABEL 2>/dev/null
  sudo launchctl bootstrap system "$DAEMON" 2>/dev/null
}

remove_daemon() {
  sudo launchctl bootout system/$LABEL 2>/dev/null
  sudo rm -f "$DAEMON"
}

# --------------------------------------------------------------------------
# 状态
# --------------------------------------------------------------------------
set_state() { # key value
  touch "$STATE_FILE"
  grep -v "^$1=" "$STATE_FILE" >"$STATE_FILE.tmp" 2>/dev/null
  echo "$1=$2" >>"$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"
}
get_state() { [ -f "$STATE_FILE" ] && sed -n "s/^$1=//p" "$STATE_FILE" | tail -1; }

next_step() { # 打印下一条步骤并消费
  [ -f "$STEPS" ] || return 1
  local s
  s=$(head -1 "$STEPS")
  [ -z "$s" ] && return 1
  tail -n +2 "$STEPS" >"$STEPS.tmp" 2>/dev/null && mv "$STEPS.tmp" "$STEPS"
  echo "$s"
}

# --------------------------------------------------------------------------
# daemon 步骤：重启后由 launchd 以 root 调用
# --------------------------------------------------------------------------
daemon_step() {
  # 防止同一次开机里被执行两次（每个 cycle 一个标记）
  CYCLE=$(( $(get_state CYCLE) + 1 ))
  if [ -f "$STATE/RUNNING-$CYCLE" ]; then exit 0; fi
  date >"$STATE/RUNNING-$CYCLE"
  set_state CYCLE "$CYCLE"
  OUT=$(get_state OUT)
  [ -z "$OUT" ] && OUT=$STATE/out
  mkdir -p "$OUT/cyc$CYCLE"
  LOG=$OUT/cyc$CYCLE/after.txt

  # 等桌面起来（匹配发生在 IOWindowServer/显示服务起来之后）
  local i=0
  while [ $i -lt 90 ]; do pgrep -x WindowServer >/dev/null 2>&1 && break; sleep 2; i=$((i+1)); done
  sleep 20

  say "cycle $CYCLE 采集" | tee -a "$LOG"
  collect "$LOG"
  cp -f "$LOG" "$STATE/last.txt" 2>/dev/null

  if verdict "$LOG"; then
    set_state RESULT PASS
    say "cycle $CYCLE: attach 成功 —— 停止自动循环" | tee -a "$LOG"
    finish
    return 0
  fi

  say "cycle $CYCLE: 仍未 attach（节点数 $(grep -A1 '== ioreg NVRM 节点' "$LOG" | tail -1)）" | tee -a "$LOG"
  local s
  s=$(next_step)
  if [ -z "$s" ]; then
    set_state RESULT EXHAUSTED
    say "所有步骤跑完仍没 attach —— 停止自动循环，报告在 $OUT" | tee -a "$LOG"
    finish
    return 0
  fi
  set_state STEP "$s"
  say "cycle $CYCLE: 下一步 = $s" | tee -a "$LOG"
  apply_step "$s" >>"$LOG" 2>&1
  sync
  sleep 3
  /sbin/shutdown -r now
}

finish() {
  rm -f "$DAEMON"
  ( launchctl bootout system/$LABEL >/dev/null 2>&1 & ) 2>/dev/null
  # 给桌面用户留一份
  local u d
  u=$(stat -f%Su /dev/console 2>/dev/null)
  if [ -n "$u" ] && [ "$u" != root ] && [ "$u" != loginwindow ]; then
    d=$(eval echo "~$u")/Desktop
    mkdir -p "$d" 2>/dev/null
    cat "$OUT"/cyc*/after.txt >"$d/g1-auto-report.txt" 2>/dev/null
    chown "$u" "$d/g1-auto-report.txt" 2>/dev/null
    sudo -u "$u" osascript -e 'display notification "自动实验结束，报告在桌面" with title "G1"' 2>/dev/null
  fi
  echo "RESULT=$(get_state RESULT)" >"$STATE/DONE"
}

# --------------------------------------------------------------------------
# 前置检查 / 启动
# --------------------------------------------------------------------------
preflight() {
  [ "$(uname -s)" = Darwin ] || { echo "只能在 macOS 上跑"; exit 2; }
  [ -d "$EXT/NVRM.kext" ] || { bad "$EXT/NVRM.kext 不存在，先装候选"; exit 2; }
  [ -d /Library/Developer/KDKs ] || { bad "没有 KDK，集合无法重建"; exit 2; }
  sudo -n true 2>/dev/null || { echo "需要 sudo 权限，先输密码:"; sudo -v || exit 2; }
}

cmd_run() {
  preflight
  local stamp OUT0
  stamp=$(date +%Y%m%d-%H%M%S)
  rm -rf "$STATE"; mkdir -p "$STATE"
  OUT0="$HERE/results/auto-$stamp"
  mkdir -p "$OUT0/cyc0" 2>/dev/null || OUT0="$STATE/out-$stamp"
  mkdir -p "$OUT0/cyc0"
  OUT="$OUT0"
  set_state OUT "$OUT0"
  set_state HERE "$HERE"
  set_state CYCLE 0
  set_state STARTED "$stamp"

  # 步骤队列（改这里就能换实验顺序；每步之后都会重启并采集）
  printf 'sign\nrebuild\nreinstall\nrebuild\n' >"$STEPS"
  # 最多跑 MAXCYC 个周期
  head -n "$MAXCYC" "$STEPS" >"$STEPS.t" && mv "$STEPS.t" "$STEPS"

  say "cycle 0 采集（改动前基线）"
  collect "$OUT/cyc0/before.txt"
  local n
  n=$(grep -A1 '== ioreg NVRM 节点' "$OUT/cyc0/before.txt" | tail -1)
  echo "  ioreg NVRM 节点数: $n"
  echo "  报告目录: $OUT"

  if verdict "$OUT/cyc0/before.txt"; then
    say "现在就已经 attach 了，不用改任何东西"
    cp -f "$OUT/cyc0/before.txt" "$HOME/Desktop/g1-auto-report.txt" 2>/dev/null
    exit 0
  fi

  local s
  s=$(next_step)
  say "cycle 0: 应用第一步 = $s"
  apply_step "$s" 2>&1 | tee "$OUT/cyc0/step.txt"
  install_daemon
  sync
  say "已装开机自启 daemon（$LABEL），即将重启"
  echo "  重启回来后不需要你做任何事；大约 1 分钟后开始采集。"
  echo "  最多 3 个周期。随时可用: bash ./G1-自动实验.command stop"
  sleep 5
  sudo /sbin/shutdown -r now
}

cmd_collect() {
  local out
  out="$HERE/results/collect-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$HERE/results" 2>/dev/null || out="$STATE/collect-$(date +%Y%m%d-%H%M%S).txt"
  collect "$out"
  verdict "$out" && echo "verdict: ATTACHED" || echo "verdict: NOT_ATTACHED"
  echo "报告: $out"
}

cmd_status() {
  echo "== 自动实验状态"
  if [ -f "$STATE_FILE" ]; then sed 's/^/   /' "$STATE_FILE"; else echo "   (没在跑)"; fi
  if [ -f "$DAEMON" ]; then echo "   daemon 已安装: $DAEMON"; else echo "   daemon 未安装"; fi
  if [ -f "$STATE/last.txt" ]; then
    echo "== 最近一次采集的关键行"
    grep -A1 -E '== ioreg NVRM 节点|== kextstat NVRM|== 签名状态' "$STATE/last.txt" | sed 's/^/   /'
  fi
  local r
  r=$(ls -dt "$HERE"/results/auto-* 2>/dev/null | head -1)
  [ -n "$r" ] && { echo "== 报告目录: $r"; ls -1 "$r"; }
}

cmd_stop() {
  remove_daemon
  echo "daemon 已移除，自动循环不会再重启。"
  echo "备份的 bundle 在 results/auto-*/cyc*/NVRM.kext.before-sign"
  echo "彻底清掉状态: sudo rm -rf $STATE"
}

case "${1:-run}" in
  --daemon-step) daemon_step ;;
  run|"")        cmd_run ;;
  collect)       cmd_collect ;;
  status)        cmd_status ;;
  stop)          cmd_stop ;;
  *)             echo "用法: bash $0 [run|collect|status|stop]"; exit 2 ;;
esac
