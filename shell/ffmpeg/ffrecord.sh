#!/bin/sh
# shellcheck disable=SC2046

case "$1" in
    -*|help|?) printf 'Usage: %s [audio]\n' "${0##*/}" ; exit 0 ;;
esac

pgrep -f ffmpeg && pkill -15 ffmpeg
icon=simplescreenrecorder 
for i in $(seq 3 -1 1);do
    notify-send -t 500 -i "$icon" "$i"
    sleep 0.5
done
notify-send -i "$icon" "Recording now..."

#alsa_input=alsa_input.pci-0000_00_0e.0.analog-stereo
alsa_input=alsa_output.pci-0000_00_0e.0.analog-stereo.monitor

case "$1" in
    audio) 
        ffmpeg -hide_banner -v 33 -y -video_size 1366x768 \
            -r 25 -f x11grab -i :0 -f pulse -ac 2 -i "$alsa_input" \
            -c:v h264 -crf 18 -profile:v baseline -pix_fmt yuv420p \
            ~/record_$(date +%d%m%Y%H%M%S).mp4
    ;;
    hdmi)
        echo hdmi
        ffmpeg -hide_banner -v 16 -stats -y -video_size 1280x1024 \
            -r 25 -f x11grab -i :0 -c:v h264 \
            -profile:v baseline -pix_fmt yuv420p \
            ~/record_$(date +%d%m%Y%H%M%S).mp4
    ;;
    *)
        ffmpeg -hide_banner -v 16 -stats -y -video_size 1366x768 \
            -r 25 -f x11grab -i :0 -c:v h264 \
            -profile:v baseline -pix_fmt yuv420p \
            ~/record_$(date +%d%m%Y%H%M%S).mp4
    ;;
esac
