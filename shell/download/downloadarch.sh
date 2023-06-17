#!/bin/sh

curl -s 'https://archlinux.org/download/' | grep -oP '(?<=href=")magnet:.*\.iso(?=")' | xargs -r aria2c
