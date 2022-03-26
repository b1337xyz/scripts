#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    <"${UEBERZUG_FIFO}" \
        ueberzug layer --parser bash --silent &
    # prevent EOF
    3>"${UEBERZUG_FIFO}" \
        exec
}
function finalise {
    3>&- \
        exec

    rm "${UEBERZUG_FIFO}"
}
function draw_preview {
    image=$(find "$1" -iregex '.*\.\(jpg\|png\|webp\|gif\)' | sort | head -n1)
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="preview" \
        [x]="0" [y]="0" \
        [width]="$COLUMNS" [height]="$((LINES - 1))" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$image")

    for _ in $(seq $((LINES - 1)));do echo ;done
    files=$(find "$1" -type f | wc -l)
    printf 'Files: %s\n' "$files"
}
function open {
    sxiv -fqrs w "$1"
}
export -f draw_preview open

trap finalise EXIT
start_ueberzug

find . -mindepth 1 -maxdepth 1 -printf '%f\n' |
    fzf --preview "draw_preview {}" \
    --preview-window "left:50%:border-none" \
    --border none \
    --bind 'ctrl-o:execute(open {})' | xargs -rI{} sxiv -fqrs w {}
