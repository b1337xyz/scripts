#!/usr/bin/env bash
# shellcheck disable=SC2016
set -e

declare -r -x TRASH_DIR=~/.local/share/mytrash
[ -d "$TRASH_DIR" ] || mkdir -vp "$TRASH_DIR"

preview() {
    cat "${1%/*}.info"; printf -- '----\n'
    if [ -d "$1" ];then
        tree -C "$1"
    else
        mime=$(file -bi "$1") 
        case "$mime" in
            text*) bat --color=always "$1" ;;
        esac
        case "${1##*.}" in
            zip|rar|7z) atool -l "$1" ;;
        esac
    fi
}

remove() {
    for i in "$@";do
        rm -rf "${i%/*}" "${i%/*}.info"
    done
}

load() {
    find "$TRASH_DIR" -mindepth 2 -maxdepth 2 -printf '%C@ %p\n' | sort -rn | cut -d' ' -f2-
}

export -f load preview remove

if [ -e "$1" ]; then
    for i in "$@";do
        rp=$(realpath -- "$i")
        dest=$(mktemp -d "${TRASH_DIR}/trash-XXXXXXXXXX")
        mv -v -- "$i" "$dest" || { rm -d "$dest"; exit 1; }
        echo "$(date '+%Y-%m-%d %H:%M') $rp" >>"${dest}.info"
    done
else
    while read -r i;do
        orig=$(cut -d' ' -f3- "${i%/*}.info") orig=${orig%/*}
        dest=
        if [ -d "$orig" ]; then
            printf 'move to %s? [Y/n] ' "$orig"
            read -r ask </dev/tty
            [ "${ask,,}" = "y" ] && dest=${orig}
        fi
        mv -vi -- "$i" "${dest:-.}" && rm -dv "${i%/*}.info" "${i%/*}"
    done < <(load | fzf -0 -m -d '/' --no-sort --with-nth -1 --border bottom \
             --border-label '╢ ctrl-e open in vim | ctrl-r remove ╟' \
             --bind 'ctrl-o:execute-silent(xdg-open {})+reload(load)' \
             --bind 'ctrl-r:execute-silent(remove {+})+reload(load)' \
             --bind 'ctrl-e:execute-silent($TERMINAL -e vim {})' \
             --preview-window 'right:65%:wrap' --preview 'preview {}')
fi
