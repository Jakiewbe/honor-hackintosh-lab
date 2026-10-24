#!/bin/bash
# G1-自动实验.command v3 — 一次启动，自动跑完「改一步 → 重启 → 采集 → 判定 → 下一步」。
#
#   bash ./G1-自动实验.command           开始（会重启，最多 4 次）
#   bash ./G1-自动实验.command collect    只采集一次，什么都不改、不重启   <-- 先跑这个
#   bash ./G1-自动实验.command status     看进度/最新结论（不重启）
#   bash ./G1-自动实验.command stop       立刻停掉所有自动循环（不重启）
#   bash ./G1-自动实验.command report     把最新报告打到屏幕上
#
# v3 相比 v2 修掉的问题：
#   1) 修 `CYCLE: unbound variable`（v2 的签名步骤根本没执行过，等于白重启一次）
#   2) 步骤失败 → 立刻停（STEP_FAILED），不再带着坏状态继续重启
#   3) 每次实验用独立的 run id / state / LaunchDaemon 标签，跑两次不会互相踩
#   4) 已经有一个自动循环在跑时拒绝启动（除非 --force）
#   5) 采集新增：加载来源（KC 还是 direct load）、内核启动期日志、设备节点父子链
#   6) 采集用 `ioreg ... 'class NVRM,'` 数节点，不再被 NVRMUserClient 干扰
#
# 回退: bash ./G1-自动实验.command stop
#       签名前的 bundle 备份在 results/auto-*/cyc*/NVRM.kext.before-sign

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
EXT=/Library/Extensions
KC=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
LABEL_BASE=com.g1.auto
MAXCYC=4

have_sudo() { sudo -n true 2>/dev/null; }

# --------------------------------------------------------------------------
# 每个 run 的路径（run id 由参数或时间戳决定）
# --------------------------------------------------------------------------
setup_run() {
  RUN="${1:-$(date +%Y%m%d-%H%M%S)}"
  STATE=/var/tmp/g1-auto/$RUN
  STATE_FILE=$STATE/state
  STEPS=$STATE/steps
  RUNNER=$STATE/self.sh
  LABEL=$LABEL_BASE.$RUN
  DAEMON=/Library/LaunchDaemons/$LABEL.plist
  mkdir -p "$STATE" 2>/dev/null
}

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }

# --------------------------------------------------------------------------
# 状态
# --------------------------------------------------------------------------
set_state() {
  touch "$STATE_FILE" 2>/dev/null
  grep -v "^$1=" "$STATE_FILE" >"$STATE_FILE.tmp" 2>/dev/null
  echo "$1=$2" >>"$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null
}
get_state() { [ -f "$STATE_FILE" ] && sed -n "s/^$1=//p" "$STATE_FILE" 2>/dev/null | tail -1; }

next_step() {
  [ -f "$STEPS" ] || return 1
  local s
  s=$(head -1 "$STEPS" 2>/dev/null)
  [ -z "$s" ] && return 1
  tail -n +2 "$STEPS" >"$STEPS.tmp" 2>/dev/null && mv "$STEPS.tmp" "$STEPS"
  echo "$s"
}

