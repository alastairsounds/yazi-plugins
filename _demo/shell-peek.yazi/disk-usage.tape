# shell-peek demo: "how big are these before I act on them?"
# Multi-selects a few crates and peeks their sizes with du, showcasing the
# %s wildcard (all selected paths) resolving in one shell call.
# Playground: a checkout of the yazi source tree at ~/.demo/yazi
# Run: just vhs disk-usage.tape (from shell-peek.yazi/), or `vhs disk-usage.tape`
# from this directory directly.

Require yazi

Output disk-usage.gif

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

Sleep 1s

# Select three crates by arrowing down + toggling selection (default keymap).
# `j` counts below assume a fresh, alphabetical (dirs-first) listing of
# ~/.demo/yazi -- `gg` resets the cursor to top first so they stay accurate
# regardless of any remembered hover position. Note: <Space> is bound to
# ["toggle", "arrow 1"], so it also nudges the cursor down a row -- each
# jump after the first is one `j` shorter to account for that.
Type "jjjjjjjjjjjjjjj" # .cargo -> yazi-core (15 down)
Sleep 400ms
Space
Sleep 500ms

Type "jjjj" # yazi-core -> yazi-fs (4 down, +1 from Space's own arrow)
Sleep 400ms
Space
Sleep 500ms

Type "jjj" # yazi-fs -> yazi-plugin (3 down, +1 from Space's own arrow)
Sleep 400ms
Space
Sleep 700ms

# Peek: how big are these, biggest first?
Type ";"
Sleep 400ms
Type "du -sh %s | sort -rh"
Sleep 400ms
Enter

Sleep 4s
