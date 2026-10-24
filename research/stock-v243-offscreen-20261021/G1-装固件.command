#!/bin/bash
# ============================================================================
#  G1 装固件（v1）
#
#  用法：
#    bash G1-装固件.command /path/to/pkg            # 目录或驱动包都行
#
#  它做四件事，全部离线，不联网：
#    1. 在给定路径里找 gsp_ga10x.bin / ucodes_ga10x.bin
#       （如果给的是 .run 包，先用 --extract-only 解开；.tar.xz 也行）
#    2. 按驱动里写死的表核对字节数和 SHA-1
#    3. 装到 /Library/NullMoth/nvfw/nvidia/610.57.04/，root:wheel 0644
#    4. 打印判决
#
#  为什么是这个路径：os-xnu2.cpp:29 写死
#    #define NV_XNU_FW_DIR "/Library/NullMoth/nvfw/nvidia/610.57.04/"
#  为什么必须核对：os-xnu2.cpp:1199 的 nv_xnu_fw_set[] 里每个文件都有字节数
#  和 SHA-1，不符就打印 "is not the image this driver shipped ... refusing it"。
# ============================================================================
set -uo pipefail
VERSION=v1
echo "==== G1 装固件 $VERSION ===="

SRC="${1:-}"
[ -n "$SRC" ] || { echo "用法: bash G1-装固件.command /path/to/pkg"; exit 2; }
[ -e "$SRC" ] || { echo "!! 路径不存在: $SRC"; exit 2; }
[ "$(uname -s)" = Darwin ] || { echo "!! 只能在 macOS 上运行"; exit 2; }

DEST=/Library/NullMoth/nvfw/nvidia/610.57.04
STAMP="$(date +%Y%m%d-%H%M%S)"
HERE="$(cd "$(dirname "$0")" && pwd -P)"
OUT="$HERE/results/fw-$STAMP"
mkdir -p "$OUT" 2>/dev/null || OUT="$HOME/Desktop/g1-fw-$STAMP"
mkdir -p "$OUT" 2>/dev/null
LOG="$OUT/run.log"
exec > >(tee -a "$LOG")
exec 2>&1

# 驱动里的表：名字 字节数 SHA1
EXPECT="
gsp_ga10x.bin 84310168 f11971026ccd86a7ea09ba525548c2e0615565ce
gsp_tu10x.bin 29381504 f20b8dc50f3576ec18c395c1b3b1cccc36bac194
ucodes_ga10x.bin 31744 1daf70f4f9a256212dead6f1ba88c694c5ae3af9
ucodes_tu10x.bin 12032 fe009104df714ad3d4233566aa0abb664614f8e9
"
expect_for() { printf '%s\n' "$EXPECT" | awk -v n="$1" '$1==n{print $2, $3}'; }

say() { printf '\n== %s\n' "$*"; }

say "0. 环境"
sw_vers
ls -ld /Library/NullMoth "$DEST" 2>/dev/null || echo "   （/Library/NullMoth 还不存在，等下创建）"

# ---- 1. 找文件 -------------------------------------------------------------
SEARCH="$SRC"
if [ -f "$SRC" ]; then
  case "$SRC" in
    *.run)
      say "1. 解包 .run（--extract-only，不安装任何东西）"
      X="$OUT/extract"
      mkdir -p "$X"
      sh "$SRC" --extract-only --target "$X" || { echo "!! 解包失败"; exit 5; }
      SEARCH="$X"
      ;;
    *.tar.xz|*.tar.gz|*.tar.bz2|*.tgz|*.txz)
      say "1. 解包压缩包（只解包，不安装）"
      X="$OUT/extract"
      mkdir -p "$X"
      tar -xf "$SRC" -C "$X" || { echo "!! 解包失败"; exit 5; }
      SEARCH="$X"
      ;;
  esac
fi

say "2. 找固件文件（${SEARCH}）"
LIST="$OUT/found.txt"
: > "$LIST"
for n in gsp_ga10x.bin gsp_tu10x.bin ucodes_ga10x.bin ucodes_tu10x.bin gsp_log_ga10x.bin gsp_log_tu10x.bin; do
  find "$SEARCH" -type f -name "$n" 2>/dev/null >> "$LIST"
