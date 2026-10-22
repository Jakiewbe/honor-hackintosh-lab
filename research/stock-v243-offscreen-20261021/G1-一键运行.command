#!/bin/bash
# ============================================================================
#  G1 一键脚本（双击运行，也可以在终端里 bash 运行）
#
#  1. 只删除"未被 Git 跟踪"的 Finder 元数据（.DS_Store / ._*），被跟踪的文件绝不动
#  2. 跑 14 项 preflight，报告存到 results/，并复制一份到桌面
#  3. 只有【退出码 0 且报告完整 PASS】才允许询问是否编译
#
#  不安装、不加载、不写 KC / NVRAM、不需要 sudo。LOAD NO-GO。
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"

# 期望提交由交付方写在 expected-commit.txt（外部给，不取当前 HEAD）
EXPECTED_FILE="$HERE/expected-commit.txt"
if [ ! -f "$EXPECTED_FILE" ]; then
  printf '!! 缺少 %s\n' "$EXPECTED_FILE"
  printf '   这个文件由交付方写在 U 盘里，内容是一行 40 位提交号。\n'
  exit 3
fi
EXPECTED_COMMIT="$(tr -d '[:space:]' < "$EXPECTED_FILE")"
[ "${#EXPECTED_COMMIT}" -eq 40 ] || { printf '!! expected-commit.txt 长度不是 40\n'; exit 3; }
case "$EXPECTED_COMMIT" in
  *[!0-9a-f]*) printf '!! expected-commit.txt 不是 40 位十六进制\n'; exit 3 ;;
esac

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
command -v git >/dev/null 2>&1 || { bad "找不到 git（需要 Command Line Tools）"; exit 2; }
mkdir -p "$RESULTS"

HEAD="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
if [ "$HEAD" != "$EXPECTED_COMMIT" ]; then
  bad "仓库提交不是交付版本"
  printf '   仓库: %s\n   期望: %s\n' "${HEAD:-读不到}" "$EXPECTED_COMMIT"
  printf '   处理: 重新拷贝完整的 HONOR-G1-FIRST-TOUCH 文件夹\n'
  exit 3
fi
printf '仓库提交: %s  (与交付一致)\n' "${HEAD:0:12}"

# ---------------------------------------------------------------- 1. 只清未跟踪的元数据
say "清理未跟踪的 Finder 元数据（被 Git 跟踪的文件不碰）"
# --others lists every untracked path, including ones a global ignore hides (some setups ignore
# .DS_Store globally); the name filter below is what decides, never the ignore configuration.
git -C "$REPO" ls-files --others -z 2>/dev/null |
while IFS= read -r -d '' rel; do
  case "$(basename "$rel")" in
    .DS_Store|._*) rm -f -- "$REPO/$rel"; printf '   removed %s\n' "$rel" ;;
  esac
done
# g1-src 两棵树不删任何东西：preflight 对它们只容忍未跟踪的 Finder 元数据。

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
cp "$PRE" "$HOME/Desktop/preflight-$STAMP.json" 2>/dev/null || true

# 判定：退出码 0 且 报告完整通过（每项 PASS、计数一致、提交绑定一致）
read -r STATUS VERDICT FAILED <<EOF
$("$PYTHON" - "$PRE" "$EXPECTED_COMMIT" <<'PY'
import json, sys
path, expected = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(path, encoding='utf-8'))
except Exception:
    print('UNREADABLE 0 UNREADABLE'); raise SystemExit(0)
checks = d.get('checks') or []
status = d.get('status', 'UNKNOWN')
failed = ' '.join('%s:%s' % (c.get('id'), str(c.get('error',''))[:80]) for c in checks if c.get('status') != 'PASS')
complete = (status == 'PASS' and len(checks) >= 14 and d.get('check_count') == len(checks)
            and d.get('repo_commit') == expected
            and all(c.get('status') == 'PASS' for c in checks))
print('%s %d %s' % (status, 1 if complete else 0, failed.replace('\n',' ') or '-'))
PY
)
EOF

STATUS="${STATUS:-UNREADABLE}"; VERDICT="${VERDICT:-0}"; FAILED="${FAILED:--}"
printf '退出码: %s | 报告: %s | 完整通过: %s\n' "$RC" "$STATUS" "$VERDICT"
[ "$FAILED" != "-" ] && printf '未通过项: %s\n' "$FAILED"
printf '报告已保存:\n   %s\n   %s\n' "$PRE" "$HOME/Desktop/preflight-$STAMP.json"

if [ "$RC" -ne 0 ] || [ "$VERDICT" != "1" ]; then
  line
  if [ "$RC" -eq 0 ] && [ "$STATUS" = "PASS" ]; then
    bad "退出码与报告不一致（退出码 0 但报告不完整），按失败处理"
  elif [ "$RC" -ne 0 ] && [ "$STATUS" = "PASS" ]; then
    bad "退出码非零但报告显示 PASS，按失败处理"
  fi
  printf 'preflight 未通过，不会进入编译。把 preflight-%s.json 发回即可。\n' "$STAMP"
  exit 4
fi

# ---------------------------------------------------------------- 3. 可选编译
line
printf 'preflight 全过。要继续编译吗？大约 20-40 分钟，全程离线。\n'
printf '继续请输入 BUILD（直接回车退出）: '
read -r answer || answer=""
if [ "$answer" != "BUILD" ]; then
  printf '已退出，未编译。下次运行会重新 preflight。\n'
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

read -r BSTATUS BOK <<EOF
$("$PYTHON" - "$BUILD_LOG" <<'PY'
import json, sys
text = open(sys.argv[1], encoding='utf-8', errors='replace').read()
start = text.find('{')
try:
    d = json.loads(text[start:]) if start >= 0 else {}
except Exception:
    d = {}
ok = (d.get('status') == 'PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU'
      and not d.get('error')
      and set((d.get('artifacts') or {})) == {'NVRM','NVRMFB','NVAccel'})
print('%s %d' % (d.get('status', 'UNKNOWN'), 1 if ok else 0))
PY
)
EOF

BSTATUS="${BSTATUS:-UNREADABLE}"; BOK="${BOK:-0}"
printf '\n退出码: %s | 结果: %s | 三产物齐全: %s\n' "$BRC" "$BSTATUS" "$BOK"
[ -n "${WORK:-}" ] && printf '本次产物目录: %s\n' "$(ls -d "$WORK"/run-* 2>/dev/null | tail -1)"
printf '日志: %s\n' "$BUILD_LOG"

if [ "$BRC" -ne 0 ] || [ "$BOK" != "1" ]; then
  line
  bad "编译未通过（退出码与结果需同时成立）"
  exit 5
fi

line
printf '编译/链接完成。这不是加载，也不是 GPU 执行：LOAD NO-GO / GPU NOT RUN。\n'
printf '把 results/ 里的这两个文件发回：\n   preflight-%s.json\n   build-%s.txt\n' "$STAMP" "$STAMP"
exit 0
