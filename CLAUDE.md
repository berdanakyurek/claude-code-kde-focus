# claude-code-kde-focus

Brings the Konsole window and correct tab to the foreground when Claude Code finishes a task or asks for approval.

## Structure

- `scripts/claude-focus.sh` — the hook script deployed to `~/.local/bin/`
- `install.sh` — installs the script, registers hooks, configures KDE
- `uninstall.sh` — reverses everything install.sh does
- `settings-hook.json` — reference snippet showing the Claude Code hook config

## How the hook works

Claude Code fires two events this project listens to:
- `Stop` — Claude finishes responding
- `Notification` — Claude is waiting for user approval or input

On either event, `claude-focus.sh` runs and:
1. Walks up the PPID chain to identify the terminal emulator by process name, maps it to a kdotool window class, and calls `kdotool windowactivate` (KDE Wayland native; `--pid` search doesn't work for terminal emulators)
2. Switches to the correct tab using a terminal-specific method (see below)
3. Sends a desktop notification via `notify-send`

## Supported terminals

Tab switching is supported for:
- **Konsole** — via `qdbus setCurrentSession` (detected via `$KONSOLE_DBUS_SERVICE`)
- **Kitty** — via `kitty @ focus-window` (requires `allow_remote_control yes` and `listen_on` in kitty config; detected via `$KITTY_LISTEN_ON`)
- **WezTerm** — via `wezterm cli activate-pane` (detected via `$WEZTERM_PANE`)

Any other terminal (Alacritty, foot, xterm, etc.) still gets window focus via the PPID walk, just without tab switching.

## Key constraints

- **kdotool only** — xdotool and wmctrl don't work for native Wayland windows on KDE
- **Focus Stealing Prevention must be None** — set via `kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel 0`; without this, `kdotool windowactivate` is silently ignored by KWin
- **KWin scripting doesn't work for one-shot execution** — loading a script via DBus does not execute its top-level code; scripts only run in response to registered KWin events
- **Konsole tab switching uses `/Windows/1`** — not `/konsole/MainWindow_1`; `setCurrentSession` lives on the `org.kde.konsole.Window` interface at the `/Windows/N` path

## install.sh behavior

- Merges hooks into existing `~/.claude/settings.json` using `jq -s '.[0] * .[1]'`
- Does not overwrite unrelated settings
- `uninstall.sh` removes only the Stop and Notification hooks, restores `FocusStealingPreventionLevel` to 2
