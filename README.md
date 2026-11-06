# freelancer skill

A Claude Code skill that spawns a **completely independent** Claude session to do one assigned task.
The spawning session only initialises it: it writes a brief, picks a model, launches the session in
its own tmux session (Linux/macOS) or a new Windows Terminal tab (Windows) and tells you its name. The freelancer owns the task end to end and
never reports back to the spawner.

## Install
Linux or macOS: needs `tmux`, `jq`, `bash` and Claude Code (`claude` on PATH).

    git clone https://github.com/badhan-kv/freelancer-skill && bash freelancer-skill/install.sh

Windows: needs Windows Terminal, Git for Windows (Git Bash) and Claude Code.

    git clone https://github.com/badhan-kv/freelancer-skill
    powershell -NoProfile -ExecutionPolicy Bypass -File freelancer-skill\install.ps1

Run it again after a `git pull`. The installer keeps the runtime `state/` folder.

## Use
In a Claude Code session started in the project folder:

    /freelancer <task>

The spawner writes `.agents/briefs/<name>.md`, starts the session and reports its name:

- **Linux/macOS:** a tmux session `fl-<name>`. Open it with `tmux attach -t fl-<name>` (detach: Ctrl-b d).
- **Windows:** a new Windows Terminal tab titled `fl-<name>` in the current window; focus stays on
  your tab, and closing the tab ends the freelancer. The first time in a new folder the tab shows
  Claude Code's trust prompt; accept it.

The result is written to `.agents/briefs/fl-<name>-result.md`.

Names must start with `fl-` and use lowercase letters, digits and hyphens (max 40 characters).
The tmux session or tab, the Claude session and the registry entry all share that name.

## Shared-machine awareness
All freelancers share one registry (`state/freelancers/`), so each can see the others.
- `scripts/resources.sh` (`.ps1` on Windows): free CPU, RAM, disk, GPU, listening ports, other freelancers and what they
  claimed, and every Claude session on the machine.
- `scripts/claim.sh add gpu:0 port:6007 ram:6G`: declare resources in use (advisory; dropped when the
  session ends). `remove` releases them.
- Every script has a `.sh` and a `.ps1` twin with the same flags; `scripts/run-for-os.sh <name> ...` runs the right one. Other helpers: `list-freelancers`, `close-freelancer.sh --name <name>`.

## Files
`SKILL.md` (spawner instructions), `freelancer-role.md` (the freelancer's system prompt), `scripts/`, `install.sh`, `install.ps1`.
Default permission mode for freelancers is `auto`; override with `--permission-mode`.

## License
MIT
