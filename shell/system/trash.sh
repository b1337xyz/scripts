#!/usr/bin/env bash
set -e

INFO_FILE=~/.local/share/mytrash/info
TRASH_DIR=~/.local/share/mytrash
[ -d "$TRASH_DIR" ] || mkdir -vp "$TRASH_DIR"

if [ -e "$1" ];then
    for i in "$@";do
        destdir=$(mktemp -d "${TRASH_DIR}/trash-XXXXXXXXXX")
        mv -v -- "$i" "$destdir" || { rm -d "$destdir"; exit 1; }
        rp=$(realpath -- "$i")
        echo "[$(date '+%Y-%m-%d %H:%M')] '$rp' -> '$destdir'" >>"$INFO_FILE"
    done
else
    while read -r i;do
        mv -vi -- "$i" . && rm -d "${i%/*}"
    done < <(find "$TRASH_DIR" -mindepth 2 -maxdepth 2 -printf '%T@ %p\n' |
             sort -rn | cut -d' ' -f2- |
             fzf -m -d '/' --no-sort --with-nth -1 \
             --preview-window 'right:62%' \
             --preview 'ls -lhd {} ;file -bi {} | grep -q ^text && bat --color=always {}')
fi
