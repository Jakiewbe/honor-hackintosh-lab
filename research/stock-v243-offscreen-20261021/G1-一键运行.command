#!/bin/bash
# ============================================================================
#  G1 一键脚本（双击运行，也可以在终端里 bash 运行）
#
#  它做三件事，全部离线：
#    1. 清掉 Finder 写的 .DS_Store（否则仓库检查会失败）
#    2. 跑 14 项 preflight，结果存成 JSON 放到 results/ 里，方便你回传
#    3. 如果 preflight 全过，问你要不要接着编译（20-40 分钟）
#
#  这个脚本不安装、不加载、不写 KC / NVRAM、不需要 sudo。
#  LOAD NO-GO：安装与回退入口在审计后已被禁用。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"

# 交付时随 U 盘附带 expected-commit.txt（外部给定，不取当前 HEAD）。
# 缺这个文件就停，避免把"碰巧等于 HEAD"当成已审版本。
EXPECTED_FILE="$HERE/expected-commit.txt"
if [ ! -f "$EXPECTED_FILE" ]; then
  printf '!! 缺少 %s\n' "$EXPECTED_FILE"
  printf '   这个文件由交付方写在 U 盘里，内容是一行 40 位提交号。\n'
  printf '   没有它就说明文件夹不完整，请重新拷贝整个目录。\n'
  exit 3
fi
EXPECTED_COMMIT="$(tr -d '[:space:]' < "$EXPECTED_FILE")"
case "$EXPECTED_COMMIT" in
  *[!0-9a-f]*|'') printf '!! expected-commit.txt 内容不是 40 位十六进制\n'; exit 3 ;;
esac
[ "${#EXPECTED_COMMIT}" -eq 40 ] || { printf '!! expected-commit.txt 长度不是 40\n'; exit 3; }

REPO="${REPO:-$HERE/g1-repo}"
export NM_SRC="${NM_SRC:-$HERE/g1-src/nm}"
export NV_SRC="${NV_SRC:-$HERE/g1-src/nv}"
export G1_TOOLS="${G1_TOOLS:-$HERE/g1-tools}"
export G1_EXPECTED_COMMIT="$EXPECTED_COMMIT"
PYTHON="${PYTHON:-python3}"
RESULTS="$HERE/results"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="${WORK:-$HOME/Desktop/g1-runs/$STAMP}"

line() { printf '%s\n' "------------------------------------------------------------------"; }
say()  { printf '\n== %s\n' "$*"; }
bad()  { printf '!! %s\n' "$*"; }

printf 'G1 一键脚本  %s\n' "$(date)"
line

# ---------------------------------------------------------------- 0. 基本检查
[ "$(uname -s)" = "Darwin" ] || { bad "这个脚本只能在 macOS 上运行"; exit 2; }
[ -f "$REPO/scripts/g1/offline_build.py" ] || { bad "找不到 $REPO/scripts/g1/offline_build.py"; exit 2; }
command -v "$PYTHON" >/dev/null 2>&1 || { bad "找不到 python3（需要 Command Line Tools）"; exit 2; }
mkdir -p "$RESULTS"

# 仓库必须就是交付的那个提交
HEAD="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
if [ "$HEAD" != "$EXPECTED_COMMIT" ]; then
  bad "仓库提交不是交付版本"
  printf '   仓库: %s\n' "${HEAD:-读不到}"
  printf '   期望: %s\n' "$EXPECTED_COMMIT"
  printf '   处理: 重新拷贝完整的 HONOR-G1-FIRST-TOUCH 文件夹\n'
  exit 3
fi
printf '仓库提交: %s  (与交付一致)\n' "${HEAD:0:12}"

# ---------------------------------------------------------------- 1. 清元数据
say "清理 Finder 元数据"
find "$REPO" -name .DS_Store -type f -delete 2>/dev/null
find "$REPO" -name '._*' -type f -delete 2>/dev/null
find "$HERE/g1-src" -name .DS_Store -type f -delete 2>/dev/null
find "$HERE/g1-src" -name '._*' -type f -delete 2>/dev/null
printf '完成\n'

