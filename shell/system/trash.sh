#!/usr/bin/env bash
set -e

INFO_FILE=~/.local/share/mytrash/info
TRASH_DIR=~/.local/share/mytrash/files

help() {
    printf 'Usage: %s -r <files*>\n' "${0##*/}"; exit 1
}
[ "$1" ] || help

preview() {
    stat -c '%x' "$1"
    file -bi -- "$1" | grep -q '^text' && bat --color=always --style=plain -- "$1"
}
export -f preview

case "$1" in
    -r)
        while read -r i;do
            mv -vi -- "$i" . && rm -d "${i%/*}"
        done < <(find "$TRASH_DIR" -mindepth 2 -maxdepth 2 -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2- |
                 fzf -m -d '/' --no-sort --with-nth -1 --preview-window 'right:60%' --preview 'preview {}')
    ;;
    -*) help ;;
    *)
        for i in "$@";do
            if [ -e "$i" ];then
                rp=$(realpath "$i")
                destdir=$(mktemp -dp "${TRASH_DIR}/trash-XXXXXXXXXX");
                mv -v -- "$rp" "$destdir"
                echo "[$(date '+%Y-%m-%d %H:%M')] '$rp' -> '$destdir'" >>"$INFO_FILE"
            fi
        done
    ;;
esac
