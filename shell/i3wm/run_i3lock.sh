#!/bin/sh
img=~/.cache/current_bg.jpg
scrot -q 100 -o -m /tmp/scrlock.png 
convert /tmp/scrlock.png -resize 1366x768\! -blur 0x2 RGB:- |
    i3lock -u -e --raw 1366x768:rgb --image /dev/stdin
#convert "$img" -resize 1366x768\! RGB:- |
#    i3lock -u -e --raw 1366x768:rgb --image /dev/stdin

[ "$1" = "off" ] && xset dpms force off
