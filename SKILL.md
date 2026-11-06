---
name: freelancer
description: Spawn a completely independent Claude session (a tmux session on Linux/macOS, a new Windows Terminal tab on Windows) to do one assigned task. The spawner only initialises it (writes the brief, launches it) and then walks away; the freelancer never reports back, owns the task end to end, and checks and declares shared resources (CPU/RAM/disk/GPU/ports) so it does not collide with other agents. Start with /freelancer <task>.
disable-model-invocation: true
argument-hint: "<task for the independent agent>"
---

# Freelancer: spawn an independent agent

Task from the user: $ARGUMENTS

You are only the **initialiser**. You hand the task to a new, fully independent Claude session
and stop. It does not report to you, you do not monitor it, wait for it, answer its questions
or close it. (Unlike `/lead`: no event watcher, no message protocol, no wrap-up.)

Scripts are in `${CLAUDE_SKILL_DIR}/scripts/`; run from the project root the task belongs to.
Run every script through the dispatcher, which picks the right version for the OS (bash/tmux on
Linux and macOS, PowerShell/Windows Terminal on Windows) with identical flags:
`"${CLAUDE_SKILL_DIR}/scripts/run-for-os.sh" <script> [args]`, with `<script>` one of
`resources`, `list-freelancers`, `spawn-freelancer`, `claim`, `close-freelancer`.

## 1. Initialise
1. If the task is unclear in a way that would make the brief useless, ask the user once. Otherwise
   proceed; do not ask for confirmation.
2. Look at the machine first so the brief reflects reality: `"${CLAUDE_SKILL_DIR}/scripts/run-for-os.sh" resources`.
3. Pick a name: must start with `fl-`, then lowercase letters, digits, hyphens (max 40 total), e.g. `fl-fix-parser`; descriptive of the task, since it is also the tmux session name / tab title the user will look for. Check `"${CLAUDE_SKILL_DIR}/scripts/run-for-os.sh" list-freelancers` for clashes.
4. Write the brief to `.agents/briefs/<name>.md`. It is the freelancer's only context, so make it
   complete: goal; why; files/areas it owns and must not touch; background it needs; what other
   agents are doing in the same project (if known); done criteria and how to verify; docs to
   update; whether it may commit (default no); resources it will likely need (GPU, ports, RAM)
   and, for training runs, the TensorBoard-link rule.
5. Pick the model by complexity (say which and why in one line):
   - `claude-opus-5-5`: architecture/design, hard or subtle debugging, cross-cutting refactors,
     security-sensitive or ambiguous work.
   - `claude-sonnet-5-5`: well-specified implementation, localized changes, tests, docs, research.
   The user's named model wins.
6. Launch:
   `"${CLAUDE_SKILL_DIR}/scripts/run-for-os.sh" spawn-freelancer --name <name> --task "<one line>" --model <model-id>`
   Options: `--permission-mode <auto|acceptEdits|manual|plan|dontAsk|bypassPermissions>`
   (default `auto`; if the user wants a specific mode, use it), `--claim "gpu:0 port:6007"` to
   pre-declare resources, `--root DIR`. Do not put `;` in `--task` on Windows.

## 2. Report and stop
Tell the user, with the name prominent so they can copy or note it down:
- **Linux/macOS:** `tmux session/window name: <name>`, open with `tmux attach -t <name>` (detach: Ctrl-b d).
- **Windows:** a new Windows Terminal tab titled **`<name>`** was opened in the current window
  (focus stays on the current tab); closing the tab ends the freelancer.
- model chosen (one line why), and that it runs independently and will not report back;
- its result will be in `.agents/briefs/<name>-result.md`.

Then you are done with this task. Do not poll it.

## Notes
- All freelancers share one global registry (`${CLAUDE_SKILL_DIR}/state/freelancers/`), so each
  one sees the others' claimed resources across projects, via the `resources` script, which also
  lists every Claude session on the machine. Resource claims are advisory.
- Stopping one (only if the user asks): `"${CLAUDE_SKILL_DIR}/scripts/run-for-os.sh" close-freelancer --name <name>`.
  List: `list-freelancers`.
- Do not put mentions of AI tooling in project files you write (brief excepted: it is gitignored
  under `.agents/`).
