#!/usr/bin/env bash
pid=$$
lock=/tmp/.watch_i3.sh
if [ -d "$lock" ];then
    for d in "$lock"/*;do pkill -P "${d##*/}" ;done
fi
sleep 1
mkdir -vp "${lock}/${pid}"
trap 'rm -vrf ${lock} 2>/dev/null' EXIT

COLORS=('#ee9090' '#ee90ee' '#eeee90' '#90eeee' '#90ee90' '#9090ee')

get_scratchpad_classes() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. | .window_properties? | .class? // empty'
}

get_scratchpad_names() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. | .name? // empty'
}

trim_str() {
    local s
    s=$1
    if [ "${#s}" -gt "$2" ];then 
        echo -n "${s::40}" | sed 's/\s\+$//; s/$/.../'
    else
        echo "$1"
    fi
}

refresh() {
    killall -USR1 i3status || true
}

scratchpad_file=/tmp/i3status.scratchpad
window_file=/tmp/i3status.window
prev=
retries=0
while [ -d "${lock}/${pid}" ] && pgrep -x i3 >/dev/null 2>&1
do

    i3-msg -t subscribe -m '[ "window" ]' | while read -r j;do

        focused_name=$(jq -Mr 'select(.change == "title"  or .change == "focus") | .container.name' <<< "$j")
        if [ -n "$focused_name" ];then
            s=$(trim_str "$focused_name" 83)
            printf '<span color="#E0FFF0">%s</span>' "$s" > "$window_file"
            refresh
        fi

        curr=$(get_scratchpad_names)
        if [ "$curr" != "$prev" ];then
            prev=$curr
            c=0
            while IFS= read -r i;do
                [ -z "$i" ] && { echo -n; break; }
                i=$(trim_str "$i" 43)
                printf '[<span color="%s">%s</span>]' "${COLORS[c]}" "$i"
                c=$(( (c+1) % 6 ))
            done <<< "$curr" > "$scratchpad_file"
            refresh
        fi
    done
    
    [ "$retries" -eq 5 ] && break
    retries=$((retries + 1))
    sleep 1
done
