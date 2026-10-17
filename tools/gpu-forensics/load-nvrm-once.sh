#!/bin/bash
# 一次性 KEXT-LOAD 取证：只加载 NVRM，采日志，然后立即卸载。
#
# 严格边界（脚本自己会检查，不满足就退出，不会"尽力而为"）：
#   * 只处理 /Library/Extensions 里已存在的 NVRM.kext —— 不复制、不安装、不替换任何文件
#   * 不加载 NVRMFB / NVAccel（它们会碰显示或加速；本次只回答"RM/GSP 能不能起来"）
#   * 不写 nvram、不改 SIP/AMFI/EFI、不重启
#   * 卸载失败或状态未回到基线 → 停下来报告，交由你决定是否重启
#
# 用法（需 root）:  sudo bash load-nvrm-once.sh
set -u

# ---------------------------------------------------------------------------
# 默认拒绝执行（2026-10-18 复审结论：P0-3）。
# 停止路径的安全闭环尚未验收（P0-1/P0-2 未关闭前不得进行真实加载）。启用需要：
#   1) 用户当场在实机侧确认；2) 显式创建 ack 文件；3) 设置环境变量。
# 缺任何一项，本脚本在改动任何状态之前退出。
ACK_FILE="${GPU_LOAD_EXPERIMENT_ACK_FILE:-$HOME/GPU-LOAD-EXPERIMENT-ACK}"
if [ "${GPU_LOAD_EXPERIMENT_ACK:-}" != "I_HOLD_A_ROLLBACK_PATH" ] || [ ! -f "$ACK_FILE" ]; then
    echo "已禁用：本次实验在复审后被禁止执行（停止安全未验收）。"
    echo "如确要执行，需用户当场确认并创建 $ACK_FILE，然后:"
    echo "  sudo GPU_LOAD_EXPERIMENT_ACK=I_HOLD_A_ROLLBACK_PATH bash $0"
    exit 90
fi
# ---------------------------------------------------------------------------

KEXT="/Library/Extensions/NVRM.kext"
# 脚本用 sudo 跑，但产物必须落在"发起者"的桌面，而不是 /var/root
OWNER="${SUDO_USER:-$USER}"
OWNER_HOME=$(eval echo "~$OWNER")
OUT="$OWNER_HOME/Desktop/gpu-forensics/$(date +%Y%m%d-%H%M%S)-load"
mkdir -p "$OUT" || exit 1
chown -R "$OWNER" "$OUT" 2>/dev/null || true
LOG="$OUT/load-session.log"
say() { printf '%s\n' "$*" | tee -a "$LOG"; }

say "=== NVRM 单次加载取证 $(date) ==="

# --- 前置检查 ---------------------------------------------------------------
[ "$(uname -s)" = "Darwin" ] || { say "不是 macOS，退出"; exit 2; }
[ "$(id -u)" = "0" ]         || { say "需要 root：sudo bash $0"; exit 2; }
[ -d "$KEXT" ]               || { say "$KEXT 不存在 —— 驱动没装，或路径不同。停止。"; exit 3; }

# 已加载就先别动，避免状态混乱
if kmutil showloaded 2>/dev/null | grep -q "com.nullmoth.NVRM"; then
    say "com.nullmoth.NVRM 已经处于加载状态 —— 本次实验要求从'未加载'开始。停止。"
    say "先执行: sudo kmutil unload -p $KEXT  (或重启) 再重跑本脚本。"
    exit 4
fi

# 记下基线
kextstat > "$OUT/00-kextstat-before.txt" 2>&1
kmutil showloaded > "$OUT/00-showloaded-before.txt" 2>&1
say "基线已记录（kextstat / showloaded）"

# 起始时间戳，供日志切片
START="$(date '+%Y-%m-%d %H:%M:%S')"
say "起始时间: $START"

# --- 加载 -------------------------------------------------------------------
say "加载 $KEXT ..."
if ! kextload "$KEXT" >> "$LOG" 2>&1; then
    say "kextload 失败，尝试 kmutil load -p ..."
    if ! kmutil load -p "$KEXT" >> "$LOG" 2>&1; then
        say "两种方式都失败。常见原因：签名/SIP 不允许、依赖缺失。"
        say "**不要**为了让加载成功去关 SIP —— 那需要另行授权。到此停止。"
        exit 5
    fi
fi
say "加载命令已返回，等待 30 秒让 RM/GSP 有机会初始化 ..."
sleep 30

# --- 采集 -------------------------------------------------------------------
kextstat > "$OUT/10-kextstat-loaded.txt" 2>&1
kmutil showloaded > "$OUT/10-showloaded-loaded.txt" 2>&1
{ log show --last 5m --style compact --predicate \
    'eventMessage CONTAINS "NVRM" OR eventMessage CONTAINS "NVKMS" OR eventMessage CONTAINS "rm_"' 2>&1; } \
    > "$OUT/20-log-after-load.txt"
{ ioreg -l -c IOFramebuffer 2>&1; } > "$OUT/21-ioreg-fb.txt"
say "日志已采集: 20-log-after-load.txt（关键看 NVRM-xnu: / NVKMS rm: 行）"

# 快速摘要，便于当场判断
{
    echo "--- 关键行摘要 ---"
    grep -E "NVRM-xnu:|NVKMS rm:|allocateDevice|grabOwnership|getDisplays|gsp|GSP|GPU_IS_LOST" \
        "$OUT/20-log-after-load.txt" 2>/dev/null | tail -60
} | tee "$OUT/22-key-lines.txt"

# --- 卸载（无论上面结果如何）------------------------------------------------
say "卸载 $KEXT ..."
UNLOAD_OK=0
if kextunload "$KEXT" >> "$LOG" 2>&1 || kmutil unload -p "$KEXT" >> "$LOG" 2>&1; then
    UNLOAD_OK=1
fi
sleep 2
kextstat > "$OUT/30-kextstat-after-unload.txt" 2>&1

if kmutil showloaded 2>/dev/null | grep -q "com.nullmoth.NVRM"; then
    say ""
    say "!! 卸载后仍能查到 com.nullmoth.NVRM —— 状态未回到基线。"
    say "!! 这通常意味着还有客户端持有它（例如别的进程/驱动）。"
    say "!! 没有做任何持久化修改；重启即可回到实验前状态。"
    say "!! 请把 $OUT 整个目录带回，并说明是否选择重启。"
    exit 6
fi

say ""
say "已卸载，模块列表回到基线（见 30-kextstat-after-unload.txt）。"
say "本次实验没有做任何持久化修改：没有装/删文件，没有写 nvram，没有改 SIP/EFI。"
say "请把 $OUT 整个目录带回复盘。"
exit 0
