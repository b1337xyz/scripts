#!/usr/bin/env bash
pid=$$
lock=/tmp/.watch_i3.sh
if [ -d "$lock" ];then
    for d in "$lock"/*;do
        if [ -d "$d" ];then
            { echo "${d##*/}"; ps -o pid= --ppid "${d##*/}"; } | xargs -tr kill
            # pkill -P "${d##*/}"
        fi
    done && sleep 1
fi
lock=${lock}/${pid}
mkdir -vp "$lock"
trap 'rm -d "$lock" && rm -d "${lock%/*}" 2>/dev/null' EXIT

COLORS=('#AA8080' '#aa80aa' '#aaaa80' '#80aaaa' '#80aa80' '#8080aa')

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

escape() {
    python3 -c 'print(__import__("html").escape(__import__("sys").stdin.readline()), end="")'
}

scratchpad_file=/tmp/i3status.scratchpad
window_file=/tmp/i3status.window
prev=
prev_window=
while [ -d "${lock}" ] && pgrep -x i3 >/dev/null 2>&1 && sleep 3
do
    i3-msg -t subscribe -m '[ "window" ]' | while read -r j
    do
        focused_name=$(jq -Mr 'select(.change == "title"  or .change == "focus") | .container.name' <<< "$j" 2>/dev/null)
        if [ -n "$focused_name" ] && [ "$focused_name" != "$prev_window" ];then # avoid unecessary killing
            prev_window=$focused_name
            s=$(trim_str "$focused_name" 63 | escape)
            printf '<span color="#E0FFF0">%s</span>' "$s" > "$window_file"
            refresh
        fi

        curr=$(get_scratchpad_names)
        if [ "$curr" != "$prev" ];then
            prev=$curr
            c=0
            while IFS= read -r i;do
                [ -z "$i" ] && { echo -n; break; }
                i=$(trim_str "$i" 43 | escape)
                printf '[<span color="%s">%s</span>]' "${COLORS[c]}" "$i"
                c=$(( (c+1) % 6 ))
            done <<< "$curr" > "$scratchpad_file"
            refresh
        fi
    done
done
