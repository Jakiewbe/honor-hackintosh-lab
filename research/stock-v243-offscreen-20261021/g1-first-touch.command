#!/bin/bash
# HONOR G1 / RTX 2050 首次接触 —— 一键脚本（macOS 双击可运行）
#
# 双击本文件即可打开终端运行；也可以：bash g1-first-touch.command
# 它会引导你做：检查环境 → 构建候选 → 备份 → 安装（只换 NVRM）→ 重启后验证 → 回退。
#
# 设计原则：
#   * 只有"安装"和"回退"需要 sudo，且都会先让你输入 YES 确认；
#   * 不跑 nvrmctl go，不跑 Metal，不碰 Windows/EFI/BIOS/SIP 其他项；
#   * 所有输出同时写进 ~/Desktop/g1-first-touch/report-<时间>.txt，方便回传。

set -uo pipefail

REPORT_DIR="$HOME/Desktop/g1-first-touch"
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$REPORT_DIR/report-$STAMP.txt"
REPO=${REPO:-$HOME/honor-hackintosh-lab}
WORK=${WORK:-$HOME/Desktop/g1-kextutil}
CAND=${CAND:-$WORK/internal-products/package-products}
BACKUP="$REPORT_DIR"

mkdir -p "$REPORT_DIR"
exec > >(tee -a "$REPORT") 2>&1

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31mSTOP: %s\033[0m\n' "$*"; exit 1; }
ask()  { local a; read -r -p "$1 " a; printf '%s' "$a"; }

say "HONOR G1 首次接触脚本   $(date)"
echo "报告会写到: $REPORT"

[[ "$(uname -s)" == Darwin ]] || die "这个脚本只能在 macOS 上运行（当前: $(uname -s)）"

# ---------------------------------------------------------------- 环境检查
check_env() {
  say "== 环境检查"
  sw_vers
  echo "--- SIP"
  csrutil status || warn "读不到 SIP 状态"
  echo "--- 已加载的相关 kext"
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' || echo "（没有 NVRM/NVAccel/NVRMFB 在运行）"
  echo "--- /Library/Extensions"
  ls -1 /Library/Extensions 2>/dev/null | head -20
  echo "--- 候选是否存在"
  if [[ -d "$CAND/NVRM.kext" ]]; then echo "有: $CAND/NVRM.kext"; else echo "无: $CAND/NVRM.kext"; fi
  echo "--- 备份卷（安装盘）"
  ls -1 /Volumes
  echo "--- boot-args"
  nvram boot-args 2>/dev/null || echo "（无）"
}

# ---------------------------------------------------------------- 构建候选
build_candidate() {
  say "== 构建候选（约 20-40 分钟；需要 Xcode 16.4 / SDK 15.5 / python3 / gmake）"
  [[ -d "$REPO" ]] || die "找不到仓库 $REPO（可用 REPO=/path/to/repo 指定）"
  [[ -f "$REPO/research/stock-v243-offscreen-20261021/device-kextutil.sh" ]] \
    || die "仓库里没有 device-kextutil.sh，请先 git fetch && git checkout 最新 main"
  bash "$REPO/research/stock-v243-offscreen-20261021/device-kextutil.sh" "$REPO" "$WORK"
  [[ -d "$CAND/NVRM.kext" ]] || die "构建结束但没有 $CAND/NVRM.kext"
  echo "候选就绪: $CAND/NVRM.kext"
}

# ---------------------------------------------------------------- 备份
do_backup() {
  say "== 备份（只读采集）"
  mkdir -p "$BACKUP/Extensions" "$BACKUP/KernelCollections"
  sudo cp -a /Library/Extensions/. "$BACKUP/Extensions"/
  sudo cp -a /System/Library/KernelCollections/. "$BACKUP/KernelCollections"/
  kextstat > "$BACKUP/kextstat-before.txt"
  shasum -a 256 /System/Library/KernelCollections/*.kc > "$BACKUP/kc-before.txt"
  for d in /System/Library/KernelCollections /Library/KernelCollections; do
    [[ -d "$d" ]] && shasum -a 256 "$d"/*.kc* >> "$BACKUP/kc-before-all.txt" 2>/dev/null
  done
  ls -la /System/Library/KernelCollections /Library/KernelCollections > "$BACKUP/kc-dirs.txt" 2>&1
  if [[ -d /Library/Extensions/NVRM.kext ]]; then echo present > "$BACKUP/nvrm-was-installed.txt"
  else echo absent > "$BACKUP/nvrm-was-installed.txt"; fi
  nvram boot-args > "$BACKUP/boot-args-before.txt" 2>&1 || true
  csrutil status > "$BACKUP/csrutil.txt" 2>&1 || true
  echo "备份完成: $BACKUP"
  echo "请回传: kextstat-before.txt / kc-before-all.txt / nvrm-was-installed.txt / boot-args-before.txt"
}

# ---------------------------------------------------------------- 安装
do_install() {
  say "== 安装（只替换 NVRM，加 -nvrmnogo）"
  [[ -d "$CAND/NVRM.kext" ]] || die "没有候选 $CAND/NVRM.kext，先选 2 构建"
  [[ -f "$BACKUP/kextstat-before.txt" ]] || die "还没有备份，先选 3 备份"
  echo "将要执行："
  echo "  rm -rf /Library/Extensions/NVRM.kext"
  echo "  cp -R $CAND/NVRM.kext /Library/Extensions/NVRM.kext"
  echo "  nvram boot-args=\"<现有> -nvrmnogo\""
  echo "  kmutil install --update-all"
  echo "不会运行 nvrmctl go，不会跑 Metal。"
  [[ "$(ask '输入 YES 继续:')" == YES ]] || { warn "已取消"; return; }

  sudo rm -rf /Library/Extensions/NVRM.kext
  sudo cp -R "$CAND/NVRM.kext" /Library/Extensions/NVRM.kext
  sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  local current
  current=$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p' || true)
  case "$current" in
    *-nvrmnogo*) echo "boot-args 已含 -nvrmnogo" ;;
    *) sudo nvram boot-args="${current} -nvrmnogo" ;;
  esac
  nvram boot-args > "$BACKUP/boot-args-after.txt" 2>&1 || true
  sudo kmutil install --update-all
  say "装好了。现在重启，然后重新运行本脚本选 5 验证。"
}

# ---------------------------------------------------------------- 验证
do_verify() {
  say "== 验证（重启后运行）"
  kextstat | grep -Ei 'NVRM|NVAccel|NVRMFB' || warn "没有 NVRM/NVAccel/NVRMFB 被加载"
  echo "--- NVRM 属性"
  ioreg -rn NVRM -l 2>/dev/null | grep -E 'nvrm-(autogo|boot-hold|kext-version|pm-violation)' || echo "（读不到）"
  echo "--- 最近 5 分钟内核日志（NVRM）"
  log show --last 5m --predicate 'eventMessage CONTAINS "NVRM"' 2>/dev/null | tail -40 || true
  echo "--- panic 记录"
  ls -1 /Library/Logs/DiagnosticReports/*.panic 2>/dev/null | tail -3 || echo "（无）"
  say "判据：NVRM 在 kextstat；nvrm-autogo 为 off (-nvrmnogo)；无 panic。"
}

# ---------------------------------------------------------------- 回退
do_rollback() {
  say "== 回退"
  if [[ -d "$BACKUP/Extensions/NVRM.kext" ]]; then
    echo "将恢复备份里的 NVRM.kext"
  else
    echo "备份里没有旧 NVRM（本来就没装），将删除候选"
  fi
  [[ "$(ask '输入 YES 继续:')" == YES ]] || { warn "已取消"; return; }
  if [[ -d "$BACKUP/Extensions/NVRM.kext" ]]; then
    sudo rm -rf /Library/Extensions/NVRM.kext
    sudo cp -R "$BACKUP/Extensions/NVRM.kext" /Library/Extensions/NVRM.kext
    sudo chown -R root:wheel /Library/Extensions/NVRM.kext
  else
    sudo rm -rf /Library/Extensions/NVRM.kext
  fi
  if [[ -f "$BACKUP/boot-args-before.txt" ]]; then
    sudo nvram boot-args="$(sed -n 's/.*boot-args[[:space:]]*//p' "$BACKUP/boot-args-before.txt")"
  else
    sudo nvram -d boot-args
  fi
  sudo kmutil install --update-all
  say "已回退。重启后确认 kextstat 与 $BACKUP/kextstat-before.txt 一致。"
}

menu() {
  while true; do
    say "请选择"
    cat <<'EOF'
  1) 环境检查（只读）
  2) 构建候选（20-40 分钟）
  3) 备份当前系统（只读）
  4) 安装候选 + -nvrmnogo（需 sudo 确认）
  5) 重启后验证
  6) 回退
  q) 退出
EOF
    case "$(ask '编号:')" in
      1) check_env ;;
      2) build_candidate ;;
      3) do_backup ;;
      4) do_install ;;
      5) do_verify ;;
      6) do_rollback ;;
      q|Q) break ;;
      *) warn "无效选择" ;;
    esac
    echo
    ask '按回车回到菜单…' >/dev/null
  done
}

menu
say "结束。报告在: $REPORT"
echo "出事时的救援步骤见 U 盘里的 RECOVERY-FROM-INSTALLER.md（用 E: 安装盘启动进 Recovery 终端）。"
