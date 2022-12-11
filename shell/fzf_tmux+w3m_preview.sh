#!/usr/bin/env bash
declare -r -x W3MIMGDISPLAY=/usr/lib/w3m/w3mimgdisplay
declare -r -x PREVIEW_FIFO=/tmp/test.fifo

preview() { 
    clear
    fonth=15 # Size of one terminal row    in pixels
    fontw=8  # Size of one terminal column in pixels

    read -r width height < <(printf '5;%s' "$1" | "$W3MIMGDISPLAY")

    # clean up
    printf '6;%s;%s;%s;%s\n3' \
        "0" "0" "$(( COLUMNS * fontw ))" "$(( LINES * fonth ))" | "$W3MIMGDISPLAY"

    x=$((fontw * x))
    y=$((fonth * y))
    max_width=$((fontw * COLUMNS))
    max_height=$((fonth * LINES))

    if [ "$width" -gt "$max_width" ]; then
        height=$((height * max_width / width))
        width=$max_width
    fi
    if [ "$height" -gt "$max_height" ]; then
        width=$((width * max_height / height))
        height=$max_height
    fi

    printf '0;1;%s;%s;%s;%s;;;;;%s\n4;\n3;' \
        "0" "0" "$width" "$height" "$1" | "$W3MIMGDISPLAY"
}

if [ -n "$PREVIEW_MODE" ];then
    sleep 1
    while :;do
        while read -r i; do
            [ "$i" = "die" ] && exit 0
            preview "$i"
        done < "$PREVIEW_FIFO"
    done
fi

script=$(realpath "$0")

mkfifo "$PREVIEW_FIFO"
tmux split-window -h -d -l '53%' -e "PREVIEW_MODE=1" "$script"
tmux swap-pane -D

end() {
    echo die > "$PREVIEW_FIFO"
    rm "$PREVIEW_FIFO"
}
trap end EXIT HUP INT

preview_fifo() {
    echo "$1" | tee "$PREVIEW_FIFO"
}
export -f preview_fifo

find ~/Pictures/ -maxdepth 3 -iname '*.jpg' |
    fzf --preview='preview_fifo {}' --preview-window='down,1'
