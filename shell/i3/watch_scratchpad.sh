#!/bin/sh
set -e

lock=/tmp/.${0##*/}
[ -d "$LOCK" ] && exit 1
mkdir -vp "${lock}/$$"
trap 'rm -vrf ${lock}' EXIT

get_scratchpad_class() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. | .window_properties? |
    "[\(.class? // empty | if length > 18 then rtrimstr(.[:15])+"..." else . end)]"' \
        | tr \\n ' ' | sed 's/^/ /'
}

get_scratchpad_name() {
    i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
    select(.name == "__i3_scratch") |
    (.floating_nodes + .nodes) | .. |
    "[\(.name? // empty | if length > 18 then rtrimstr(.[:15])+"..." else . end)]"' \
        | tr \\n ' ' | sed 's/^/ /'
}

file=/tmp/i3status.scratchpad
i3-msg -t subscribe -m '[ "window" ]' | while read -r _;do
    scratchpad=$(get_scratchpad_name)
    [ -z "$scratchpad" ] && continue
    if ! diff -q <(printf '%s' "$scratchpad") "$file"
    then
        printf '%s' "$scratchpad" > "$file"
        killall -USR1 i3status
    fi
done
