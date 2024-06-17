#!/usr/bin/env bash
declare -A windows=()

while IFS=: read -r id name;do
    [ "$name" = null ] && continue
    windows[${id}]="${name}"
done < <(i3-msg -t get_tree | i3-msg -t get_tree |
    jq -r '.. | select(.window_properties? and .window_type == "normal") | select(.focused | not) | "\(.id):\(.name)"')

name=$(for k in "${windows[@]}";do echo "$k" ;done | dmenu -l 10 -c -i)
for id in "${!windows[@]}";do
    if [ "$name" = "${windows[${id}]}" ];then
        i3-msg "[con_id=${id##*:}]" focus
        break
    fi
done
