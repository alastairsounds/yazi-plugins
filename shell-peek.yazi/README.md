# shell-peek.yazi: shell output notifier

Yazi plugin to peek the shell output after executing a command.

## Usage

```toml
{ on = "!", run = "plugin shell-peek", desc = "Run a shell command" }
{ on = "@", run = "plugin shell-peek -- git status", desc = "Run a fixed command" }
```

Placeholders like `%h` (hovered path), `%s` (selected paths), `%d` (selected
dirs) are resolved in the command string — see `main.lua` for the full list.
