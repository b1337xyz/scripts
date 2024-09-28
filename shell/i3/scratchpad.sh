#!/bin/sh
i3-msg -t get_tree | jq -Mcr '.. | .nodes? // empty | .[] |
select(.name == "__i3_scratch") |
(.floating_nodes + .nodes) | .. | .window_properties? |
"[\(.class? // empty | if length > 18 then rtrimstr(.[:15])+"..." else . end)]"' \
    | tr \\n ' ' | sed 's/^/ /' > /tmp/i3status.scratchpad

killall -USR1 i3status
