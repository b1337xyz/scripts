#!/bin/sh

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name' | head -1)
end() {
    pkill -9 unclutter
    i3-msg bar mode toggle
    i3-msg workspace "$workspace"
}
trap end EXIT INT HUP
i3-msg workspace "lock"
unclutter -b --jitter 9999 --start-hidden --hide-on-touch
xtrlock