# --------------------------------------------------------------------------
# 采集（不改变任何东西）
# --------------------------------------------------------------------------
collect() { # $1 = 输出文件
  local out="$1"
  : >"$out"
  {
    echo "== collected"; date
    echo "== host"; uname -a 2>&1
    echo "== 开机时刻 / 运行时长"; sysctl -n kern.boottime 2>&1; uptime
    echo "== kextstat NVRM"
    kextstat 2>/dev/null | grep -i nvrm || echo '(NVRM 未加载)'
    echo "== ioreg NVRM 节点（class NVRM, 计数）"
    ioreg -w0 -l -p IOService 2>/dev/null | grep -c 'class NVRM,'
    echo "== ioreg NVRM 关键属性"
    ioreg -r -w0 -l -c NVRM 2>/dev/null | grep -E 'nvrm-bars|IOProbeScore|"IOClass"|IOProviderClass' | head -8
    echo "== GPU PCI 设备节点（含父子链，看 NVRM 是不是它的子节点）"
    ioreg -w0 -l -r -n pci10de,25a9 -d 3 2>&1 | head -40
    echo "== 加载来源（kmutil inspect：我们这份是从 KC 还是 direct load 来的）"
    kmutil inspect 2>/dev/null | grep -i -B3 nullmoth | head -20 || echo '(读不到 kmutil inspect)'
    echo "== 安装的 bundle"
    if [ -d "$EXT/NVRM.kext" ]; then
      ls -l "$EXT/NVRM.kext/Contents/MacOS/NVRM" 2>&1
      shasum -a 256 "$EXT/NVRM.kext/Contents/MacOS/NVRM" 2>&1
    else
      echo '(NVRM.kext 不在)'
    fi
    echo "== 签名状态（signed @none = 未签名）"
    codesign -dv --verbose=4 "$EXT/NVRM.kext" 2>&1 | head -8
    codesign --verify --deep --strict "$EXT/NVRM.kext" 2>&1 | head -3
    echo "== personality（IOKitPersonalities）"
    /usr/libexec/PlistBuddy -c 'Print :IOKitPersonalities' \
      "$EXT/NVRM.kext/Contents/Info.plist" 2>&1 | head -40
    echo "== 在用辅助集合里的 NVRM"
    kmutil inspect -a x86_64 -A "$KC" 2>&1 | grep -i nullmoth | head -5 || echo '(集合里没有)'
    echo "== 集合 sha256"; shasum -a 256 "$KC" 2>&1
    echo "== 我们的开机 daemon"
    ls -1 /Library/LaunchDaemons 2>/dev/null | grep -i g1auto || echo '(没有)'
    echo "== boot-args"; nvram boot-args 2>&1
    echo "== NVRAM 里的 nullmoth-*（驱动开机守卫：nullmoth-nv-starts >= 2 会让 probe 直接返回 NULL）"
    (nvram -p 2>/dev/null || sudo -n nvram -p 2>/dev/null) | grep -i nullmoth || echo '(没有 nullmoth-* 变量)'
    echo "== 内核启动期日志（NVRM / 匹配 / 签名相关，本次开机以来）"
    log show --last 20m --style compact --predicate 'process == "kernel"' 2>/dev/null \
      | grep -i -E 'nvrm|nullmoth|kext|match' | head -40 || echo '(kernel 日志空)'
    echo "== syspolicy / kernelmanagerd 日志（本次开机以来）"
    log show --last 20m --style compact --predicate \
      'eventMessage CONTAINS "NVRM" OR eventMessage CONTAINS "NullMoth" OR eventMessage CONTAINS "restricted lookup table" OR eventMessage CONTAINS "canLoadKernelExtension"' \
      2>/dev/null | tail -50
  } >>"$out" 2>&1
}

verdict() { # $1 = 采集文件；0 = attach 成功
  local f="$1" n
  n=$(grep -A1 '== ioreg NVRM 节点' "$f" 2>/dev/null | tail -1)
  case "$n" in
    ''|0|'(NVRM 未加载)') return 1 ;;
    *)                    return 0 ;;
  esac
}

# --------------------------------------------------------------------------
# 开机守卫（这是真正的拦路虎，见 NVRM/nvrm_off.h）
#   probe() 第一行就是 if (nvrm_driver_off()) return NULL;
#   nvrm_driver_off() = -nvoff 或 nullmoth-remove 存在 或 nullmoth-nv-starts >= 2
#   计数只在 NVRM::start 里 +1，只有 NVRMFB 点亮 head（或本卡没有 head 可点）才清掉。
#   我们只装了 NVRM，所以计数只涨不清 → 两次开机后驱动再也不 probe，日志一行都没有。
# --------------------------------------------------------------------------
guard_show() {
  echo "== NVRAM nullmoth-*"
  (nvram -p 2>/dev/null || sudo -n nvram -p 2>/dev/null) | grep -i nullmoth || echo "  (没有)"
  echo "== boot-args 里的 -nvoff"
  if nvram boot-args 2>/dev/null | grep -q -- '-nvoff'; then echo "  有 -nvoff"; else echo "  没有 -nvoff"; fi
}

