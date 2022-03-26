#!/bin/sh
output="${1%.*}.mp3"
i=1
while [ -s "$output" ];do
    output="${i}_${1%.*}.mp3"
    i=$((i+1))
done
printf '%s \e[1;37m~\e[34m>\e[m %s\n' "$1" "$output"

if ! ffmpeg -hide_banner -v 16 -i "$1" -vn -c:a libmp3lame -q:a 5 "$output";then
    rm -v "$output"; exit 1
fi
exit 0
