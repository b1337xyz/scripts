#!/usr/bin/env bash

[ -f "$1" ] || exit 1

# convert "$1" -fuzz 1% -fill 'rgb(255,200,255)' -opaque 'rgb(234, 205, 87)'  out.jpg
# convert "$1" -fuzz 5% -fill 'rgb(240,210,240)' -opaque 'rgb(235, 214, 89)'  out.jpg

read -r -p "ORIGINAL HEX: " hex
read -r -p "NEW HEX VALUE: " new_hex
[ -z "$hex" ] && exit 1
[ -z "$new_hex" ] && exit 1
convert "$1" -fuzz 1% -fill "$new_hex" -opaque "$hex" out.jpg
sxiv out.jpg
