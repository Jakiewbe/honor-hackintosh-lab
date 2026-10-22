#!/bin/bash
# Historical deployment entry withdrawn after the 2026-10-22 audit.
set -euo pipefail
printf '%s
' 'STOP: LOAD NO-GO. Installation, KC/NVRAM changes and rollback are disabled.'
printf '%s
' 'Use g1-first-touch.command for offline preflight/build only; see DEVICE-CHECKLIST-20261021.md.'
exit 42
