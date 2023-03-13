#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2155,SC2317,SC2120
set -e

root=$(realpath "$0") root=${root%/*}
source "${root}/preview.sh" || exit 1

declare -r -x readed_file=~/.cache/fzfmanga.readed
declare -r -x mainfile=$(mktemp --dry-run)

[ -f "$readed_file" ] || :>"$readed_file"

preview() {
    img=$(find "$1" -type f -iregex '.*\.\(jpg\|png\|webp\)' | sort -V | head -1)
    draw_preview "$img"
    for _ in $(seq $((LINES - 6)));do echo ;done
    printf 'files: '
    find "$1" -type f -iregex '.*\.\(jpg\|png\|webp\)' | wc -l
    grep -qxF "$1" "$readed_file" && printf '\033[1;32mReaded\033[m\n'
    printf '%s\n' "${1##*/}"
}
finalise() {
    printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"
    rm "$UEBERZUG_FIFO" "$mainfile" 2>/dev/null
    jobs -p | xargs -r kill
}
main() {
    case "$1" in
        open)
            if hash devour; then
                devour nsxiv -bfqrs w "$2"
            else
                nsxiv -bfqrs w "$2"
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
            [ -d "$2" ] || return 1
            printf '{"action": "remove", "identifier": "preview"}\n' > "$UEBERZUG_FIFO"
            clear
            printf 'Deleting "%s", are you sure? (y/N) ' "$2"
            read -r ask
            [ "${ask,,}" != "y" ] && return
            find "$2" -maxdepth 1 -iregex '.*\.\(jpg\|png\)' -delete
            rm -d "$2"
        ;;
        hide)
            grep -xvFf "$readed_file" "$mainfile"
        ;;
        shuffle) shuf "$mainfile" ;;
        cd) search "$2" | tee "$mainfile" ;;
        *) search | tee "$mainfile" ;;
    esac
}
search() {
    find "${1:-.}" -mindepth 1 -maxdepth 1 \
        \( -type d -o -type l \) | sort -V
}
export -f preview main search
trap finalise EXIT
start_ueberzug

header="ctrl-o open
ctrl-r reload
ctrl-s shuffle
ctrl-d remove
ctrl-a toggle readed
ctrl-h hide readed
"

main | fzf --header "$header" \
    --preview "preview {}" \
    --preview-window "left:30%:border-none:wrap" \
    --border none \
    --bind 'ctrl-r:reload(main)' \
    --bind 'ctrl-s:reload(main shuffle)' \
    --bind 'ctrl-h:reload(main hide)' \
    --bind 'ctrl-g:reload(main cd {})' \
    --bind 'ctrl-a:execute(main readed {})+refresh-preview' \
    --bind 'ctrl-d:execute(main delete {})+reload(main)' \
    --bind 'ctrl-o:execute(main open {})'

exit 0
