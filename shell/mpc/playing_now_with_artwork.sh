#!/usr/bin/env bash
COVERS=~/.cache/covers.local
[ -d "$COVERS" ] || mkdir "$COVERS"

function reset_background {
    printf "\e]20;;100x100+1000+1000\a"
}
reset_background

main() {
    pgrep Xorg &>/dev/null || return 1
    declare -A INFO
    if [ -z "$1" ];then
        IFS=',' read -ra arr < <(mpc -f '%file%,%artist%,%album%,%title%,%time%' 2>/dev/null)
        fpath=~/Music/"${arr[0]}"
        INFO[Filename]="${arr[0]##*/}"
        INFO[Author]="${arr[1]}"
        INFO[Album]="${arr[2]}"
        INFO[Title]="${arr[3]}"
        INFO[Duration]="${arr[4]}"
    else
        fpath=~/Music/"$1"
        INFO[Filename]="${1##*/}"
        INFO[Author]="$2"
        INFO[Album]="$3"
        INFO[Title]="$4"
        INFO[Duration]="$5"
    fi
    check="$(md5sum "$fpath" | awk '{print $1}')"
    if ! [ -f "$COVERS"/"$check".jpg ];then
        tmpdir="$(mktemp -d)"
        ffmpeg -hide_banner -v -8 -i "$fpath" "${tmpdir}"/cover.jpg || rm -rf "$tmpdir"
        if [ -d "$tmpdir" ];then
            cp "$tmpdir"/cover.jpg "$COVERS"/"$check".jpg
            printf "\e]20;${COVERS}/${check}.jpg;64x64+85+24:op=keep-aspect\a"
        fi
    else
        printf "\e]20;${COVERS}/${check}.jpg;64x64+85+24:op=keep-aspect\a"
    fi
    for k in "${!INFO[@]}";do
        [ -n "${INFO[Title]}" ] && [ "$k" = "Filename" ] || [ -z "${INFO[$k]}" ] && continue
        printf '%s: %s\\n' "$k" "${INFO[$k]}"
    done | xargs -0 notify-send -t 5000 "♫ Playing now - $(date +%d/%m/%y' '%H:%M:%S)"
    # I din't find wet, a way to show icons with dunst at the awesome window manager.
    #done | xargs -0 notify-send -i "$COVERS"/"$check".jpg -t 5000 "♫ Playing now - $(date +%d/%m/%y' '%H:%M:%S)"
}
main || exit 1
case $1 in
    --loop)
        trap 'break' 2
        while pgrep Xorg >/dev/null;do
            watch -gtn 5 mpc current >/dev/null
            main || break
        done
    ;;
esac
