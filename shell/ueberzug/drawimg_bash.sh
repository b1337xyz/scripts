#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
file -Lbi -- "$1" 2>/dev/null | grep -q '^image/' || exit 1

declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x PREVIEW_ID="preview"

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
    rm "${UEBERZUG_FIFO}" &>/dev/null
}
function draw_img {
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="0" [y]="0" \
        [width]="$((COLUMNS))" [height]="$((LINES - 2))" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
trap finalise EXIT
start_ueberzug

clear
draw_img "$1"
for _ in $(seq "$LINES");do echo ;done
string="Press any key"
for _ in $(seq $((COLUMNS / 2 - (${#string} / 2) - 1)));do echo -n ' ' ;done
read -r -s -n1 -p "$string" </dev/tty
clear
