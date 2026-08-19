# count-todos demo: "where are all the @todos, across the whole tree?"
# Bare plugin invoke opens a search view listing every file with a match.
# Playground: the fixtures/ tree committed alongside this tape.
# Run: just vhs count-todos.yazi todo-search.tape (from repo root), or
# `vhs todo-search.tape` from this directory directly.

Require yazi

Output todo-search.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1280
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

Hide
Type "cd fixtures && clear && yazi"
Enter
Sleep 1s
Show

Sleep 1s

# Bare invoke: search view of every file with a @todo match.
Type "`"
Sleep 1.0s
Type "t"
Sleep 1.5s
Type "j"
Sleep 4s
