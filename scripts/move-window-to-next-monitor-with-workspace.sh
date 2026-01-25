#!/usr/bin/env bash
set -euo pipefail

window_id=""
workspace=""

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

workspace="$(aerospace list-workspaces --focused --json | python3 -c '
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

if [[ -z "$window_id" || -z "$workspace" ]]; then
  exit 0
fi

# Move the focused window to the next monitor (wrap around).
aerospace move-node-to-monitor --wrap-around next --window-id "$window_id"
