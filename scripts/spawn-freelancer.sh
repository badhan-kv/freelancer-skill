#!/usr/bin/env bash
# Launch an independent freelancer Claude session in its own tmux window, then return.
# The brief must already exist at <root>/.agents/briefs/<name>.md.
# Usage: spawn-freelancer.sh --name N --task T [--root DIR] [--model X] [--permission-mode M] [--claim "gpu:0 port:6006"]
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
name= task= root=$PWD mode=auto model= claims=
while [ $# -gt 0 ]; do
    case $1 in
        --name) name=$2; shift 2 ;;
        --task) task=$2; shift 2 ;;
        --root) root=$2; shift 2 ;;
        --model) model=$2; shift 2 ;;
        --permission-mode) mode=$2; shift 2 ;;
        --claim) claims=$2; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
[ -n "$name" ] && [ -n "$task" ] || { echo "Need --name and --task" >&2; exit 2; }
[[ $name =~ ^fl-[a-z0-9][a-z0-9-]{0,36}$ ]] || { echo "Name must start with 'fl-', then lowercase letters, digits, hyphens (max 40 total), e.g. fl-fix-parser" >&2; exit 2; }
case "$mode" in auto|acceptEdits|manual|plan|dontAsk|bypassPermissions) ;; *) echo "Bad permission mode: $mode" >&2; exit 2 ;; esac
command -v tmux >/dev/null && command -v jq >/dev/null || { echo "tmux and jq are required" >&2; exit 1; }
root=$(cd "$root" && pwd)
brief="$root/.agents/briefs/$name.md"
[ -f "$brief" ] || { echo "Brief not found: $brief (write it before spawning)" >&2; exit 1; }
if existing=$(read_fl "$name") && fl_alive "$existing"; then
    echo "Freelancer '$name' is already running" >&2; exit 1
fi
ensure_agents_ignored "$root"
claims_json=$(printf '%s\n' $claims | jq -R . | jq -s .)
save_fl "$name" "$(jq -n --arg name "$name" --arg task "$task" --arg root "$root" --arg mode "$mode" \
    --arg model "$model" --arg created "$(date +%Y-%m-%dT%H:%M:%S)" --argjson claims "$claims_json" \
    '{name:$name, task:$task, root:$root, permissionMode:$mode, model:$model, claims:$claims,
      status:"starting", hostPid:null, created:$created}')"

# One tmux session per freelancer, named exactly like the freelancer (so: tmux attach -t <name>).
if tmux has-session -t "=$name" 2>/dev/null; then
    echo "A tmux session named '$name' already exists; pick another name (see: tmux ls)" >&2; exit 1
fi
tmux new-session -d -s "$name" -n "$name" -c "$root" \
    "bash $(printf '%q' "$SKILL_DIR/scripts/run-freelancer.sh") $(printf '%q' "$name")"
tmux set-window-option -t "=$name:" automatic-rename off >/dev/null
set_fl "$name" '.tmuxSession=$s' --arg s "$name"

status=starting
for _ in $(seq 1 40); do
    sleep 0.5; status=$(read_fl "$name" | jq -r .status); [ "$status" = starting ] || break
done
if [ "$status" = running ]; then
    echo "Spawned freelancer '$name' (mode $mode${model:+, model $model}). It is independent; nothing will report back."
    echo "tmux session/window name: $name"
    echo "Open it with: tmux attach -t $name     (detach: Ctrl-b d)"
else
    echo "WARNING: '$name' did not report running within 20s (status: $status). Check: tmux attach -t $name"
fi
