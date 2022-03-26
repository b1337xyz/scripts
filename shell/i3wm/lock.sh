#!/bin/sh

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name' | head -n1)
end() {
    pkill unclutter
    i3-msg bar mode toggle
    i3-msg workspace "$workspace"
}
end
trap end EXIT
i3-msg workspace "lock"
unclutter -b --jitter 99999 --start-hidden --hide-on-touch
xtrlock
