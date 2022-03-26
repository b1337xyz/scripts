#!/usr/bin/env bash
declare -r -x DEFAULT_PREVIEW_POSITION="left"
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
    &>/dev/null \
        rm "${UEBERZUG_FIFO}"
    #&>/dev/null \
    #    kill $(jobs -p)
}

function calculate_position {
    < <(</dev/tty stty size) \
        read TERMINAL_LINES TERMINAL_COLUMNS

    case "${PREVIEW_POSITION:-${DEFAULT_PREVIEW_POSITION}}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 2)) ;;
    esac
}

function draw_preview {
    calculate_position

    img=$(printf '%s' "${1##*/}" | md5sum | awk '{print $1}')
    img=~/.cache/covers/"${img}.jpg"
    
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="$((COLUMNS + 2))" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img")
        # add [synchronously_draw]=True if you want to see each change
}

trap finalise EXIT
start_ueberzug 2>/dev/null

export -f draw_preview calculate_position

find -L ~/Videos -mindepth 2 -maxdepth 2 | sort | fzf --preview "draw_preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:22%"
