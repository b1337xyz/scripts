#!/usr/bin/env bash

out=new_${1##*/}
if ! ffmpeg -hide_banner -i "$1" -c:v libvpx -maxrate 5M -b:v 2600k -pix_fmt yuv420p 
then
    rm "$out"
    exit 1
fi

