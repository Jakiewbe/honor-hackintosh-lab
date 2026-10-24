#!/bin/bash
# ============================================================================
#  G1 装固件 v2
#
#  用法（三种都行）：
#    bash G1-装固件.command                     # 自动在常见位置找
#    bash G1-装固件.command /path/to/dir        # 给定目录
#    bash G1-装固件.command /path/to/x.tar.gz   # 给定发行包（.tar.gz/.tgz/.dmg/.run 都行）
#
#  它做四件事，全部离线，不联网：
#    1. 找 gsp_ga10x.bin / ucodes_ga10x.bin
#       （.tar.gz 解开；.dmg 挂载；.run 用 --extract-only，都不安装任何东西）
#    2. 按驱动里写死的表核对字节数和 SHA-1
#    3. 装到 /Library/NullMoth/nvfw/nvidia/610.57.04/，root:wheel 0644
#    4. 打印判决 + 重启后该看到什么
#
#  为什么是这个路径：kexts/NVRM/os-xnu2.cpp:29
#    #define NV_XNU_FW_DIR "/Library/NullMoth/nvfw/nvidia/610.57.04/"
#  为什么必须核对：os-xnu2.cpp:1199 的 nv_xnu_fw_set[] 里每个文件都有字节数和
#    SHA-1，不符就打印 "is not the image this driver shipped ... refusing it"。
#
#  !! 不要运行发行包里的 install.sh —— 那会把我们编译的 kext 和 KC 换掉。本脚本只取固件。
# ============================================================================
set -uo pipefail
VERSION=v2
echo "==== G1 装固件 $VERSION ===="

[ "$(uname -s)" = Darwin ] || { echo "!! 只能在 macOS 上运行"; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd -P)"

# results/ 可能在只读 U 盘上：能写就写旁边，不能写退桌面
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/results/fw-$STAMP"
if ! mkdir -p "$OUT" 2>/dev/null; then
  OUT="$HOME/Desktop/g1-fw-$STAMP"; mkdir -p "$OUT" 2>/dev/null
fi
LOG="$OUT/run.log"
exec > >(tee -a "$LOG")
exec 2>&1
MNT=""; EXTRACTED=""

say() { printf '\n== %s\n' "$*"; }
cleanup() { [ -z "$MNT" ] || hdiutil detach "$MNT" -quiet 2>/dev/null; }
trap cleanup EXIT

# ---- 0. 环境 ---------------------------------------------------------------
say "0. 环境"
sw_vers
ls -ld /Library/NullMoth /Library/NullMoth/nvfw/nvidia/610.57.04 2>/dev/null \
  || echo "   （/Library/NullMoth 还不存在，等一下创建）"

# ---- 1. 找文件 -------------------------------------------------------------
FW_NAMES='gsp_ga10x.bin gsp_tu10x.bin ucodes_ga10x.bin ucodes_tu10x.bin gsp_log_ga10x.bin'

hunt() {   # hunt <dir> → 打印找到的固件路径
  local d="$1" n
  [ -d "$d" ] || return 0
  for n in $FW_NAMES; do
    find "$d" -type f -name "$n" 2>/dev/null
  done
}

PREP="$OUT/prep"; mkdir -p "$PREP"
SRC="${1:-}"

prepare() {   # prepare <path> → 设置 SEARCH
  local s="$1"
  [ -e "$s" ] || { echo "!! 路径不存在: $s"; return 1; }
  if [ -d "$s" ]; then SEARCH="$s"; return 0; fi
  case "$s" in
    *.tar.gz|*.tgz)  say "1. 解包 $(basename "$s")"
                     tar -xzf "$s" -C "$PREP" || { echo "!! 解包失败"; return 1; } ;;
    *.tar.xz|*.txz)  say "1. 解包 $(basename "$s")"
                     tar -xJf "$s" -C "$PREP" || { echo "!! 解包失败"; return 1; } ;;
    *.tar.bz2)       say "1. 解包 $(basename "$s")"
                     tar -xjf "$s" -C "$PREP" || { echo "!! 解包失败"; return 1; } ;;
    *.zip)           say "1. 解包 $(basename "$s")"
                     unzip -q "$s" -d "$PREP" || { echo "!! 解包失败"; return 1; } ;;
    *.dmg)           say "1. 挂载 $(basename "$s")（只读，不安装）"
                     MNT="$PREP/dmg"; mkdir -p "$MNT"
                     hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$s" >/dev/null \
                       || { echo "!! 挂载失败"; return 1; }
                     SEARCH="$MNT"; return 0 ;;
    *.run)           say "1. 解包 $(basename "$s")（--extract-only，不安装）"
                     sh "$s" --extract-only --target "$PREP" || { echo "!! 解包失败"; return 1; } ;;
    *)               echo "!! 不认识的文件类型: ${s}（可以给目录，或 .tar.gz/.dmg/.run/.zip）"; return 1 ;;
  esac
  SEARCH="$PREP"; return 0
}

