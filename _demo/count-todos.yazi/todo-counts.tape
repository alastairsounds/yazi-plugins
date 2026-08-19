# count-todos demo: "which files still need work?"
# Shows @todo counts rolled up per file and per directory in the file list.
# Playground: the fixtures/ tree committed alongside this tape.
# Static screenshot (nothing animates), so vhs only records to gif; grab a
# still frame and drop the gif:
#   ffmpeg -y -sseof -1 -i todo-counts.gif -update 1 todo-counts.png
#   rm todo-counts.gif
# Run: just vhs count-todos.yazi todo-counts.tape (from repo root), or
# `vhs todo-counts.tape` from this directory directly.

Require yazi

Output todo-counts.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1280
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

# Boring setup: jump straight into the fixture tree so the recording is just
# "open yazi, counts are already there".
Hide
Type "cd fixtures && clear && yazi"
Enter
Sleep 1s
Show

Sleep 1s
