#!/bin/bash

set -e

. settings.env

usage() {
    echo "Usage: $0 [debug [remote=<port>] | cleanup] ['device' | 'simulator']"
}

noTarget() {
    echo "No connected device or running simulator."
    exit 1
}

extractInfoField() {
    local field=$1
    xmllint --xpath "/plist/dict/key[text()='$field']/following-sibling::string[1]/child::text()" Info.plist
}

clean() {
    rm -rf "$BUNDLE"
}

build() {
    mkdir -p build
    mkdir -p "$BUNDLE"
    cp Info.plist "$BUNDLE"
    make clean && make
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
    codesign -f -s "$SIGNING_IDENTITY" --entitlements "$ENTITLEMENTS" "$BUNDLE"
}

bundle() {
    cp Info.plist "$BUNDLE"
    cp "$TARGET" "$BUNDLE/app"
    cp -r resources/* "$BUNDLE"
    xattr -cr "$BUNDLE"
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

waitForPath() {
    local jsonLog=$1
    
    set +e
    while [[ ! -f "$jsonLog" || ! $(grep DebugServerLaunched "$jsonLog") ]]; do
        sleep 0.5
        grep -q -E 'Event.*:.*Error' "$jsonLog" && \
        grep -E -A2 'Event.*:.*Error' "$jsonLog" && \
        exit 99
    done
    set -e
}

getPath() {
    local jsonLog=$1

    grep -A 2 DebugServerLaunched "$jsonLog" | grep Path | sed -e 's!\\!!g' | cut -f4 -d'"'
}

saveLLDBInitCommands() {
    local deviceApp=$1
    cat <<EOF > .init.lldb
script fruitstrap_device_app="${deviceApp}"
script fruitstrap_connect_url="connect://127.0.0.1:${DEBUG_PORT}"
EOF
}

launchOnDevice() {
    echo "Building for device"
    export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
    export TARGET=build/app.device
    clean
    build
    bundle
    cp "$PROFILE" "$BUNDLE"

    echo "Signing for device"
    sign

    echo "Launching on connected device"
    if [[ -z "$DEBUG" ]]; then
        ios-deploy -L -d -b "$BUNDLE"
    else
        if [[ -z "$DEBUG_PORT" ]]; then
            ios-deploy -d -b "$BUNDLE"
        else
            ios-deploy -N -p $DEBUG_PORT -b "$BUNDLE" --json > .debugserver.json &
            echo $! > .debugserver.pid
            echo -n "Waiting for debug server.."
            waitForPath .debugserver.json
            echo "running"
            local deviceApp=$(getPath .debugserver.json)
            echo "Device app path: $deviceApp"
            saveLLDBInitCommands $deviceApp
        fi
    fi
}

cleanup() {
    set +e
    [[ -f .debugserver.pid ]] && kill $(cat .debugserver.pid)
    rm -f .debugserver.pid .debugserver.json .init.lldb
    exit 0
}

launchOnSimulator() {
    echo "Building for simulator"
    export SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
    export TARGET=build/app.simulator
    clean
    build
    bundle

    echo "Launching on simulator"
    xcrun simctl install booted "$BUNDLE"
    
    if [[ -z "$DEBUG" ]]; then
        xcrun simctl launch booted "$BUNDLE_ID"
    else
        local nameAndPID=$(xcrun simctl launch -w booted "$BUNDLE_ID")
        local PID=${nameAndPID/*:/}
        PID=${PID// /}
        echo "App running with pid $PID"
        if [[ -z "$DEBUG_PORT" ]]; then
            lldb -p $PID -o continue
        else
            debugServer=$(xcode-select -p)/../SharedFrameworks/LLDB.framework/Resources/debugserver
            if [[ -x "$debugServer" ]]; then
                echo "Launching debug server on port $DEBUG_PORT"
                "$debugServer" localhost:$DEBUG_PORT --attach=$PID
            else
                echo "Failed to locate debug server"
                exit 1
            fi
        fi
    fi
}

deviceConnected() {
    ios-deploy -c -t 1
}

simulatorRunning() {
    xcrun simctl getenv booted HOME &> /dev/null
}

verifySimulatorRunning() {
    simulatorRunning || (open -a Simulator && sleep 3)
    simulatorRunning || noTarget
}

for arg in $*; do
    case $arg in
        debug)
            export DEBUG=1
            ;;
        remote=*)
            DEBUG_PORT=${arg/*=/}
            [[ -z "$DEBUG_PORT" ]] && usage
            ;;
        cleanup)
            cleanup
            ;;
        device)
            FORCE_DEVICE=1
            ;;
        simulator)
            FORCE_SIMULATOR=1
            ;;
        *)
            usage
            ;;
    esac
done

BUNDLE_ID=$(extractInfoField CFBundleIdentifier)
BUNDLE=$(extractInfoField CFBundleName).app
BINARY=$(extractInfoField CFBundleExecutable)
PROFILE="$BUNDLE_ID.mobileprovision"
ENTITLEMENTS="$BUNDLE_ID.entitlements"

if [[ $FORCE_DEVICE ]] || deviceConnected && [[ ! $FORCE_SIMULATOR ]]; then
    checkProvisioning
    launchOnDevice
else
    verifySimulatorRunning
    launchOnSimulator
fi
