#!/usr/bin/env bash

set -e

INFO_FILE=~/.local/share/mytrash/info
declare -r -x TRASH_DIR=~/.local/share/mytrash/files
[ -d "$TRASH_DIR" ] || mkdir -p "$TRASH_DIR"

preview() {
    local file="${TRASH_DIR}/$1"
    stat -c '%x' "$file"
    file -bi -- "$file" | grep -q '^text' &&
        bat --color=always --style=plain -- "$file"
}
export -f preview

while [ $# -gt 0 ];do
    case "$1" in
        -r)
            find "$TRASH_DIR" -type f -printf '%T@ %f\n' | sort -rn | cut -d' ' -f2-  |
            fzf --no-sort -m --preview-window 'right:60%' \
                --preview 'preview {}' --print0 | xargs -r0I{} mv -vi "${TRASH_DIR}/{}" .
        ;;
        -*) printf 'usage: %s -r <files*>\n' "${0##*/}"; exit 1 ;;
        *)
            if [ -f "$1" ];then
                fname="${1##*/}"
                f="${TRASH_DIR}/$fname"
                rp=$(realpath "$1")
                n=1
                while [ -f "$f" ];do
                    f="${TRASH_DIR}/${fname}.$n"
                    n=$((n + 1))
                done
                mv -v -- "$1" "$f"
                echo "[$(date '+%Y.%m.%d %H:%M:%S')] '$rp' > '$f'" >> "$INFO_FILE"
            fi
        ;;
    esac
    shift
done