if [ -n "$SRC" ]; then
  prepare "$SRC" || exit 5
else
  say "1. 没给参数，自动找（只在这些位置找，别处不动）"
  for d in "$HERE/固件" "$HERE/firmware" "$HERE/nvfw" "$HERE" "$HOME/Downloads" "$HOME/Desktop"; do
    if [ -n "$(hunt "$d" | head -1)" ]; then SEARCH="$d"; printf '   命中: %s\n' "$d"; break; fi
  done
  [ -n "${SEARCH:-}" ] || {
    echo "!! 常见位置里都没找到固件"
    echo "   找过: $HERE/固件  $HERE/firmware  $HERE/nvfw  $HERE  ~/Downloads  ~/Desktop"
    echo "   要么把 gsp_ga10x.bin 放进 $HERE/固件/，要么给出路径："
    echo "     bash G1-装固件.command /path/to/pkg"
    exit 5
  }
fi

say "2. 找固件文件（${SEARCH}）"
LIST="$OUT/found.txt"; : > "$LIST"
hunt "$SEARCH" >> "$LIST"
sort -u "$LIST" -o "$LIST"
if [ ! -s "$LIST" ]; then
  echo "!! 在 ${SEARCH} 里没找到任何固件文件"
  echo "   找过: $FW_NAMES"
  echo "   如果是发行包，固件在 Users/Shared/nvfw/nvidia/610.57.04/ 下面"
  exit 5
fi
sed 's/^/   /' "$LIST"

# ---- 3. 核对 ---------------------------------------------------------------
say "3. 按驱动内建表核对（字节数 + SHA-1）"
EXPECT="
gsp_ga10x.bin 84310168 f11971026ccd86a7ea09ba525548c2e0615565ce
gsp_tu10x.bin 29381504 f20b8dc50f3576ec18c395c1b3b1cccc36bac194
ucodes_ga10x.bin 31744 1daf70f4f9a256212dead6f1ba88c694c5ae3af9
ucodes_tu10x.bin 12032 fe009104df714ad3d4233566aa0abb664614f8e9
"
expect_for() { printf '%s\n' "$EXPECT" | awk -v n="$1" '$1==n{print $2, $3}'; }

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
    printf '%-22s %12s B  %s\n' "$base" "$size" "$sha" | tee -a "$REPORT"
    printf '%-22s  期望 %s B / %s  → MISMATCH\n' '' "$esize" "$esha" | tee -a "$REPORT"
    BAD=$((BAD+1))
  fi
done < "$LIST"

[ "$BAD" -eq 0 ] || { echo "!! 有不符的文件，一个都没装"; exit 5; }
grep -q 'gsp_ga10x\.bin$' "$LIST" || { echo "!! 没有 gsp_ga10x.bin —— RTX 2050（GA107）必须要它"; exit 5; }

# ---- 4. 安装 ---------------------------------------------------------------
say "4. 安装到 /Library/NullMoth/nvfw/nvidia/610.57.04"
DEST=/Library/NullMoth/nvfw/nvidia/610.57.04
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
printf '   gsp_ga10x.bin sha1: '; shasum -a 1 "$DEST/gsp_ga10x.bin" 2>/dev/null | cut -d' ' -f1

{
  printf 'verdict: FIRMWARE_INSTALLED\n'
  printf 'script: %s\n' "$VERSION"
  printf 'dest: %s\n' "$DEST"
  printf 'verified_ok: %s  mismatch: %s\n' "$OK" "$BAD"
  printf 'source: %s\n' "${SRC:-（自动查找）$SEARCH}"
} > "$OUT/fw-report.txt"

say "下一步"
printf '  sudo reboot\n'
printf '  重启后：bash G1-一键诊断.command\n'
printf '  成功的样子（内核日志里会出现）：\n'
printf '    nv_get_firmware type=0 family=4 -> .../gsp_ga10x.bin\n'
printf '      firmware loaded: 84310168 bytes\n'
printf '  日志目录：%s\n' "$OUT"
exit 0
