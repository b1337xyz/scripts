#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2155,SC2317,SC2120

root=$(realpath "$0") root=${root%/*}
source "${root}/preview.sh" || exit 1

declare -r -x readed_file=~/.cache/fzfmanga.readed
declare -r -x mainfile=$(mktemp --dry-run)

[ -f "$readed_file" ] || :>"$readed_file"

preview() {
    img=$(find -L "$1" -type f -iregex '.*\.\(jpg\|png\|webp\)' | sort -V | head -1)
    draw_preview "$img"
    for _ in $(seq $((LINES - 2)));do echo ;done
    grep -qxF "$1" "$readed_file" && printf '\033[1;32mReaded\033[m\n'
}
finalise() {
    printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"
    rm "$UEBERZUG_FIFO" "$mainfile" 2>/dev/null
    jobs -p | xargs -r kill
}
main() {
    local target
    [ -e "$2" ] && target=$(realpath -- "$2")
    case "$1" in
        open)
            if command -v devour &>/dev/null;then
                devour nsxiv -fqrs w "$target"
            else
                nsxiv -fqrs w "$target"
            fi 2>/dev/null
        ;;
        readed)
            if ! grep -qxF "$2" "$readed_file"; then
                echo "$2" >> "$readed_file"
            else
                echo "$2" | sed -e 's/[]\[\*\$]/\\\\&/g' | xargs -rI{} sed -i "/{}/d"
            fi
        ;;
        delete)
            [ -d "$target" ] || return 1
            printf 'Are you sure? (Y/n) '
            read -r ask
            [ "${ask,,}" != "y" ] && return
            find "$target" -maxdepth 1 -iregex '.*\.\(jpg\|png\)' -delete
            rm -d "$target"
        ;;
        hide)
            grep -xvFf "$readed_file" "$mainfile"
        ;;
        shuffle) shuf "$mainfile" ;;
        cd) search "$target" | tee "$mainfile" ;;
        *) search | tee "$mainfile" ;;
    esac
}
search() {
    find "${1:-.}" -mindepth 1 -maxdepth 1 \
        \( -type d -o -type l \) -printf '%f\n' | sort -V
}
export -f preview main search
trap finalise EXIT HUP INT
start_ueberzug
clear

main | fzf --header "ctrl-o open
ctrl-r reload
ctrl-s shuffle
ctrl-d remove
ctrl-a toggle readed
ctrl-h hide readed
ctrl-g change directory" \
    --preview "preview {}" --print0 \
    --preview-window "left:30%:border-none" \
    --border none \
    --bind 'ctrl-r:reload(main)' \
    --bind 'ctrl-s:reload(main shuffle)' \
    --bind 'ctrl-g:reload(main cd {})' \
    --bind 'ctrl-a:execute(main readed {})+refresh-preview' \
    --bind 'ctrl-h:reload(main hide)' \
    --bind 'ctrl-d:execute(main delete {})+reload(main)' \
    --bind 'ctrl-o:execute(main open {})' | xargs -0rI{} nsxiv -rfqs w '{}'

exit 0
