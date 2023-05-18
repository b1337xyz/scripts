#!/usr/bin/env bash

out=${1##*/} out=${out%.*}.webm
ffmpeg -hide_banner -t 13 -i "$1" -c:v libvpx -b:v 1M "$out"