guard_clear() {
  local before after
  before=$(nvram -p 2>/dev/null | grep -i 'nullmoth-nv-starts' || true)
  sudo nvram -d nullmoth-nv-starts 2>/dev/null
  sudo nvram -d nullmoth-remove 2>/dev/null
  after=$(nvram -p 2>/dev/null | grep -i 'nullmoth-nv-starts' || true)
  echo "  守卫计数: ${before:-（无）} -> ${after:-（已清除）}"
  [ -z "$after" ]
}

# --------------------------------------------------------------------------
# 改动步骤（每个都必须自检；失败一律返回非零 → 整个实验停止，不再重启）
# --------------------------------------------------------------------------
step_sign() {
  say "步骤: ad-hoc 签名 NVRM.kext"
  local cyc="${CYCLE:-0}" bk
  bk="$OUT/cyc$cyc/NVRM.kext.before-sign"
  mkdir -p "$OUT/cyc$cyc" 2>/dev/null
  if [ ! -d "$bk" ]; then
    cp -R "$EXT/NVRM.kext" "$bk" 2>/dev/null && echo "  已备份原 bundle: $bk"
  else
    echo "  备份已存在: $bk"
  fi
  codesign --force --deep --sign - "$EXT/NVRM.kext" 2>&1 | sed 's/^/   /'
  codesign -dv --verbose=4 "$EXT/NVRM.kext" 2>&1 | head -6 | sed 's/^/   /'
  chown -R root:wheel "$EXT/NVRM.kext" 2>/dev/null
  chmod -R go-w "$EXT/NVRM.kext" 2>/dev/null
  if ! codesign --verify --deep --strict "$EXT/NVRM.kext" 2>&1 | sed 's/^/   verify: /'; then
    bad "签名后校验失败"
  fi
  codesign --verify --deep --strict "$EXT/NVRM.kext" >/dev/null 2>&1 || { bad "签名无效"; return 1; }
  echo "  签名 OK"
}

step_rebuild() {
  say "步骤: 重建辅助内核集合（kmutil create -n aux）"
  local cyc="${CYCLE:-0}"
  mkdir -p "$OUT/cyc$cyc" 2>/dev/null
  local K=/System/Library/Kernels/kernel
  local KB=/System/Library/KernelCollections/BootKernelExtensions.kc
  local KS=/System/Library/KernelCollections/SystemKernelExtensions.kc
  local NEW="$KC.g1-new" rc
  local args=(--volume-root / --allow-missing-kdk -B "$KB" -S "$KS")
  [ -f "$K" ] && args+=(--kernel "$K")
  kmutil create -n aux "${args[@]}" --repository "$EXT" -A "$NEW" -z \
    --no-variant-extension >"$OUT/cyc$cyc/rebuild.log" 2>&1
  rc=$?
  sed 's/^/   /' "$OUT/cyc$cyc/rebuild.log" 2>/dev/null | tail -6
  if [ "$rc" != 0 ] || [ ! -f "$NEW" ]; then
    bad "重建失败 rc=$rc"
    log show --last 3m --predicate 'process == "kmutil"' --style compact 2>/dev/null \
      | tail -15 | sed 's/^/   | /'
    rm -f "$NEW"
    return 1
  fi
  if ! kmutil inspect -a x86_64 -A "$NEW" 2>/dev/null | grep -qi nullmoth; then
    bad "新集合里没有 NVRM，拒绝替换"
    rm -f "$NEW"
    return 1
  fi
  cp -p "$KC" "$OUT/cyc$cyc/AuxiliaryKernelExtensions.kc.before" 2>/dev/null
  chmod 0644 "$NEW" 2>/dev/null; chown root:wheel "$NEW" 2>/dev/null
  mv -f "$NEW" "$KC" || { bad "替换集合失败"; return 1; }
  chmod 0644 "$KC" 2>/dev/null; chown root:wheel "$KC" 2>/dev/null
  echo "  集合 sha256: $(shasum -a 256 "$KC" 2>/dev/null | cut -d' ' -f1)"
  kmutil inspect -a x86_64 -A "$KC" 2>&1 | grep -i nullmoth | head -2 | sed 's/^/   集合里: /'
}

