#!/bin/bash
# 用假 nvram / sysctl / log / kextstat / ioreg 在非 macOS 上完整跑一遍
# G1-试跑一次.command 的每条分支，断言退出码与关键输出。
#
# 跑法：bash tests/command_scripts/test_trial.sh
# 退出码 0 = 全部通过。
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
TARGET="$REPO/research/stock-v243-offscreen-20261021/G1-试跑一次.command"
STUBS="$REPO/tests/command_scripts/stubs"
PASS=0
FAIL=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---- 测试环境 -------------------------------------------------------------
setup() {
  WORK="$TMP/w$RANDOM"
  mkdir -p "$WORK/state" "$WORK/results" "$WORK/panics" "$WORK/lib"
  cp "$TARGET" "$WORK/lib/x.command"
  export G1_STATE_DIR="$WORK/state"
  export G1_PANIC_DIR="$WORK/panics"
  export G1_NVRAM_FILE="$WORK/nvram.txt"
  export G1_LOG_FIXTURE="$WORK/log.txt"
  export G1_NO_ELEVATE=1
  export G1_BOOT_EPOCH="$(date +%s)"
  export PATH="$STUBS:$PATH"
  : >"$G1_NVRAM_FILE"
  : >"$G1_LOG_FIXTURE"
}
run() { ( cd "$WORK/lib" && bash ./x.command "$@" 2>&1 ); }

ok()   { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; }
chk()  { # chk 描述 期望子串 实际输出
  case "$3" in *"$2"*) ok "$1" ;; *) bad "$1" "缺少 [$2]" ;; esac
}
chk_not() { case "$3" in *"$2"*) bad "$1" "不该出现 [$2]" ;; *) ok "$1" ;; esac; }
chk_rc() { if [ "$3" = "$2" ]; then ok "$1"; else bad "$1" "rc=$3 期望 $2"; fi; }

fixture_log() { # 写一段带所有关键标记的日志
  cat >"$G1_LOG_FIXTURE" <<'EOF'
2026-10-25 00:10:01.000000+0800 kernel NVRM: probe 10de:25a9 class 03.00 subsystem 103c:8a1f
2026-10-25 00:10:01.100000+0800 kernel NVRM: boot guard: start 1 without a display so far (the driver turns itself off after 2)
2026-10-25 00:10:02.000000+0800 kernel NVRM: PASS 1 REACHED: RM initialised, private state built, GSP firmware requested
2026-10-25 00:10:02.500000+0800 kernel NVRM: nv_get_firmware type=0 family=4 -> /Library/NullMoth/nvfw/nvidia/610.57.04/gsp_ga10x.bin
2026-10-25 00:10:02.600000+0800 kernel NVRM: firmware loaded: 84310168 bytes
2026-10-25 00:10:02.700000+0800 kernel NVRM: RmInitAdapter failed! (0x61:0x56:2025)
EOF
}

echo "== T1  go：写入守卫 1、解除闭嘴"
setup; OUT=$(run go); RC=$?
chk_rc "T1 退出码 0" 0 "$RC"
chk    "T1 报告 [1/2]"  "[1/2]" "$OUT"
chk    "T1 报告 [2/2]"  "[2/2]" "$OUT"
chk    "T1 提示重启"    "下一步：重启" "$OUT"
chk    "T1 守卫已写入"  "nullmoth-nv-starts" "$(cat "$G1_NVRAM_FILE")"
chk    "T1 守卫值 %01"  "%01" "$(cat "$G1_NVRAM_FILE")"
chk_not "T1 remove 已删除" "nullmoth-remove" "$(cat "$G1_NVRAM_FILE")"
[ -f "$G1_STATE_DIR/go-at" ] && ok "T1 写入 go-at 标记" || bad "T1 写入 go-at 标记"

echo "== T2  go：守卫写不进去必须中止，且不解闭嘴"
setup; printf 'nullmoth-remove\t1\n' >"$G1_NVRAM_FILE"
OUT=$(G1_STUB_FAIL_SET=nullmoth-nv-starts bash -c "$(declare -p G1_STATE_DIR G1_PANIC_DIR G1_NVRAM_FILE G1_LOG_FIXTURE G1_NO_ELEVATE G1_BOOT_EPOCH PATH 2>/dev/null); cd '$WORK/lib' && bash ./x.command go" 2>&1); RC=$?
chk_rc "T2 退出码 3" 3 "$RC"
chk    "T2 明确报错" "守卫写入失败" "$OUT"
chk    "T2 remove 仍在" "nullmoth-remove" "$(cat "$G1_NVRAM_FILE")"
[ -f "$G1_STATE_DIR/go-at" ] && bad "T2 不该写 go-at" || ok "T2 未写 go-at"

echo "== T3  go：remove 删不掉必须中止"
setup; printf 'nullmoth-remove	1
' >"$G1_NVRAM_FILE"
OUT=$(G1_STUB_FAIL_DEL=nullmoth-remove bash -c "$(declare -p G1_STATE_DIR G1_PANIC_DIR G1_NVRAM_FILE G1_LOG_FIXTURE G1_NO_ELEVATE G1_BOOT_EPOCH PATH 2>/dev/null); cd '$WORK/lib' && bash ./x.command go" 2>&1); RC=$?
chk_rc "T3 退出码 4" 4 "$RC"
chk    "T3 提示手动" "sudo nvram -d" "$OUT"

echo "== T4  report：没跑过 go"
setup; fixture_log; OUT=$(run report); RC=$?
chk_rc "T4 退出码 0" 0 "$RC"
chk    "T4 说明没跑过" "没跑过 go" "$OUT"
chk    "T4 仍然给历史日志" "firmware loaded" "$OUT"

