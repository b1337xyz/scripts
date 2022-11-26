#!/usr/bin/env bash
SIZE="800x1080"
FONT_SIZE=52
BG_COLOR="#000000"
FG_COLOR="#ffffff"
PREVIEW_TEXT="ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\n\
abcdefghijklm\nnopqrstuvwxyz\n1234567890\n!@#$\%^&*,.;:\n_-=+'\"|\\(){}[]"

use_dmenu=0
case "$1" in
    --dmenu) use_dmenu=1 ;;
esac

# font_name=$(fc-list | cut -d':' -f2 | sort | uniq | fzf | sed 's/^\s*//;s/\s*$//')
# [ -z "$font_name" ] && exit 1
# font_path=$(fc-list | grep -F "$font_name" | head -n1 | cut -d':' -f1)
# image="/tmp/.${font_name}.jpg"
if [ "$use_dmenu" -eq 1 ];then
    font_path=$(fc-list | cut -d':' -f1 | dmenu -i -l 20 -c)
else
    font_path=$(fc-list | cut -d':' -f1 | fzf)
fi
[ -z "$font_path" ] && exit 1
image="${font_path##*/}"
image="/tmp/.${image%.*}.jpg"

if ! [ -f "$image" ];then
    convert -size "$SIZE" xc:"$BG_COLOR" -fill "$FG_COLOR" \
        -pointsize "$FONT_SIZE" -font "$font_path" -gravity center \
        -annotate +0+0 "$PREVIEW_TEXT" "$image" || exit 1
fi
sxiv -fqp "$image"
font_name="${font_path##*/}"
font_name="${font_name%.*}"
echo -n "$font_name" | xclip -sel clip
notify-send "$font_name copied to clipboard"
