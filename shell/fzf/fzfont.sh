#!/usr/bin/env bash
# shellcheck disable=SC1090
source ~/.scripts/shell/fzf/preview.sh
declare -r -x DEFAULT_PREVIEW_POSITION=right
declare -r -x thumbs=~/.cache/thumbnails/fonts
[ -d "$thumbs" ] || mkdir -vp "$thumbs"

function preview {
    font_name=${1##*/}
    font_name=${font_name%.*}
    img="${thumbs}/${font_name}.jpg"
    imgsize=500x700
    fontsize=30
    bgc="#000000"
    fgc="#ffffff"
    preview_text="▁▂▃▄▅▆▇█\nABCDEFGHIJKLM\nNOPQRSTUVWXYZ\nabcçdefghijklm\nnopqrstuvwxyz\n1234567890\n!@#$\%^&*,.;:\n_-=+'\"|\\(){}[]"

    if ! [ -f "$img" ];then
        convert -size "$imgsize" xc:"$bgc" -fill "$fgc" \
            -pointsize "$fontsize" -font "$1" -gravity center \
            -annotate +0+0 "$preview_text" "$img"
    fi

    draw_preview "$img"
}
function copy {
    fc-list -f '%{family}:%{file}\n' | grep -F "$1" | cut -d':' -f1 | tr -d \\n | xclip -sel clip
    notify-send "Clipboard" "$(xclip -sel clip -o)"
}
export -f preview copy
trap finalise EXIT
start_ueberzug

if [ -d "$1" ];then
    find "$1" -iregex '.*\.\(ttf\|otf\)'
else
    fc-list -f '%{file}\n' | grep -iP '\.(ttf|otf)'
fi | sort -uV | fzf -d '/' --with-nth -1 \
    -e --preview "preview {}" \
    --preview-window 'right:60%,border-left' \
    --bind 'enter:execute(copy {})' \
