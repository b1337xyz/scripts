#!/usr/bin/env bash
pid=$$
lock=/tmp/.watch_scratchpad.sh
if [ -d "$lock" ];then
    for d in "$lock"/*;do pkill -P "${d##*/}" ;done
fi
sleep 1
mkdir -vp "${lock}/${pid}"
trap 'rm -vrf ${lock} 2>/dev/null' EXIT

COLORS=('#ee9090' '#ee90ee' '#eeee90' '#90eeee' '#90ee90' '#9090ee')

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

file=/tmp/i3status.scratchpad
prev=
retries=0
while [ -d "${lock}/${pid}" ] && pgrep -x i3 >/dev/null 2>&1
do

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
        killall -USR1 i3status || true
    done
    
    [ "$retries" -eq 5 ] && break
    retries=$((retries + 1))
    sleep 1
done
