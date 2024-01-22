#!/usr/bin/env bash
# source: https://superuser.com/questions/712893/how-to-split-a-video-file-by-size-with-ffmpeg
set -e
while [ $# -gt 0 ];do
	case "$1" in
		[0-9]*) size=$1 ;;
		*) [ -f "$1" ] && FILE=$1 ;;
	esac
	shift
done
duration=$(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of default=noprint_wrappers=1:nokey=1 |cut -d. -f1)
cur_duration=0
basename="${FILE%.*}"
ext="${FILE##*.}"
part=1
while [[ $cur_duration -lt $duration ]]; do
	part_file="${basename}-part-${part}.$ext"
	ffmpeg -hide_banner -ss "$cur_duration" -async 1 -i "$FILE" -fs "$size" -c copy "$part_file"
	new_duration=$(ffprobe  -i "$part_file" -show_entries format=duration -v quiet -of default=noprint_wrappers=1:nokey=1 | cut -d. -f1)
	cur_duration=$((cur_duration + new_duration))
	part=$((part + 1))
done
