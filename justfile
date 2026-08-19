default:
    @just --list --unsorted

# Demo assets live outside <plugin>.yazi/, so `ya pkg add` does not ship them.

# Config for yazi and ya. Excludes personal plugins so gifs stay generic.
export YAZI_CONFIG_HOME := justfile_directory() / "_demo/.config/yazi"

# Tapes with nothing to animate: `vhs` still records a gif, but `vhs`/`vhs-all`
# convert it to a still png and drop the gif. Match by tape filename, no
# extension. Add a name here instead of remembering to convert by hand.
screenshot_tapes := "shorten-symlink todo-counts"

# Upgrade yazi package to latest version
[group ('yazi')]
ya-pkg:
    ya pkg upgrade --discard

# Symlink each demo plugin into _demo/.config/yazi/plugins/ for keymap.toml.
[group ('yazi')]
link:
    #!/usr/bin/env sh
    set -eu
    mkdir -p {{ justfile_directory() }}/_demo/.config/yazi/plugins
    cd {{ justfile_directory() }}/_demo/.config/yazi/plugins
    for dir in {{ justfile_directory() }}/_demo/*/; do
        name="$(basename "$dir")"
        ln -sfn "../../../../$name" "$name"
    done

# Record one demo gif. Usage: just vhs shell-peek.yazi lint-check.tape
#
# Fresh XDG_RUNTIME_DIR per run: yazi shares one DDS socket per uid, and
# without this a demo recording can cross-talk with your real yazi session.
[group ('vhs')]
vhs subdir tape:
    #!/usr/bin/env sh
    set -eu
    export XDG_RUNTIME_DIR="$(mktemp -d)"
    trap 'rm -rf "$XDG_RUNTIME_DIR"' EXIT
    cd {{ justfile_directory() }}/_demo/{{ subdir }}
    vhs {{ tape }}
    name="$(basename {{ tape }} .tape)"
    case " {{ screenshot_tapes }} " in
        *" $name "*)
            ffmpeg -y -sseof -1 -i "$name.gif" -update 1 "$name.png" -loglevel error
            rm "$name.gif"
            ;;
    esac

# Re-record all gifs for a plugin, in parallel: just vhs-all shell-peek.yazi
#
# Delegates to `vhs` per tape (XDG_RUNTIME_DIR isolation, png conversion).
[group ('vhs')]
vhs-all subdir:
    #!/usr/bin/env sh
    set -eu
    cd {{ justfile_directory() }}/_demo/{{ subdir }}
    printf '%s\n' *.tape | xargs -P "$(getconf _NPROCESSORS_ONLN)" -I{} \
        just vhs {{ subdir }} {}
