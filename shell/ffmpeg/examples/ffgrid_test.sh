#!/usr/bin/env bash

# 2x2
# 0_0       | w0_0
# 0_h0      | w0_h0

# 3x3
# 0_0       | w0_0       | w0+w0_0       
# 0_h0      | w0_h0      | w0+w0_h0      
# 0_h0+h0   | w0_h0+h0   | w0+w0_h0+h0   

# 4x4
# 0_0       | w0_0       | w0+w0_0       | w0+w0+w0_0
# 0_h0      | w0_h0      | w0+w0_h0      | w0+w0+w0_h0+h0
# 0_h0+h0   | w0_h0+h0   | w0+w0_h0+h0   | w0+w0+w0_h0+h0
# 0_h0+h0+h0| w0_h0+h0+h0| w0+w0_h0+h0+h0| w0+w0+w0_h0+h0+h0

n=3
y=
for (( i=0 ; i < n; i++ ));do
    case "$i" in
        0) w=0 ;;
        1) w=w0 ;;
        *) w="${w}+w0" ;;
    esac
    for (( j=0 ; j < n ; j++ ));do
        case "$j" in
            0) h=0 ;;
            1) h=h0 ;;
            *) h="${h}+h0" ;;
        esac
        y="${y}${w}_${h}\n"
    done
done
echo -ne "$y"

