# better-symlinks demo: "where does this symlink actually point?"
# Shows a symlink target shortened to ~ instead of the full $HOME path.
# Playground: a symlink created under $HOME so the shortening applies.
# Static screenshot (nothing animates), so vhs only records to gif; grab a
# still frame and drop the gif:
#   ffmpeg -y -sseof -1 -i shorten-symlink.gif -update 1 shorten-symlink.png
#   rm shorten-symlink.gif
# Run: just vhs better-symlinks.yazi shorten-symlink.tape (from repo root), or
# `vhs shorten-symlink.tape` from this directory directly.

Require yazi

Output shorten-symlink.gif

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font"
Set FontSize 20
Set Width 1900
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms
Set Padding 20

# Boring setup: create a symlink under $HOME pointing at another path under
# $HOME, so the plugin has something to shorten. Wide terminal so the fully
# resolved target isn't truncated.
Hide
Type "mkdir -p ~/.demo/better-symlinks && echo 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.' > ~/.demo/better-symlinks/target.txt && ln -sfn ~/.demo/better-symlinks/target.txt ~/.demo/better-symlinks/config-link"
Enter
Type "cd ~/.demo/better-symlinks && clear && yazi"
Enter
Sleep 1s
Show

Sleep 1s

# Teardown: quit yazi and remove the scratch playground so ~/.demo/better-symlinks/
# doesn't linger between recordings. Hidden since the screenshot is already captured.
Hide
Type "q"
Sleep 500ms
Type "rm -rf ~/.demo/better-symlinks"
Enter
Sleep 500ms
