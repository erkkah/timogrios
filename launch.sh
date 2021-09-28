#!/bin/bash

set -e

. settings.env

usage() {
    echo "Usage: $0 [debug]"
}

for arg in $*; do
    case $arg in
        debug)
            DEBUG=1
            ;;
        *)
            usage
            ;;
    esac
done

noTarget() {
    echo "No connected device or running simulator."
    exit 1
}

extractInfoField() {
    local field=$1
    xmllint --xpath "/plist/dict/key[text()='$field']/following-sibling::string[1]/child::text()" Info.plist
}

build() {
    mkdir -p build
    mkdir -p "$BUNDLE"
    cp Info.plist "$BUNDLE"
    make
    cp "$TARGET" "$BUNDLE/$BINARY"
}

extractEntitlements() {
    local profile=$1
    local entitlementsFile=$2
    echo "Extracting entitlements from profile $profile"
    local dict=$(
    security cms -D -i "$profile" | \
    xmllint --xpath "/plist/dict/key[text()='Entitlements']/following-sibling::dict[position()=1]" -
    )
    cat <<DOC > "$entitlementsFile"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> <plist version="1.0">
$dict
</plist>
DOC
}

downloadProfile() {
    local profileID=$1
    echo "Downloading provisioning profile $profileID"
    asc profiles read "$profileID" &>/dev/null || (echo "Profile not found" && exit 1)
    local uuid=$(asc profiles read "$profileID" --csv | tail +2 | cut -f2 -d',')
    asc profiles read "$profileID" --download-path . &>/dev/null
    mv "$uuid.mobileprovision" $PROFILE
}

checkProvisioning() {
    [[ -f "$PROFILE" ]] || downloadProfile $PROVISIONING_PROFILE_ID
    [[ -f "$ENTITLEMENTS" ]] || extractEntitlements $PROFILE "$ENTITLEMENTS"
}

sign() {
    echo codesign -f -s "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" "$BUNDLE"
    codesign -f -s "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" "$BUNDLE"
}

bundle() {
    cp Info.plist "$BUNDLE"
    cp "$TARGET" "$BUNDLE/app"
    cp -r resources/* "$BUNDLE"
}

package() {
    echo "Packaging"
    PAYLOAD=build/Payload
    BUNDLEBASE=$(basename $BUNDLE)
    IPA=${BUNDLEBASE/.app/.ipa}

    rm -rf "$PAYLOAD"
    mkdir -p "$PAYLOAD"
    cp -r "$BUNDLE" "$PAYLOAD/$BUNDLEBASE"
    rm -f $IPA
    (cd $(dirname $PAYLOAD) && zip -r ../$IPA $(basename $PAYLOAD))
}

launchOnDevice() {
    echo "Building for device"
    export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
    export TARGET=build/app.device
    build
    bundle
    cp "$PROFILE" "$BUNDLE"

    echo "Signing for device"
    sign

    echo "Launching on connected device"
    if [[ -z "$DEBUG" ]]; then
        local justLaunch=-L
    fi
    ios-deploy -d $justLaunch -b "$BUNDLE"
}

launchOnSimulator() {
    echo "Building for simulator"
    export SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
    export TARGET=build/app.simulator
    build
    bundle

    echo "Launching on simulator"
    xcrun simctl install booted "$BUNDLE"
    
    if [[ -z "$DEBUG" ]]; then
        xcrun simctl launch booted "$BUNDLE_ID"
    else
        local nameAndPID=$(xcrun simctl launch -w booted "$BUNDLE_ID")
        local PID=${nameAndPID/*:/}
        lldb -o run -p $PID
    fi
}

deviceConnected() {
    ios-deploy -c -t 1
}

verifySimulatorRunning() {
    xcrun simctl getenv booted HOME &> /dev/null || (open -a Simulator && sleep 3)
    xcrun simctl getenv booted HOME &> /dev/null || noTarget
}

PROFILE="embedded.mobileprovision"
BUNDLE_ID=$(extractInfoField CFBundleIdentifier)
BUNDLE=$(extractInfoField CFBundleName).app
BINARY=$(extractInfoField CFBundleExecutable)
ENTITLEMENTS="$BUNDLE_ID.entitlements"

if deviceConnected; then
    checkProvisioning
    launchOnDevice
else
    verifySimulatorRunning
    launchOnSimulator
fi
