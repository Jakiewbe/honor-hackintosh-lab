#!/bin/bash
# ============================================================================
#  G1 修复加载（一键）
#
#  问题：`kmutil install --update-all` 会连 release 的 Boot/System 集合一起重写，
#        而它们在只读系统卷上，于是报 "Read-only file system"，第三方 kext 永远进不了集合。
#
#  做法：只重建可写的辅助集合（/Library/KernelCollections/AuxiliaryKernelExtensions.kc），
#        把 boot/system 的输出重定向到 /tmp。脚本按顺序试几种 kmutil 调用方式，
#        第一个真正成功的就停；每一步都留日志。
#
#  只碰辅助集合；不写系统卷、不改 boot-args、不动 EFI。需要 sudo。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/results/fix-$STAMP"
AUX="/Library/KernelCollections/AuxiliaryKernelExtensions.kc"
mkdir -p "$OUT" 2>/dev/null || OUT="$HOME/Desktop/g1-fix-$STAMP"

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }

[ "$(uname -s)" = "Darwin" ] || { bad "只能在 macOS 上运行"; exit 2; }
[ -d /Library/Extensions/NVRM.kext ] || { bad "NVRM.kext 不在 /Library/Extensions，先跑加载实验的 install"; exit 2; }

say "现状"
printf 'build: %s\n' "$(sw_vers -buildVersion)"
printf 'KDK:   %s\n' "$(ls -1 /Library/Developer/KDKs 2>/dev/null | tr '\n' ' ')"
printf 'aux:   %s\n' "$(ls -l "$AUX" 2>/dev/null || echo '缺失')"
if kextstat 2>/dev/null | grep -q NVRM; then
  say "NVRM 已经加载，不需要修"
  exit 0
fi

say "取得权限"
sudo -v || { bad "需要 sudo"; exit 2; }

kmutil create --help >"$OUT/create-help.txt" 2>&1
kmutil install --help >"$OUT/install-help.txt" 2>&1
printf 'kmutil create 支持的路径参数：\n'
grep -oE '\-\-(aux|boot|system|variant-suffix|update-all)[a-z-]*' "$OUT/create-help.txt" | sort -u | sed 's/^/  /'

has_flag() { grep -q -- "$1" "$OUT/create-help.txt"; }

# ---- 候选策略 --------------------------------------------------------------
attempt() {
  local name="$1"; shift
  say "尝试: $name"
  printf '  kmutil %s\n' "$*"
  sudo kmutil "$@" >"$OUT/$name.log" 2>&1
  local rc=$?
  tail -6 "$OUT/$name.log" | sed 's/^/    /'
  if [ "$rc" -eq 0 ]; then
    printf '  退出码 0\n'
    return 0
  fi
  printf '  退出码 %s\n' "$rc"
  return 1
}

loaded() { sudo kmutil showloaded 2>/dev/null | grep -qi 'NVRM'; }

SUCCESS=""

# S1: 显式三路径，boot/system 写到 /tmp，aux 写真实位置
if [ -z "$SUCCESS" ] && has_flag '--aux-path' && has_flag '--boot-path' && has_flag '--system-path'; then
  if attempt S1-boot-system-tmp create --update-all --variant-suffix release \
       --boot-path /tmp/g1-boot.kc --system-path /tmp/g1-system.kc --aux-path "$AUX"; then
    loaded && SUCCESS="S1"
  fi
fi

# S2: 只给 aux 路径
if [ -z "$SUCCESS" ] && has_flag '--aux-path'; then
  if attempt S2-aux-only create --update-all --variant-suffix release --aux-path "$AUX"; then
    loaded && SUCCESS="S2"
  fi
fi

# S3: 三路径但不带 variant-suffix
if [ -z "$SUCCESS" ] && has_flag '--aux-path' && has_flag '--boot-path' && has_flag '--system-path'; then
  if attempt S3-no-variant create --update-all \
       --boot-path /tmp/g1-boot.kc --system-path /tmp/g1-system.kc --aux-path "$AUX"; then
    loaded && SUCCESS="S3"
  fi
fi

# S4: 原来的 install（留作对照，通常仍会因只读失败）
if [ -z "$SUCCESS" ]; then
  if attempt S4-install install --update-all; then
    loaded && SUCCESS="S4"
  fi
fi

# ---- 结果 ------------------------------------------------------------------
say "结果"
if [ -n "$SUCCESS" ]; then
  printf '策略 %s 成功；辅助集合已重建。\n' "$SUCCESS"
  ls -l "$AUX" | sed 's/^/  /'
  sudo kmutil showloaded 2>/dev/null | grep -i 'NVRM' | sed 's/^/  /'
  {
    printf 'verdict: AUX_REBUILT\n'
    printf 'strategy: %s\n' "$SUCCESS"
    printf 'build: %s\n' "$(sw_vers -buildVersion)"
    printf 'aux_sha256: %s\n' "$(shasum -a 256 "$AUX" | cut -d' ' -f1)"
  } > "$OUT/fix-report.txt"
  say "现在重启：sudo reboot"
  printf '重启后用 G1-一键诊断.command 确认。\n'
  rc=0
else
  printf '四种方式都没成功。最后的错误：\n'
  for f in "$OUT"/S*.log; do
    printf '\n--- %s\n' "$(basename "$f")"
    grep -E 'Error|failed|Could not|Read-only|unknown|Usage' "$f" | head -6 | sed 's/^/  /'
  done
  {
    printf 'verdict: ALL_STRATEGIES_FAILED\n'
    printf 'build: %s\n' "$(sw_vers -buildVersion)"
  } > "$OUT/fix-report.txt"
  rc=5
fi

printf '\n日志目录: %s\n' "$OUT"
cp -R "$OUT" "$HOME/Desktop/" 2>/dev/null || true
exit "$rc"
