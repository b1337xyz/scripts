#!/bin/sh
ffmpeg -hide_banner -f v4l2 -video_size 640x480 -i /dev/video0 -vframes 1 camera_%03d.png
