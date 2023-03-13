#!/bin/sh

ffmpeg -v 24 -stats -i "$1" -map 0 -c copy -f null -
