#!/usr/bin/env bash

shopt -s checkwinsize; (:;:)
stty -echo </dev/tty
tput civis

cleanup() { stty echo </dev/tty; tput cnorm; }
trap cleanup EXIT

update() { read ROWS COLS < <(stty size </dev/tty); }
trap update SIGWINCH
update

move_cursor() { printf '\e[%d;%dH' "$1" "$2"; } # LINE COLUMN

center_text() {
    local n y x text len
    n=$1
    y=$(( (ROWS / 2) + n ))
    x=$(( COLS / 2 ))
    text=$2
    len=${#text}
    move_cursor $y $(( x - (len / 2) ))
    printf '%s' "$text"
}

read_keys() {
    # read -sN1 KEY </dev/tty
    # case "$KEY" in
    #     [a-z]|'') return ;;
    # esac
    read -sN1 -t 0.0001 </dev/tty
    KEY=$REPLY
}

draw() {
    # $1 = starting row(y)   $2 = starting column(x)
    # $3 = width             $4 = height
    # $5 = text
    local sx sy width height x y text
    sx=$2
    sy=$1
    width=$3 width=$(( sx + width ))
    height=$4 height=$(( sy + height ))
    text=$5
    tmp=()
    for (( x = sx ; x < width; x++ ));do
        for (( y = sy ; y < height; y++ ));do
            move_cursor "$y" "$x"
            printf '%s' "$text"
            tmp+=( $y:$x )
        done
    done
    AREA=(${tmp[@]})
}

if [ "$COLUMNS" -gt 80 ];then
    ROWS=$((ROWS / 2))
    COLS=$((COLS / 2))
fi

printf '\e[2J' # clear
center_text 0 'use w and s for the left player, k and j for the right, q to exit'
center_text 2 'press any key'
read -rsN1


declare -a AREA=()
paddle_height=3
paddle_width=1
player1_paddle=$'\e[44m \e[m'
player2_paddle=$'\e[41m \e[m'
player1_score=0
player2_score=0

begin() {
    printf '\e[2J' # clear
    ball_shadow=' '
    player1_y=$(( (ROWS / 2) - (paddle_height / 2) ))
    player1_x=1
    draw $player1_y $player1_x $paddle_width $paddle_height \
        "$player1_paddle"
    player1_area=(${AREA[@]})

    player2_y=$(( (ROWS / 2) - (paddle_height / 2) ))
    player2_x=$(( COLS - paddle_width ))
    draw $player2_y $player2_x $paddle_width $paddle_height \
        "$player2_paddle"
    player2_area=(${AREA[@]})

    ball_width=1
    ball_height=1
    ball=$'\e[30;47mB\e[m'
    ball_y=$(( ( ROWS / 2 ) - (ball_height / 2) ))
    ball_x=$(( ( COLS / 2  ) - (ball_width / 2) ))

    speed=0.088
    ball_dirx=$(echo -e '1\n-1' | shuf -n1)
    ball_diry=$(echo -e '1\n-1' | shuf -n1)
}
begin

while sleep ${speed};do
    for (( y = 1; y < ROWS; y++ ));do
        move_cursor "$y" "$(( COLS / 2 ))"
        printf '.'
    done

    draw $ball_py $ball_px $ball_width $ball_height "$ball_shadow"
    draw $ball_y $ball_x $ball_width $ball_height $ball

    ball_px=$ball_x
    ball_py=$ball_y
    ball_x=$(( ball_x + ball_dirx ))
    ball_y=$(( ball_y + ball_diry ))

    hit=0
    for (( i = 0; i < ${#player1_area[@]}; i++ ));do
        IFS=: read y x <<< "${player1_area[i]}"
        if [ "$ball_x" -eq "$x" ] && [ "$ball_y" -eq "$y" ];then
            ball_shadow=$player1_paddle
            hit=1
            break
        fi
    done

    for (( i = 0; i < ${#player2_area[@]}; i++ ));do
        IFS=: read y x <<< "${player2_area[i]}"
        if [ "$ball_x" -eq "$x" ] && [ "$ball_y" -eq "$y" ];then
            ball_shadow=$player2_paddle
            hit=1
            break
        fi
    done

    if [ "$hit" -eq 1 ];then
        [ "$ball_dirx" -eq 1 ] && ball_dirx=-1 || ball_dirx=1
        ball_x=$ball_px
        ball_y=$ball_py
        if [ $((RANDOM % 2)) -eq 0 ];then
            ball_diry=0
            speed=0.022
        else
            ball_diry=$(echo -e '1\n-1' | shuf -n1)
            speed=0.055
        fi
    fi

    if [ "$ball_x" -ge "$COLS" ];then
        ((player1_score++))
        begin
        continue
    elif [ "$ball_x" -le 1 ];then
        ((player2_score++))
        begin
        continue
    elif [ "$ball_y" -ge "$ROWS" ] || [ "$ball_y" -le 1 ];then
        [ "$ball_diry" -eq 1 ] && ball_diry=-1 || ball_diry=1
    fi

    move_cursor $ROWS 1 
    printf '%s' $player1_score

    move_cursor $ROWS $(( COLS - 2 ))
    printf '%-2s' $player2_score

    read_keys
    case "$KEY" in
        w|s)
            player1_py=$player1_y
            if [ "$KEY" = w ] && [ "$player1_y" -gt 1 ];then
                player1_y=$((player1_y - 1))
            elif [ "$KEY" = s ] &&
                 [ "$((player1_y + paddle_height))" -le "$ROWS" ]
            then
                player1_y=$((player1_y + 1))
            fi

            draw $player1_py $player1_x $paddle_width $paddle_height \
                ' ' 
            draw $player1_y $player1_x $paddle_width $paddle_height \
                "$player1_paddle"

            player1_area=(${AREA[@]})
        ;;
        j|k)
            player2_py=$player2_y
            if [ "$KEY" = k ] && [ "$player2_y" -gt 1 ];then
                player2_y=$((player2_y - 1))
            elif [ "$KEY" = j ] &&
                 [ "$((player2_y + paddle_height))" -le "$ROWS" ]
            then
                player2_y=$((player2_y + 1))
            fi

            draw $player2_py $player2_x $paddle_width $paddle_height \
                ' ' 
            draw $player2_y $player2_x $paddle_width $paddle_height \
                "$player2_paddle"

            player2_area=(${AREA[@]})
        ;;
        q) exit 0 ;;
    esac
done