step_reinstall() {
  say "步骤: 从 U 盘重新安装 NVRM.kext 再重建集合"
  local src='' h
  h=$(get_state HERE); [ -z "$h" ] && h="$HERE"
  for d in "$h/NVRM.kext" "$h/候选/NVRM.kext" "$h/build/NVRM.kext" "$h/../NVRM.kext"; do
    [ -d "$d" ] && { src="$d"; break; }
  done
  if [ -z "$src" ]; then
    say "跳过: U 盘上没有 NVRM.kext"
    return 2                     # 2 = 跳过，不算失败
  fi
  rm -rf "$EXT/NVRM.kext" && cp -R "$src" "$EXT/NVRM.kext" || { bad "复制失败"; return 1; }
  chown -R root:wheel "$EXT/NVRM.kext" 2>/dev/null
  chmod -R 755 "$EXT/NVRM.kext" 2>/dev/null
  chmod 644 "$EXT/NVRM.kext/Contents/Info.plist" 2>/dev/null
  chmod -R go-w "$EXT/NVRM.kext" 2>/dev/null
  echo "  已安装: $src"
  step_rebuild
}

apply_step() { # 0=成功 1=失败 2=跳过
  CYCLE="${CYCLE:-0}"
  case "$1" in
    none)      say "步骤: 什么都不改，只看这一轮开机（守卫已清）" ;;
    sign)      step_sign ;;
    rebuild)   step_rebuild ;;
    reinstall) step_reinstall ;;
    "")        return 2 ;;
    *)         bad "未知步骤 $1"; return 1 ;;
  esac
}

# --------------------------------------------------------------------------
# LaunchDaemon
# --------------------------------------------------------------------------
install_daemon() {
  mkdir -p "$STATE"
  cp -f "$0" "$RUNNER" || { bad "复制 runner 失败"; return 1; }
  chmod 0755 "$RUNNER"
  local tmp=$STATE/$LABEL.plist.tmp
  cat >"$tmp" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$RUNNER</string><string>--daemon-step</string><string>$RUN</string></array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$STATE/daemon.out</string>
  <key>StandardErrorPath</key><string>$STATE/daemon.err</string>
</dict>
</plist>
PLIST
  sudo install -m 0644 -o root -g wheel "$tmp" "$DAEMON" || { bad "写 $DAEMON 失败"; return 1; }
  echo "  已写 $DAEMON"
  sudo launchctl bootout "system/$LABEL" 2>/dev/null
  sudo launchctl bootstrap system "$DAEMON" 2>/dev/null
}

remove_daemon() { # $1 可选 = 指定 run
  local r="${1:-}"
  if [ -n "$r" ]; then
    sudo launchctl bootout "system/$LABEL_BASE.$r" 2>/dev/null
    sudo rm -f "/Library/LaunchDaemons/$LABEL_BASE.$r.plist"
    return
  fi
  local f b
  # v2 的旧标签（没有 run 后缀）也要清掉
  if [ -f "/Library/LaunchDaemons/$LABEL_BASE.plist" ]; then
    sudo launchctl bootout "system/$LABEL_BASE" 2>/dev/null
    sudo rm -f "/Library/LaunchDaemons/$LABEL_BASE.plist"
    echo "  已移除 $LABEL_BASE（v2 遗留）"
  fi
  for f in /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    b=$(basename "$f" .plist)
    sudo launchctl bootout "system/$b" 2>/dev/null
    sudo rm -f "$f"
    echo "  已移除 $b"
  done
}

