#!/bin/sh
set -e

lock=/tmp/.${0##*/}
[ -d "$LOCK" ] && exit 1
mkdir -vp "${lock}/$$"
trap 'rm -vrf ${lock}' EXIT

get_scratchpad_class() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. | .window_properties? | .class? // empty'
}

get_scratchpad_name() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. | .name? // empty'
}

COLORS=(
'#ee9090'
'#ee90ee'
'#eeee90'
'#90eeee'
'#90ee90'
'#9090ee'
)

file=/tmp/i3status.scratchpad
prev=
rm "$file"
i3-msg -t subscribe -m '[ "window" ]' | while read -r _;do
    curr=$(get_scratchpad_name)
    [ "$curr" = "$prev" ] && continue
    prev=$curr

    c=0
    while IFS= read -r i;do
        printf '[<span color="%s">%s</span>]' "${COLORS[c]}" "$i"
        c=$(( (c+1) % 6 ))
    done <<< "$curr" > "$file"
    killall -USR1 i3status
done
