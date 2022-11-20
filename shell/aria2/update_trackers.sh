#!/bin/sh

conf=~/.config/aria2/aria2.conf
url=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt

curl -s "$url" | tee ~/.cache/trackers_best.txt | awk '
/[a-z]/{ s = s","$0 }
END {
    sub(/^,/, "", s)
    gsub(/\//, "\\\\/", s)
    printf("bt-tracker=%s\n", s)
}' | xargs -trI{} sed -i 's/^bt-tracker=.*/{}/' "$conf"
