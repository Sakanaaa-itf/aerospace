#!/usr/bin/env bash
set -euo pipefail

window_id=""
source_workspace=""
target_workspace=""

window_id="$(aerospace list-windows --focused --json | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if isinstance(data, list):
    if not data:
        sys.exit(1)
    data = data[0]

def pick(d, *keys):
    for key in keys:
        if key in d:
            return d[key]
    return None

window_id = pick(data, "window-id", "window_id", "id")
if window_id is None:
    sys.exit(1)

print(window_id)
')"

source_workspace="$(aerospace list-workspaces --focused --json | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if isinstance(data, list):
    if not data:
        sys.exit(1)
    data = data[0]

workspace = data.get("workspace")
if workspace is None:
    sys.exit(1)

print(workspace)
')"

if [[ -z "$window_id" || -z "$source_workspace" ]]; then
  exit 0
fi

map_workspace_for_other_monitor() {
  case "$1" in
    1) echo "A" ;;
    2) echo "B" ;;
    3) echo "C" ;;
    4) echo "D" ;;
    5) echo "E" ;;
    6) echo "F" ;;
    7) echo "G" ;;
    8) echo "H" ;;
    9) echo "I" ;;
    A) echo "1" ;;
    B) echo "2" ;;
    C) echo "3" ;;
    D) echo "4" ;;
    E) echo "5" ;;
    F) echo "6" ;;
    G) echo "7" ;;
    H) echo "8" ;;
    I) echo "9" ;;
    *) echo "$1" ;;
  esac
}

target_workspace="$(map_workspace_for_other_monitor "$source_workspace")"

# Move focused window to mirrored workspace bank and follow it with focus.
# Workspace-to-monitor assignment decides which monitor it lands on.
aerospace move-node-to-workspace --focus-follows-window --window-id "$window_id" "$target_workspace"