runs_present() {
  local n=0
  [ -f "/Library/LaunchDaemons/$LABEL_BASE.plist" ] && n=$((n+1))
  n=$((n + $(ls -1 /Library/LaunchDaemons 2>/dev/null | grep -c "$LABEL_BASE\.")))
  echo "$n"
}

# --------------------------------------------------------------------------
# 结束
# --------------------------------------------------------------------------
finish() {
  remove_daemon "$RUN"
  cp -f "$STATE/last.txt" "$OUT/last.txt" 2>/dev/null
  cat "$OUT"/cyc*/after.txt >"$OUT/REPORT.txt" 2>/dev/null
  local u d
  u=$(stat -f%Su /dev/console 2>/dev/null)
  if [ -n "$u" ] && [ "$u" != root ] && [ "$u" != loginwindow ]; then
    d=$(eval echo "~$u")/Desktop
    mkdir -p "$d" 2>/dev/null
    cp -f "$OUT/REPORT.txt" "$d/g1-auto-report.txt" 2>/dev/null
    chown "$u" "$d/g1-auto-report.txt" 2>/dev/null
    sudo -u "$u" osascript -e "display notification \"自动实验结束：$(get_state RESULT)\" with title \"G1\"" 2>/dev/null
  fi
  echo "RESULT=$(get_state RESULT)" >"$STATE/DONE"
}

# --------------------------------------------------------------------------
# daemon：重启后由 launchd 以 root 调用
# --------------------------------------------------------------------------
daemon_step() {
  setup_run "$1"
  OUT=$(get_state OUT); [ -z "$OUT" ] && OUT=$STATE/out
  local now_boot ib
  now_boot=$(sysctl -n kern.boottime 2>/dev/null | tr -dc 0-9 | cut -c1-12)
  ib=$(get_state INSTALL_BOOT)
  # 装 daemon 的那次开机不算：RunAtLoad 会让它立刻跑起来，那时没有任何新信息
  if [ -n "$ib" ] && [ "$now_boot" = "$ib" ]; then
    mkdir -p "$STATE"
    say "daemon 在安装它的那次开机里被启动 —— 不采集、不重启，等下次开机" >>"$STATE/daemon.out"
    exit 0
  fi
  CYCLE=$(( $(get_state CYCLE) + 1 ))
  # 同一次开机只跑一次
  [ -f "$STATE/BOOT-$now_boot" ] && exit 0
  date >"$STATE/BOOT-$now_boot"
  set_state CYCLE "$CYCLE"
  mkdir -p "$OUT/cyc$CYCLE"
  LOG=$OUT/cyc$CYCLE/after.txt

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

  local s rc applied=0
  while :; do
    s=$(next_step) || break
    [ -z "$s" ] && break
    set_state STEP "$s"
    say "cycle $CYCLE: 下一步 = $s" | tee -a "$LOG"
    apply_step "$s" >>"$LOG" 2>&1; rc=$?
    if [ "$rc" = 0 ]; then applied=1; break; fi
    if [ "$rc" = 2 ]; then say "  跳过 $s" | tee -a "$LOG"; continue; fi
    set_state RESULT STEP_FAILED
    say "步骤 $s 失败 —— 停止自动循环，不重启。修好后再跑 collect。" | tee -a "$LOG"
    finish
    return 0
  done

  if [ "$applied" != 1 ]; then
    set_state RESULT EXHAUSTED
    say "步骤队列跑完（或全部跳过）仍没 attach —— 停止自动循环，不再重启。报告在 $OUT" | tee -a "$LOG"
    finish
    return 0
  fi

  { echo "== 重启前清掉开机守卫计数"; guard_clear; } >>"$LOG" 2>&1
  sync; sleep 3
  /sbin/shutdown -r now
}

