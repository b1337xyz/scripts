#!/bin/sh
pkill -x dunst #  && $(dunst >/dev/null 2>&1 &)
notify-send -u low "Low notification" "$(uname -a)" 
notify-send -u normal "Normal notification" "$(uname -a)" 
notify-send -u critical "Critical notification" "$(uname -a)" 
