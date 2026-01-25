#!/usr/bin/env bash
set -euo pipefail

main_name="Built-in Retina Display"

sub_name="$(
  aerospace list-monitors --json | python3 -c '
import json
import sys

data = json.load(sys.stdin)
main = sys.argv[1]

for monitor in data:
    name = monitor.get("monitor-name")
    if name and name != main:
        print(name)
        break
' "$main_name"
)"

if [[ -z "${sub_name}" ]]; then
  exit 0
fi

aerospace focus-monitor "$sub_name"
