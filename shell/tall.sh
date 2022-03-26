#!/usr/bin/env bash
main() {
    find . -maxdepth 1 -iregex '.*\.\(png\|jpg\|webp\|gif\)' | while read -r i;do
        IFS='x' read -r width height < <(mediainfo --Output='Image;%Width%x%Height%' "$i")
        #IFS='x' read -r width height < <(identify -format '%wx%h' "$i")
        [ -z "$width" ] && continue
        [ "$width" -lt "$height" ] && printf '%s\n' "$i"
    done
}

case "$1" in
    ?|-h|--help|help) printf 'Usage: %s [mv cp rm]\n' "${0##*/}" ; exit 0 ;;
    rm)
        main | while read -r i;do rm -vf "$i" ;done ;;
    mv)
        [ -d "$2" ] || { mkdir -vp "$2" || exit 1; }
        main | while read -r i;do mv -vi "$i" "$2" ;done ;;
    cp)
        [ -d "$2" ] || { mkdir -vp "$2" || exit 1; }
        main | while read -r i;do cp -v "$i" "$2" ;done ;;
    *) main ;;
esac

