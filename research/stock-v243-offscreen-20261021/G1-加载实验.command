#!/bin/bash
# ============================================================================
#  G1 加载实验（一键，可回退）—— 把已构建的 NVRM 装进系统并只加载、不启动 GPU
#
#  这是唯一会写系统文件的脚本，且每一步都要手动确认：
#    plan     只打印将要做什么，不改任何东西
#    backup   备份扩展与内核集合
#    install  只安装 NVRM + 追加 -nvrmnogo + 重建内核集合（需要 sudo）
#    verify   重启后检查加载结果
#    rollback 撤销安装、还原 boot-args、重建内核集合（需要 sudo）
#    status   显示当前进度
#
#  它不做：nvrmctl go、Metal、GPU 计算、睡眠测试、显示所有权变更。
#  -nvrmnogo 只关闭 auto-go，不保证硬件不被触碰（start() 仍会动 BAR1）。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAGE="${1:-status}"
RESULTS="$HERE/results"
CAND_ROOT="$HOME/Desktop/g1-runs"
BACKUP="$RESULTS/load-$(date +%Y%m%d-%H%M%S)"
STATE="$RESULTS/load-state.env"

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }
ask() { local a; read -r -p "$1 " a; printf '%s' "$a"; }

[ "$(uname -s)" = "Darwin" ] || { bad "只能在 macOS 上运行"; exit 2; }
mkdir -p "$RESULTS"

# 最近的候选：g1-runs/<stamp>/run-*/internal-products/package-products/NVRM.kext
find_candidate() {
  ls -dt "$CAND_ROOT"/*/run-*/internal-products/package-products/NVRM.kext 2>/dev/null | head -1
}
CANDIDATE="$(find_candidate)"

load_state() {
  [ -f "$STATE" ] && . "$STATE"
}
save_state() {
  {
    printf 'BACKUP=%s\n' "${BACKUP:-}"
    printf 'STAGE=%s\n' "${STAGE_NAME:-}"
    printf 'CANDIDATE=%s\n' "${CANDIDATE:-}"
    printf 'PRIOR_NVRM=%s\n' "${PRIOR_NVRM:-absent}"
    printf 'DELIVERED_COMMIT=%s\n' "${DELIVERED_COMMIT:-unknown}"
  } > "$STATE"
}
load_state
[ -n "${BACKUP:-}" ] || BACKUP="$RESULTS/load-$(date +%Y%m%d-%H%M%S)"
DELIVERED_COMMIT="$( [ -f "$HERE/expected-commit.txt" ] && tr -d '[:space:]' < "$HERE/expected-commit.txt" || echo unknown )"

status() {
  say "状态"
  printf '交付提交: %s\n' "$DELIVERED_COMMIT"
  printf '候选 NVRM: %s\n' "${CANDIDATE:-（没找到，先跑一次构建）}"
  if [ -n "${CANDIDATE:-}" ] && [ -f "$CANDIDATE/Contents/MacOS/NVRM" ]; then
    printf '候选可执行 SHA256: %s\n' "$(shasum -a 256 "$CANDIDATE/Contents/MacOS/NVRM" | cut -d' ' -f1)"
  fi
  printf '备份目录: %s\n' "${BACKUP:-（尚未备份）}"
  printf '阶段: %s\n' "${STAGE_NAME:-未开始}"
  printf '\n当前已加载的 NV kext:\n'
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' || echo '  （无）'
  printf '\nboot-args:\n'
  nvram boot-args 2>/dev/null || echo '  （无）'
}

plan() {
  say "将要执行的动作（不改任何东西）"
  cat <<'EOF'
  backup   : 复制 /Library/Extensions 到备份目录；记录所有内核集合的 SHA256；
             记录 kextstat、boot-args、csrutil、kmutil showloaded
  install  : rm -rf /Library/Extensions/NVRM.kext
             cp -R <候选>/NVRM.kext /Library/Extensions/NVRM.kext
             chown -R root:wheel 该 bundle
             nvram boot-args="<现有> -nvrmnogo"
             kmutil install --update-all
  verify   : kextstat / ioreg NVRM 属性 / 最近 5 分钟内核日志 / panic 报告
  rollback : 恢复备份里的 NVRM（若原本有）或删除候选；
             把 boot-args 还原成备份里的原文；kmutil install --update-all
EOF
  printf '\n候选:\n  %s\n' "${CANDIDATE:-（没找到）}"
  printf '备份将写入:\n  %s\n' "$BACKUP"
}

