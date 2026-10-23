#!/bin/bash
# ============================================================================
#  G1 修复加载（v3，按上游 install.sh 的做法重写）
#
#  上游 nullmoth/nvidia-macos-driver 的 package/install.sh 早就绕过了我们踩的坑：
#    * 不调 `kmutil install --update-all`（那会重写只读系统卷上的 Boot/System 集合）
#    * 只建辅助集合：kmutil create -n aux -B <BootKC> -S <SystemKC>
#                      --repository <目录> -A <输出> -z --allow-missing-kdk
#    * 先在临时目录建一份测试集合，用 `kmutil inspect -a x86_64 -A` 确认包含
#      com.nullmoth.NVRM，再建正式集合、原子替换、替换前备份。
#    * kext 必须 root:wheel 且不可被其他用户写，否则 kmutil 会静默跳过。
#
#  本脚本完全照这个流程做，只重建辅助集合，不写系统卷、不改 boot-args、不动 EFI。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/results/fix3-$STAMP"
EXT=/Library/Extensions
KC=/Library/KernelCollections/AuxiliaryKernelExtensions.kc
KB=/System/Library/KernelCollections/BootKernelExtensions.kc
KS=/System/Library/KernelCollections/SystemKernelExtensions.kc
K=/System/Library/Kernels/kernel
BUNDLE=com.nullmoth.NVRM
mkdir -p "$OUT" 2>/dev/null || OUT="$HOME/Desktop/g1-fix3-$STAMP"

say() { printf '\n== %s\n' "$*"; }
bad() { printf '!! %s\n' "$*"; }
die() { bad "$*"; printf '日志: %s\n' "$OUT"; exit 5; }

[ "$(uname -s)" = "Darwin" ] || { bad "只能在 macOS 上运行"; exit 2; }
[ -d "$EXT/NVRM.kext" ] || { bad "$EXT/NVRM.kext 不存在，先装候选"; exit 2; }
if kextstat 2>/dev/null | grep -q NVRM; then say "NVRM 已经加载，不需要修"; exit 0; fi

say "现状"
printf 'build: %s\n' "$(sw_vers -buildVersion)"
printf 'KDK:   %s\n' "$(ls -1 /Library/Developer/KDKs 2>/dev/null | tr '\n' ' ')"
printf 'aux:   %s\n' "$(ls -l "$KC" 2>/dev/null || echo 缺失)"
printf '输入集合: %s / %s\n' "$KB" "$KS"
AUX_BEFORE=$(shasum -a 256 "$KC" 2>/dev/null | cut -d' ' -f1)

sudo -v || { bad "需要 sudo"; exit 2; }

# 从 U 盘/exFAT 拷过来的 kext 会丢掉可执行位（诊断里看到 Contents/MacOS/NVRM 是 0644）。
# 先把已安装的 bundle 权限修正成标准形态，再建集合。
say "0. 修正 bundle 权限"
sudo chown -R root:wheel "$EXT/NVRM.kext" 2>/dev/null
sudo chmod 0755 "$EXT/NVRM.kext/Contents/MacOS" 2>/dev/null
sudo chmod 0755 "$EXT/NVRM.kext/Contents/MacOS/NVRM" 2>/dev/null
sudo chmod 0644 "$EXT/NVRM.kext/Contents/Info.plist" 2>/dev/null
sudo chmod -R go-w "$EXT/NVRM.kext" 2>/dev/null
ls -l "$EXT/NVRM.kext/Contents/MacOS/NVRM" | sed 's/^/   /'

# 与上游一致：允许缺 KDK；有 /System/Library/Kernels/kernel 就一并给出
EXTRA="--allow-missing-kdk"
[ -f "$K" ] && EXTRA="$EXTRA --kernel $K"

T=$(sudo mktemp -d /tmp/g1-aux.XXXXXX) || die "建临时目录失败"

# ---- 1. 测试集合 -----------------------------------------------------------
say "1. 建测试集合（不动系统）"
sudo mkdir -p "$T/repo"
sudo cp -R "$EXT/." "$T/repo/" || die "复制扩展目录失败"
# 上游注释：macOS 26 的 kmutil 会静默跳过非 root 拥有的 kext
sudo chown -R root:wheel "$T/repo" || die "chown 失败"
sudo chmod -R go-w "$T/repo" || die "chmod 失败"

