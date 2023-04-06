#!/usr/bin/env bash
set -e

while read -r i
do
    # ffmpeg can't copy the cover art from flac to opus
    ffmpeg -hide_banner -nostdin -i "$i" -map 0 -map_metadata 0 -f flac - |
        opusenc - "${i%.*}.opus" && rm -v "$i"
done < <(find . -type f -iname '*\.flac')

# while read -r i; do
#     ffmpeg -hide_banner -i "$i" -map_metadata 0 -map 0 -f flac - | opusenc - "${i%.*}.opus" && rm -v "$i"
# done < <(find . -type f -iname '*\.m4a')
