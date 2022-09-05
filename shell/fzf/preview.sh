#!/usr/bin/env bash
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")

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
    jobs -p | xargs -r kill
}
function calculate_position {
    < <(</dev/tty stty size) \
        read -r TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION:-left}" in
        left|up|top) X=1 Y=0 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1    ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1))  ;;
    esac
}
function draw_preview {
    calculate_position

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="preview" \
        [x]="${X}" [y]="${Y}"               \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$1")
}
export -f draw_preview calculate_position 
