#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  exit 1
fi

role="$1" # main | sub
if [[ "$role" != "main" && "$role" != "sub" ]]; then
  exit 1
fi

monitors_json="$(aerospace list-monitors --json 2>/dev/null || echo '[]')"

target_name="$(
  printf '%s' "$monitors_json" | /usr/bin/python3 -c '
import json
import sys

role = sys.argv[1]

try:
    data = json.load(sys.stdin)
except Exception:
    data = []

if not isinstance(data, list):
    data = [data]

def norm(key):
    return str(key).strip().lower().replace("_", "-")

def get_name(monitor):
    for key in ("monitor-name", "monitor_name", "name", "display-name"):
        value = monitor.get(key)
        if isinstance(value, str) and value:
            return value
    for key, value in monitor.items():
        if isinstance(value, str) and "name" in norm(key) and value:
            return value
    return ""

def is_main(monitor):
    for key, value in monitor.items():
        if isinstance(value, bool) and "main" in norm(key):
            return value
    return False

names = []
main_name = ""
for monitor in data:
    name = get_name(monitor)
    if not name:
        continue
    names.append(name)
    if not main_name and is_main(monitor):
        main_name = name

if not names:
    print("")
    sys.exit(0)

if not main_name:
    main_name = names[0]

if role == "main":
    print(main_name)
else:
    for name in names:
        if name != main_name:
            print(name)
            break
' "$role"
)"

if [[ -z "$target_name" ]]; then
  exit 0
fi

focused_json="$(aerospace list-monitors --focused --json 2>/dev/null || echo '{}')"

focused_name="$(
  printf '%s' "$focused_json" | /usr/bin/python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

if isinstance(data, list):
    data = data[0] if data else {}

for key in ("monitor-name", "monitor_name", "name", "display-name"):
    value = data.get(key)
    if isinstance(value, str) and value:
        print(value)
        sys.exit(0)

print("")
'
)"

if [[ "$focused_name" == "$target_name" ]]; then
  exit 0
fi

windows_json="$(aerospace list-windows --all --json 2>/dev/null || echo '[]')"

target_window_id="$(
  printf '%s' "$windows_json" | /usr/bin/python3 -c '
import json
import sys

target_name = sys.argv[1]

try:
    data = json.load(sys.stdin)
except Exception:
    data = []

if not isinstance(data, list):
    data = [data]

def norm(key):
    return str(key).strip().lower().replace("_", "-")

def pick_window_id(window):
    for key in ("window-id", "window_id", "id"):
        value = window.get(key)
        if value is not None:
            return str(value)
    return ""

def pick_monitor_name(window):
    for key in ("monitor-name", "monitor_name", "monitor"):
        value = window.get(key)
        if isinstance(value, str) and value:
            return value
    for key, value in window.items():
        nk = norm(key)
        if isinstance(value, str) and "monitor" in nk and "name" in nk and value:
            return value
    return ""

def is_focused(window):
    for key, value in window.items():
        if isinstance(value, bool) and "focus" in norm(key):
            return value
    return False

fallback = ""
focused = ""
for window in data:
    if pick_monitor_name(window) != target_name:
        continue
    wid = pick_window_id(window)
    if not wid:
        continue
    if not fallback:
        fallback = wid
    if is_focused(window):
        focused = wid
        break

print(focused or fallback)
' "$target_name"
)"

if [[ -n "$target_window_id" ]]; then
  aerospace focus --window-id "$target_window_id"
fi