done
sort -u "$LIST" -o "$LIST"
if [ ! -s "$LIST" ]; then
  echo "!! 在 $SEARCH 里没找到任何固件文件"
  echo "   找过: gsp_ga10x.bin gsp_tu10x.bin ucodes_ga10x.bin ucodes_tu10x.bin gsp_log_*.bin"
  echo "   如果是 .run 包，解包后应出现在 NVIDIA-Linux-*/firmware/ 下"
  exit 5
fi
sed 's/^/   /' "$LIST"

# ---- 3. 核对 ---------------------------------------------------------------
say "3. 按驱动内建表核对（字节数 + SHA-1）"
OK=0; BAD=0; REPORT="$OUT/verify.txt"; : > "$REPORT"
while IFS= read -r f; do
  base="$(basename "$f")"
  size="$(stat -f %z "$f" 2>/dev/null)"
  sha="$(shasum -a 1 "$f" | cut -d' ' -f1)"
  exp="$(expect_for "$base")"
  if [ -z "$exp" ]; then
    printf '%-22s %12s B  %s  (表里没有，不校验)\n' "$base" "$size" "$sha" | tee -a "$REPORT"
    continue
  fi
  esize="${exp%% *}"; esha="${exp##* }"
  if [ "$size" = "$esize" ] && [ "$sha" = "$esha" ]; then
    printf '%-22s %12s B  %s  OK\n' "$base" "$size" "$sha" | tee -a "$REPORT"
    OK=$((OK+1))
  else
    printf '%-22s %12s B  %s  MISMATCH（期望 %s B / %s）\n' "$base" "$size" "$sha" "$esize" "$esha" | tee -a "$REPORT"
    BAD=$((BAD+1))
  fi
done < "$LIST"

[ "$BAD" -eq 0 ] || { echo "!! 有不符的文件，不安装"; exit 5; }

# ga10x 必须在：RTX 2050 是 GA107，日志已经证明它在要 gsp_ga10x.bin
grep -q 'gsp_ga10x\.bin$' "$LIST" || { echo "!! 没有 gsp_ga10x.bin —— RTX 2050（GA107）必须要它"; exit 5; }

# ---- 4. 安装 ---------------------------------------------------------------
say "4. 安装到 $DEST"
sudo -v || { echo "!! sudo 没拿到授权"; exit 2; }
sudo mkdir -p "$DEST" || { echo "!! 建目录失败"; exit 5; }
sudo chown root:wheel /Library/NullMoth /Library/NullMoth/nvfw /Library/NullMoth/nvfw/nvidia "$DEST" 2>/dev/null
sudo chmod 0755 /Library/NullMoth /Library/NullMoth/nvfw /Library/NullMoth/nvfw/nvidia "$DEST" 2>/dev/null

while IFS= read -r f; do
  sudo cp -f "$f" "$DEST/$(basename "$f")" || { echo "!! 拷贝失败: $f"; exit 5; }
done < "$LIST"
sudo chown root:wheel "$DEST"/* 2>/dev/null
sudo chmod 0644 "$DEST"/* 2>/dev/null

say "5. 落盘结果"
ls -l "$DEST" | sed 's/^/   /'
printf '   sha1: '; shasum -a 1 "$DEST/gsp_ga10x.bin" 2>/dev/null | cut -d' ' -f1

{
  printf 'verdict: FIRMWARE_INSTALLED\n'
  printf 'script: %s\n' "$VERSION"
  printf 'dest: %s\n' "$DEST"
  printf 'verified_ok: %s  mismatch: %s\n' "$OK" "$BAD"
  printf 'source: %s\n' "$SRC"
} > "$OUT/fw-report.txt"

say "下一步"
printf '  sudo reboot\n'
printf '  重启后：bash G1-一键诊断.command，看「内核 NV log」里是否出现\n'
printf '         nv_get_firmware ... firmware loaded: 84310168 bytes\n'
printf '  日志：%s\n' "$LOG"
cp -R "$OUT" "$HOME/Desktop/" 2>/dev/null || true
exit 0
