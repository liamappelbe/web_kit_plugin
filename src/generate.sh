#!/bin/bash
set -e

THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FLUTTER_DIR="$( which flutter )/.."

swiftc -c "$THIS_DIR/../ios/Classes/WebKitPlugin.swift"  \
    -module-name web_kit_plugin                          \
    -target x86_64-apple-ios11.0-simulator               \
    -sdk "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" \
    -F "$FLUTTER_DIR/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator"                             \
    -emit-objc-header-path "$THIS_DIR/WebKitPlugin.h"

dart run ffigen --config="$THIS_DIR/ffigen.yaml"
