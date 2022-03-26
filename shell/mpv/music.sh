#!/bin/sh

f() {
    find ~/Music -iregex '.*\.\(mp3\)' -print0
}

case "$1" in
    -i) f | sort -z | fzf -m --read0 --print0 | xargs -r0 mpv ;;
    *) f | xargs -r0 mpv --shuffle ;;
esac
