# shell-peek demo: "did I forget to format this file?"
# Peeks a single file with rustfmt --check, right from the file list.
# Playground: a checkout of the yazi source tree at ~/.demo/yazi
# Run: just vhs lint-check.tape (from shell-peek.yazi/), or `vhs lint-check.tape`
# from this directory directly.

Require yazi

Output lint-check.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1280
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

# Boring setup: jump straight to the target file so the recording is just
# "run the peek".
Hide
Type "cd ~/.demo/yazi/yazi-widgets/src && clear && yazi lib.rs"
Enter
Sleep 1s
Show

Sleep 1s

# Peek: is this file formatted correctly?
Type ";"
Sleep 400ms
Type "rustfmt --check %h 2>/dev/null"
Sleep 400ms
Enter

Sleep 4s
