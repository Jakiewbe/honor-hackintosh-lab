#!/bin/bash
# 只读取证采集 —— 不加载、不卸载、不写 nvram、不改 SIP/EFI/系统目录。
# 用法: bash collect.sh            （输出目录会打印在最后）
#       bash collect.sh before     （同一会话里加载前采集）
#       bash collect.sh after      （加载后采集，用于对比）
set -u
TAG="${1:-before}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/gpu-forensics/${STAMP}-${TAG}"
mkdir -p "$OUT" || { echo "无法创建 $OUT"; exit 1; }

say() { printf '%s\n' "$*" | tee -a "$OUT/summary.txt" >/dev/null; }
run() { local f="$1"; shift; { echo "\$ $*"; "$@" 2>&1; echo "[exit=$?]"; } > "$OUT/$f" 2>&1; }

if [ "$(uname -s)" != "Darwin" ]; then
    echo "这不是 macOS —— 脚本只能在 macOS 里跑。"
    exit 2
fi

echo "采集到: $OUT"
say "=== GPU forensics bundle ($TAG) $(date) ==="

# 1. 身份与版本
run 01-os.txt            sw_vers
run 02-uname.txt         uname -a
run 03-model.txt         sysctl -n hw.model
run 04-sip.txt           csrutil status
run 05-nvram.txt         nvram -p
run 06-bootargs.txt      bash -c 'nvram -p | grep -i boot-args || echo "no boot-args entry"'

# 2. kext 现状
run 10-kmutil-loaded.txt kmutil showloaded
run 11-kextstat.txt      kextstat
run 12-nvrm-present.txt  bash -c 'ls -la /Library/Extensions/NVRM.kext 2>&1; ls -la /Library/Extensions/NVRMFB.kext 2>&1; ls -la /Library/Extensions/NVAccel.kext 2>&1'
run 13-nvrm-plist.txt    bash -c 'plutil -p /Library/Extensions/NVRM.kext/Contents/Info.plist 2>&1 | head -60'

# 3. 显示与 PCI
run 20-displays.txt      system_profiler SPDisplaysDataType
run 21-pci.txt           system_profiler SPPCIDataType
run 22-ioreg-nvidia.txt  bash -c 'ioreg -l -p IODeviceTree -r -n PEGP 2>&1 | head -40; echo ---; ioreg -l -r -n "display" 2>&1 | head -40'
run 23-ioreg-fb.txt      bash -c 'ioreg -l -c IOFramebuffer 2>&1 | head -60'
run 24-iopci-nvidia.txt  bash -c 'ioreg -l -c IOPCIDevice 2>&1 | grep -i -A3 -B3 "10de" | head -80'

# 4. 内核日志（近 10 分钟）
run 30-log-kernel.txt    bash -c 'log show --last 10m --style compact --predicate "process == \"kernel\"" 2>&1 | tail -400'
run 31-log-nvrm.txt      bash -c 'log show --last 30m --style compact --predicate "eventMessage CONTAINS \"NVRM\" OR eventMessage CONTAINS \"NVKMS\"" 2>&1 | tail -400'
run 32-log-gpu.txt       bash -c 'log show --last 30m --style compact --predicate "eventMessage CONTAINS[c] \"gsp\" OR eventMessage CONTAINS[c] \"GPU\" OR eventMessage CONTAINS[c] \"nvidia\"" 2>&1 | tail -300'

# 5. 系统是否健康
run 40-uptime.txt        uptime
run 41-panic-files.txt   bash -c 'ls -la /Library/Logs/DiagnosticReports/*.panic 2>&1 | tail -10'

say ""
say "采集完成。请把整个目录打包带回:"
say "  cd \"$OUT/..\" && tar czf \"${OUT}.tar.gz\" \"$(basename "$OUT")\""
say "目录内容:"
{ ls -la "$OUT"; } | tee -a "$OUT/summary.txt" >/dev/null
ls -la "$OUT"