sudo kmutil create -n aux --volume-root / $EXTRA \
  -B "$KB" -S "$KS" --repository "$T/repo" -A "$T/aux.kc" -z >"$OUT/test-build.log" 2>&1
test_rc=$?
tail -8 "$OUT/test-build.log" | sed 's/^/   /'
[ "$test_rc" -eq 0 ] || die "测试集合构建失败"
[ -s "$T/aux.kc" ] || die "测试集合没有产物"

sudo kmutil inspect -a x86_64 -A "$T/aux.kc" >"$OUT/test-inspect.txt" 2>&1
if grep -q "$BUNDLE" "$OUT/test-inspect.txt"; then
  printf '   测试集合里已包含 %s\n' "$BUNDLE"
else
  die "测试集合里没有 $BUNDLE（kmutil 可能跳过了它，看 test-build.log）"
fi

# ---- 2. 备份 + 正式集合 ----------------------------------------------------
say "2. 备份现有辅助集合并建正式集合"
sudo cp -p "$KC" "$OUT/AuxiliaryKernelExtensions.kc.before" 2>/dev/null || printf '   （无旧集合可备份）\n'
NEWKC="$KC.g1-new"
sudo rm -f "$NEWKC"
sudo kmutil create -n aux --volume-root / $EXTRA \
  -B "$KB" -S "$KS" --repository "$EXT" -A "$NEWKC" -z >"$OUT/live-build.log" 2>&1
live_rc=$?
tail -8 "$OUT/live-build.log" | sed 's/^/   /'
[ "$live_rc" -eq 0 ] || die "正式集合构建失败"
[ -s "$NEWKC" ] || die "正式集合没有产物"

sudo kmutil inspect -a x86_64 -A "$NEWKC" >"$OUT/live-inspect.txt" 2>&1
grep -q "$BUNDLE" "$OUT/live-inspect.txt" || die "正式集合里没有 $BUNDLE"

sudo mv -f "$NEWKC" "$KC" || die "发布新集合失败"
sudo chmod 0644 "$KC" 2>/dev/null || true
sudo rm -rf "$T"

AUX_AFTER=$(shasum -a 256 "$KC" 2>/dev/null | cut -d' ' -f1)

say "结果"
printf 'aux sha256: %s -> %s\n' "${AUX_BEFORE:-none}" "${AUX_AFTER:-none}"
printf '集合内容（含 NVRM 的行）:\n'
grep -i 'nullmoth\|NVRM' "$OUT/live-inspect.txt" | head -6 | sed 's/^/   /'
{
  printf 'verdict: AUX_REBUILT_UPSTREAM_RECIPE\n'
  printf 'build: %s\n' "$(sw_vers -buildVersion)"
  printf 'aux_sha256_before: %s\n' "${AUX_BEFORE:-none}"
  printf 'aux_sha256_after: %s\n' "${AUX_AFTER:-none}"
  printf 'bundle: %s\n' "$BUNDLE"
  printf 'boot_args: %s\n' "$(nvram boot-args 2>/dev/null | sed -n 's/.*boot-args[[:space:]]*//p')"
  printf 'recipe: kmutil create -n aux --volume-root / --allow-missing-kdk -B Boot -S System --repository %s -A <out> -z\n' "$EXT"
} > "$OUT/fix-report.txt"

say "集合已重建。重启方式二选一"
printf '  保守（加载但不初始化 GPU）：\n'
printf '    sudo nvram boot-args="$(nvram boot-args | sed -n "s/.*boot-args[[:space:]]*//p") -nvrmnogo"\n'
printf '    sudo reboot\n'
printf '  直接（auto-go 约 10 秒后尝试初始化 GPU）：\n'
printf '    sudo reboot\n'
printf '  说明：驱动自带启动守卫，连续两次启动没把显示拉起来会自己关掉并退回固件帧缓冲。\n'
printf '\n回退：把 %s/AuxiliaryKernelExtensions.kc.before 拷回 %s\n' "$OUT" "$KC"
printf '重启后跑 G1-一键诊断.command 确认加载。\n'
printf '\n日志: %s\n' "$OUT"
cp -R "$OUT" "$HOME/Desktop/" 2>/dev/null || true
exit 0
