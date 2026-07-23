# shell-peek.yazi: shell output notifier

Yazi plugin to peek the shell output after executing a command.

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

> [!NOTE] The `--log` flag must come immediately after the leading `--`. yazi only forwards the plugin id and everything after that first `--` to the plugin, so a flag placed before it is silently dropped.
