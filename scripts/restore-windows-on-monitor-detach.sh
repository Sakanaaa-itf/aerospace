#!/usr/bin/env bash
set -euo pipefail

WATCH_MODE="false"
if [[ "${1:-}" == "--watch" ]]; then
  WATCH_MODE="true"
fi

POLL_SECONDS="${AEROSPACE_MONITOR_DETACH_POLL_SECONDS:-1}"
SUB_MONITOR_WORKSPACE="${AEROSPACE_SUB_MONITOR_WORKSPACE:-10}"
STATE_DIR="${TMPDIR:-/tmp}/aerospace-monitor-detach"
PID_FILE="${STATE_DIR}/pid"

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

LOCAL_CONFIG_FILE="${HOME}/.config/aerospace/aerospace.toml.local"
BASE_CONFIG_FILE="${HOME}/.config/aerospace/aerospace.toml.base"

lookup_app_workspace_in_file() {
  local config_file="$1"
  local app_id="$2"
  if [[ -z "$app_id" || ! -f "$config_file" ]]; then
    return 1
  fi
  awk -v app_id="$app_id" '
    /^\[\[on-window-detected\]\]/ { current_app=""; next }
    /if\.app-id/ {
      split($0, a, "'\''")
      if (a[2] != "") { current_app=a[2] }
      next
    }
    /move-node-to-workspace/ {
      if (current_app == app_id) {
        split($0, a, "'\''")
        split(a[2], b, /[[:space:]]+/)
        if (b[2] != "") { print b[2]; exit 0 }
      }
    }
  ' "$config_file"
}

lookup_app_workspace() {
  local app_id="$1"
  local workspace=""

  workspace="$(lookup_app_workspace_in_file "$LOCAL_CONFIG_FILE" "$app_id" || true)"
  if [[ -n "$workspace" ]]; then
    printf '%s\n' "$workspace"
    return 0
  fi

  workspace="$(lookup_app_workspace_in_file "$BASE_CONFIG_FILE" "$app_id" || true)"
  if [[ -n "$workspace" ]]; then
    printf '%s\n' "$workspace"
    return 0
  fi

  return 1
}

restore_once() {
  local monitor_rows=""
  local non_main_count=""
  local window_rows=""

  monitor_rows="$("$AEROSPACE_BIN" list-monitors --format '%{monitor-is-main}' 2>/dev/null || true)"
  if [[ -z "$monitor_rows" ]]; then
    return 0
  fi

  non_main_count="$(printf '%s\n' "$monitor_rows" | awk '$1 != "true" { c++ } END { print c + 0 }')"
  if [[ "$non_main_count" -gt 0 ]]; then
    return 0
  fi

  window_rows="$("$AEROSPACE_BIN" list-windows --workspace "$SUB_MONITOR_WORKSPACE" --format '%{window-id}|%{app-bundle-id}' 2>/dev/null || true)"
  if [[ -z "$window_rows" ]]; then
    return 0
  fi

  printf '%s\n' "$window_rows" \
    | awk 'NF' \
    | while IFS='|' read -r window_id app_id; do
        if [[ -z "$window_id" || -z "$app_id" ]]; then
          continue
        fi
        mapped_workspace="$(lookup_app_workspace "$app_id" || true)"
        if [[ -z "$mapped_workspace" || "$mapped_workspace" == "$SUB_MONITOR_WORKSPACE" ]]; then
          continue
        fi
        "$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$mapped_workspace" 2>/dev/null || true
      done
}

if [[ "$WATCH_MODE" != "true" ]]; then
  restore_once
  exit 0
fi

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    exit 0
  fi
fi
echo "$$" >"$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

while true; do
  restore_once || true
  /bin/sleep "$POLL_SECONDS"
done
