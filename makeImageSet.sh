#!/bin/bash

type=$1
base=$2
colorOrImage=$3

usage() {
    echo "Usage: $0 <'icon'|'screen'> <basename> <color|image>"
    exit
}

[[ -z "$type" || -z "$base" || -z "$colorOrImage" ]] && usage

screens="320x480; 640x960;@2x 640x1136;-568h@2x 750x1334;-667h@2x 1242x2208;-736h@3x \
1125x2436;-1125h 2436x1125;-Landscape-X 768x1024;-Portrait 1024x768;-Landscape \
1536x2048;-Portrait@2x 2048x1536;-Landscape@2x"

icons="120x120;@2x 180x180;@3x 167x167;-ipadpro@2x 152x152;-ipad@2x 1024x1024;-appstore"

if [[ ! -f "$colorOrImage" ]]; then
    colorOrImage="xc:$colorOrImage"
fi

case $type in
    screen)
        kinds=$screens
        ;;
    icon)
        kinds=$icons
        ;;
    *)
        echo "Unknown type $type"
        exit 1
        ;;
esac

for kind in $kinds; do
    size=${kind/;*/}
    mod=${kind/*;/}

    convert -resize "$size!" "$colorOrImage" "${base}${mod}.png"
done
