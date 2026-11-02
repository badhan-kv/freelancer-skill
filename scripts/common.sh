#!/usr/bin/env bash
# Shared helpers for the freelancer skill scripts. Source this file.
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REG_DIR="$SKILL_DIR/state/freelancers"     # global registry: one JSON per freelancer, all projects

reg_file() { echo "$REG_DIR/$1.json"; }
read_fl() { local f; f=$(reg_file "$1"); [ -f "$f" ] && cat "$f"; }
save_fl() { mkdir -p "$REG_DIR"; printf '%s\n' "$2" > "$(reg_file "$1")"; }
# set_fl NAME JQ_FILTER [jq args...]
set_fl() {
    local name=$1 filter=$2 f tmp; shift 2; f=$(reg_file "$name")
    [ -f "$f" ] || { echo "No freelancer '$name' registered" >&2; return 1; }
    tmp=$(mktemp) && jq "$@" "$filter" "$f" > "$tmp" && mv "$tmp" "$f"
}
pid_alive() { [ -n "$1" ] && [ "$1" != null ] && kill -0 "$1" 2>/dev/null; }
# Kernel start time of a PID: with the PID it identifies one process (guards against PID reuse).
pid_start() { local s; s=$(cat "/proc/$1/stat" 2>/dev/null) || return 1; s=${s##*) }; awk '{print $20}' <<<"$s"; }
# fl_alive JSON: the registered host process is still the same, running process.
fl_alive() {
    local pid st; pid=$(jq -r '.hostPid // empty' <<<"$1"); st=$(jq -r '.hostStart // empty' <<<"$1")
    pid_alive "$pid" && [ "$(pid_start "$pid")" = "$st" ]
}
ensure_agents_ignored() {
    local root=$1 gi="$1/.gitignore"
    [ -e "$root/.git" ] || [ -f "$gi" ] || return 0
    grep -qE '^\.agents/?$' "$gi" 2>/dev/null && return 0
    echo '.agents/' >> "$gi"
}