# ---------------------------------------------------------------- 2. preflight
say "preflight（14 项，几秒）"
printf '工作目录（本次新建）: %s\n' "$WORK"
mkdir -p "$(dirname "$WORK")"

PRE="$RESULTS/preflight-$STAMP.json"
"$PYTHON" "$REPO/scripts/g1/offline_build.py" preflight \
  --repo "$REPO" \
  --expected-commit "$EXPECTED_COMMIT" \
  --nm "$NM_SRC" --nv "$NV_SRC" \
  --make-archive "$G1_TOOLS/make-4.4.1.tar.gz" \
  --work "$WORK" >"$PRE" 2>&1
RC=$?

# 同时放一份到桌面，方便直接拖进聊天窗口
cp "$PRE" "$HOME/Desktop/preflight-$STAMP.json" 2>/dev/null || true

STATUS="$("$PYTHON" - "$PRE" <<'PY' 2>/dev/null
import json, sys
try:
    print(json.load(open(sys.argv[1], encoding='utf-8')).get('status', 'UNKNOWN'))
except Exception:
    print('UNREADABLE')
PY
)"
case "$STATUS" in
  PASS) printf '结果: PASS\n' ;;
  *)    printf '结果: %s\n' "$STATUS" ;;
esac

FAILED="$("$PYTHON" - "$PRE" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding='utf-8'))
    for c in d.get('checks', []):
        if c.get('status') != 'PASS':
            print('   - %s: %s' % (c.get('id'), str(c.get('error', ''))[:160]))
except Exception:
    pass
PY
)"
[ -n "$FAILED" ] && { printf '未通过项:\n%s\n' "$FAILED"; }

printf '\n报告已保存:\n   %s\n   %s\n' "$PRE" "$HOME/Desktop/preflight-$STAMP.json"

if [ "$STATUS" != "PASS" ]; then
  line
  printf 'preflight 没过，按上面的项修；把 preflight-%s.json 发回即可。\n' "$STAMP"
  printf '（常见：SDK 不是 15.5、.DS_Store 未清、WORK 用了旧目录、空间不足 8 GB）\n'
  exit "$RC"
fi

# ---------------------------------------------------------------- 3. 可选编译
line
printf 'preflight 全过。要继续编译吗？大约 20-40 分钟，全程离线。\n'
printf '继续请输入 BUILD（直接回车退出）: '
read -r answer || answer=""
if [ "$answer" != "BUILD" ]; then
  printf '已退出，未编译。下次运行本脚本会重新 preflight。\n'
  exit 0
fi

say "编译 / 链接"
BUILD_LOG="$RESULTS/build-$STAMP.txt"
"$PYTHON" "$REPO/scripts/g1/offline_build.py" build \
  --repo "$REPO" \
  --expected-commit "$EXPECTED_COMMIT" \
  --nm "$NM_SRC" --nv "$NV_SRC" \
  --make-archive "$G1_TOOLS/make-4.4.1.tar.gz" \
  --work "$WORK" >"$BUILD_LOG" 2>&1
BRC=$?
cp "$BUILD_LOG" "$HOME/Desktop/build-$STAMP.txt" 2>/dev/null || true

BSTATUS="$("$PYTHON" - "$BUILD_LOG" <<'PY' 2>/dev/null
import json, sys
try:
    text = open(sys.argv[1], encoding='utf-8', errors='replace').read()
    start = text.find('{')
    data = json.loads(text[start:]) if start >= 0 else {}
    print(data.get('status', 'UNKNOWN'))
except Exception:
    print('UNREADABLE')
PY
)"
printf '\n编译结果: %s\n' "$BSTATUS"
[ -n "${WORK:-}" ] && printf '本次产物目录: %s\n' "$(ls -d "$WORK"/run-* 2>/dev/null | tail -1)"
printf '日志: %s\n' "$BUILD_LOG"
line
printf '把 results/ 里这两个文件发回即可：\n'
printf '   preflight-%s.json\n   build-%s.txt\n' "$STAMP" "$STAMP"
exit "$BRC"
