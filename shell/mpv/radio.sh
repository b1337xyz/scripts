#!/bin/sh

url=$(dmenu -l 10 -i -c << EOF | awk '{print $2}'
J-Pop       https://igor.torontocast.com:1025
City-Pop    https://igor.torontocast.com:1710
J-Hip-Hop   https://kathy.torontocast.com:3350
J-Rock      https://kathy.torontocast.com:3340
J1GOLD      https://jenny.torontocast.com:2000/stream/J1GOLD
J1HD        https://maggie.torontocast.com:2000/stream/J1HD
J1HISTS     https://jenny.torontocast.com:2000/stream/J1HITS
J1XTRA      https://jenny.torontocast.com:2000/stream/J1XTRA
Kawaii      https://kathy.torontocast.com:3060
Vaporwave   http://radio.plaza.one/opus
Vaporwave   https://ice4.somafm.com/vaporwaves-128-mp3
EOF
)
[ -z "$url" ] && exit 1
xterm -name floating_terminal -title radio -e "mpv --profile=radio $url"
