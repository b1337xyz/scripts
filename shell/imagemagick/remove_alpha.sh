#!/bin/sh

out=new_${1##*/}
convert -background black -alpha remove -alpha off "$1" "$out"
