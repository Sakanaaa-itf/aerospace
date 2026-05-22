#!/usr/bin/env bash
set -euo pipefail

TARGET_WORKSPACE="${1:-}"
if [[ -z "$TARGET_WORKSPACE" ]]; then
  exit 0
fi

AEROSPACE_BIN="${AEROSPACE_BIN:-}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  AEROSPACE_BIN="$(command -v aerospace || true)"
fi
if [[ -z "$AEROSPACE_BIN" && -x "/opt/homebrew/bin/aerospace" ]]; then
  AEROSPACE_BIN="/opt/homebrew/bin/aerospace"
elif [[ -z "$AEROSPACE_BIN" && -x "/usr/local/bin/aerospace" ]]; then
  AEROSPACE_BIN="/usr/local/bin/aerospace"
fi
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

focused_monitor_info="$("$AEROSPACE_BIN" list-monitors --focused --format '%{monitor-id}|%{monitor-is-main}' 2>/dev/null || true)"
if [[ -z "$focused_monitor_info" ]]; then
  "$AEROSPACE_BIN" workspace "$TARGET_WORKSPACE" 2>/dev/null || true
  exit 0
fi
IFS='|' read -r _ focused_monitor_is_main <<<"$focused_monitor_info"

monitor_count="$("$AEROSPACE_BIN" list-monitors --format '%{monitor-id}' 2>/dev/null | awk 'NF { c++ } END { print c + 0 }')"
if [[ "${monitor_count:-0}" -le 1 ]]; then
  "$AEROSPACE_BIN" workspace "$TARGET_WORKSPACE" 2>/dev/null || true
  exit 0
fi

main_workspace="$("$AEROSPACE_BIN" list-workspaces --monitor main --visible --format '%{workspace}' 2>/dev/null | head -n1 || true)"
secondary_workspace="$("$AEROSPACE_BIN" list-workspaces --monitor secondary --visible --format '%{workspace}' 2>/dev/null | head -n1 || true)"

case "$focused_monitor_is_main" in
  true|1|yes|y|on)
    focused_monitor_label="main"
    other_monitor_label="secondary"
    other_workspace="$secondary_workspace"
    ;;
  false|0|no|n|off)
    focused_monitor_label="secondary"
    other_monitor_label="main"
    other_workspace="$main_workspace"
    ;;
  *)
    "$AEROSPACE_BIN" workspace "$TARGET_WORKSPACE" 2>/dev/null || true
    exit 0
    ;;
esac

"$AEROSPACE_BIN" workspace "$TARGET_WORKSPACE" 2>/dev/null || true

if [[ -n "$other_workspace" && "$other_workspace" != "$TARGET_WORKSPACE" ]]; then
  "$AEROSPACE_BIN" focus-monitor "$other_monitor_label" 2>/dev/null || true
  "$AEROSPACE_BIN" workspace "$other_workspace" 2>/dev/null || true
fi

"$AEROSPACE_BIN" focus-monitor "$focused_monitor_label" 2>/dev/null || true

exit 0
