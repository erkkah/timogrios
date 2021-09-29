#!/bin/bash

extractInfoField() {
    local field=$1
    xmllint --xpath "/plist/dict/key[text()='$field']/following-sibling::string[1]/child::text()" Info.plist
}

bundleID=$(extractInfoField CFBundleIdentifier)
bundleName=$(extractInfoField CFBundleDisplayName)

asc bundle-ids register $bundleID "$bundleName"
