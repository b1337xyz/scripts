#!/bin/sh

output=new_${1##*/}
if ! ffmpeg -i "$1" -map_metadata 0 -map 0:v -map 0:a \
    -map 0:s:m:title:'PortuguÃªs(Brasil)'   \
    -map 0:s:m:title:'English(US)'          \
    -map 0:t? \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -metadata:s:s:1 language=eng        \
    -metadata:s:s:1 title='English'     \
    -disposition:s:0 default            \
    -c copy "$output"
then
    rm -vf "$output"
    exit 1
fi
