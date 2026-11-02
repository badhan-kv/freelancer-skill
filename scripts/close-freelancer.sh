#!/usr/bin/env bash
# Stop a freelancer and close its window. Only on the user's request: freelancers end themselves otherwise.
# Usage: close-freelancer.sh --name N
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ "${1:-}" = --name ] && name=$2 || { echo "Usage: close-freelancer.sh --name N" >&2; exit 2; }
j=$(read_fl "$name") || { echo "No freelancer '$name'" >&2; exit 1; }
if fl_alive "$j"; then kill -TERM "$(jq -r .hostPid <<<"$j")" 2>/dev/null; fi
tmux kill-session -t "=$name" 2>/dev/null || true
set_fl "$name" '.status="closed" | .claims=[] | .ended=$t' --arg t "$(date +%Y-%m-%dT%H:%M:%S)"
echo "Closed '$name'."
