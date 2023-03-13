#!/bin/sh

output_dir=~/Documents/speedtest
[ -d "$output_dir" ] || mkdir -p "$output_dir"
speedtest-cli --json > "${output_dir}/$(date +speedtest_%Y-%m-%d_%H:%M.json)"