do_backup() {
  say "备份"
  [ -d /Library/Extensions ] || { bad "找不到 /Library/Extensions"; exit 2; }
  mkdir -p "$BACKUP"
  sudo cp -a /Library/Extensions "$BACKUP/Extensions"
  shasum -a 256 /System/Library/KernelCollections/*.kc* > "$BACKUP/kc-before.txt" 2>/dev/null
  [ -d /Library/KernelCollections ] && shasum -a 256 /Library/KernelCollections/*.kc* >> "$BACKUP/kc-before.txt" 2>/dev/null
  kextstat > "$BACKUP/kextstat-before.txt"
  nvram boot-args > "$BACKUP/boot-args-before.txt" 2>&1 || true
  csrutil status > "$BACKUP/csrutil.txt" 2>&1 || true
  kmutil showloaded > "$BACKUP/showloaded-before.txt" 2>&1 || true
  if [ -d /Library/Extensions/NVRM.kext ]; then echo present > "$BACKUP/nvrm-was-installed.txt"
  else echo absent > "$BACKUP/nvrm-was-installed.txt"; fi
  PRIOR_NVRM="$(cat "$BACKUP/nvrm-was-installed.txt")"
  STAGE_NAME="backup-done"
  save_state
  printf '备份完成: %s\n' "$BACKUP"
  printf '回传: kextstat-before.txt  nvrm-was-installed.txt  boot-args-before.txt  kc-before.txt\n'
}

do_install() {
  say "安装（只装 NVRM，加 -nvrmnogo）"
  CANDIDATE="$(find_candidate)"
  [ -n "${CANDIDATE:-}" ] || { bad "没找到候选 NVRM.kext，先完成一次构建"; exit 2; }
  # 一键：没有备份就先自动备份，而不是让用户再记一条命令。
  if [ ! -f "$BACKUP/kextstat-before.txt" ]; then
    say "还没有备份，先自动备份"
    do_backup
  fi
  printf '候选: %s\n' "$CANDIDATE"
  printf '将执行: 替换 /Library/Extensions/NVRM.kext、追加 -nvrmnogo、重建内核集合\n'
  [ "$(ask '输入 INSTALL 继续:')" = "INSTALL" ] || { bad "已取消"; exit 1; }

  sudo rm -rf /Library/Extensions/NVRM.kext
  sudo cp -R "$CANDIDATE" /Library/Extensions/NVRM.kext
  sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  local current
  current="$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p' || true)"
  case "$current" in
    *-nvrmnogo*) echo "boot-args 已含 -nvrmnogo" ;;
    *) sudo nvram boot-args="${current} -nvrmnogo" ;;
  esac
  sudo kmutil install --update-all 2>&1 | tee "$BACKUP/kmutil-install.txt"
  STAGE_NAME="install-done"
  save_state
  say "安装完成。现在重启，然后运行：bash G1-加载实验.command verify"
}

do_verify() {
  say "验证（重启后）"
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' | tee "$BACKUP/kextstat-after.txt" || bad "没有 NV kext 被加载"
  ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation)' | tee "$BACKUP/nvrm-properties.txt" || true
  log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"' 2>/dev/null | tail -40 | tee "$BACKUP/nvrm-log.txt" || true
  ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 | tee "$BACKUP/panic-reports.txt" || true
  local loaded=0
  kextstat | grep -q 'NVRM' && loaded=1
  local nogo=0
  [ -f "$BACKUP/nvrm-properties.txt" ] && grep -q 'nvrm-autogo' "$BACKUP/nvrm-properties.txt" && nogo=1
  printf '\n判据: 加载=%s  auto-go属性=%s\n' "$loaded" "$nogo"
  if [ "$loaded" = 1 ] && [ "$nogo" = 1 ]; then
    STAGE_NAME="verify-pass"
    save_state
    say "NVRM 已加载且 auto-go 关闭。GPU 仍未初始化、未执行任何计算。"
    VERDICT="PASS_LOADED_AUTOGO_OFF"
  else
    STAGE_NAME="verify-failed"
    save_state
    bad "未满足判据；不要继续，直接 rollback"
    VERDICT="FAILED_NOT_LOADED"
  fi
  {
    printf '{\n'
    printf '  "verdict": "%s",\n' "$VERDICT"
    printf '  "loaded_nvrm": %s,\n' "$loaded"
    printf '  "nvrm_autogo_property": %s,\n' "$nogo"
    printf '  "candidate": "%s",\n' "${CANDIDATE:-unknown}"
    printf '  "backup": "%s",\n' "$BACKUP"
    printf '  "delivered_commit": "%s",\n' "$DELIVERED_COMMIT"
    printf '  "gpu": "NOT_RUN",\n'
    printf '  "scope": "KEXT_LOAD_ONLY"\n'
    printf '}\n'
  } > "$BACKUP/result.json"
  printf '结果: %s\n' "$BACKUP/result.json"
}

do_rollback() {
  say "回退"
  [ -d "${BACKUP:-}" ] || { bad "找不到备份目录，不能用这个脚本回退"; exit 2; }
  if [ -d "$BACKUP/Extensions/NVRM.kext" ]; then
    printf '将恢复备份中的 NVRM.kext\n'
  else
    printf '备份中没有旧 NVRM，将删除候选\n'
  fi
  [ "$(ask '输入 ROLLBACK 继续:')" = "ROLLBACK" ] || { bad "已取消"; exit 1; }
  if [ -d "$BACKUP/Extensions/NVRM.kext" ]; then
    sudo rm -rf /Library/Extensions/NVRM.kext
    sudo cp -R "$BACKUP/Extensions/NVRM.kext" /Library/Extensions/NVRM.kext
    sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  else
    sudo rm -rf /Library/Extensions/NVRM.kext
  fi
  if [ -f "$BACKUP/boot-args-before.txt" ]; then
    local args
    args="$(sed -n 's/.*boot-args[[:space:]]*//p' "$BACKUP/boot-args-before.txt")"
    if [ -n "$args" ]; then sudo nvram boot-args="$args"; else sudo nvram -d boot-args; fi
  fi
  sudo kmutil install --update-all 2>&1 | tee "$BACKUP/kmutil-rollback.txt"
  STAGE_NAME="rolled-back"
  save_state
  say "回退完成。重启后对比 kextstat-before.txt。"
}

case "$STAGE" in
  status)   status ;;
  plan)     plan ;;
  backup)   do_backup ;;
  install|go) do_install ;;
  verify)   do_verify ;;
  rollback) do_rollback ;;
  *)
    status
    printf '\n可用阶段: plan | backup | install | verify | rollback | status\n'
    ;;
esac
