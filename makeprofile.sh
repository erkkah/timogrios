#!/bin/bash

set -e

KIND=$1

usage() {
    echo "Usage: $0 <development|appstore>"
    exit 1
}

case "$KIND" in
    dev*)
        KIND=ios_app_development
        CERT=ios_development
        DESC="Development"
        ;;
    app*)
        KIND=ios_app_store
        CERT=ios_distribution
        DESC="App Store"
        ;;
    *)
        usage
        ;;
esac

extractInfoField() {
    local field=$1
    xmllint --xpath "/plist/dict/key[text()='$field']/following-sibling::string[1]/child::text()" Info.plist
}

bundleID=$(extractInfoField CFBundleIdentifier)
bundleName=$(extractInfoField CFBundleDisplayName)

serial=$(asc certificates list --filter-type $CERT --csv | tail +2 | cut -f1 -d',')
asc profiles create "$bundleName $DESC" $KIND $bundleID --certificates-serial-numbers $serial

