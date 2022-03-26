#!/bin/sh


url="$1"
rpath=$(realpath "$0")
rpath="${rpath%/*}"
cd "$rpath" || exit 1

main_dir=/tmp/.4chan
html=$(mktemp -u "${main_dir}/XXXXXXXX.html")

[ -d "$main_dir" ] || mkdir "$main_dir"
ln -rs script.js style.css "$main_dir"

scrap() {
    curl -s "$url" | grep -oP '(?<=href=")[^"]*\.(jpg|png|gif|webm)' | sort -u | while read -r i;do
        i="http:$i"
        case "${i##*.}" in
            jpg|png|gif)
                printf '<div class="post"><a target="_blank" href="%s"><img src="%s"></a></div>\n' "$i" "$i" ;;
            webm)
                printf '<div class="post"><video controls muted loop><source src="%s" type="video/webm"></video></div>\n' "$i" ;;
        esac
    done
}

cat << EOF > "$html"
<!DOCTYPE html>
<html>
    <head>
        <title></title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="style.css">
    </head>
    <body>
        <div id="menu">
            <button onclick="showAll()">Show All</button>
            <button onclick="unmute(this)">Unmute</button>
            <button onclick="onlyVid()">Only videos</button>
            <button onclick="onlyGif()">Only gifs</button>
            <button onclick="onlyImg()">Only png/jpg</button>
            <button onclick="onlyWide()">Width >= Height</button>
            <button onclick="onlyTall()">Width < Height</button>
            <input type="range" min="1" max="100" value="100" id="slider">
        </div>
        <div id="url"><a href="$url">$url</a></div>
        <div id="main">
$(scrap)
        </div>
        <div id="counter">
            [<span id="counter-current">1</span>/<span id="counter-total"></span>]
        </div>
        <script src="script.js"></script>
    </body>
</html>
EOF

if [ -n "$QUTE_FIFO" ];then
    url="file://$html"
    echo ":open -t $url" >> "$QUTE_FIFO"
fi
