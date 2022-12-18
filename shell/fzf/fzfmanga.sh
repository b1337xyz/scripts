#!/usr/bin/env bash

source ~/.scripts/shell/fzf/preview.sh

declare -r -x readed_file=~/.cache/fzfmanga.readed
declare -r -x mainfile=$(mktemp --dry-run)

[ -f "$readed_file" ] || :>"$readed_file"

preview() {
    img=$(find -L "$1" -type f -iregex '.*\.\(jpg\|png\|webp\)' | sort -V | head -1)
    draw_preview "$img"
    for _ in $(seq $((LINES - 2)));do echo ;done
    files=$(find "$1" -type f | wc -l)
    grep -qxF "$1" "$readed_file" && printf '\033[1;32mReaded\033[m\n'
    printf 'Files: %s\n' "$files"
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
            set -- nsxiv -fqrs w "$target"
            if command -v devour &>/dev/null;then
                devour "$@"
            else
                $("$@")
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
            read ask
            [ "${ask,,}" != "y" ] && return
            find "$target" -maxdepth 1 -iregex '.*\.\(jpg\|png\)' -delete
            rm -d "$target"
        ;;
        hide)
            grep -xvFf "$readed_file" "$mainfile"
        ;;
        *)
            find . -mindepth 1 -maxdepth 1 \
                \( -type d -o -type l \) -printf '%f\n' | sort -V | tee "$mainfile"
        ;;
    esac
}
export -f preview main
trap finalise EXIT HUP INT
start_ueberzug
clear

main | fzf --header "ctrl-o open
ctrl-r remove
ctrl-a toggle readed
ctrl-h hide readed" \
    --preview "preview {}" --print0 \
    --preview-window "left:30%:border-none" \
    --border none \
    --bind 'ctrl-a:execute(main readed {})+refresh-preview' \
    --bind 'ctrl-h:reload(main hide)' \
    --bind 'ctrl-r:execute(main delete {})+reload(main)' \
    --bind 'ctrl-o:execute(main open {})' | xargs -0rI{} nsxiv -rfqs w '{}'

exit 0
