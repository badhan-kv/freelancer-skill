#!/usr/bin/env bash
# Snapshot of machine resources and of what the other agents are using. Read-only.
# Usage: resources.sh [--self NAME]   (NAME is left out of the "other freelancers" list)
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
self=${FREELANCER_NAME:-}; [ "${1:-}" = --self ] && self=$2
echo "== Machine =="
echo "CPU: $(nproc) cores, load $(cut -d' ' -f1-3 /proc/loadavg)"
free -h | awk '/^Mem:/ {printf "RAM: %s total, %s available\n",$2,$7}'
df -h "$HOME" | awk 'NR==2 {printf "Disk (home): %s free of %s (%s used)\n",$4,$2,$5}'
if command -v nvidia-smi >/dev/null; then
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null | sed 's/^/GPU /'
    nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader 2>/dev/null | sed 's/^/  GPU process: /'
fi
echo "Listening ports: $(ss -ltnH 2>/dev/null | awk '{n=split($4,a,":"); print a[n]}' | sort -nu | tr '\n' ' ')"
echo
echo "== Other freelancers (claimed resources) =="
found=0
for f in "$REG_DIR"/*.json; do
    [ -f "$f" ] || continue
    j=$(<"$f"); n=$(jq -r .name <<<"$j"); [ "$n" = "$self" ] && continue
    if fl_alive "$j"; then
        found=1
        echo "- $n | $(jq -r .root <<<"$j") | $(jq -r .task <<<"$j") | claims: $(jq -r '.claims | join(" ") | if .=="" then "none" else . end' <<<"$j")"
    fi
done
[ $found = 1 ] || echo "(none running)"
echo
echo "== All Claude sessions on this machine (any spawner) =="
ps -eo pid,rss,pcpu,args --no-headers | awk '$4 ~ /(^|\/)claude$/ || $4 ~ /claude/ && $5 !~ /^--(version|help)/' \
  | grep -E '(^| )([^ ]*/)?claude( |$)' | grep -v grep | while read -r pid rss cpu rest; do
    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
    printf -- '- pid %s | %s MB RSS | %s%% CPU | cwd %s\n' "$pid" "$((rss/1024))" "$cpu" "${cwd:-?}"
done
echo
echo "Heaviest processes (by RAM):"
ps -eo pid,rss,pcpu,comm --sort=-rss --no-headers | head -6 | awk '{printf "  pid %s | %d MB | %s%% CPU | %s\n",$1,$2/1024,$3,$4}'
