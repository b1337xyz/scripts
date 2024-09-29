#!/usr/bin/env bash
set -e

lock=/tmp/.${0##*/}
if [ -d "$lock" ];then
    for d in "$lock"/*;do kill "${d##*/}" && rm -d "$d" ;done
    sleep .2
fi
mkdir -vp "${lock}/$$"
trap 'rm -vrf ${lock} 2>/dev/null' EXIT

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
        [ -z "$i" ] && { echo -n; break; }
        [ "${#i}" -gt 43 ] && i=$(echo -n "${i::40}" | sed 's/\s+$//')...
        printf '[<span color="%s">%s</span>]' "${COLORS[c]}" "$i"
        c=$(( (c+1) % 6 ))
    done <<< "$curr" > "$file"
    killall -USR1 i3status
done
