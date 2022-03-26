#!/usr/bin/env bash
# shellcheck disable=SC2155
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x PREVIEW_ID="preview"
declare -r -x tmpfile=$(mktemp)
declare -r -x FZF_DEFAULT_COMMAND="find . -maxdepth 1 -iregex '.*\.\(jpg\|jpeg\|png\)$'"

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
    rm "${UEBERZUG_FIFO}" "$tmpfile" &>/dev/null
}

function calculate_position {
    < <(</dev/tty stty size) \
        read -r TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
function draw_preview {
    calculate_position

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
export -f draw_preview calculate_position

trap finalise EXIT
start_ueberzug

fzf -m -0 --disabled --preview "draw_preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:75%:border-sharp" \
    --bind 'ctrl-d:execute(rm -v {+})+reload()+clear-query+first' | while read -r i;do [ -f "$i" ] && rm -vf "$i" ;done
