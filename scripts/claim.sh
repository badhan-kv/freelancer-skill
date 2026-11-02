#!/usr/bin/env bash
# Declare or release resources so other freelancers can see them (GPU, ports, big RAM, a directory...).
# Usage: claim.sh add "gpu:0" "port:6006" "ram:6G" | claim.sh remove "port:6006" | claim.sh show
# Needs FREELANCER_NAME (set automatically in a freelancer's window) or --name N before the verb.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
name=${FREELANCER_NAME:-}; [ "${1:-}" = --name ] && { name=$2; shift 2; }
[ -n "$name" ] || { echo "No freelancer name (set FREELANCER_NAME or pass --name)" >&2; exit 2; }
verb=${1:-show}; shift || true
case $verb in
    add)    for c in "$@"; do set_fl "$name" '.claims = ((.claims + [$c]) | unique)' --arg c "$c"; done ;;
    remove) for c in "$@"; do set_fl "$name" '.claims -= [$c]' --arg c "$c"; done ;;
    show) ;;
    *) echo "Usage: claim.sh [--name N] add|remove|show [claim...]" >&2; exit 2 ;;
esac
echo "Claims of $name: $(read_fl "$name" | jq -r '.claims | join(" ")')"
