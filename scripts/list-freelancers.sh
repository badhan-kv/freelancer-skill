#!/usr/bin/env bash
# List registered freelancers (all projects). Read-only.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
for f in "$REG_DIR"/*.json; do
    [ -f "$f" ] || { echo "(no freelancers registered)"; exit 0; }
    j=$(<"$f"); st=$(jq -r .status <<<"$j"); fl_alive "$j" || [ "$st" = closed ] || st="dead($st)"
    echo "$(jq -r .name <<<"$j") | $st | $(jq -r '.model // "default"' <<<"$j") | $(jq -r .root <<<"$j") | $(jq -r .task <<<"$j")"
done
