#!/usr/bin/env bash
set -euo pipefail

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

window_monitor_id_any() {
  local candidate_id="$1"
  "$AEROSPACE_BIN" list-windows --monitor all --format '%{window-id}|%{monitor-id}' 2>/dev/null \
    | awk -F '|' -v id="$candidate_id" '$1 == id { print $2; exit }'
}

focused_monitor_info="$("$AEROSPACE_BIN" list-monitors --focused --format '%{monitor-id}|%{monitor-is-main}' 2>/dev/null || true)"
if [[ -z "$focused_monitor_info" ]]; then
  exit 0
fi
IFS='|' read -r focused_monitor_id focused_monitor_is_main <<<"$focused_monitor_info"
if [[ -z "$focused_monitor_id" ]]; then
  exit 0
fi

target_monitor_id=""
while IFS='|' read -r monitor_id monitor_name; do
  if [[ -n "$monitor_id" && "$monitor_id" != "$focused_monitor_id" ]]; then
    target_monitor_id="$monitor_id"
    break
  fi
done < <("$AEROSPACE_BIN" list-monitors --format '%{monitor-id}|%{monitor-name}' 2>/dev/null || true)

if [[ -z "$target_monitor_id" ]]; then
  exit 0
fi

target_visible_workspace="$("$AEROSPACE_BIN" list-workspaces --monitor "$target_monitor_id" --visible --format '%{workspace}' 2>/dev/null | head -n1 || true)"
if [[ -z "$target_visible_workspace" ]]; then
  exit 0
fi

window_info="$("$AEROSPACE_BIN" list-windows --focused --format '%{window-id}|%{app-bundle-id}' 2>/dev/null || true)"
IFS='|' read -r focused_window_id focused_app_id <<<"$window_info"

if [[ -z "$focused_app_id" ]]; then
  focused_app_id="$(osascript -e 'tell application "System Events" to get bundle identifier of first process whose frontmost is true' 2>/dev/null || true)"
fi

candidate_ids=""
if [[ -n "$focused_window_id" ]]; then
  candidate_ids+="${focused_window_id}"$'\n'
fi
if [[ -n "$focused_app_id" ]]; then
  candidate_ids+="$("$AEROSPACE_BIN" list-windows --monitor all --app-bundle-id "$focused_app_id" --format '%{window-id}|%{monitor-id}' 2>/dev/null \
    | awk -F '|' -v monitor_id="$focused_monitor_id" '$2 == monitor_id { print $1 }')"$'\n'
fi

if [[ -z "${candidate_ids//$'\n'/}" ]]; then
  exit 0
fi

moved_window_id=""
while IFS= read -r candidate_id; do
  if [[ -z "$candidate_id" ]]; then
    continue
  fi
  if "$AEROSPACE_BIN" move-node-to-workspace --focus-follows-window --window-id "$candidate_id" "$target_visible_workspace" 2>/dev/null; then
    for _ in 1 2 3; do
      moved_monitor_id="$(window_monitor_id_any "$candidate_id" || true)"
      if [[ "$moved_monitor_id" == "$target_monitor_id" ]]; then
        moved_window_id="$candidate_id"
        break
      fi
      /bin/sleep 0.05
    done
    if [[ -n "$moved_window_id" ]]; then
      break
    fi
  fi
done < <(printf '%s' "$candidate_ids" | awk 'NF && !seen[$0]++')

if [[ -z "$moved_window_id" ]]; then
  exit 0
fi

"$AEROSPACE_BIN" focus --window-id "$moved_window_id" 2>/dev/null || true

case "$focused_monitor_is_main" in
  true|1|yes|y|on) focused_monitor_is_main="true" ;;
  false|0|no|n|off) focused_monitor_is_main="false" ;;
  *) focused_monitor_is_main="unknown" ;;
esac

# When returning from sub -> main, apply app's main-workspace mapping.
if [[ "$focused_monitor_is_main" == "false" ]]; then
  mapped_workspace="$(lookup_app_workspace "$focused_app_id" || true)"
  if [[ -n "$mapped_workspace" ]]; then
    "$AEROSPACE_BIN" move-node-to-workspace --focus-follows-window --window-id "$moved_window_id" "$mapped_workspace" 2>/dev/null || true
    "$AEROSPACE_BIN" focus --window-id "$moved_window_id" 2>/dev/null || true
  fi
fi

exit 0
