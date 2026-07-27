# shell-peek.yazi: shell output notifier

Yazi plugin to peek the shell output after executing a command.

## Install

```sh
ya pkg add alastairsounds/yazi-plugins:shell-peek
```

## Usage

```toml
[mgr]
keymap = [
  { on = ";",     run = "plugin shell-peek",               desc = "Run a shell command (peek)" },
  { on = "<C-g>", run = "plugin shell-peek -- git status", desc = "Run 'git status' (peek)" },
]
```

Placeholders like `%h` (hovered path), `%s` (selected paths), `%d` (selected dirs) are resolved in the command string — see `main.lua` for the full list.

## Logging to a file

Pass `--log` right after the `--` to also append the run to `~/.local/state/yazi/shell-peek.log`, updated live as the command produces output (so `tail -f` shows a long-running command's progress, not just the final result):

```toml
[mgr]
keymap = [
  { on = "<C-;>", run = "plugin shell-peek -- --log", desc = "Run a shell command (peek and log)" },
]
```

```sh
tail -f ~/.local/state/yazi/shell-peek.log
```

Each run is bookended by an ISO 8601 timestamp so entries stay greppable even
with multiline output in between:

```log
2026-07-23T20:18:11Z | for i in {1..10}; do echo "line $i"; sleep 1; done
line 1
line 2
...
line 10
2026-07-23T20:18:21Z | exit 0
```

> [!NOTE] The `--log` flag must come immediately after the leading `--`. yazi only forwards the plugin id and everything after that first `--` to the plugin, so a flag placed before it is silently dropped.
