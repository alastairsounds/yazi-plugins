# confirm-quit demo: "did I mean to close all these tabs?"
# Opens a second tab, then quits -- the plugin intercepts `q` and asks for
# confirmation instead of exiting immediately.
# Playground: a checkout of the yazi source tree at ~/.demo/yazi
# Run: just vhs confirm-quit.yazi multi-tab-quit.tape (from repo root), or
# `vhs multi-tab-quit.tape` from this directory directly.

Require yazi

Output multi-tab-quit.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1280
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

Hide
Type "cd ~/.demo/yazi && clear && yazi"
Enter
Sleep 1s
Show

Sleep 0.1s

# Open a second tab.
Type "tt"
Sleep 1s

# Quit with multiple tabs open -- the plugin asks for confirmation.
Type "q"
Sleep 2s

# Confirm so the recording shows the actual quit, not just the modal.
Type "y"
Sleep 2s
