#!/usr/bin/env bash
# Install the freelancer skill to ~/.claude/skills/freelancer (keeps its runtime state/).
set -euo pipefail
for c in tmux jq claude; do command -v "$c" >/dev/null || { echo "Missing requirement: $c" >&2; exit 1; }; done
src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); dst=$HOME/.claude/skills/freelancer
mkdir -p "$dst/state/freelancers"
cp -r "$src/SKILL.md" "$src/freelancer-role.md" "$src/scripts" "$dst/"
chmod +x "$dst"/scripts/*.sh
echo "Installed to $dst. Use: /freelancer <task>"
