#!/bin/sh
pkill -x dunst && dunst &
sleep 0.3
notify-send -u low "Low notification" "$(uname -a)" 
notify-send -u normal "Normal notification" "$(uname -a)" 
notify-send -u critical "Critical notification" "$(uname -a)" 
