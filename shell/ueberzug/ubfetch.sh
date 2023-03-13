#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x PREVIEW_ID="preview"
declare -r -x WIDTH=30  # width occupied by the image
declare -r -x HEIGHT=16

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    <"${UEBERZUG_FIFO}" \
        ueberzug layer --parser bash --silent &
    # prevent EOF
    3>"${UEBERZUG_FIFO}" \
        exec
}
function finalise {
    3>&- \
        exec
    rm "${UEBERZUG_FIFO}" &>/dev/null
    clear
}
function draw_img {
    [ -f "$1" ] || return 1
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="0" [y]="0" \
        [width]="$WIDTH" [height]="$HEIGHT" \
        [scaler]=forced_cover [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
export -f draw_img

start_ueberzug
trap finalise EXIT

while [ $# -gt 0 ];do
    case "$1" in
        *) 
            if [ -f "$1" ];then
                img=$1
            elif [ -d "$1" ];then
                img=$(find "$1" -iregex '.*\.\(jpg\|png\)' | shuf -n1)
            fi
        ;;
    esac
    shift
done
[ -z "$img" ] && img=$(find ~/Pictures -iregex '.*\.\(jpg\|png\)' | shuf -n1)
clear
draw_img "$img"

# OS=$(awk -F'"' '/DISTRIB_DESCRIPTION/{print $2}' /etc/lsb-release)
OS=$(awk -F'"' '/PRETTY_NAME/{print $2}' /etc/os-release)
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //g')
PKGS=$(pacman -Qq | wc -l )
MEM=$(free -m | awk '/^Mem:/{printf("%-4sMiB | %sMiB", $3, $2)}')
# SWAP=$(free -m | awk '/^Swap:/{printf("%-4sMiB | %sMiB", $3, $2)}')
IP=$(ip -br a | awk '/wlan0/{print substr($3, 1, length($3)-3)}')
WM=$(wmctrl -m | awk '/^Name:/{print $2}')
# shellcheck disable=SC2046
# TERMINAL=$(ps -p $(ps -p $PPID -o ppid=) o args=)

printf '%'"$WIDTH"'s\e[1;35m os\e[m     \e[1;35m:\e[m %s\n' ' ' "$OS" 
printf '%'"$WIDTH"'s\e[1;35m kernel\e[m \e[1;35m:\e[m %s\n' ' ' "$KERNEL" 
printf '%'"$WIDTH"'s\e[1;35m uptime\e[m \e[1;35m:\e[m %s\n' ' ' "$UPTIME" 
printf '%'"$WIDTH"'s\e[1;35m ip\e[m     \e[1;35m:\e[m %s\n' ' ' "$IP" 
printf '%'"$WIDTH"'s\e[1;35m pkgs\e[m   \e[1;35m:\e[m %s\n' ' ' "$PKGS" 
printf '%'"$WIDTH"'s\e[1;35m wm\e[m     \e[1;35m:\e[m %s\n' ' ' "$WM" 
printf '%'"$WIDTH"'s\e[1;35m term\e[m   \e[1;35m:\e[m %s\n' ' ' "$TERMINAL" 
printf '%'"$WIDTH"'s\e[1;35m memory\e[m \e[1;35m:\e[m %s\n' ' ' "$MEM" 
# printf '%'"$WIDTH"'s\e[1;35m swap\e[m   \e[1;35m:\e[m %s\n' ' ' "$SWAP" 
printf '\n\n%'"$WIDTH"'s  ... PRESS ANY KEY ... '   ' '
read -N 1 -r -s _
