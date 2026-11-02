# freelancer skill

A Claude Code skill that spawns a **completely independent** Claude session to do one assigned task.
The spawning session only initialises it: it writes a brief, picks a model, launches the session in
its own tmux session and tells you the session name. The freelancer owns the task end to end and
never reports back to the spawner.

## Install
Needs Linux or macOS with `tmux`, `jq`, `bash` and Claude Code (`claude` on PATH).

    git clone https://github.com/badhan-kv/freelancer-skill && bash freelancer-skill/install.sh

Run it again after a `git pull`. The installer keeps the runtime `state/` folder.

## Use
In a Claude Code session started in the project folder:

    /freelancer <task>

The spawner writes `.agents/briefs/<name>.md`, starts the session and reports
`tmux session/window name: fl-<name>`. Open it with `tmux attach -t fl-<name>` (detach: Ctrl-b d).
The result is written to `.agents/briefs/fl-<name>-result.md`.

Names must start with `fl-` and use lowercase letters, digits and hyphens (max 40 characters).
The tmux session, the Claude session and the registry entry all share that name.

## Shared-machine awareness
All freelancers share one registry (`state/freelancers/`), so each can see the others.
- `scripts/resources.sh`: free CPU, RAM, disk, GPU, listening ports, other freelancers and what they
  claimed, and every Claude session on the machine.
- `scripts/claim.sh add gpu:0 port:6007 ram:6G`: declare resources in use (advisory; dropped when the
  session ends). `remove` releases them.
- Other helpers: `list-freelancers.sh`, `close-freelancer.sh --name <name>`.

## Files
`SKILL.md` (spawner instructions), `freelancer-role.md` (the freelancer's system prompt), `scripts/`.
Default permission mode for freelancers is `auto`; override with `--permission-mode`.

## License
MIT
