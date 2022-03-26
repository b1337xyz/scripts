#!/usr/bin/env bash
PLAYLIST_DIR="$HOME/Music/playlists"
PLAYLIST="$(find "$PLAYLIST_DIR" -type f -exec basename {} \; | dmenu -l 15 -p '>')"
[ -z "$PLAYLIST" ] && exit 1
[ "${PLAYLIST##*.}" != 'm3u' ] && PLAYLIST="${PLAYLIST}.m3u"
PLAYLIST="${PLAYLIST_DIR}/$PLAYLIST"

[ -a "$PLAYLIST" ] || printf "#EXTM3U\n" > "$PLAYLIST"
IFS=',' read -r -a INFO < <(mpc -f '%time%,%title%,%file%' | head -n1)
INFO[0]=$(((${INFO[0]%:*} * 60) + ${INFO[0]##*:}))
INFO[2]=~/Music/"${INFO[2]}"
[ -a "${INFO[2]}" ] || { printf '"%s" does not exit\n' "${INFO[2]}" >&2; exit 1; }
if [ -a "$PLAYLIST" ];then
    while read -r l;do
        [ "${INFO[2]}" = "$l" ] && { printf '%s already in %s\n' "${l##*/}" "$PLAYLIST" >&2; exit 1; }
    done < <(awk '!/^#/{print}' "$PLAYLIST")
fi
cat << EOF >> "$PLAYLIST"
#EXTINF:${INFO[0]},${INFO[1]}
${INFO[2]}
EOF
if [ -n "${INFO[1]}" ];then
    notify-send -t 3500 "${INFO[1]}" "$PLAYLIST"
else
    notify-send -t 3500 "$(basename "${INFO[2]%.*}")" "$PLAYLIST"
fi
