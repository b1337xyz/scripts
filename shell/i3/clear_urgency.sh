#!/bin/sh
sleep 10
i3-msg -t get_workspaces | jq -Mcr '.[].name' | while read -r _
do
    i3-msg workspace next >/dev/null 2>&1
done
