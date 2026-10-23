#!/bin/bash
# ============================================================================
#  G1 修复加载（v3.3）
#
#  只重建辅助集合 /Library/KernelCollections/AuxiliaryKernelExtensions.kc，
#  不写系统卷、不改 boot-args、不动 EFI。配方与上游 package/install.sh 一致：
#    kmutil create -n aux --volume-root / --allow-missing-kdk
#      -B <BootKernelExtensions.kc> -S <SystemKernelExtensions.kc>
#      --repository <目录> -A <输出> -z
#
#  v3.2 相对 v3.1 的变化：全流程 set -x 追踪写进 run.log；每次 kmutil 都记退出
#  码；用 --no-variant-extension 固定产物路径；kmutil 失败时自动抓 os_log
#  （kmutil 不少错误只走 unified logging，stdout/stderr 是空的），并按
#  +--kdk / +-a x86_64 -V release 顺序升级重试。
# ============================================================================
set -uo pipefail
VERSION=v3.3
echo "==== G1 修复加载 $VERSION ===="

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/results/fix3-$STAMP"
mkdir -p "$OUT" 2>/dev/null || OUT="$HOME/Desktop/g1-fix3-$STAMP"
mkdir -p "$OUT" 2>/dev/null
LOG="$OUT/run.log"
exec > >(tee -a "$LOG")
exec 2>&1

EXT=/Library/Extensions
KC=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
KB=/System/Library/KernelCollections/BootKernelExtensions.kc
KS=/System/Library/KernelCollections/SystemKernelExtensions.kc
K=/System/Library/Kernels/kernel
BUNDLE=com.nullmoth.NVRM
say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }
PS4='+ '

