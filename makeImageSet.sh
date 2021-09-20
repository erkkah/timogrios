#!/bin/bash

base=$1
color=$2

usage() {
    echo "Usage: $0 <basename> <color>"
    exit
}

[[ -z $base ]] && usage
[[ -z $color ]] && usage

kinds="320x480; 640x960;@2x 640x1136;-568h@2x 750x1334;-667h@2x 1242x2208;-736h@3x \
1125x2436;-1125h 2436x1125;-Landscape-X 768x1024;-Portrait 1024x768;-Landscape \
1536x2048;-Portrait@2x 2048x1536;-Landscape@2x"

for kind in $kinds; do
    size=${kind/;*/}
    mod=${kind/*;/}

    convert -size $size "xc:$color" "${base}${mod}.png"
done