# --------------------------------------------------------------------------
# 命令
# --------------------------------------------------------------------------
preflight() {
  [ "$(uname -s)" = Darwin ] || { echo "只能在 macOS 上跑"; exit 2; }
  [ -d "$EXT/NVRM.kext" ] || { bad "$EXT/NVRM.kext 不存在，先装候选"; exit 2; }
  [ -d /Library/Developer/KDKs ] || { bad "没有 KDK，集合无法重建"; exit 2; }
  sudo -n true 2>/dev/null || { echo "需要 sudo 权限，先输密码:"; sudo -v || exit 2; }
}

cmd_run() {
  setup_run
  preflight
  local n
  n=$(runs_present)
  if [ "$n" != 0 ] && [ "${FORCE:-0}" != 1 ]; then
    bad "已经有 $n 个自动循环在跑："
    ls -1 /Library/LaunchDaemons 2>/dev/null | grep "$LABEL_BASE\." | sed 's/^/   /'
    echo "  先停掉: bash ./G1-自动实验.command stop"
    echo "  或者强来: bash ./G1-自动实验.command --force"
    exit 2
  fi
  [ "${FORCE:-0}" = 1 ] && { echo "== 先清掉旧的自动循环"; remove_daemon; }

  OUT="$HERE/results/auto-$RUN"
  mkdir -p "$OUT/cyc0" 2>/dev/null || { OUT="$STATE/out"; mkdir -p "$OUT/cyc0"; }
  set_state OUT "$OUT"
  set_state HERE "$HERE"
  set_state CYCLE 0
  set_state STARTED "$RUN"
  # 记下安装 daemon 时的开机时刻，daemon 用它拒绝在同一次开机里跑
  set_state INSTALL_BOOT "$(sysctl -n kern.boottime 2>/dev/null | tr -dc 0-9 | cut -c1-12)"

  # 步骤队列：先什么都不改（守卫清零后看固件能不能被吃进去），再试签名 / 重建
  local spare=''
  for d in "$HERE/NVRM.kext" "$HERE/候选/NVRM.kext" "$HERE/build/NVRM.kext"; do
    [ -d "$d" ] && { spare="$d"; break; }
  done
  if [ -n "$spare" ]; then
    printf 'none\nsign\nrebuild\nreinstall\nrebuild\n' >"$STEPS"
    echo "  找到备用 bundle: $spare"
  else
    printf 'none\nsign\nrebuild\n' >"$STEPS"
  fi
  head -n "$MAXCYC" "$STEPS" >"$STEPS.t" && mv "$STEPS.t" "$STEPS"

  say "cycle 0 采集（改动前基线）"
  CYCLE=0 collect "$OUT/cyc0/before.txt"
  echo "  ioreg NVRM 节点数: $(grep -A1 '== ioreg NVRM 节点' "$OUT/cyc0/before.txt" | tail -1)"
  echo "  报告目录: $OUT"

  # 关键：先看/清开机守卫，否则驱动 probe 直接返回 NULL，后面所有实验都是空转
  say "cycle 0: 开机守卫状态"
  guard_show | tee -a "$OUT/cyc0/before.txt"
  if verdict "$OUT/cyc0/before.txt"; then
    say "现在就已经 attach 了，不用改任何东西"
    cp -f "$OUT/cyc0/before.txt" "$HOME/Desktop/g1-auto-report.txt" 2>/dev/null
    exit 0
  fi
  say "cycle 0: 清掉守卫计数"
  guard_clear | tee -a "$OUT/cyc0/before.txt"

  local s rc applied=0
  while :; do
    s=$(next_step) || break
    [ -z "$s" ] && break
    say "cycle 0: 应用 $s"
    CYCLE=0 apply_step "$s" 2>&1 | tee "$OUT/cyc0/step.txt"; rc=${PIPESTATUS[0]}
    if [ "$rc" = 0 ]; then applied=1; break; fi
    if [ "$rc" = 2 ]; then say "  跳过 $s"; continue; fi
    set_state RESULT STEP_FAILED
    bad "第 1 步就失败了，不重启、不装 daemon。看 $OUT/cyc0/step.txt"
    exit 3
  done
  [ "$applied" = 1 ] || { bad "步骤队列里没有可执行的步骤，什么都不做不重启"; exit 3; }

  install_daemon || { bad "装 daemon 失败，不重启"; exit 3; }
  sync
  say "已装开机自启 daemon（$LABEL），即将重启"
  echo "  重启回来后不用你做任何事；大约 1 分钟后开始采集。"
  echo "  最多 $MAXCYC 个周期，任何一步失败或 attach 成功都会自动停。"
  echo "  随时: bash ./G1-自动实验.command status | stop"
  sleep 5
  sudo /sbin/shutdown -r now
}

