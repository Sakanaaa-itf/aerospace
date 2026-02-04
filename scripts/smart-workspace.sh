#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  exit 1
fi

slot="$1"

map_slot_to_secondary_workspace() {
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
    *) echo "$1" ;;
  esac
}

focused_workspace="$(
  aerospace list-windows --focused --json | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if isinstance(data, list):
    if not data:
        print("")
        sys.exit(0)
    data = data[0]

workspace = data.get("workspace") or data.get("workspace-name") or data.get("workspace_name")
print(workspace if isinstance(workspace, str) else "")
'
)"

if [[ -z "$focused_workspace" ]]; then
  focused_workspace="$(
    aerospace list-workspaces --focused --json | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if isinstance(data, list):
    if not data:
        print("")
        sys.exit(0)
    data = data[0]

workspace = data.get("workspace")
print(workspace if isinstance(workspace, str) else "")
'
  )"
fi

if [[ -z "$focused_workspace" ]]; then
  target_workspace="$slot"
elif [[ "$focused_workspace" =~ ^[A-I]$ ]]; then
  target_workspace="$(map_slot_to_secondary_workspace "$slot")"
else
  target_workspace="$slot"
fi

# Avoid side effects on repeated presses (e.g. opt+1 twice)
if [[ "$focused_workspace" == "$target_workspace" ]]; then
  exit 0
fi

aerospace workspace --fail-if-noop "$target_workspace"
