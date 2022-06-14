#!/usr/bin/env bash

set -e

TRASH_DIR=~/.local/share/mytrash/files
[ -d "$TRASH_DIR" ] || mkdir -p "$TRASH_DIR"

preview() {
    file -bi -- "$1" | grep -q '^text' &&
        bat --color=always --style=plain -- "$1"
}
export -f preview

while [ $# -gt 0 ];do
    case "$1" in
        -r) find "$TRASH_DIR" -type f | fzf --preview 'preview {}' --print0 | xargs -r0I{} mv -vi {} . ;;
        -*) printf 'usage: %s -r <files*>\n' "${0##*/}"; exit 1 ;;
        *)
            if [ -f "$1" ];then
                n=1
                f="${TRASH_DIR}/${1}"
                while [ -f "$f" ];do
                    f="${TRASH_DIR}/${1}.$n"
                    n=$((n + 1))
                done
                mv -v -- "$1" "$f"
            fi
        ;;
    esac
    shift
done
