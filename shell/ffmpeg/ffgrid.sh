#!/usr/bin/env bash

input=$1
d=$2
cmd=(ffmpeg -hide_banner -v 16 -stats -y)

[[ "$d" =~ [0-9]*x[0-9]* ]] || exit 1

cols=${d%x*}
rows=${d##*x}
n=$(( cols * rows  ))
filter=
for (( i=0 ; i < n ; i++ ));do
    cmd+=( -i "\"$input\"")
    filter="${filter}[$i:v]"
done
# cmd+=( -t 10)
filter="${filter}xstack=inputs=$n:layout="

cmd+=( -filter_complex )
for (( i=0 ; i < cols; i++ ));do
    case "$i" in
        0) w=0 ;;
        1) w=w0 ;;
        *) w="${w}+w0" ;;
    esac
    for (( j=0 ; j < rows ; j++ ));do
        case "$j" in
            0) h=0 ;;
            1) h=h0 ;;
            *) h="${h}+h0" ;;
        esac
        filter="${filter}${w}_${h}|"
    done
done

cmd+=( "\"${filter}[v]\"" -map '"[v]"' -crf 16 -an -c:v libx264 \
    -preset fast -pix_fmt yuv420p -s 1366x780 "${input%.*}_${d}.mp4")

eval "${cmd[*]}"