cmd_collect() {
  setup_run "collect-$(date +%Y%m%d-%H%M%S)"
  local out="$HERE/results/$RUN.txt"
  mkdir -p "$HERE/results" 2>/dev/null || out="/var/tmp/g1-auto/$RUN.txt"
  collect "$out"
  if verdict "$out"; then echo "verdict: ATTACHED"; else echo "verdict: NOT_ATTACHED"; fi
  echo "报告: $out"
}

cmd_status() {
  echo "== 自动循环"
  local f
  for f in /Library/LaunchDaemons/$LABEL_BASE.*.plist; do
    [ -f "$f" ] || continue
    echo "  已安装: $(basename "$f" .plist)"
  done
  [ -f "$f" ] || echo "  (没有在跑的自动循环)"
  echo "== 各 run 状态"
  local d
  for d in /var/tmp/g1-auto/*/; do
    [ -f "$d/state" ] || continue
    echo "  --- $(basename "$d")"
    sed 's/^/     /' "$d/state"
  done
  echo "== 最近一次采集的关键行"
  local r
  r=$(ls -dt /var/tmp/g1-auto/*/last.txt 2>/dev/null | head -1)
  if [ -n "$r" ]; then
    grep -A1 -E '== ioreg NVRM 节点|== kextstat NVRM|== 签名状态|== 加载来源' "$r" | head -20 | sed 's/^/   /'
    echo "   (完整: $r)"
  fi
}

cmd_report() {
  local r
  r=$(ls -dt "$HERE"/results/auto-*/REPORT.txt "$HERE"/results/auto-*/last.txt 2>/dev/null | head -1)
  [ -z "$r" ] && r=$(ls -dt /var/tmp/g1-auto/*/last.txt 2>/dev/null | head -1)
  [ -z "$r" ] && { echo "还没有报告"; exit 1; }
  echo "== $r"
  cat "$r"
}

cmd_stop() {
  remove_daemon
  echo "所有自动循环已移除，不会再自动重启。"
  echo "签名前的 bundle 备份: results/auto-*/cyc*/NVRM.kext.before-sign"
  echo "集合备份: results/auto-*/cyc*/AuxiliaryKernelExtensions.kc.before"
}

case "${1:-run}" in
  --daemon-step) daemon_step "${2:-}" ;;
  run|"")        cmd_run ;;
  --force)       FORCE=1 cmd_run ;;
  collect)       cmd_collect ;;
  guard)         guard_show; say "清掉守卫"; guard_clear ;;
  status)        cmd_status ;;
  report)        cmd_report ;;
  stop)          cmd_stop ;;
  *)             echo "用法: bash $0 [run|collect|status|report|stop|--force]"; exit 2 ;;
esac
