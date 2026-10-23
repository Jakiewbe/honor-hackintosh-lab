#!/bin/bash
# ============================================================================
#  G1 修复加载（一键，v2）
#
#  前一次的失败与根因：
#    * `kmutil install --update-all` 会重写 release 的 Boot/System 集合，
#      而它们在只读系统卷上 → "Read-only file system"。
#    * 真正需要重建的只有可写的辅助集合：
#        /Library/KernelCollections/AuxiliaryKernelExtensions.kc
#
#  这一版用 `kmutil create` 的 `-n aux`（只做辅助集合）配合
#  `-A/--auxiliary-path`、`-L/--no-system-collection`，不再碰系统卷。
#
#  成功判据：退出码 0，且辅助集合里确实出现 com.nullmoth.NVRM。
#  建好后需要重启才生效（showloaded 读的是当前内核状态）。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/results/fix2-$STAMP"
AUX="/Library/KernelCollections/AuxiliaryKernelExtensions.kc"
BUNDLE_ID="com.nullmoth.NVRM"
mkdir -p "$OUT" 2>/dev/null || OUT="$HOME/Desktop/g1-fix2-$STAMP"

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }

[ "$(uname -s)" = "Darwin" ] || { bad "只能在 macOS 上运行"; exit 2; }
[ -d /Library/Extensions/NVRM.kext ] || { bad "NVRM.kext 不在 /Library/Extensions"; exit 2; }
if kextstat 2>/dev/null | grep -q NVRM; then say "NVRM 已经加载，不需要修"; exit 0; fi

say "现状"
printf 'build: %s\n' "$(sw_vers -buildVersion)"
printf 'KDK:   %s\n' "$(ls -1 /Library/Developer/KDKs 2>/dev/null | tr '\n' ' ')"
printf 'aux:   %s\n' "$(ls -l "$AUX" 2>/dev/null || echo '缺失')"
AUX_BEFORE=$(shasum -a 256 "$AUX" 2>/dev/null | cut -d' ' -f1)
printf 'aux sha256: %s\n' "${AUX_BEFORE:-none}"

say "取得权限"
sudo -v || { bad "需要 sudo"; exit 2; }

kmutil create --help >"$OUT/create-help.txt" 2>&1
FLAGS=$(grep -oE '\-\-[a-z-]+' "$OUT/create-help.txt" | sort -u)
has() { printf '%s\n' "$FLAGS" | grep -qx -- "$1"; }
printf 'create 支持: aux-path=%s new=%s no-system=%s\n' \
  "$(has --auxiliary-path && echo yes || echo no)" \
  "$(has --new && echo yes || echo no)" \
  "$(has --no-system-collection && echo yes || echo no)"

# 辅助集合里是否真的有我们的 kext
aux_has_nvrm() {
  # 先试 kmutil 自己的列举（存在则最可靠），再退回字符串扫描
  if sudo kmutil showloaded --collection auxiliary 2>/dev/null | grep -qi 'NVRM'; then return 0; fi
  if strings "$AUX" 2>/dev/null | grep -q "$BUNDLE_ID"; then return 0; fi
  return 1
}

attempt() {
  local name="$1"; shift
  say "尝试: $name"
  printf '  sudo kmutil %s\n' "$*"
  sudo kmutil "$@" >"$OUT/$name.log" 2>&1
  local rc=$?
  tail -5 "$OUT/$name.log" | sed 's/^/    /'
  printf '  退出码 %s\n' "$rc"
  [ "$rc" -eq 0 ] || return 1
  if aux_has_nvrm; then
    printf '  辅助集合里已出现 %s\n' "$BUNDLE_ID"
    return 0
  fi
  bad "命令成功但辅助集合里没找到 $BUNDLE_ID"
  return 1
}

SUCCESS=""
run() { local n="$1"; shift; if [ -z "$SUCCESS" ] && attempt "$n" "$@"; then SUCCESS="$n"; fi; }

# 只做辅助集合：-n aux；显式给 aux 路径；-L 不生成 system 集合；-z 跳过本地签名检查
if has --new && has --auxiliary-path; then
  run S1-aux-explicit create -n aux -L -z --variant-suffix release -A "$AUX" -R /
  run S2-aux-no-L  create -n aux -z --variant-suffix release -A "$AUX" -R /
  run S3-aux-nosuffix create -n aux -L -z -A "$AUX" -R /
fi
# 最后退回原命令，仅作对照
run S4-install install --update-all

say "结果"
AUX_AFTER=$(shasum -a 256 "$AUX" 2>/dev/null | cut -d' ' -f1)
printf 'aux sha256: %s -> %s\n' "${AUX_BEFORE:-none}" "${AUX_AFTER:-none}"

if [ -n "$SUCCESS" ]; then
  printf '策略 %s 成功。\n' "$SUCCESS"
  ls -l "$AUX" | sed 's/^/  /'
  {
    printf 'verdict: AUX_REBUILT\n'
    printf 'strategy: %s\n' "$SUCCESS"
    printf 'build: %s\n' "$(sw_vers -buildVersion)"
    printf 'aux_sha256_before: %s\n' "${AUX_BEFORE:-none}"
    printf 'aux_sha256_after: %s\n' "${AUX_AFTER:-none}"
    printf 'bundle: %s\n' "$BUNDLE_ID"
  } > "$OUT/fix-report.txt"
  say "现在重启：sudo reboot"
  printf '重启后运行 G1-一键诊断.command 确认加载。\n'
  rc=0
else
  printf '所有策略都没成功。错误摘要：\n'
  for f in "$OUT"/S*.log; do
    [ -f "$f" ] || continue
    printf '\n--- %s\n' "$(basename "$f")"
    grep -E 'Error|failed|Could not|Read-only|unknown|Usage|not found' "$f" | head -6 | sed 's/^/  /'
  done
  {
    printf 'verdict: ALL_STRATEGIES_FAILED\n'
    printf 'build: %s\n' "$(sw_vers -buildVersion)"
    printf 'aux_sha256_before: %s\n' "${AUX_BEFORE:-none}"
    printf 'aux_sha256_after: %s\n' "${AUX_AFTER:-none}"
  } > "$OUT/fix-report.txt"
  rc=5
fi

printf '\n日志目录: %s\n' "$OUT"
cp -R "$OUT" "$HOME/Desktop/" 2>/dev/null || true
exit "$rc"
