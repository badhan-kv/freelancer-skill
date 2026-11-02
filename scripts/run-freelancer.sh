#!/usr/bin/env bash
# Runs inside the freelancer's tmux window: sets the environment and starts claude.
# Usage: run-freelancer.sh NAME   (cwd = project root)
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
name=$1; root=$PWD
w=$(read_fl "$name") || { echo "No freelancer '$name' registered"; read -r -p 'Press Enter to close'; exit 1; }
# Do not inherit the spawner's session identity: this claude is its own, unrelated session.
unset CLAUDECODE CLAUDE_PID CLAUDE_CODE_SESSION_ID CLAUDE_CODE_CHILD_SESSION \
      CLAUDE_CODE_BRIDGE_SESSION_ID CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ATTENDED \
      CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN NO_COLOR AI_AGENT \
      GIT_ASKPASS GIT_EDITOR GIT_TERMINAL_PROMPT GCM_INTERACTIVE COREPACK_ENABLE_AUTO_PIN
mode=$(jq -r .permissionMode <<<"$w"); model=$(jq -r '.model // empty' <<<"$w")
export FREELANCER_NAME=$name FREELANCER_SKILL_DIR=$SKILL_DIR
printf '\033]2;%s\007' "$name"
set_fl "$name" '.status="running" | .hostPid=$pid | .hostStart=$st | .started=$t' \
    --argjson pid $$ --arg st "$(pid_start $$)" --arg t "$(date +%Y-%m-%dT%H:%M:%S)"
role=$(<"$SKILL_DIR/freelancer-role.md"); role=${role//\{\{NAME\}\}/$name}
prompt="You are freelancer '$name'. Read your brief at .agents/briefs/$name.md, run $SKILL_DIR/scripts/resources.sh, then start."
args=(--name "$name" --append-system-prompt "$role" --permission-mode "$mode")
[ -n "$model" ] && args+=(--model "$model")
claude "${args[@]}" "$prompt"
code=$?
set_fl "$name" '.status="closed" | .claims=[] | .ended=$t | .exitCode=$c' \
    --arg t "$(date +%Y-%m-%dT%H:%M:%S)" --argjson c "$code"
exit 0
