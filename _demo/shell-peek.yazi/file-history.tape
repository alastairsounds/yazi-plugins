# shell-peek demo: "why does this file look the way it does?"
# Peeks a hovered file's recent commit history without leaving the list.
# Playground: a checkout of the yazi source tree at ~/.demo/yazi
# Run: just vhs file-history.tape (from shell-peek.yazi/), or `vhs file-history.tape`
# from this directory directly.

Require yazi

Output file-history.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1280
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

Hide
Type "cd ~/.demo/yazi/yazi-fm/src/app && clear && yazi mod.rs"
Enter
Sleep 1s
Show

Sleep 1s

# Peek: what recently changed here?
Type ";"
Sleep 400ms
Type "git --no-pager log -5 --oneline -- %h"
Sleep 400ms
Enter

Sleep 4s
