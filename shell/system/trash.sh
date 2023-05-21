#!/usr/bin/env bash
set -e

INFO_FILE=~/.local/share/mytrash/info
TRASH_DIR=~/.local/share/mytrash
[ -d "$TRASH_DIR" ] || mkdir -vp "$TRASH_DIR"

preview() {
    stat -c '%s %z' "$1"
    if [ -d "$1" ];then
        tree -C "$1"
    else
        mime=$(file -bi "$1")
        case "$mime" in
            text*) bat --color=always "$1" ;;
        esac
    fi
}
export -f preview

if [ -e "$1" ];then
    for i in "$@";do
        destdir=$(mktemp -d "${TRASH_DIR}/trash-XXXXXXXXXX")
        mv -v -- "$i" "$destdir" || { rm -d "$destdir"; exit 1; }
        rp=$(realpath -- "$i")
        echo "[$(date '+%Y-%m-%d %H:%M')] '$rp' -> '$destdir'" >>"$INFO_FILE"
    done
else
    while read -r i;do
        [ -e "$i" ] && mv -vi -- "$i" . && rm -d "${i%/*}"
    done < <(find "$TRASH_DIR" -mindepth 2 -maxdepth 2 -printf '%C@ %p\n' |
             sort -rn | cut -d' ' -f2- |
             fzf -m -d '/' --no-sort --with-nth -1 \
             --bind 'ctrl-e:execute($TERMINAL -e vim {})' \
             --preview-window 'right:68%' --preview 'preview {}')
fi