say "0. 环境"
[ "$(uname -s)" = Darwin ] || { echo "只能在 macOS 上运行"; exit 2; }
sw_vers
ls -d /Library/Developer/KDKs/*.kdk 2>/dev/null
ls -l "$KC" 2>/dev/null
AUX_BEFORE=$(shasum -a 256 "$KC" 2>/dev/null | cut -d' ' -f1)

[ -d "$EXT/NVRM.kext" ] || { bad "$EXT/NVRM.kext 不存在，先装候选"; exit 2; }
if kextstat 2>/dev/null | grep -q NVRM; then say "NVRM 已经加载，不需要修"; exit 0; fi

sudo -v || { bad "sudo 没拿到授权"; exit 2; }

say "1. 修正 bundle 权限（exFAT 拷贝会丢可执行位）"
sudo chown -R root:wheel "$EXT/NVRM.kext" 2>/dev/null
sudo chmod -R 755 "$EXT/NVRM.kext" 2>/dev/null
sudo chmod 644 "$EXT/NVRM.kext/Contents/Info.plist" 2>/dev/null
sudo chmod -R go-w "$EXT/NVRM.kext" 2>/dev/null
ls -l "$EXT/NVRM.kext/Contents/MacOS/NVRM"

T=$(sudo mktemp -d /tmp/g1-aux.XXXXXX) || { bad "建临时目录失败"; exit 5; }
say "2. 建测试集合（${T}，不动系统）"
sudo mkdir -p "$T/repo"
sudo cp -R "$EXT/." "$T/repo/" || { bad "复制扩展目录失败"; exit 5; }
sudo chown -R root:wheel "$T/repo"
sudo chmod -R go-w "$T/repo"

BASE=(--volume-root / --allow-missing-kdk -B "$KB" -S "$KS")
[ -f "$K" ] && BASE+=(--kernel "$K")
KDKP=$(ls -d /Library/Developer/KDKs/*.kdk 2>/dev/null | head -1)
BUILDNUM=$(sw_vers -buildVersion)

build_test() {
  local tag="$1"; shift
  local out="$T/aux-$tag.kc" rc
  echo "   ---- [$tag] kmutil create -n aux ${BASE[*]} --repository $T/repo -A $out -z --no-variant-extension $*"
  sudo kmutil create -n aux "${BASE[@]}" --repository "$T/repo" -A "$out" -z \
    --no-variant-extension "$@" >"$OUT/build-$tag.log" 2>&1
  rc=$?
  echo "   rc=$rc   目录："
  ls -l "$T" | sed 's/^/      /'
  sed 's/^/      | /' "$OUT/build-$tag.log"
  if [ "$rc" -ne 0 ]; then
    echo "   ---- kmutil 的 unified log（最后 6 分钟）:"
    sudo log show --last 6m --predicate 'process == "kmutil"' --style compact \
      >"$OUT/oslog-$tag.txt" 2>&1
    tail -25 "$OUT/oslog-$tag.txt" | sed 's/^/      /'
  fi
  return "$rc"
}

TEST_OK=0
if build_test exact; then TEST_OK=1
elif build_test kdk --kdk "$KDKP" --build "$BUILDNUM"; then TEST_OK=1
elif build_test arch --kdk "$KDKP" --build "$BUILDNUM" -a x86_64 -V release -v; then TEST_OK=1
fi

if [ "$TEST_OK" -ne 1 ]; then
  say "三次构建都失败，抓 kmutil 的 unified log"
  sudo log show --last 5m --predicate 'process == "kmutil"' --style compact \
    >"$OUT/kmutil-oslog.txt" 2>&1
  tail -40 "$OUT/kmutil-oslog.txt" | sed 's/^/   /'
  bad "测试集合构建失败（日志 ${LOG}）"
  exit 5
fi

AUXFILE=$(ls -1 "$T"/aux-*.kc 2>/dev/null | head -1)
[ -n "$AUXFILE" ] && [ -s "$AUXFILE" ] || { bad "没有产物文件"; exit 5; }

say "3. 验证测试集合含 $BUNDLE"
sudo kmutil inspect -a x86_64 -A "$AUXFILE" >"$OUT/test-inspect.txt" 2>&1
grep -i 'nullmoth' "$OUT/test-inspect.txt" | head -5
grep -q "$BUNDLE" "$OUT/test-inspect.txt" || {
  bad "测试集合里没有 ${BUNDLE}（kmutil 跳过了它）"
  grep -i 'highpoint\|iordma' "$OUT/test-inspect.txt" | head -5
  exit 5
}

say "4. 备份旧集合 + 建正式集合"
sudo cp -p "$KC" "$OUT/AuxiliaryKernelExtensions.kc.before" 2>/dev/null || \
  echo "   （无旧集合可备份）"
NEWKC="$KC.g1-new"
sudo rm -f "$NEWKC"
echo "   kmutil create -n aux ${BASE[*]} --repository $EXT -A $NEWKC -z --no-variant-extension"
sudo kmutil create -n aux "${BASE[@]}" --repository "$EXT" -A "$NEWKC" -z \
  --no-variant-extension >"$OUT/live-build.log" 2>&1
live_rc=$?
echo "   rc=$live_rc"
sed 's/^/   | /' "$OUT/live-build.log"
if [ "$live_rc" -ne 0 ] || [ ! -s "$NEWKC" ]; then
  sudo log show --last 3m --predicate 'process == "kmutil"' --style compact \
    >"$OUT/kmutil-oslog.txt" 2>&1
  tail -40 "$OUT/kmutil-oslog.txt" | sed 's/^/   /'
  bad "正式集合构建失败"
  exit 5
fi

sudo kmutil inspect -a x86_64 -A "$NEWKC" >"$OUT/live-inspect.txt" 2>&1
grep -q "$BUNDLE" "$OUT/live-inspect.txt" || { bad "正式集合里没有 $BUNDLE"; exit 5; }

say "5. 原子替换"
sudo mv -f "$NEWKC" "$KC" || { bad "替换失败"; exit 5; }
sudo chmod 0644 "$KC" 2>/dev/null
sudo rm -rf "$T"
AUX_AFTER=$(shasum -a 256 "$KC" 2>/dev/null | cut -d' ' -f1)

say "结果"
printf 'aux sha256: %s -> %s\n' "${AUX_BEFORE:-none}" "${AUX_AFTER:-none}"
printf '集合里的 nullmoth 条目：\n'
grep -i 'nullmoth' "$OUT/live-inspect.txt" | head -6 | sed 's/^/   /'
{
  printf 'verdict: AUX_REBUILT_UPSTREAM_RECIPE\n'
  printf 'script: %s\n' "$VERSION"
  printf 'build: %s\n' "$(sw_vers -buildVersion)"
  printf 'kdk: %s\n' "${KDKP:-none}"
  printf 'aux_sha256_before: %s\n' "${AUX_BEFORE:-none}"
  printf 'aux_sha256_after: %s\n' "${AUX_AFTER:-none}"
  printf 'bundle: %s\n' "$BUNDLE"
  printf 'boot_args: %s\n' "$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p')"
} > "$OUT/fix-report.txt"

say "重启"
printf '  sudo reboot\n'
printf '  首次重启若提示「系统扩展已被阻止」：系统设置 > 隐私与安全性 > 允许，再重启一次\n'
printf '  回退：sudo cp -p %s/AuxiliaryKernelExtensions.kc.before %s\n' "$OUT" "$KC"
printf '  日志：%s\n' "$LOG"
cp -R "$OUT" "$HOME/Desktop/" 2>/dev/null || true
exit 0
