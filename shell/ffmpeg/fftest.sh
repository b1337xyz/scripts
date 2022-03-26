#!/bin/sh

ffmpeg -v 16 -stats -i "$1" -map 0 -c copy -f null -
