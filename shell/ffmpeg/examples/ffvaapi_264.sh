ffmpeg -vaapi_device /dev/dri/renderD128 \
    -i "$1" -c:a copy \
    -vf 'format=nv12,hwupload' -c:v h264_vaapi \
    -qp 18 output.mp4
