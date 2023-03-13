#!/bin/sh

convert "$1" -fill "#4F4F4F" -fuzz 32% -opaque "#1D7CB6" -crop 2000x1210+0+100 out.png