echo "== T5  report：已重启，固件读到但 adapter 失败"
setup; fixture_log
echo "$(( $(date +%s) - 3600 ))" >"$G1_STATE_DIR/go-at"; echo "2026-10-25 00:09:00" >"$G1_STATE_DIR/go-at-readable"
OUT=$(run report); RC=$?
chk_rc "T5 退出码 0" 0 "$RC"
chk    "T5 判定已重启" "已重启过" "$OUT"
chk    "T5 结论固件读到" "固件被读到了" "$OUT"
chk    "T5 结论 adapter" "adapter 初始化失败" "$OUT"
chk    "T5 标记统计" "[1] firmware loaded" "$OUT"
chk    "T5 给出下一步" "下一步该做什么" "$OUT"

echo "== T6  report：还没重启"
setup; fixture_log
echo "$(( $(date +%s) + 3600 ))" >"$G1_STATE_DIR/go-at"; echo "2026-10-25 09:00:00" >"$G1_STATE_DIR/go-at-readable"
OUT=$(run report)
chk "T6 判定还没重启" "还没重启" "$OUT"

echo "== T7  report：有 panic 文件"
setup; fixture_log
printf 'panic(cpu 0 caller 0xffffff8012345678): NVRM fault\nRAX: 0x0 RBX: 0xffffff90\n' >"$WORK/panics/kernel-2026-10-25.panic"
OUT=$(run report)
chk "T7 找到 panic" "找到 panic 文件" "$OUT"
chk "T7 打印栈"   "panic(cpu 0 caller" "$OUT"

echo "== T8  report：固件没读到"
setup
printf '2026-10-25 00:10:01 kernel NVRM: probe 10de:25a9\n2026-10-25 00:10:02 kernel NVRM: nv_get_firmware type=0 family=4 -> /Library/NullMoth/x\n2026-10-25 00:10:02 kernel NVRM: vnode_open failed 2\n' >"$G1_LOG_FIXTURE"
OUT=$(run report)
chk "T8 结论 vnode_open" "固件仍然没读到" "$OUT"
chk "T8 给出 sha1 核验" "f11971026ccd86a7ea09ba525548c2e0615565ce" "$OUT"

echo "== T9  report：驱动没启动"
setup; printf '2026-10-25 00:10:01 kernel IOGraphics: display online\n' >"$G1_LOG_FIXTURE"
OUT=$(run report)
chk "T9 结论没 probe" "驱动这次没启动" "$OUT"
chk "T9 提示每轮都要 go" "每一轮实验都要先 go" "$OUT"

echo "== T10 status"
setup; printf 'nullmoth-nv-starts\t%%02\nnullmoth-remove\t1\n' >"$G1_NVRAM_FILE"
printf '163 0 0xffffff7f97174000 0xe47ff8 com.nullmoth.NVRM (0.1)\n' >"$WORK/kextstat.txt"
OUT=$(G1_KEXTSTAT_FIXTURE="$WORK/kextstat.txt" bash -c "$(declare -p G1_STATE_DIR G1_PANIC_DIR G1_NVRAM_FILE G1_LOG_FIXTURE G1_NO_ELEVATE G1_BOOT_EPOCH PATH 2>/dev/null); cd '$WORK/lib' && bash ./x.command status" 2>&1); RC=$?
chk_rc "T10 退出码 0" 0 "$RC"
chk "T10 显示守卫" "%02" "$OUT"
chk "T10 显示驱动" "com.nullmoth.NVRM" "$OUT"
chk "T10 显示上次 go" "上次 go" "$OUT"

echo "== T11 cancel"
setup; printf 'nullmoth-nv-starts\t%%01\n' >"$G1_NVRAM_FILE"
OUT=$(run cancel); RC=$?
chk_rc "T11 退出码 0" 0 "$RC"
chk "T11 写入 remove" "nullmoth-remove" "$(cat "$G1_NVRAM_FILE")"
chk_not "T11 守卫已清" "nullmoth-nv-starts" "$(cat "$G1_NVRAM_FILE")"

echo "== T12 未知子命令"
setup; OUT=$(run bogus); RC=$?
chk_rc "T12 退出码 2" 2 "$RC"
chk "T12 打印用法" "用法" "$OUT"

echo "== T13  报告落到 U 盘目录（results/）"
setup; OUT=$(run go)
N=$(ls -1 "$WORK/lib/results"/report-*.txt 2>/dev/null | wc -l | tr -d ' ')
[ "$N" = "1" ] && ok "T13 results/ 有报告" || bad "T13 results/ 有报告" "找到 $N 个"

echo "== T14  macOS 专有路径不可用时仍能跑（模拟 /usr/sbin 缺失）"
setup; OUT=$(run status); RC=$?
chk_rc "T14 退出码 0" 0 "$RC"

echo "== T15  报告永远不是 0 字节（早失败也留头）"
setup
OUT=$(G1_STUB_FAIL_SET=nullmoth-nv-starts run go); RC=$?
FIRST_REPORT=$(ls -1 "$G1_STATE_DIR"/report-*.txt 2>/dev/null | head -1)
if [ -n "$FIRST_REPORT" ] && [ -s "$FIRST_REPORT" ]; then
  ok "T15 报告非空"
else
  bad "T15 报告非空" "文件=${FIRST_REPORT:-无}"
fi
grep -q '^# G1 试跑报告' "$FIRST_REPORT" 2>/dev/null   && ok "T15 首行是报告头" || bad "T15 首行是报告头" "$(head -1 "$FIRST_REPORT" 2>/dev/null)"

printf '\n合计: PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ] || exit 1
