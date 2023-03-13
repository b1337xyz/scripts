#!/usr/bin/env bash

url='https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/'
url=${url}/$(curl -s "$url" | grep -oP '(?<=href=")debian-\d+\.\d+\.\d+-amd64-netinst\.iso(?=">)' | tail -1)

aria2c -d . "$url"

